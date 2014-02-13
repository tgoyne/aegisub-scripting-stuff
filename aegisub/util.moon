min = (a, b) -> if a < b then a else b
max = (a, b) -> if a > b then a else b
mid = (a, b, c) -> min(max(a, b), c)

-- Make a shallow copy of a table
copy = (tbl) -> {k, v for k, v in pairs tbl}

{:min, :max, :mid, :copy}
