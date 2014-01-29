require 'wx'
require 'moon'

wxm = {k\sub(3), v for k, v in pairs wx}

class Component
  new: (props) =>
    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent) =>
    @parent = parent
    @rendered = @render!
    @control = @rendered\build parent, @
    @control

  destroy: (control) =>
    control\Destroy!

  set_state: (key, value) =>
    @state[key] = value
    @rendered\destroy @control
    @parent\add @build @parent, @
    @parent.window\Layout!

class Label extends Component
  build: (parent, component) =>
    wxm.StaticText parent.window, -1, @props.text

class Column extends Component
  build: (parent, component) =>
    @sizer = wxm.BoxSizer wxm.VERTICAL
    @window = parent.window
    for child in *@props.items
      @sizer\Add child\build @, component
    @sizer

  destroy: (control) =>
    control\Clear true

  add: (control) =>
    @sizer\Add control

class TextCtrl extends Component
  build: (parent, component) =>
    ctrl = wxm.TextCtrl parent.window, -1, @props.value
    if @props.on_change
      ctrl\Connect wxm.EVT_COMMAND_TEXT_UPDATED, ->
        @props.on_change component, new_value: ctrl\GetValue()
    ctrl

class Button extends Component
  build: (parent, component) =>
    btn = wxm.Button parent.window, -1, @props.label
    if @props.on_click
      btn\Connect wxm.EVT_COMMAND_BUTTON_CLICKED, ->
        @props.on_click component
    btn

class Window
  new: (opts) =>
    moon.p opts
    @title = opts.title
    @contents = opts.contents

  show: =>
    frame = wxm.Frame wx.NULL, -1, @title, wxm.DefaultPosition,
                      wxm.Size(600, 400), wxm.DEFAULT_FRAME_STYLE

    @window = frame
    @sizer = wxm.BoxSizer wxm.HORIZONTAL

    @add @contents\build @, @contents
    frame\SetSizerAndFit @sizer
    frame\Show true
    wxm.GetApp!\MainLoop!

  add: (control) =>
    @sizer\Add control

{:Label, :Window, :Component, :Column, :TextCtrl, :Button}
