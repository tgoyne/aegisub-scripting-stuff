gui = require 'aegisub.gui'
require 'moon'
require('fun')()

local *

tr = (str) -> str

data =
  layer: false
  start_time: true
  end_time: true
  style: false
  actor: false
  margin_l: false
  margin_r: false
  margin_v: false
  effect: false
  text: false

class PasteOverDialog extends gui.Component
  initial_state: =>
    @props.fields

  select_all: =>
    for k, _ in pairs @props.fields
      @set_state k, true

  select_none: =>
    for k, _ in pairs @props.fields
      @set_state k, false

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
            items: {
              {label: tr'Layer',           key: 'layer',      value: @state.layer}
              {label: tr'Start Time',      key: 'start_time', value: @state.start_time}
              {label: tr'End Time',        key: 'end_time',   value: @state.end_time}
              {label: tr'Style',           key: 'style',      value: @state.style}
              {label: tr'Actor',           key: 'actor',      value: @state.actor}
              {label: tr'Margin Left',     key: 'margin_l',   value: @state.margin_l}
              {label: tr'Margin Right',    key: 'margin_r',   value: @state.margin_r}
              {label: tr'Margin Vertical', key: 'margin_v',   value: @state.margin_v}
              {label: tr'Effect',          key: 'effect',     value: @state.effect}
              {label: tr'Text',            key: 'text',       value: @state.text}
            }
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
      gui.StandardButtons 'ok', 'cancel', 'help', help_page: 'manual:Paste Over'
    }

window = gui.Window
  title: 'Select Fields to Paste Over'
  contents: PasteOverDialog fields: data

window\show!

