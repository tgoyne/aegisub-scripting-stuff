bit = require 'bit'
moon = require 'moon'
util = require 'aegisub.util'
require'aegisub.gui.base'!
require'fun'!
require 'strict'
require 'wx'

wxm = {k\sub(3), v for k, v in pairs wx}

class GuiControl extends Control
  updaters:
    label: (value) => @control\SetLabel value
    enable: (value) => @control\Enable if value == nil then true else value
    hidden: (value) => @control\Show not value
    tooltip: (value) => @control\SetToolTip value
  force_initial_update: {'tooltip'}

add_updaters = (tbl) ->
  for k, v in pairs GuiControl.updaters
    if tbl[k] == nil
      tbl[k] = v
  tbl

class Label extends GuiControl
  required_props: {'label'}
  do_build: (parent, component) => wxm.StaticText parent.window, -1, @props.label

class TextCtrl extends GuiControl
  required_props: {'value'}
  prop_types: value: 'string'
  updaters: add_updaters value: (new_value) => @control\ChangeValue new_value

  do_build: (parent, component) =>
    with wxm.TextCtrl parent.window, -1, @props.value
      \Connect wxm.EVT_COMMAND_TEXT_UPDATED, ->
        @call 'on_change', \GetValue()

class SpinCtrl extends GuiControl
  required_props: {'value'}
  prop_types:
    value: 'number'
    min: 'number'
    max: 'number'
  updaters: add_updaters
    value: (new_value) => @control\SetValue new_value
    min: (new_value) => @control\SetRange new_value, util.max new_value, @props.max or 100
    max: (new_value) => @control\SetRange util.min(@props.min or 0, new_value), new_value

  do_build: (parent, component) =>
    @built_props = {}
    with wxm.SpinCtrl parent.window, -1
      \Connect wxm.EVT_COMMAND_SPINCTRL_UPDATED, ->
        value = \GetValue()
        if value != @props.value
          @call 'on_change', value

class Button extends GuiControl
  required_props: {'label'}
  prop_types: on_click: 'function'

  do_build: (parent, component) =>
    @built_props = label: @props.label
    with wxm.Button parent.window, -1, @props.label
      \Connect wxm.EVT_COMMAND_BUTTON_CLICKED, ->
        @call 'on_click'

class CheckList extends GuiControl
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

  updaters: add_updaters
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

class ComboBox extends GuiControl
  required_props: {'items'}
  prop_types:
    value: 'string'
    index: 'number'
  updaters: add_updaters
    items: (new_value) => @control\Set new_value
    value: (new_value) => if new_value then @control\SetStringSelection new_value
    index: (new_value) => if new_value then @control\SetSelection new_value

  do_build: (parent, component) =>
    built_props = readonly: @props.readonly, value: @props.value, items: @props.items
    flags = if @props.readonly then wxm.CB_READONLY else 0
    with wxm.ComboBox parent.window, -1, @props.value or '', wxm.DefaultPosition, wxm.DefaultSize, @props.items, flags
      \Connect wxm.EVT_COMMAND_COMBOBOX_SELECTED, ->
        @call 'on_change', \GetSelection(), \GetValue()

class CheckBox extends GuiControl
  required_props: {'label'}
  updaters: add_updaters value: (new_value) => @control\SetValue new_value

  do_build: (parent, component) =>
    @built_props = label: @props.label
    with wxm.CheckBox parent.window, -1, @props.label
      \Connect wxm.EVT_COMMAND_CHECKBOX_CLICKED, (e) ->
        @call 'on_change', e\IsChecked()

button_masks =
  ok:         wxm.OK
  cancel:     wxm.CANCEL
  yes:        wxm.YES
  no:         wxm.NO
  apply:      wxm.APPLY
  close:      wxm.CLOSE
  help:       wxm.HELP
  no_default: wxm.NO_DEFAULT

button_names =
  [wxm.ID_OK]: 'ok'
  [wxm.ID_CANCEL]: 'cancel'
  [wxm.ID_YES]: 'yes'
  [wxm.ID_NO]: 'no'
  [wxm.ID_APPLY]: 'apply'
  [wxm.ID_CLOSE]: 'close'
  [wxm.ID_HELP]: 'help'

class StandardButtons extends Control
  do_build: (parent, component) =>
    buttons = 0
    for btn in *@props.buttons
      flag = button_masks[btn]
      if flag
        buttons = bit.bor buttons, flag

    parent.window\Connect wxm.EVT_COMMAND_BUTTON_CLICKED, (e) ->
      e\Skip!
      name = button_names[e\GetId()]
      if name
        @call 'on_' .. name

    parent.window\CreateButtonSizer buttons

  update: -> false

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

  truncate: (final_count) =>
    for i = @sizer\GetChildren()\GetCount(), final_count + 1, -1
      window = @sizer\GetItem(i - 1)\GetWindow()
      if window
        window\Destroy!
      else
        @sizer\Detach i - 1

  move_item: (src, dst) =>
    assert src > dst
    assert src <= @sizer\GetChildren()\GetCount()
    sizer_item = @sizer\GetItem src - 1
    child = sizer_item\GetSizer() or sizer_item\GetWindow()
    assert child

    @sizer\Detach src - 1
    @sizer\Insert dst - 1, child

class BoxSizer extends Sizer
  create_sizer: (parent, component) =>
    wxm.BoxSizer @props.dir

class StaticBoxSizer extends Sizer
  create_sizer: (parent, component) =>
    wxm.StaticBoxSizer @props.dir, parent.window, @props.label

class Column extends Component
  required_props: {'items'}
  render: => BoxSizer dir: wxm.VERTICAL, items: @props.items

class Row extends Component
  required_props: {'items'}
  render: => BoxSizer dir: wxm.HORIZONTAL, items: @props.items

class StaticBox extends Component
  required_props: {'items', 'direction', 'label'}
  prop_types: direction: 'string'

  render: =>
    dir = if @props.direction == 'vertical' then wxm.VERTICAL else wxm.HORIZONTAL
    StaticBoxSizer dir: dir, label: @props.label, items: @props.items

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
        @window\Fit!

    @window = frame
    @sizer = wxm.BoxSizer wxm.HORIZONTAL

    @add @contents\build @, @contents
    frame\SetSizerAndFit @sizer
    frame\Show true

  add: (control) =>
    @sizer\Add control

  update: =>
    @contents\update!

class Dialog extends Sizer
  required_props: {'title', 'items'}
  prop_types:
    title: 'string'
    items: 'table'
    direction: 'string'

  create_sizer: (parent, component) =>
    @built_props = {}
    @dir = if @props.direction == 'horizontal' then wxm.HORIZONTAL else wxm.VERTICAL
    wxm.BoxSizer @dir

  updaters: add_updaters
    title: (value) => @window\SetTitle value

create_dialog = (component) ->
  frame = wxm.Dialog wx.NULL, -1, '', wxm.DefaultPosition,
                     wxm.Size(600, 400), wxm.DEFAULT_FRAME_STYLE

  frame\Connect wxm.EVT_IDLE, ->
    if component\update!
      frame\Layout!
      frame\Fit!

  sizer = wxm.BoxSizer wxm.HORIZONTAL
  parent =
    window: frame
    add: (ctrl) -> sizer\Add ctrl

  sizer\Add component\build parent, component

  frame\SetSizerAndFit sizer
  frame

show = (component) -> create_dialog(component)\Show true
show_modal = (component) -> create_dialog(component)\ShowModal true

open_dialog = (opts) ->
  flags = wxm.FD_OPEN
  flags = bit.bor flags, wxm.FD_MULTIPLE if opts.multiple
  flags = bit.bor flags, wxm.FD_FILE_MUST_EXIST if opts.must_exist != false -- nil is true

  dialog = wxm.FileDialog wx.NULL, opts.message or '', opts.dir or '', opts.file or '', opts.wildcard or '*.*', flags
  if dialog\ShowModal! == wxm.ID_CANCEL
    return nil
  if opts.multiple then dialog\GetPaths() else dialog\GetPath()

save_dialog = (opts) ->
  flags = wxm.FD_SAVE
  flags = bit.bor flags, wxm.FD_OVERWRITE_PROMPT unless opts.force_overwrite

  dialog = wxm.FileDialog wx.NULL, opts.message or '', opts.dir or '', opts.file or '', opts.wildcard or '*.*', flags
  if dialog\ShowModal! == wxm.ID_CANCEL
    return nil
  dialog\GetPath()

main_loop = -> wxm.GetApp!\MainLoop!

{:Label, :Window, :Component, :Column, :TextCtrl, :Button, :Row, :CheckList,
  :StandardButtons, :StaticBox, :main_loop, :open_dialog, :save_dialog,
  :ComboBox, :CheckBox, :Dialog, :show, :show_modal, :SpinCtrl}
