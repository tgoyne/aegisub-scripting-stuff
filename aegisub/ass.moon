util = require 'aegisub.util'
lpeg = require 'lpeg'
require('fun')()

error    = error
pairs    = pairs
select   = select
sformat  = string.format
tonumber = tonumber
type     = type

local *

-- Generates ASS hexadecimal string from R, G, B integer components, in &HBBGGRR& format
color_str = (c) -> sformat "&H%02X%02X%02X&", c.b or 0, c.g or 0, c.r or 0
-- Format an alpha-string for \Xa style overrides
alpha_str = (a) ->
  a = a.a if type(a) == 'table'
  sformat "&H%02X&", a or 0
-- Format an ABGR string for use in style definitions (these don't end with & either)
style_color_str = (c) -> sformat "&H%02X%02X%02X%02X", c.a or 0, c.b or 0, c.g or 0, c.r or 0

local color_peg
do
  import P, S, R, Ct, Cg, Cc from lpeg
  HexDigit = R'AZ' + R'az' + R'09'
  Comp = (HexDigit * HexDigit) / ((n) -> tonumber n, 16)

  A = Cg Comp, 'a'
  R = Cg Comp, 'r'
  G = Cg Comp, 'g'
  B = Cg Comp, 'b'

  A0 = Cg Cc(0), 'a'
  R0 = Cg Cc(0), 'r'
  G0 = Cg Cc(0), 'g'
  B0 = Cg Cc(0), 'b'

  Prefix = P'&'^-1 * S'Hh'^-1
  Postfix = P'&'^-1

  Style = Prefix * A * B * G * R
  Override = Prefix * A0 * B * G * R * Postfix
  AlphaOverride = Prefix * A * B0 * G0 * R0 * Postfix
  Html = P'#' * A0 * R * G * B

  color_peg = Ct(Style + Override + AlphaOverride + Html)

-- Extract colour components of an ASS colour
parse_color = (s) -> lpeg.match color_peg, s

-- Create an alpha override code from a style definition colour code
alpha_from_style = (scolor) -> alpha_str parse_color scolor

-- Create an colour override code from a style definition colour code
color_from_style = (scolor) -> color_str parse_color scolor

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

local style_peg
do
  import P, S, C, R, Ct, Cg, Cc, match from lpeg

  Space = P' '^0
  IntPeg = Space * P'-'^-1 * R'09'^1 / tonumber * Space * P','^-1
  DoublePeg = Space * (P'-'^-1 * R'09'^1 * (P'.' * R'09'^0)^-1) / tonumber * Space * P','
  StringPeg = Space * C((P(1) - P',')^0) * Space * P','
  BoolPeg = Space * ((P'-1' * Cc true) + P'0' * Cc false) * Space * P','
  ColorPeg = Space * color_peg * Space * P','

  Int = (name) -> Cg IntPeg, name
  Double = (name) -> Cg DoublePeg, name
  String = (name) -> Cg StringPeg, name
  Bool = (name) -> Cg BoolPeg, name
  Color = (name) -> Cg ColorPeg, name

  full_peg  = String'name'
  full_peg *= String'font'
  full_peg *= Double'font_size'
  full_peg *= Color'fill_color' * Color'karaoke_color' * Color'border_color' * Color'shadow_color'
  full_peg *= Bool'bold' * Bool'italic' * Bool'underline' * Bool'strikeout'
  full_peg *= Double'scale_x' * Double'scale_y'
  full_peg *= Double'spacing'
  full_peg *= Double'angle'
  full_peg *= Int'border_style'
  full_peg *= Double'border' * Double'shadow'
  full_peg *= Int'alignment'
  full_peg *= Cg Ct(IntPeg * IntPeg * IntPeg), 'margin'
  full_peg *= Int'encoding'

  style_peg = (str) -> match Ct(full_peg), str

parse_style = (str, skip_trim) ->
  if not skip_trim
    descriptor, str = str\match('([^:]+): *(.+)')
    return nil unless descriptor == 'Style' and str
  style_peg str

{:color_str, :alpha_str, :style_color_str, :parse_color, :alpha_from_style,
  :color_from_style, :parse_time, :time_str, :parse_style}
