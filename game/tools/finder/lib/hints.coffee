servers = [
  4004 # Tempest Reach
  4009 # Celestial Hills
  4012 # Mount Tyrannas
  4021 # Lake of Tears
  4024 # Ascension Valley
  4026 # Valley of Titans
]

module.exports =
  # value validation
  field:
    message:
      cChargeSkill:
        x: 'position'
        y: 'position'
        z: 'position'

      cGetImage:
        image: 'image_name'

      cGivePartyLeader:
        target: 'player_id'

      cMove:
        x1: 'position'
        y1: 'position'
        z1: 'position'

      cUseSkill:
        x1: 'position'
        y1: 'position'
        z1: 'position'

      sAbnormalAdd:
        target: any: ['npc_id', 'pc_id']
        stacks: 'abnormal_stacks'

      sAbnormalRemove:
        target: any: ['npc_id', 'pc_id']

      sAbnormalUpdate:
        target: any: ['npc_id', 'pc_id']
        stacks: 'abnormal_stacks'

      sAbsorbDamage:
        target: any: ['npc_id', 'pc_id']

      sAttackStart:
        source: any: ['npc_id', 'pc_id']

      sAttackEnd:
        source: any: ['npc_id', 'pc_id']

      sAttackResult:
        source: any: ['npc_id', 'pc_id']
        target: any: ['npc_id', 'pc_id']

      sCharacterAnimation:
        target: any: ['npc_id', 'pc_id']

      sConditionAdd:
        target: 'pc_id'

      sGuildMotd:
        motd: none: ['system_message']

      sImage:
        name: 'image_name'

      sNpcDespawn:
        target: 'npc_id'
        x: 'position'
        y: 'position'
        z: 'position'

      sNpcEmotion:
        creature: 'npc_id'

      sNpcInfo:
        id: 'npc_id'

      sNpcMove:
        target: 'npc_id'
        x1: 'position'
        y1: 'position'
        z1: 'position'

      sOutfitText:
        owner: 'player_id'

      sPartyAbnormalAdd:
        target: 'player_id'
        stacks: 'abnormal_stacks'

      sPartyAbnormalList:
        target: 'player_id'
        abnormals:
          stacks: 'abnormal_stacks'

      sPartyAbnormalUpdate:
        target: 'player_id'
        stacks: 'abnormal_stacks'

      sPartyConditionAdd:
        target: 'player_id'

      sPartyConditionActivate:
        target: 'player_id'

      sPartyConditionRemove:
        target: 'player_id'

      sPartyLeader:
        target: 'player_id'

      sPartyMove:
        target: 'player_id'
        x: 'position'
        y: 'position'
        z: 'position'

      sPartyUpdateStats:
        target: 'player_id'
        level: 'level'

      sPartyUpdateHp:
        target: 'player_id'

      sPartyUpdateMp:
        target: 'player_id'

      sPartyUpdateRe:
        target: 'player_id'
        maxRe: 'max_resolve'

      sPlayerMove:
        target: 'pc_id'
        x1: 'position'
        y1: 'position'
        z1: 'position'

      sPlayerOutfit:
        id: 'pc_id'

      sPlayerPosition:
        target: 'pc_id'
        x: 'position'
        y: 'position'
        z: 'position'

      sPlayerUnload:
        target: 'pc_id'

      sProjectile:
        source: 'pc_id'
        x1: 'position'
        y1: 'position'
        z1: 'position'

      sProjectedAttack:
        x1: 'position'
        y1: 'position'
        z1: 'position'
        source: 'pc_id'

      sSystemMessage:
        message: all: ['system_message'], none: ['trade_message']

      sTargetInfo:
        target: any: ['npc_id', 'pc_id']
        level: 'level'
        abnormals:
          stacks: 'abnormal_stacks'

      sTradeMessage:
        message: 'trade_message'

      sUpdateMp:
        target: 'pc_id'

      sUpdateRe:
        maxRe: 'max_resolve'

    type:
      abnormal_stacks: (value) ->
        value > 0

      image_name: (value) ->
        0 is value.lastIndexOf 'guildlogo_', 0

      level: (value) ->
        1 <= value <= 60

      max_resolve: (value) ->
        value in [1200, 1500, 2000]

      npc_id: (value) ->
        value.high >> 16 in [0x0C, 0x0D, 0x0F, 0x11] and
        (value.high & 0xFF00) is 0x8000

      pc_id: (value) ->
        value.low >> 16 in servers and
        (value.high & 0xFF00) is 0x8000

      player_id: (value) ->
        value.low in servers

      position: (value) ->
        0.000001 < Math.abs(value) < 1000000

      system_message: (value) ->
        value.match(/^@(\d+)(\x0B|$)/)?

      trade_message: (value) ->
        match = value.match /^@(\d+)(\x0B|$)/
        !!match and 353 <= match[1] <= 374

  # probably won't ever change
  enumerable:
    cChargeSkill:
      skill: 'skill'

    cChatMessage:
      channel: 'chat_channel'

    cEmote:
      emote: 'character_animation'

    cMove:
      type: 'move_type'

    cUseSkill:
      skill: 'skill'

    sAbnormalAdd:
      id: 'abnormal_id'

    sAbnormalRemove:
      id: 'abnormal_id'

    sAbnormalUpdate:
      id: 'abnormal_id'

    sAttackStart:
      model: 'model'
      skill: 'skill'

    sAttackEnd:
      model: 'model'
      skill: 'skill'

    sAttackResult:
      model: 'model'
      skill: 'skill'

    sCharacterAnimation:
      animation: 'character_animation'

    sChargedSkill:
      skill: 'skill'

    sChatMessage:
      channel: 'chat_channel'

    sConditionAdd:
      id: 'condition_id'

    sConditionActivate:
      id: 'condition_id'

    sConditionList:
      conditions:
        id: 'condition_id'

    sConditionRemove:
      id: 'condition_id'

    sCooldownSkill:
      skill: 'skill'

    sGuildBankLog:
      events:
        item: 'item'

    sInventory:
      items:
        id: 'item'

    sLootSpawn:
      item: 'item'

    sLootWindow:
      item: 'item'

    sNpcDespawn:
      type: 'despawn_type'

    sNpcEmotion:
      emotion: 'npc_emotion'

    sNpcInfo:
      npc: 'npc_id'

    sPartyAbnormalAdd:
      id: 'abnormal_id'

    sPartyAbnormalList:
      abnormals:
        id: 'abnormal_id'
      conditions:
        id: 'condition_id'

    sPartyAbnormalRemove:
      id: 'abnormal_id'

    sPartyAbnormalUpdate:
      id: 'abnormal_id'

    sPartyConditionAdd:
      id: 'condition_id'

    sPartyConditionActivate:
      id: 'condition_id'

    sPartyConditionRemove:
      id: 'condition_id'

    sPlayerMove:
      type: 'move_type'

    sPlayerUnload:
      unk: 'pc_unload_type'

    sProjectile:
      model: 'model'
      skill: 'skill'

    sProjectedAttack:
      model: 'model'

    sServerInfo:
      serverName: 'server_name'

    sTargetInfo:
      abnormals:
        id: 'abnormal_id'
      conditions:
        id: 'condition_id'

    sUpdateHp:
      type: 'update_hp_type'

    sUpdateMp:
      type: 'update_mp_type'

  # probably comes right before another message
  precedes:
    #cChatMessage: 'sChatMessage'
    #cWhisper: 'sWhisper'
    cGetAllianceStandings: 'sAllianceStandings'
    cGetCharacters: 'sCharacterList'
    cGetFriends: 'sFriendUpdate'
    cGetGuildApps: 'sGuildApps'
    cGetGuildInfo: 'sGuildInfo'
    cGivePartyLeader: 'sPartyLeader'
    cPreviewItem: 'sPreviewItem'

  # require non-empty array
  array:
    sConditionList: 'conditions'
    sFriendList: 'friends'
    sFriendUpdate: 'friends'
    sGuildBankLog: 'events'
    sGuildHistory: 'events'
    sOutfitText: 'items'
    sPreviewItem: 'items'

  # custom functions
  custom:
    #sAbsorbDamage: (event) ->
    #  0 < event.damage < 2000000

    sCharacterAnimation: (event) ->
      event.unk1 in [0, 2]
