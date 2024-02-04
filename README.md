# piecharts.sile

[![License](https://img.shields.io/github/license/Omikhleia/piecharts.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/piecharts.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/piecharts.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/piecharts.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/piecharts.sile)

This collection of packages for the [SILE](https://github.com/sile-typesetter/sile) typesetting system provides for the rendering of pie (donut) charts.

![Example](./samplepies.png)

## Installation

These packages require SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.

To install the latest development version and all its dependencies (see below),
you may use the provided “rockspec”:

```
luarocks --lua-version 5.4 install piecharts.sile
```

(Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.)

## Usage

Once the collection is installed, the **piecharts** experimental package is available.
It provides basic tools for reading a CSV file and rendering a pie (donut) chart.

## License

The code in this repository is released under the MIT License, Copyright 2024, Omikhleia.
