fs = require 'fs'
path = require 'path'

protocol = require '../../lib/protocol'
stream = require '../../lib/protocol/stream'
heuristics = require './lib/heuristics'

fp = process.argv[2]
if !fp?
  console.log "Usage: #{process.argv[0..1].join ' '} <file>"
  process.exit 1



# phase 1: precheck
file = fs.readFileSync fp, 'utf-8'
lines = file.split '\n'
count = lines.length

unknown = []
past1 = []
past2 = []
for line, i in lines
  if i % 10 is 0
    process.stdout.write "precheck: #{i} / #{count} (#{(i * 100 / count).toFixed 1}%)"
    process.stdout.write `'\033[0G'`

  match = line.match /^\*?\s*\d+ \| (<-|->) [0-9A-F]{4} \| ((?:[0-9A-F]{2}(?: |$)){4,})/
  if match
    data = new Buffer match[2].replace(/\s/g, ''), 'hex'
    code = data.readUInt16LE 2
    name = protocol.map.code[code]
    past2.push name ? '?'
    past1.push name ? '?'
    past2 = past1
    past1 = []
    if name?
      heuristics.feed name, protocol.parse name, data
    else
      past1 = []
      unknown.push [match[1], data, past1]

process.stdout.write '\n'
heuristics.save()



# phase 2: run heuristics
unmapped = {}
for name of protocol.messages when !protocol.map.name[name]?
  unmapped[name] = {}

start = Date.now()
length = unknown.length

for [direction, data, lookahead], i in unknown
  if i > 99 and i % 10 is 0
    process.stdout.write "guessing: #{i} / #{length} (#{(i * 100 / length).toFixed 1}%) "
    t = (Date.now() - start) / 1000
    total = length * t / i
    process.stdout.write "ETA: #{Math.round total - t} sec   "
    process.stdout.write `'\033[0G'`

  type = { '<-': 's', '->': 'c' }[direction]
  for name of unmapped when name[0] is type
    buffer = new Buffer data.length
    data.copy buffer
    reader = new stream.Readable buffer, 4

    if heuristics.check protocol.messages[name], reader, lookahead, name
      code = "000#{data.readUInt16LE(2).toString(16).toUpperCase()}"[-4..]
      unmapped[name][code] ?= 0
      unmapped[name][code]++

process.stdout.write '\n'



# output
certain = {}
uncertain = {}

for name, finds of unmapped
  codes = Object.keys finds
  if codes.length is 1
    certain[name] = [codes[0], finds[codes[0]]]
  else
    codes.sort (a, b) -> finds[b] - finds[a]
    uncertain[name] = codes.map (i) -> [i, finds[i]]

fp = path.join __dirname, "data/out-#{Date.now()}.txt"
file = fs.createWriteStream fp

for name, [code, amount] of certain
  file.write "#{name} #{code} # #{amount} samples\n"

file.write '\n'

for name, codes of uncertain
  total = 0
  total += count for [code, count] in codes

  file.write "#{name} - #{total} samples\n"

  for [code, count] in codes[0..9]
    file.write "- #{code}: #{count} (#{(count * 100 / total).toFixed 1}%)\n"

  file.write '\n'

file.end()

console.log 'output written to:', fp
