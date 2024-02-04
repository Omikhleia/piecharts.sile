std = "min+sile"
include_files = {
  "**/*.lua",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  "lua_modules",
  ".lua",
  ".luarocks",
  ".install"
}
globals = {
  -- acceptable as SILE has the necessary compatibility shims:
  -- pl.utils.unpack provides extra functionality and nil handling
  -- but our modules shouldn't be using that anyway.
  "table.unpack"
}
files["**/*_spec.lua"] = {
  std = "+busted"
}
max_line_length = false
ignore = {
  "581", -- operator order warning doesn't account for custom table metamethods
  "212/self", -- unused argument self: counterproductive warning
}
-- vim: ft=lua
