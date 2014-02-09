require 'wx'

get = ->
  data = nil
  cb = wx.wxClipboard.Get()
  if cb\Open!
    if cb\IsSupported wx.wxDF_TEXT
      raw_data = wx.wxTextDataObject()
      cb\GetData raw_data
      data = raw_data\GetText()
    cb\Close!
  data

set = (value) ->
  error 'Clipboard value must be a string', 2 unless type(value) == 'string'

  cb = wx.wxClipboard.Get()
  if cb\Open!
    succeeded = cb\SetData wx.wxTextDataObject value
    cb\Close!
    cb\Flush!
  succeeded
