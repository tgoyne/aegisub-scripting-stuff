util = require 'aegisub.util'

describe 'util.min', ->
  it 'should return nil given no arguments', ->
    assert.is.nil util.min()
  it 'should return the value given one argument', ->
    assert.are.equal 1, util.min 1
  it 'should return the smallest value given several', ->
    assert.are.equal 2, util.min 3, 4, 2
  it 'should return the first smallest value if multiple are equal', ->
    mt = __lt: (a, b) -> a.v < b.v
    wrap = (value) -> setmetatable {v: value}, mt

    a = wrap 7
    b = wrap 5
    c = wrap 5

    assert.are.equal b, util.min a, b, c
    assert.are.equal b, util.min b, a, c
    assert.are.equal b, util.min b, c, a
    assert.are.equal c, util.min a, c, b
    assert.are.equal c, util.min c, a, b
    assert.are.equal c, util.min c, b, a

describe 'util.max', ->
  it 'should return nil given no arguments', ->
    assert.is.nil util.max()
  it 'should return the value given one argument', ->
    assert.are.equal 1, util.max 1
  it 'should return the largest value given several', ->
    assert.are.equal 4, util.max 3, 4, 2

