ass = require 'aegisub.ass'

describe 'alpha_str', ->
  it 'should give &H00& for 0', ->
    assert.are.equal '&H00&', ass.alpha_str 0
  it 'should give &HFF& for 255', ->
    assert.are.equal '&HFF&', ass.alpha_str 255

describe 'style_color_str', ->
  it 'should give a valid abgr color string', ->
    assert.are.equal '&H11223344', ass.style_color_str 68, 51, 34, 17

describe 'parse_color', ->
  it 'should be able to parse style colors', ->
    res = {ass.parse_color '&H11223344'}
    assert.are.same {68, 51, 34, 17}, res

  it 'should be able to parse override colors', ->
    res = {ass.parse_color '&H112233&'}
    assert.are.same {51, 34, 17, 0}, res

  it 'should be able to parse alpha overrides', ->
    res = {ass.parse_color '&H22&'}
    assert.are.same {0, 0, 0, 34}, res

  it 'should be able to parse HTML colors', ->
    res = {ass.parse_color '#112233'}
    assert.are.same {17, 34, 51, 0}, res

describe 'alpha_from_style', ->
  it 'should return an alpha override value from a style color string', ->
    assert.are.equal '&H33&', ass.alpha_from_style '&H33221100'

describe 'parse_time', ->
  it 'should return 0 for an empty string', ->
    assert.are.equal 0, ass.parse_time ''

  it 'should return the correct time for a valid string', ->
    assert.are.equal 16683300, ass.parse_time '4:38:03.30'

  it 'should support commas as the decimal separator', ->
    assert.are.equal 16683300, ass.parse_time '4:38:03,30'

  it 'should support missing hours', ->
    assert.are.equal 2283280, ass.parse_time '38:03.28'

  it 'should support missing hours and minutes', ->
    assert.are.equal 3280, ass.parse_time '03.28'

  it 'should support missing centiseconds', ->
    assert.are.equal 16683000, ass.parse_time '4:38:03'

  it 'should support milliseconds', ->
    assert.are.equal 16683303, ass.parse_time '4:38:03.303'

describe 'time_str', ->
  it 'should give a correct string for a valid time', ->
    assert.are.equal '4:38:03.30', ass.time_str 16683300
