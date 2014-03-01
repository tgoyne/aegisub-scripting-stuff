gui = require 'aegisub.gui.base'
moon = require 'moon'

describe 'Component', ->
  it 'should not be instantiatable directly', ->
    assert.is.error -> gui.Component{}
  it 'should require a props table', ->
    class NoOpComponent extends gui.Component
      render: ->
    assert.is.error -> NoOpComponent!

describe 'Container', ->
  class TestContainer extends gui.Container
    new: (...) =>
      @items = {}
      super ...
    add: (child) => table.insert @items, child
    insert: (index, child) => table.insert @items, index, child
    truncate: (len) =>
      for i = #@items, len + 1, -1
        table.remove @items, i
    move_item: (src, dst) =>
      assert src > dst
      assert src <= #@items
      v = @items[src]
      table.remove @items, src
      table.insert @items, dst, v

  class ControlA extends gui.Control
    do_build: -> { type: 'a', Destroy: -> }

  class ControlB extends gui.Control
    do_build: -> { type: 'b', Destroy: -> }

  class ControlC extends gui.Control
    do_build: -> { type: 'c', Destroy: -> }

  build = (items) ->
    container = TestContainer items: items
    parent = TestContainer items: {container}
    container\build parent, parent
    container, parent

  it 'should build passed in items', ->
    assert.is.equal 0, #build({}).items
    assert.is.equal 1, #build({ControlA{}}).items
    assert.is.equal 2, #build({ControlA({}), ControlB{}}).items

  it 'should support adding items on to the end', ->
    c = build {}

    c\update items: {ControlA{}}
    assert.is.equal 1, #c.items
    assert.is.equal 'a', c.items[1].type

    c\update items: {ControlA({}), ControlB{}}
    assert.is.equal 2, #c.items
    assert.is.equal 'b', c.items[2].type

  it 'should support changing the type of a control at the beginning', ->
    c = build {ControlA({}), ControlB{}}

    c\update items: {ControlB({}), ControlB{}}
    assert.is.equal 2, #c.items
    assert.is.equal 'b', c.items[1].type
    assert.is.equal 'b', c.items[2].type

  it 'should not read out-of-bounds controls when inserting at the beginning', ->
    c = build {ControlA({}), ControlB({}), ControlB({})}

    c\update items: {ControlC({}), ControlB({}), ControlB{}}
    assert.is.equal 3, #c.items
    assert.is.equal 'c', c.items[1].type
    assert.is.equal 'b', c.items[2].type
    assert.is.equal 'b', c.items[3].type

  it 'should recreate controls which have changed type', ->
    c = build {ControlA({}), ControlB{}}
    c.items[1].data = 'stuff'

    c\update items: {ControlB({}), ControlB{}}
    assert.is.nil c.items[1].data

  it 'should not recreate controls which have not changed type', ->
    c = build {ControlA({}), ControlB{}}
    c.items[1].data = 'stuff'

    c\update items: {ControlA({}), ControlA{}}
    assert.is.equal 'stuff', c.items[1].data

  it 'should support inserting a control of a different type at the beginning', ->
    c = build {ControlB({}), ControlB{}}
    c.items[1].data = 'stuff'
    c.items[2].data = 'stuff'

    c\update items: {ControlA({}), ControlB({}), ControlB{}}
    assert.is.equal 3, #c.items

    assert.is.equal 'a', c.items[1].type
    assert.is.nil c.items[1].data

    assert.is.equal 'b', c.items[2].type
    assert.is.equal 'stuff', c.items[2].data

    assert.is.equal 'b', c.items[3].type
    assert.is.equal 'stuff', c.items[3].data

  it 'should remove from end when keys are not present', ->
    c = build {ControlB({}), ControlB{}}
    c.items[1].data = 1
    c.items[2].data = 2

    c\update items: {ControlB{}}
    assert.is.equal 1, #c.items
    assert.is.equal 1, c.items[1].data

  it 'should remove missing keys when keys are used', ->
    c = build {ControlB(key: 1), ControlB(key: 2)}
    c.items[1].data = 1
    c.items[2].data = 2

    c\update items: {ControlB(key: 2)}
    assert.is.equal 1, #c.items
    assert.is.equal 2, c.items[1].data

  it 'should support reordering keyed controls without recreating them', ->
    c = build {ControlB(key: 'a'), ControlB(key: 'b')}
    c.items[1].data = 1
    c.items[2].data = 2

    c\update items: {ControlB(key: 'b'), ControlB(key: 'a')}
    assert.is.equal 2, c.items[1].data
    assert.is.equal 1, c.items[2].data

  it 'should support inserting unkeyed elements between a header and a footer without recreating', ->
    c = build {ControlA({}), ControlB({})}
    c.items[1].data = 1
    c.items[2].data = 2

    c\update items: {ControlA({}), ControlC({}), ControlB({})}
    c.items[2].data = 3
    c\update items: {ControlA({}), ControlC({}), ControlC({}), ControlB({})}

    assert.is.equal 'a', c.items[1].type
    assert.is.equal 'c', c.items[2].type
    assert.is.equal 'c', c.items[3].type
    assert.is.equal 'b', c.items[4].type

    assert.is.equal 1, c.items[1].data
    assert.is.equal 3, c.items[2].data
    assert.is.equal 2, c.items[4].data
