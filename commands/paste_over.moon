app       = require 'aegisub.app'
clipboard = require 'aegisub.clipboard'
gui       = require 'aegisub.gui'
tr        = require 'aegisub.gettext'

require 'moon'
require('fun')()

local *

fields = {
  {label: tr'Layer',           key: 'layer'}
  {label: tr'Start Time',      key: 'start_time'}
  {label: tr'End Time',        key: 'end_time'}
  {label: tr'Style',           key: 'style'}
  {label: tr'Actor',           key: 'actor'}
  {label: tr'Margin Left',     key: 'margin_l'}
  {label: tr'Margin Right',    key: 'margin_r'}
  {label: tr'Margin Vertical', key: 'margin_v'}
  {label: tr'Effect',          key: 'effect'}
  {label: tr'Text',            key: 'text'}
}

class PasteOverDialog extends gui.Component
  initial_state: =>
    @props.data

  select_all: =>
    for field in *@props.fields
      @set_state field.key, true

  select_none: =>
    for field in *@props.fields
      @set_state field.key, false

  select_times: =>
    @select_none!
    @set_state 'start_time', true
    @set_state 'end_time', true

  select_text: =>
    @select_none!
    @set_state 'text', true

  render: =>
    gui.Column items: {
      gui.StaticBox
        direction: 'vertical'
        label: tr'Fields'
        margin: 5
        padding: 5
        expand: true
        items: {
          gui.CheckList
            on_checked: @set_state
            items: [{label: field.label, key: field.key, value: @state[field.key]} for field in *@props.fields]
        }
      gui.Row items: {
        gui.Button
          label: '&All'
          on_click: @select_all
          enable: any ((_, v) -> not v), @state
        gui.Button
          label: '&None'
          on_click: @select_none
          enable: any ((_, v) -> v), @state
        gui.Button
          label: '&Times'
          on_click: @select_times
          enable: any ((k, v) -> not v == (k == 'start_time' or k == 'end_time')), @state
        gui.Button
          label: 'T&ext'
          on_click: @select_text
          enable: any ((k, v) -> not v == (k == 'text')), @state
      }
      gui.StandardButtons buttons: 'ok', 'cancel', 'help', help_page: 'manual:Paste Over'
    }

app.register_command
  name: 'edit/line/paste/over'
  menu: tr'Paste Lines &Over...'
  display: tr'Paste Lines Over'
  help: tr'Paste subtitles over others'
  validate: (context) -> clipboard.get()\len() > 0
  call: (context) ->
    selected = app.options.get 'Tool/Paste Lines Over/Fields'
    data = {f.key, v for _, f, v in zip(fields, selected)}

    window = gui.Window
      title: 'Select Fields to Paste Over'
      contents: PasteOverDialog fields: fields, data: data

    window\show!

