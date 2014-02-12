app = require 'aegisub.app'
gui = require 'aegisub.gui'
lfs = require 'lfs'
moonscript = require 'moonscript'

for file in lfs.dir 'commands'
  if file\match '%.moon$'
    moonscript.dofile "commands/#{file}"

class MainFrame extends gui.Component
  btn: (command) =>
    gui.Button
      label: command.display
      on_click: @btn_click
      on_click_arg: command

  btn_click: (command) =>
    command\call nil

  render: =>
    gui.Column items: [@btn c for c in *@props.commands]

window = gui.Window
  title: 'Aegisub GUI stuff'
  contents: MainFrame commands: app.commands

window\show!
gui.main_loop!
