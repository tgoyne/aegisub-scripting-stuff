min = (...) ->
  ret = nil
  for i = 1, select '#', ...
    v = select i, ...
    if not ret or v < ret
      ret = v
  ret

max = (...) ->
  ret = nil
  for i = 1, select '#', ...
    v = select i, ...
    if not ret or ret < v
      ret = v
  ret

mid = (a, b, c) -> min(max(a, b), c)

-- Make a shallow copy of a table
copy = (tbl) -> {k, v for k, v in pairs tbl}

exportable_mt = __call: (t) ->
  old_strict = __STRICT
  _G.__STRICT = false
  for k, v in pairs t
    _G[k] = v
  _G.__STRICT = old_strict

exportable = (exports) -> setmetatable exports, exportable_mt

{:min, :max, :mid, :copy, :exportable}
