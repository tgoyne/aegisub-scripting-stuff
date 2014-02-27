util = require 'aegisub.util'
require'fun'!
require 'strict'

property_types =
  label: 'string'
  on_change: 'function'
  items: 'table'

shallow_table_eq = (a, b) ->
  return false unless #a == #b
  for _, v1, v2 in zip a, b
    return false unless v1 == v2
  true

class Component
  new: (props) =>
    if not props or type(props) != 'table'
      error 'Contructing a compontent requires a properties table', 3

    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent, component) =>
    assert parent and component and type(component) == 'table'
    @parent = parent
    @component = component
    @destroy!
    @child = @render!
    @child\build parent, @

  destroy: =>
    if @child
      @child\destroy!

  set_state: (key, value) =>
    assert key
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
      assert new_child
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
  required_props: {}
  prop_types: {}
  updaters: {}

  new: (props) =>
    if not props or type(props) != 'table'
      error 'Contructing a compontent requires a properties table', 3

    for k in *@required_props
      if not props[k]
        error "Property '#{k}' is required for #{@@__name}", 3
    for k, v in pairs props
      expected = @@prop_types[k] or property_types[k]
      if expected and type(v) != expected
        error "Property '#{k}' is of type #{type(v)}, but should be of type #{expected}", 3

    @props = props
    @state = {}
    if @initial_state
      @state = @initial_state!

  build: (parent, component) =>
    assert parent and component and type(component) == 'table'

    @destroy!
    @component = component
    @built_props = @props
    @control = @do_build parent, component
    @apply_diff @built_props, @props
    @control

  destroy: =>
    @control\Destroy! if @control

  update: (new_props) =>
    if new_props
      @apply_diff @props, new_props
      @props = new_props
    false

  apply_diff: (old_props, new_props) =>
    assert old_props and type(old_props) == 'table', 'old_props is nil'
    return unless new_props

    for k, v in pairs @@updaters
      old = old_props[k]
      new = new_props[k]
      continue unless new != nil

      if old == nil
        v(@, new)
      elseif type(old) == 'table'
        if not shallow_table_eq old, new
          v(@, new)
      elseif old != new
        v(@, new)

  call: (name, ...) =>
    if @props[name]
      @props[name](@component, ...)

class Container extends Control
  required_props: {'items'}

  do_build: (parent, component) =>
    @window = parent.window
    for child in *@props.items
      @add child\build @, component

  update: (new_props) =>
    if not new_props
      did_update = [child\update! for child in *@props.items]
      return any ((x) -> x), did_update

    new_items = new_props.items
    old_items = @props.items

    any = false
    for i = 1, util.max #new_items, #old_items
      new = new_items[i]
      old = old_items[i]

      if old and new and old.__class == new.__class
        did_update = old\update new.props
        any or= did_update
        continue

      any = true
      old_items[i] = new

      if old
        old\destroy!
      if new
        @insert i, new\build @, @component

    any

util.exportable {:Component, :Control, :Container, :shallow_table_eq}