util = require 'aegisub.util'

error    = error
pairs    = pairs
select   = select
sformat  = string.format
tonumber = tonumber
type     = type

local *

-- Generates ASS hexadecimal string from R, G, B integer components, in &HBBGGRR& format
color_str = (r, g, b) -> sformat "&H%02X%02X%02X&", b, g, r
-- Format an alpha-string for \Xa style overrides
alpha_str = (a) -> sformat "&H%02X&", a
-- Format an ABGR string for use in style definitions (these don't end with & either)
style_color_str = (r, g, b, a) -> sformat "&H%02X%02X%02X%02X", a, b, g, r

-- Extract colour components of an ASS colour
parse_color = (s) ->
  local a, b, g, r

  -- Try a style first
  a, b, g, r = s\match '&H(%x%x)(%x%x)(%x%x)(%x%x)'
  if a then
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)

  -- Then a colour override
  b, g, r = s\match '&H(%x%x)(%x%x)(%x%x)&'
  if b then
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), 0

  -- Then an alpha override
  a = s\match '&H(%x%x)&'
  if a then
    return 0, 0, 0, tonumber(a, 16)

  -- Ok how about HTML format then?
  r, g, b, a = s\match '#(%x%x)(%x?%x?)(%x?%x?)(%x?%x?)'
  if r then
    return tonumber(r, 16), tonumber(g, 16) or 0, tonumber(b, 16) or 0, tonumber(a, 16) or 0

-- Create an alpha override code from a style definition colour code
alpha_from_style = (scolor) -> alpha_str select 4, parse_color scolor

-- Create an colour override code from a style definition colour code
color_from_style = (scolor) ->
  r, g, b = parse_color scolor
  color_str r or 0, g or 0, b or 0

parse_time = (str) ->
  current = 0
  time = 0
  after_decimal = -1

  for c in str\gmatch '[,.:0-9]'
    if c == ':'
      time = time * 60 + current
      current = 0
    elseif c == '.' or c == ','
      time = (time * 60 + current) * 1000
      current = 0
      after_decimal = 100
    elseif after_decimal < 0
      current *= 10
      current += c - '0'
    else
      time += (c - '0') * after_decimal
      after_decimal /= 10

  if after_decimal < 0
      time = (time * 60 + current) * 1000

  util.mid 0, time, 10 * 60 * 60 * 1000 - 1

time_str = (ms) ->
  sformat '%d:%02d:%02d.%02d', ms / 3600000, (ms % 3600000) / 60000,
    (ms % 60000) / 1000, (ms % 1000) / 10

{:color_str, :alpha_str, :style_color_str, :parse_color, :alpha_from_style,
  :color_from_style, :parse_time, :time_str}
