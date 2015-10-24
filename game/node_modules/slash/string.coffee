# from string.js

entities =
  amp: '&'
  lt: '<'
  gt: '>'
  quot: '"'
  apos: "'"

reversedEscapeChars = {}
reversedEscapeChars[v] = k for k, v of entities

module.exports =
  stripTags: (s) -> s.replace /<\/?[^<>]*>/gi, ''

  escapeHTML: (s) -> s.replace /[&<>"']/g, (m) -> "&#{reversedEscapeChars[m]};"

  decodeHTMLEntities: (s) ->
    s
    .replace /&#(\d+);?/g, (_, code) -> String.fromCharCode code
    .replace /&#[xX]([A-Fa-f0-9]+);?/g, (_, hex) -> String.fromCharCode parseInt hex, 16
    .replace /&([^;\W]+;?)/g, (m, e) ->
      switch typeof target = entities[e.replace /;$/, '']
        when 'number'
          String.fromCharCode target
        when 'string'
          target
        else
          m
