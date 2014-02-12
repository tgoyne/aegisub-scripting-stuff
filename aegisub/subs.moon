copy = (tbl) -> {k, v for k, v in pairs tbl}

class SubtitlesFileBackingStore
  new: =>
    @script_info =
      Title: 'Default Aegisub File'
      ScriptType: 'v4.00+'
      WrapStyle: '0'
      ScaledBorderAndShadow: 'yes'
      PlayResX: '1280'
      PlayResY: '720'
      'YCbRcMatrix': 'None'
    @styles = {}
    @dialogue = {}

  apply_changes: (changes) =>
    for change in *changes
      {change_type, table, index, value} = change
      switch change_type
        when 'insert'
          table.insert @[table], index, value
        when 'set'
          @[table][index] = value
        when 'delete'
          table.remove @[table], index

copy_line_proxy = =>
  copy = {}
  for k, _ in pairs getmetatable(@).__index
    copy[k] = @[k]
  copy

line_proxy = (line) ->
  proxy = setmetatable({}, __index: line)
  proxy.copy = copy_dialogue_proxy
  proxy

class ProxyTable
  new: => @proxies = {}
  get: (line) =>
    return unless line
    proxy = @proxies[line]
    if not proxy
      proxy = line_proxy line
      @proxies[line] = proxy
    proxy

styles_table = (backing, pending_changes) ->
  proxy = newproxy true
  tbl = copy backing.styles
  style_proxies = ProxyTable()

  with getmetatable(proxy)
    .__len = => #tbl
    .__index = (k) =>
      style_proxies\get if type(k) == 'number'
        tbl[k]
      else
        for style in *tbl
          return style if style.name == k

    .__newindex = (k, v) =>
      if type(k) == 'string'
        for i = 1, #self
          if tbl[i].name == k
            k = i
            break
        if type(k) == 'string'
          k = #self + 1

      tbl[k] = v
      table.insert pending_changes, {'style', 'set', k, v}
  proxy

script_info_table = (backing, pending_changes) ->
  proxy = newproxy true
  tbl = copy backing.script_info

  with getmetatable(proxy)
    .__len = -> #tbl
    .__index = (k) => tbl[k]
    .__newindex = (k, v) =>
      tbl[k] = v
      table.insert pending_changes, {'script_info', 'set', k, v}
  proxy

dialogue_table = (backing, pending_changes) ->
  proxy = newproxy true
  tbl = copy backing.dialogue
  dialogue_proxies = ProxyTable()

  with getmetatable(proxy)
    .__len = -> #tbl
    .__index = (k) =>
      dialogue_proxies\get tbl[k]

    .__newindex = (k, v) =>
      tbl[k] = v
      table.insert pending_changes, {'dialogue', 'set', k, v}
  proxy

class SubtitlesFile
  new: =>
    @_backing = SubtitlesFileBackingStore()
    @_pending_changes = {}

    @script_info = script_info_table @_backing, @_pending_changes
    @styles = styles_table @_backing, @_pending_changes
    @dialogue = dialogue_table @_backing, @_pending_changes

