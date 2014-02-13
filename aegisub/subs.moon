ass = require 'aegisub.ass'
util = require 'aegisub.util'

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
  tbl = util.copy backing.styles
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
  tbl = util.copy backing.script_info

  with getmetatable(proxy)
    .__len = -> #tbl
    .__index = (k) => tbl[k]
    .__newindex = (k, v) =>
      tbl[k] = v
      table.insert pending_changes, {'script_info', 'set', k, v}
  proxy

dialogue_table = (backing, pending_changes) ->
  proxy = newproxy true
  tbl = util.copy backing.dialogue
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

  save: (filename) =>
    file = io.open filename, 'wb'

    file\write '[Script Info]\n'
    for key, value in pairs @script_info
      file\write string.format '%s: %s\n', key, value

    file\write '\n[V4+ Styles]\n'
    file\write 'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n'
    for style in *@styles
      file\write string.format 'Style: %s,%s,%g,%s,%s,%s,%s,%d,%d,%d,%d,%g,%g,%g,%g,%d,%g,%g,%i,%i,%i,%i,%i',
        style.name, style.font, style.fontsize,
        ass.style_color_str style.primary,
        ass.style_color_str style.secondary,
        ass.style_color_str style.outline,
        ass.style_color_str style.shadow,
        if style.bold then -1 else 0,
        if style.italic then -1 else 0,
        if style.underline then -1 else 0,
        if style.strikeout then -1 else 0,
        style.scale_x, style.scale_y, style.spacing, style.angle,
        style.border_style, style.outline_w, style.shadow_x, style.alignment,
        style.margin[0], style.margin[1], style.margin[2], style.encoding

    file\write '\n[Events]\n'
    file\write 'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'
    for event in *@dialogue
      file\write string.format '%s: %d,%s,%s,%s,%s,%d,%d,%d,%s,%s\n',
        if event.comment then 'Comment' else 'Dialogue',
        event.layer,
        ass.time_str event.start_time,
        ass.time_str event.end_time,
        event.style, event.actor,
        event.margin[0], event.margin[1], event.margin[2],
        event.effect, event.text

{:SubtitlesFile}

