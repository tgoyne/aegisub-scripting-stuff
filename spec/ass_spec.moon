ass = require 'aegisub.ass'

describe 'alpha_str', ->
  it 'should give &H00& for 0', ->
    assert.are.equal '&H00&', ass.alpha_str 0
  it 'should give &H00& for table without alpha', ->
    assert.are.equal '&H00&', ass.alpha_str r: 255, g: 255, b: 255
  it 'should give &HFF& for 255', ->
    assert.are.equal '&HFF&', ass.alpha_str 255
  it 'should give &HFF& for {a: 255}', ->
    assert.are.equal '&HFF&', ass.alpha_str a: 255

describe 'style_color_str', ->
  it 'should give a valid abgr color string', ->
    assert.are.equal '&H11223344', ass.style_color_str r: 68, g: 51, b: 34, a: 17

describe 'parse_color', ->
  it 'should be able to parse style colors', ->
    assert.are.same {r: 68, g: 51, b: 34, a: 17}, ass.parse_color '&H11223344'

  it 'should be able to parse override colors', ->
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color '&H112233&'

  it 'should be able to parse alpha overrides', ->
    assert.are.same {r: 0, g: 0, b: 0, a: 34}, ass.parse_color '&H22&'

  it 'should be able to parse HTML colors', ->
    assert.are.same {r: 17, g: 34, b: 51, a: 0}, ass.parse_color '#112233'

  it 'should be able to parse malformed garbage', ->
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color '&H112233'
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color '&h112233'
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color 'h112233'
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color '112233'
    assert.are.same {r: 51, g: 34, b: 17, a: 0}, ass.parse_color '&112233'

    assert.are.same {r: 0, g: 0, b: 0, a: 34}, ass.parse_color '&H22'
    assert.are.same {r: 0, g: 0, b: 0, a: 34}, ass.parse_color '&h22'
    assert.are.same {r: 0, g: 0, b: 0, a: 34}, ass.parse_color 'H22'
    assert.are.same {r: 0, g: 0, b: 0, a: 34}, ass.parse_color '22'

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

describe 'parse_style', ->
  it 'should return nil when given a non-style', ->
    assert.is.nil ass.parse_style 'Dialogue: not a style line'
    assert.is.nil ass.parse_style 'no colon at all'

  it 'should return a correct style table when given a valid string', ->
    style = ass.parse_style 'Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H9C3131CB,&H00000000,-1,0,-1,0,90,110,1.1,5.5,1,2,3,7,10,20,30,1'
    assert.is.not.nil style
    assert.are.equal 'Default', style.name
    assert.are.equal 'Arial', style.font
    assert.are.equal 20, style.font_size
    assert.are.same {r: 255, g: 255, b: 255, a: 0}, style.fill_color
    assert.are.same {r: 255, g: 0, b: 0, a: 0}, style.karaoke_color
    assert.are.same {r: 203, g: 49, b: 49, a: 156}, style.border_color
    assert.are.same {r: 0, g: 0, b: 0, a: 0}, style.shadow_color
    assert.is.true style.bold
    assert.is.false style.italic
    assert.is.true style.underline
    assert.is.false style.strikeout
    assert.are.equal 90, style.scale_x
    assert.are.equal 110, style.scale_y
    assert.are.equal 1.1, style.spacing
    assert.are.equal 5.5, style.angle
    assert.are.equal 1, style.border_style
    assert.are.equal 2, style.border
    assert.are.equal 3, style.shadow
    assert.are.equal 7, style.alignment
    assert.are.same {10, 20, 30}, style.margin
    assert.are.equal 1, style.encoding

describe 'parse_event', ->
  it 'should return a correct dialogue table with given a valid string', ->
    event = ass.parse_event 'Dialogue: 2,0:00:00.00,0:00:05.00,Default,actor,5,10,15,effect,hello, world'
    assert.is.not.nil event
    assert.is.false event.comment
    assert.is.equal 2, event.layer
    assert.is.equal 0, event.start_time
    assert.is.equal 5000, event.end_time
    assert.is.equal 'Default', event.style
    assert.is.equal 'actor', event.actor
    assert.is.same {5, 10, 15}, event.margin
    assert.is.equal 'effect', event.effect
    assert.is.equal 'hello, world', event.text

  it 'should handle commented lines', ->
    event = ass.parse_event 'Comment: 2,0:00:00.00,0:00:05.00,Default,actor,5,10,15,effect,hello, world'
    assert.is.not.nil event
    assert.is.true event.comment
    assert.is.equal 2, event.layer
    assert.is.equal 0, event.start_time
    assert.is.equal 5000, event.end_time
    assert.is.equal 'Default', event.style
    assert.is.equal 'actor', event.actor
    assert.is.same {5, 10, 15}, event.margin
    assert.is.equal 'effect', event.effect
    assert.is.equal 'hello, world', event.text
