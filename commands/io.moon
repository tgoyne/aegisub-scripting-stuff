app = require 'aegisub.app'
gui = require 'aegisub.gui'
subs = require 'aegisub.subs'
tr = require 'aegisub.gettext'
moon = require 'moon'

app.register_command
  name: 'subtitle/open'
  menu: tr'Open'
  display: tr'Open'
  call: (context) =>
    filename = gui.open_dialog
      message: tr'Open subtitles file'
      wildcard: '*.ass'
    return unless filename

    context.subs = subs.open filename

app.register_command
  name: 'subtitle/save'
  menu: tr'Save'
  display: tr'Save'
  call: (context) =>
    filename = gui.save_dialog
      message: tr'Save subtitles file'
      wildcard: '*.ass'
    return unless filename

    context.subs\save filename
