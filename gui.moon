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
    @destroy!
    @child = @render!
    @child\build parent, @

  destroy: =>
    if @child
      @child\destroy!

  set_state: (key, value) =>
    @state[key] = value
    @dirty = true

  call: (name, value) =>
    if @props[name]
      @props[name](value)

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
    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent, component) =>
    @destroy!
    @control = @do_build parent, component
    @control

  destroy: =>
    @control\Destroy! if @control

  update: (new_props) =>
    false

class Label extends Control
  do_build: (parent, component) =>
    wxm.StaticText parent.window, -1, @props.text

  update: (new_props) =>
    return unless new_props
    if new_props.text != @props.text
      @control\SetLabel new_props.text
    @props = new_props
    false

class Column extends Control
  do_build: (parent, component) =>
    @component = component
    @sizer = wxm.BoxSizer wxm.VERTICAL
    @window = parent.window
    for child in *@props.items
      @sizer\Add child\build @, component
    @sizer

  destroy: =>
    if @control
      @control\Clear true

  add: (control) =>
    @sizer\Add control

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
        @sizer\Add new\build @, @component
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
          @sizer\Add new\build @, @component
          any = true
          old_items[i] = new

    any

class TextCtrl extends Control
  do_build: (parent, component) =>
    ctrl = wxm.TextCtrl parent.window, -1, @props.value
    if @props.on_change
      ctrl\Connect wxm.EVT_COMMAND_TEXT_UPDATED, ->
        @props.on_change component, new_value: ctrl\GetValue()
    ctrl

  update: (new_props) =>
    return unless new_props
    if new_props.value != @props.value
      @control\ChangeValue new_props.value
    @props = new_props
    false

class Button extends Control
  do_build: (parent, component) =>
    btn = wxm.Button parent.window, -1, @props.label
    if @props.on_click
      btn\Connect wxm.EVT_COMMAND_BUTTON_CLICKED, ->
        @props.on_click component
    btn

  update: (new_props) =>
    return unless new_props
    if new_props.label != @props.label
      @control\SetLabel new_props.value
    @props = new_props
    false

class Window
  new: (opts) =>
    moon.p opts
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
    wxm.GetApp!\MainLoop!

  add: (control) =>
    @sizer\Add control

  update: =>
    @contents\update!

{:Label, :Window, :Component, :Column, :TextCtrl, :Button}
