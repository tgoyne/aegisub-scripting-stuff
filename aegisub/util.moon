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

{:min, :max, :mid, :copy}
