_p = pairs
_ip = ipairs
export pairs = (t, ...) -> (t and getmetatable(t) and getmetatable(t).__pairs or _p) t, ...
export ipairs = (t, ...) -> (t and getmetatable(t) and getmetatable(t).__ipairs or _ip) t, ...

app  = require 'aegisub.app'
gui  = require 'aegisub.gui'
subs = require 'aegisub.subs'
tr   = require 'aegisub.gettext'
util = require 'aegisub.util'

class TextProperty extends gui.Component
  on_change: (new_value) =>
    @call 'on_change', @props.key, new_value
  render: =>
    gui.Row items: {
      gui.Label label: @props.label
      gui.TextCtrl value: @props.value, on_change: @on_change
    }

class FilePropertiesDialog extends gui.Component
  initial_state: => util.copy @props.file.info
  make_text_property: (label, key) =>
    TextProperty label: label, key: key, value: @state[key] or '', on_change: @set_state
  set_sbas: (value) => @set_state 'ScaledBorderAndShadow', value and 'yes' or 'no'
  set_res: (value, field) => @set_state field, value

  render: =>
    gui.Dialog
      title: tr'Script Properties'
      items: {
        gui.StaticBox
          direction: 'vertical'
          label: tr'Script'
          items: {
            @make_text_property tr'Title:', 'Title'
            @make_text_property tr'Original script:', 'Original Script'
            @make_text_property tr'Translation:', 'Original Translation'
            @make_text_property tr'Editing:', 'Original Editing'
            @make_text_property tr'Timing:', 'Original Timing'
            @make_text_property tr'Synch point:', 'Synch Point'
            @make_text_property tr'Updated by:', 'Script Updated By'
            @make_text_property tr'Update details:', 'Update Details'
          }
        gui.StaticBox
          direction: 'horizontal'
          label: tr'Resolution'
          items: {
            gui.SpinCtrl
              value: tonumber @state.PlayResX
              max: 10000
              on_change: @set_res
              on_change_arg: 'PlayResX'
            gui.Label label: 'x'
            gui.SpinCtrl
              value: tonumber @state.PlayResY
              max: 10000
              on_change: @set_res
              on_change_arg: 'PlayResY'
            gui.Button
              label: tr'From &video'
              on_click: @set_from_video
              enable: false
          }
        gui.StaticBox
          direction: 'flexgrid'
          label: tr'Options'
          items: {
            gui.Row items: {
              gui.Label label: tr'Wrap Style: '
              gui.ComboBox
                readonly: true
                items: {
                  tr'0: Smart wrapping, top line is wider'
                  tr'1: End-of-line word wrapping, only \\N breaks'
                  tr'2: No word wrapping, both \\n and \\N break'
                  tr'3: Smart wrapping, bottom line is wider'
                }
                index: tonumber @state.WrapStyle
            }
            gui.Row items: {
              --gui.Spacer 0
              gui.CheckBox
                label: tr'Scale Border And Shadow'
                tooltip: tr'Scale border and shadow together with script/render resolution. If this is unchecked, relative border and shadow size will depend on renderer.'
                value: @state.ScaledBorderAndShadow == 'yes'
                on_change: @set_sbas
            }
          }
        gui.StandardButtons
          buttons: {'ok', 'cancel', 'help'}
          on_ok: =>
            for k, v in pairs @state
              @props.file.info[k] = v
      }

app.register_command
  name: 'subtitle/properties'
  menu: tr'&Properties...'
  display: tr'Properties'
  help: tr'Open script properties window'
  call: (context) =>
    gui.show FilePropertiesDialog file: context.subs

