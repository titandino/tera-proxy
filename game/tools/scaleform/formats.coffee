module.exports =
  'ui-packet':
    0x08: { name: 'version' } # ?
    0x12: { name: 'count' } # ?
    0x32: { }
    0x43: { }
    0x52: { name: 'data', many: true, format: 'ui-data-class' }
  'ui-data-class':
    0x08: { name: 'version' } # ?
    0x52: { name: 'name', type: 'string' } # alt. 'class'
    0xA2: { name: 'data', type: 'slice' }
    0xF0: { name: 'more' } # ?
    0x140: { name: 'originalLength' }
  'class-S1ChatController':
    0x08: { name: 'version' } # ?
    0x12: { name: 'tab', many: true, format: 'chat-tab' }
    0x22: { name: 'channel', many: true, format: 'chat-channel' }
    0x28: { name: 'unk', format: 'chat-unk' }
  'chat-tab':
    0x050: { name: 'position' }
    0x0A0: { }
    0x0F0: { }
    0x140: { }
    0x190: { }
    0x1E0: { }
    0x232: { name: 'name', type: 'string' }
    0x28D: { name: 'fontSize', type: 'float' }
    0x2D0: { name: 'oapcity' }
    0x322: { name: 'channels', many: true, format: 'tab-channel' }
  'tab-channel':
    0x3A: { name: 'name', type: 'string' }
  'chat-channel':
    0x0A: { name: 'name', type: 'string' }
    0x10: { name: 'r' }
    0x18: { name: 'g' }
    0x20: { name: 'b' }
  'chat-unk': {}
