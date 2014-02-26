bit = require 'bit'
require 'wx'
require 'moon'

wxm = {k\sub(3), v for k, v in pairs wx}

class Component
  new: (props) =>
    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent, component) =>
    @parent = parent
    @component = component
    @destroy!
    @child = @render!
    @child\build parent, @

  destroy: =>
    if @child
      @child\destroy!

  set_state: (key, value) =>
    @state[key] = value
    @dirty = true

  call: (name, ...) =>
    if @props[name]
      @props[name](@component, ...)

  update: (new_props) =>
    if new_props
      @props = new_props
    if @dirty or new_props
      @dirty = false
      new_child = @render!
      if new_child.__class == @child.__class
        @child\update new_child.props
      else
        @destroy!
        @child = new_child
        @parent\add @child\build @parent, @
      true
    else if @child
      @child\update!
    else
      false

class Control
  new: (props) =>
    for k in *@required_props
      if not props[k]
        error "Property '#{k}' is required for #{@@__name}", 3
    for k, v in pairs @prop_types
      if props[k] and type(props[k]) != v
        error "Property '#{k}' is of type #{type(props[k])}, but should be of type #{v}", 3

    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent, component) =>
    @destroy!
    @component = component
    @control = @do_build parent, component
    @control

  destroy: =>
    @control\Destroy! if @control

  update: (new_props) =>
    false

  call: (name, ...) =>
    if @props[name]
      @props[name](@component, ...)

  required_props: {}
  prop_types: {}

class Label extends Control
  required_props: {'text'}
  prop_types: text: 'string'

  do_build: (parent, component) =>
    wxm.StaticText parent.window, -1, @props.text

  update: (new_props) =>
    return unless new_props
    if new_props.text != @props.text
      @control\SetLabel new_props.text
    @props = new_props
    false

class Container extends Control
  required_props: {'items'}
  prop_types: items: 'table'

  do_build: (parent, component) =>
    @window = parent.window
    for child in *@props.items
      @add child\build @, component
    nil

  update: (new_props) =>
    if not new_props
      any = false
      for child in *@props.items
        did_update = child\update!
        any or= did_update
      return any

    new_items = new_props.items
    old_items = @props.items

    count = if #new_items > #old_items then #new_items else #old_items

    any = false
    for i = 1, count
      new = new_items[i]
      old = old_items[i]
      if new and not old
        @add new\build @, @component
        any = true
        table.insert(old_items, new)
      else if old and not new
        old\destroy!
        any = true
        table.remove(old_items, i)
      else
        if old.__class == new.__class
          did_update = old\update new.props
          any or= did_update
        else
          old\destroy!
          @add new\build @, @component
          any = true
          old_items[i] = new

    any

class Sizer extends Container
  do_build: (parent, component) =>
    @sizer = @create_sizer parent, component
    super parent, component
    @sizer

  destroy: =>
    if @control
      @control\Clear true

  add: (control) =>
    flags = wxm.SizerFlags()
    flags = flags\Expand()
    flags = flags\Border()
    @sizer\Add control, flags

class Column extends Sizer
  dir: wxm.VERTICAL
  create_sizer: (parent, component) =>
    wxm.BoxSizer @dir

class Row extends Sizer
  dir: wxm.HORIZONTAL
  create_sizer: (parent, component) =>
    wxm.BoxSizer @dir

class StaticBox extends Sizer
  required_props: {'items', 'direction', 'label'}
  prop_types:
    items: 'table'
    direction: 'string'
    label: 'string'

  create_sizer: (parent, component) =>
    @dir = if @props.direction == 'vertical' then wxm.VERTICAL else wxm.HORIZONTAL
    wxm.StaticBoxSizer @dir, parent.window, @props.label

class TextCtrl extends Control
  required_props: {'value'}
  prop_types:
    value: 'string'
    on_change: 'function'

  do_build: (parent, component) =>
    ctrl = wxm.TextCtrl parent.window, -1, @props.value
    ctrl\Connect wxm.EVT_COMMAND_TEXT_UPDATED, ->
      @call 'on_change', ctrl\GetValue()
    ctrl

  update: (new_props) =>
    return unless new_props
    if new_props.value != @props.value
      @control\ChangeValue new_props.value
    @props = new_props
    false

class Button extends Control
  required_props: {'label'}
  prop_types:
    label: 'string'
    on_click: 'function'

  do_build: (parent, component) =>
    btn = wxm.Button parent.window, -1, @props.label
    btn\Connect wxm.EVT_COMMAND_BUTTON_CLICKED, ->
      @call 'on_click', @props.on_click_arg
    @props.enable = true if @props.enable == nil
    if not @props.enable
      btn\Enable false
    btn

  update: (new_props) =>
    return unless new_props
    if new_props.label != @props.label
      @control\SetLabel new_props.value
    new_props.enable = true if new_props.enable == nil
    if new_props.enable != @props.enable
      @control\Enable new_props.enable
    @props = new_props
    false

class CheckList extends Control
  build: (parent, component) =>
    @destroy!
    @component = component
    labels = [item.label for item in *@props.items]
    @values = [false for item in *@props.items]
    @control = wxm.CheckListBox parent.window, -1, wxm.DefaultPosition, wxm.DefaultSize, labels
    @set_values!
    @control\Connect wxm.EVT_COMMAND_CHECKLISTBOX_TOGGLED, (e) ->
      idx = e\GetInt()
      value = @control\IsChecked idx
      @values[idx + 1] = value
      @call 'on_checked', @props.items[idx + 1].key, value
    @control

  set_values: =>
    for i = 1, #@props.items
      new_value = @props.items[i].value
      if new_value != @values[i]
        @values[i] = new_value
        @control\Check(i - 1, new_value)
    nil

  update: (new_props) =>
    return unless new_props
    -- TODO handle changed labels
    @props = new_props
    @set_values!
    false

class ComboBox extends Control
  required_props: {'items'}
  prop_types:
    items: 'table'
    value: 'string'
    index: 'number'
    on_change: 'function'

  do_build: (parent, component) =>
    flags = if @props.readonly then wxm.CB_READONLY else 0
    @value = @props.value
    @items = @props.items
    cmb = wxm.ComboBox parent.window, -1, @value or '', wxm.DefaultPosition, wxm.DefaultSize, @items, flags
    cmb\Connect wxm.EVT_COMMAND_COMBOBOX_SELECTED, ->
      @call 'on_change', cb\GetSelection(), cb\GetValue(), @props.on_change_arg
    @do_update cmb
    cmb

  table_cmp: (a, b) =>
    return false if #a != #b
    for _, v1, v2 in zip a, b
      return false if v1 != v2
    true

  do_update: (ctrl) =>
    if not @table_cmp @props.items, @items
      @items = @props.items
      ctrl\Set @items
    if @props.value and @props.value != @value
      @value = @props.value
      ctrl\SetStringSelection @value
    if @props.index and @props.index != @index
      @index = @props.index
      ctrl\SetSelection @index

  update: (new_props) =>
    if new_props
      @props = new_props
      @do_update @control
    false

class CheckBox extends Control
  required_props: {'label'}
  prop_types:
    label: 'string'
    on_change: 'function'

  do_build: (parent, component) =>
    cb = wxm.CheckBox parent.window, -1, @props.label
    if @props.value
      cb\SetValue true
    cb\Connect wxm.EVT_COMMAND_CHECKBOX_CLICKED, (e) ->
      @call 'on_change', e\IsChecked(), @props.on_change_arg
    cb

  update: (new_props) =>
    return unless new_props
    if new_props.value != @props.value
      cb\SetValue new_props.value
    if new_props.label != @props.label
      cb\SetLabel new_props.label
    @props = new_props
    false

class StandardButtons extends Control
  do_build: (parent, component) =>
    wxm.StaticText parent.window, -1, 'standardbuttons'
  update: => false

class Window
  new: (opts) =>
    @title = opts.title
    @contents = opts.contents

  show: =>
    frame = wxm.Frame wx.NULL, -1, @title, wxm.DefaultPosition,
                      wxm.Size(600, 400), wxm.DEFAULT_FRAME_STYLE

    frame\Connect wxm.EVT_IDLE, ->
      if @update!
        @window\Layout!

    @window = frame
    @sizer = wxm.BoxSizer wxm.HORIZONTAL

    @add @contents\build @, @contents
    frame\SetSizerAndFit @sizer
    frame\Show true

  add: (control) =>
    @sizer\Add control

  update: =>
    @contents\update!

open_dialog = (opts) ->
  flags = wxm.FD_OPEN
  flags = bit.band flags, wxm.FD_MULTIPLE if opts.multiple
  flags = bit.band flags, wxm.FD_FILE_MUST_EXIST if opts.must_exist != false -- nil is true

  dialog = wxm.FileDialog wx.NULL, opts.message or '', opts.dir, opts.file, opts.wildcard or '*.*', flags
  if dialog\ShowModal! == wxm.ID_CANCEL
    return nil
  if opts.multiple then dialog\GetPaths() else dialog\GetPath()

save_dialog = (opts) ->
  flags = wxm.FD_SAVE
  flags = bit.band flags, wxm.FD_OVERWRITE_PROMPT unless opts.force_overwrite

  dialog = wxm.FileDialog wx.NULL, opts.message or '', opts.dir, opts.file, opts.wildcard or '*.*', flags
  if dialog\ShowModal! == wxm.ID_CANCEL
    return nil
  dialog\GetPath()

main_loop = -> wxm.GetApp!\MainLoop!

{:Label, :Window, :Component, :Column, :TextCtrl, :Button, :Row, :CheckList,
  :StandardButtons, :StaticBox, :main_loop, :open_dialog, :save_dialog, :ComboBox, :CheckBox}
