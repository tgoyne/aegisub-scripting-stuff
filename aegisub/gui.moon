bit = require 'bit'
moon = require 'moon'
util = require 'aegisub.util'
require'aegisub.gui.base'!
require'fun'!
require 'strict'
require 'wx'

wxm = {k\sub(3), v for k, v in pairs wx}

class Label extends Control
  required_props: {'text'}
  prop_types: text: 'string'
  updaters: text: (new_value) => @control\SetLabel new_value
  do_build: (parent, component) => wxm.StaticText parent.window, -1, @props.text

class TextCtrl extends Control
  required_props: {'value'}
  prop_types: value: 'string'
  updaters: value: (new_value) => @control\ChangeValue new_value

  do_build: (parent, component) =>
    with wxm.TextCtrl parent.window, -1, @props.value
      \Connect wxm.EVT_COMMAND_TEXT_UPDATED, ->
        @call 'on_change', ctrl\GetValue()

class Button extends Control
  required_props: {'label'}
  prop_types: on_click: 'function'
  updaters:
    label: (new_value) => @control\SetLabel new_value
    enable: (new_value) => @control\Enable new_value

  do_build: (parent, component) =>
    @built_props = label: @props.label
    with wxm.Button parent.window, -1, @props.label
      \Connect wxm.EVT_COMMAND_BUTTON_CLICKED, ->
        @call 'on_click', @props.on_click_arg

  update: (new_props) =>
    if new_props and new_props.enable == nil
      new_props.enable = true
    super new_props

class CheckList extends Control
  do_build: (parent, component) =>
    @built_properties = {}
    @labels = [item.label for item in *@props.items]
    @values = [false for item in *@props.items]
    with wxm.CheckListBox parent.window, -1, wxm.DefaultPosition, wxm.DefaultSize, @labels
      \Connect wxm.EVT_COMMAND_CHECKLISTBOX_TOGGLED, (e) ->
        idx = e\GetInt()
        value = @control\IsChecked idx
        if value != @values[idx + 1]
          @values[idx + 1] = value
          @call 'on_checked', @props.items[idx + 1].key, value

  updaters:
    items: (new_items) =>
      labels = [item.label for item in *new_items]
      if not shallow_table_eq @labels, labels
        @control\Set labels
        @labels = labels

      values = [item.value for item in *new_items]
      for i = 1, #values
        if values[i] != @values[i]
          @control\Check i - 1, values[i]
      @values = values

class ComboBox extends Control
  required_props: {'items'}
  prop_types:
    value: 'string'
    index: 'number'
  updaters:
    items: (new_value) => @control\Set new_value
    value: (new_value) => if new_value then @control\SetStringSelection new_value
    index: (new_value) => if new_value then @control\SetSelection new_value

  do_build: (parent, component) =>
    built_props = readonly: @props.readonly, value: @props.value, items: @props.items
    flags = if @props.readonly then wxm.CB_READONLY else 0
    with wxm.ComboBox parent.window, -1, @props.value or '', wxm.DefaultPosition, wxm.DefaultSize, @props.items, flags
      \Connect wxm.EVT_COMMAND_COMBOBOX_SELECTED, ->
        @call 'on_change', cb\GetSelection(), cb\GetValue(), @props.on_change_arg

class CheckBox extends Control
  required_props: {'label'}
  updaters:
    value: (new_value) => @control\SetValue new_value
    label: (new_value) => @control\SetLabel new_value

  do_build: (parent, component) =>
    @built_props = label: @props.label
    with wxm.CheckBox parent.window, -1, @props.label
      \Connect wxm.EVT_COMMAND_CHECKBOX_CLICKED, (e) ->
        @call 'on_change', e\IsChecked(), @props.on_change_arg

class StandardButtons extends Control
  do_build: (parent, component) =>
    wxm.StaticText parent.window, -1, 'standardbuttons'
  update: => false

class Sizer extends Container
  do_build: (parent, component) =>
    @sizer = @create_sizer parent, component
    super parent, component
    @sizer

  destroy: =>
    if @control
      @control\Clear true

  add: (control) =>
    assert control, 'Control is nil'
    @sizer\Add control, wxm.SizerFlags()\Expand()\Border()

  insert: (pos, control) =>
    assert control, 'Control is nil'
    @sizer\Insert pos - 1, control, wxm.SizerFlags()\Expand()\Border()

  remove: -> -- Do nothing since destroyed the control removes it

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
  prop_types: direction: 'string'

  create_sizer: (parent, component) =>
    @dir = if @props.direction == 'vertical' then wxm.VERTICAL else wxm.HORIZONTAL
    wxm.StaticBoxSizer @dir, parent.window, @props.label

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
