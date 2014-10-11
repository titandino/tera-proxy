module.exports = class CircularBuffer
  constructor: (@size = 65536) ->
    @buffer = new Buffer @size
    @length = 0
    @start = 0
    @end = 0

  write: (data) ->
    length = data.length
    space = @size - @end
    if length > space
      data.copy @buffer, @end, 0, space
      data.copy @buffer, 0, space
      @end = length - space
    else
      data.copy @buffer, @end
      @end += length
    @length += length

  peek: (amount) ->
    out = new Buffer amount
    space = @size - @start
    if amount < space
      @buffer.copy out, 0, @start, @start + amount
    else
      @buffer.copy out, 0, @start, @size
      @buffer.copy out, space, 0, amount - space
    out

  read: (amount) ->
    out = new Buffer amount
    space = @size - @start
    if amount < space
      @buffer.copy out, 0, @start, @start += amount
    else
      @buffer.copy out, 0, @start, @size
      @buffer.copy out, space, 0, @start = amount - space
    @length -= amount
    out
