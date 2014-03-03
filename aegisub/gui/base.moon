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

append_varpack = (a, n, b, ...) ->
  if n == 0 then a else b, append_varpack a, n - 1, ...

call_handler = (name, ...) =>
  fn = @props[name]
  return unless fn

  arg = @props[name .. '_arg']
  if not arg
    return fn @component, ...
  count = select '#', ...
  if count == 0
    return fn @component, arg
  fn @component, append_varpack arg, count, ...

class Component
  new: (props) =>
    if not @render
      error 'Components must have a render method', 3
    if not props or type(props) != 'table'
      error 'Contructing a compontent requires a properties table', 3

    @props = props
    @state = if @initial_state then @initial_state! else {}

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

  call: call_handler

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

apply_diff = (old_props, new_props) =>
  assert old_props and type(old_props) == 'table', 'old_props is nil'
  return unless new_props

  for k, v in pairs @@updaters
    old = old_props[k]
    new = new_props[k]
    continue unless new != nil

    if old and type(old) == 'table'
      if not shallow_table_eq old, new
        v(@, new)
    elseif not old or old != new
      v(@, new)

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

    if @force_initial_update
      if @built_pors == @props
        @built_props = util.copy @props
      for prop in *@force_initial_update
        @built_props[prop] = nil

    @apply_diff @built_props, @props
    @control

  destroy: =>
    @control\Destroy! if @control

  apply_diff: apply_diff

  update: (new_props) =>
    if new_props
      @apply_diff @props, new_props
      @props = new_props
    false

  call: call_handler

class Container extends Control
  required_props: {'items'}

  do_build: (parent, component) =>
    @window = parent.window
    for child in *@props.items
      @add child\build @, component

  apply_diff: apply_diff

  update: (new_props) =>
    if not new_props
      did_update = [child\update! for child in *@props.items]
      return any ((x) -> x), did_update

    @apply_diff @props, new_props

    keyed = {}
    unkeyed = {}
    for i, item in ipairs @props.items
      if item.props.key
        keyed[item.props.key] = i
      else
        table.insert unkeyed, i

    positions = {}
    existing_item_for = (item) ->
      key = item.props.key
      if key
        idx = keyed[key]
        return @props.items[idx], idx

      cls = item.__class
      position = positions[cls] or 1
      for i = position, #unkeyed
        if @props.items[unkeyed[i]].__class == cls
          positions[cls] = i + 1
          idx = unkeyed[i]
          return @props.items[idx], idx

      positions[cls] = #unkeyed + 1
      return nil

    new_items = {}
    needs_layout = false
    new_contents = {}

    for new_idx, new_item in ipairs new_props.items
      old_item, old_idx = existing_item_for new_item
      if old_item
        table.insert new_items, old_item
        table.insert new_contents, old_idx
        child_needs_layout = old_item\update new_item.props
        needs_layout or= child_needs_layout
      else
        table.insert new_items, new_item
        table.insert new_contents, new_item\build @, @component
        needs_layout = true

    -- This is O(n^2) for reversing a list. Might be worth caring about.
    incr = 0
    for i, control in ipairs new_contents
      if type(control) == 'number'
        control += incr
        continue if i == control

        assert control > i
        @move_item control, i

        for j = i + 1, #new_contents
          v = new_contents[j]
          if type(v) == 'number' and v >= i and v < control
            new_contents[j] += 1
      else
        incr += 1
        @insert i, control

    @truncate #new_contents
    @props.items = new_items
    needs_layout

util.exportable {:Component, :Control, :Container, :shallow_table_eq}
