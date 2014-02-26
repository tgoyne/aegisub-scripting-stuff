subs = require 'aegisub.subs'

_p = pairs
_ip = ipairs
pairs = (t, ...) -> (getmetatable(t).__pairs or _p) t, ...
ipairs = (t, ...) -> (getmetatable(t).__ipairs or _ip) t, ...

describe 'SubtitlesFile', ->
  local file
  before_each -> file = subs.SubtitlesFile!

  describe 'Script Info', ->
    it 'should set fields by default', ->
      assert.are.equal '0', file.info.WrapStyle
      assert.are.equal 'v4.00+', file.info.ScriptType

    it 'should support modifying fields', ->
      file.info.Title = 'File title'
      assert.are.equal 'File title', file.info.Title

    it 'should support looping over the fields with `pairs`', ->
      assert.has_no.errors ->
        for key, value in pairs file.info
          key = value

  describe 'Styles', ->
    it 'should initially be empty', ->
      assert.are.equal, 0, #file.styles
    it 'should support inserting new styles', ->
      assert.has_no_errors ->
        file.styles[1] = {name: 'Default'}
        assert.is.not.nil file.styles[1]
    it 'should support inserting new styles by name', ->
      assert.has_no_errors ->
        file.styles['Default'] = {name: 'Default'}
        assert.is.not.nil file.styles['Default']
    it 'should support looking up styles by name', ->
        file.styles[1] = {name: 'Default'}
        assert.is.not.nil file.styles['Default']
    it 'should be case-insensitive when looking up styles', ->
        file.styles[1] = {name: 'Default'}
        assert.is.not.nil file.styles['default']
    it 'should support in-place mutation', ->
        file.styles[1] = {name: 'Default'}
        file.styles[1].font_size = 20
        assert.is.equal 20, file.styles[1].font_size
    it 'should support looping over the fields with `ipairs`', ->
      assert.has_no.errors ->
        for i, style in ipairs file.styles
          key = value

describe 'open', ->
  it 'should be able to open a simple test file', ->
    file = subs.open 'aegisub/tests/files/test.ass'
    assert.is.not.nil file
    assert.is.equal 1, #file.styles
    assert.is.equal 1, #file.events
    assert.is.equal 'File Title', file.info.Title

