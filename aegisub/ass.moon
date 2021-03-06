util = require 'aegisub.util'
lpeg = require 'lpeg'
require'fun'!
require 'checks'

error    = error
pairs    = pairs
select   = select
sformat  = string.format
tonumber = tonumber
type     = type
tinsert  = table.insert

local *

local color_peg, style_peg, time_peg, event_peg, dialogue_body_peg
do
  import P, S, R, C, V, Ct, Cg, Cc, Cf, match from lpeg

  -- Time parsing
  Hours = R'09' / ((n) -> 60 * 60 * 1000 * tonumber n)
  Minutes = (R'05' * R'09') / ((n) -> 60 * 1000 * tonumber n)
  Seconds = (R'05' * R'09' * (S'.,' * R'09'^0)^-1) / (n) ->
    n = n\gsub ',', '.'
    1000 * tonumber n

  time_peg = Cf Hours * ':' * Minutes * ':' * Seconds + Minutes * ':' * Seconds + Seconds, op.add

  -- Color parsing
  HexDigit = R'AZ' + R'az' + R'09'
  Comp = (HexDigit * HexDigit) / ((n) -> tonumber n, 16)

  Ac = Cg Comp, 'a'
  Rc = Cg Comp, 'r'
  Gc = Cg Comp, 'g'
  Bc = Cg Comp, 'b'

  A0 = Cg Cc(0), 'a'
  R0 = Cg Cc(0), 'r'
  G0 = Cg Cc(0), 'g'
  B0 = Cg Cc(0), 'b'

  Prefix = P'&'^-1 * S'Hh'^-1
  Postfix = P'&'^-1

  Style = Prefix * Ac * Bc * Gc * Rc
  Override = Prefix * A0 * Bc * Gc * Rc * Postfix
  AlphaOverride = Prefix * Ac * B0 * G0 * R0 * Postfix
  Html = P'#' * A0 * Rc * Gc * Bc

  color_peg = Ct(Style + Override + AlphaOverride + Html)

  -- Style parsing
  Space = P' '^0
  IntPeg    = Space * P'-'^-1 * R'09'^1 / tonumber * Space * P','^-1
  DoublePeg = Space * (P'-'^-1 * R'09'^1 * (P'.' * R'09'^0)^-1) / tonumber * Space * P','
  StringPeg = Space * C((P(1) - P',')^0) * Space * P','
  BoolPeg   = Space * ((P'-1' * Cc true) + P'0' * Cc false) * Space * P','
  ColorPeg  = Space * color_peg * Space * P','
  TimePeg   = Space * time_peg * Space * P','

  Int    = (name) -> Cg IntPeg, name
  Double = (name) -> Cg DoublePeg, name
  String = (name) -> Cg StringPeg, name
  Bool   = (name) -> Cg BoolPeg, name
  Color  = (name) -> Cg ColorPeg, name
  Time   = (name) -> Cg TimePeg, name

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

  -- Dialogue parsing
  event_peg  = Int'layer'
  event_peg *= Time'start_time' * Time'end_time'
  event_peg *= String'style'
  event_peg *= String'actor'
  event_peg *= Cg Ct(IntPeg * IntPeg * IntPeg), 'margin'
  event_peg *= String'effect'
  event_peg *= Cg P(1)^0, 'text'

  event_peg = Ct event_peg

  -- Dialogue body parsing
  ArgChar = P(1) - S'\\},)'
  BasicArg = C (ArgChar - P'(') * (ArgChar - P' ' + P' '^1 * ArgChar)^0
  ArgSep = Space * ',' * Space

  TagName = C(P'r' + P'fn' + (R'09' + R'az') * R'az'^0)

  Comment = Ct Cc'comment' * C (P(1) - S'\\}')^1

  BlockContents = P{
    'BlockContents',
    Arg: BasicArg + Ct (V'BlockContents' - P')')^1
    Args: (P'(' * Space * V'Arg' * (ArgSep * V'Arg')^0 * Space * (P')' + #P'}')) + V'Arg'^-1
    Tag: P'\\' * Space * Ct(Cc'tag' * TagName * Space * V'Args')
    BlockContents: P' '^1 + V'Tag' + Comment
  }

  OverrideBlock = '{' * BlockContents^0 * '}'

  PlainText = Ct Cc'text' * C (P(1) - OverrideBlock)^1
  dialogue_body_peg = Ct (OverrideBlock + PlainText)^0

-- Generates ASS hexadecimal string from R, G, B integer components, in &HBBGGRR& format
color_str = (c) ->
  checks 'table'
  sformat "&H%02X%02X%02X&", c.b or 0, c.g or 0, c.r or 0
-- Format an alpha-string for \Xa style overrides
alpha_str = (a) ->
  checks 'table|number'
  a = a.a if type(a) == 'table'
  sformat "&H%02X&", a or 0
-- Format an ABGR string for use in style definitions (these don't end with & either)
style_color_str = (c) ->
  checks 'table'
  sformat "&H%02X%02X%02X%02X", c.a or 0, c.b or 0, c.g or 0, c.r or 0

-- Extract colour components of an ASS colour
parse_color = (s) ->
  checks 'string'
  lpeg.match color_peg, s

-- Create an alpha override code from a style definition colour code
alpha_from_style = (scolor) -> alpha_str parse_color scolor

-- Create an colour override code from a style definition colour code
color_from_style = (scolor) -> color_str parse_color scolor

parse_time = (str) ->
  checks 'string'
  lpeg.match(time_peg, str) or 0

time_str = (ms) ->
  checks 'number'
  sformat '%d:%02d:%02d.%02d', ms / 3600000, (ms % 3600000) / 60000,
    (ms % 60000) / 1000, (ms % 1000) / 10

parse_style = (str, descriptor) ->
  checks 'string', '?string'
  if not descriptor
    descriptor, str = str\match('([^:]+): *(.+)')
    return nil unless descriptor == 'Style' and str
  style_peg str

parse_event = (str, descriptor) ->
  checks 'string', '?string'
  if not descriptor
    descriptor, str = str\match('([^:]+): *(.+)')
    return nil unless (descriptor == 'Dialogue' or descriptor == 'Comment') and str
  event = lpeg.match event_peg, str
  event.comment = descriptor == 'Comment' if event
  event

lex_dialogue_body = (str) ->
  checks 'string'
  lpeg.match dialogue_body_peg, str

gen_dialogue_body = (tbl) ->
  checks 'table'

  tag_str = (tok) ->
    tag_name = '\\' .. tok[2]
    return tag_name if #tok == 2
    return tag_name .. tok[3] if #tok == 3 and tok[2] != 'clip'

    out = {tag_name, '('}
    for i = 3, #tok
      if type(tok[i]) == 'table' then
        for _, tag in ipairs tok[i]
          tinsert out, tag_str tag
      else
        tinsert out, tok[i]
      if i < #tok
        tinsert out, ','
    tinsert out, ')'
    table.concat out, ''

  out = {}
  state = 'text'

  for _, tok in ipairs tbl
    old_state = state
    state = tok[1]
    if state != old_state
      if old_state == 'text'
        tinsert out, '{'
      elseif state == 'text'
        tinsert out, '}'
      else
        tinsert out, '}{'

    switch state
      when 'text', 'comment'
        tinsert out, tok[2]

      when 'tag'
        tinsert out, tag_str tok

  if state != 'text'
    tinsert out, '}'
  table.concat out, ''

{:color_str, :alpha_str, :style_color_str, :parse_color, :alpha_from_style,
  :color_from_style, :parse_time, :time_str, :parse_style, :parse_event,
  :lex_dialogue_body, :gen_dialogue_body}
