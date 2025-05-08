package = "piecharts.sile"
version = "dev-1"
source = {
  url = "git+https://github.com/Omikhleia/piecharts.sile.git",
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
  "grail"
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.piecharts"] = "packages/piecharts/init.lua",
    ["sile.piecharts.csv"] = "piecharts/csv.lua",
  }
}
