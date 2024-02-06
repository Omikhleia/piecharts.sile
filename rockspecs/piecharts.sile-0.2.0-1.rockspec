rockspec_format = "3.0"
package = "piecharts.sile"
version = "0.2.0-1"
source = {
  url = "git+https://github.com/Omikhleia/piecharts.sile.git",
  tag = "v0.2.0",
}
description = {
  summary = "Pie charts for the SILE typesetting system.",
  detailed = [[
    This collection packages for the SILE typesetter system allows reading CSV files
    and rendering pie (donut) charts from them.
  ]],
  homepage = "https://github.com/Omikhleia/piecharts.sile",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.piecharts"] = "packages/piecharts/init.lua",
    ["sile.piecharts.color"] = "piecharts/color.lua",
    ["sile.piecharts.csv"] = "piecharts/csv.lua",
    ["sile.piecharts.arc"] = "piecharts/arc.lua",
    ["sile.piecharts.drawing"] = "piecharts/drawing.lua",
  }
}
