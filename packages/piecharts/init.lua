--- Pie charts for the SILE typesetting system
--
-- License: MIT
-- Copyright (C) 2022-2025 Omikhleia / Didier Willis
--
local readCsvFile = require("piecharts.csv").readCsvFile
local readCsvString = require("piecharts.csv").readCsvString
local icu = require("justenoughicu")

local PathRenderer = require("grail.renderer")
local Color = require("grail.color")

--- Scale the content to fit within the specified maximum width and height and return it as an hbox.
-- @tparam table content The content to be scaled.
-- @tparam number maxwidth The maximum width for the content in points.
-- @tparam number maxheight The maximum height for the content in points.
-- @treturn hbox The scaled content typeset as an hbox node.
local function scaleContent(content, maxwidth, maxheight)
  local fontTargetSize
  local box
  SILE.call("font", { size = 10 }, function ()
    local tmp = SILE.typesetter:makeHbox(content)
    local rh = (tmp.height:tonumber() + tmp.depth:tonumber()) / maxheight -- height ratio to maxheight
    local rw = tmp.width:tonumber() / maxwidth -- width ratio to maxwidth
    fontTargetSize = 10 / math.max(rh, rw)
  end)
  SILE.call("font", { size = fontTargetSize }, function ()
    box = SILE.typesetter:makeHbox(content)
  end)
  return box
end

--- Format a number to a language-specific string representation.
-- For instance, in English, 1234.56 becomes "1,234.56", while in French, it becomes "1 234,56".
-- @tparam number number The number to format.
-- @tparam number decimals The number of decimal places to include if the number is not an integer.
-- @treturn string The formatted number as a language-dependent string.
local function formatLocalNumber (number, decimals)
  local fmt = (number % 1 == 0 and "%d" or "%." .. decimals .. "f")
  local s = string.format(fmt, number)
  -- NOTE: SU.formatNumber() delegates to the ICU library, but SILE's C wrapper converts
  -- the input to a double and uses ICU unum_formatDouble() to format it.
  -- This might not be robust in all cases, due to floating point precision.
  -- Well, here it should be ok in our case, but we should perhaps remember and report to SILE:
  -- Maybe it should use ICU's unum_formatDecimal() which takes a "numeric string" as input,
  -- following the Decimal Arithmetic Specification...
  return SU.formatNumber(s, { style = "decimal" })
end

local nnsp = luautf8.char(0x2009) -- narrow no-break space

local base = require("packages.base")

local package = pl.class(base)
package._name = "piecharts"

function package:registerCommands ()

  self:registerCommand("piechart", function (options, _)
    local data
    if options._parsed_table_ and type(options._parsed_table_) == "table" then
      data = options._parsed_table_
    else
      local csvfile = SU.required(options, "csvfile", "piechart")
      data = readCsvFile(csvfile)
    end

    local column = SU.cast("integer", options.column or 2)
    if column < 2 then
      SU.error("Invalid column number for piechart")
    end
    local decimals = SU.cast("integer", options.decimals or 0)
    local standout = SU.boolean(options.standout or false)
    local offsetRatio = 0.05 -- (arbitrary) for "standout" top value
    local pieInnerRatio = 0.6 -- (arbitrary) ratio of the inner circle to the outer circle
    local percentage = SU.boolean(options.percentage or false)
    local gradient = SU.boolean(options.gradient or false)
    local cutoff = SU.cast("number", options.cutoff or 0)
    local graphHeight = SU.cast("measurement", options.height or "4em"):tonumber()

    local pieDiameter = (standout and graphHeight * (1 - offsetRatio) or graphHeight)
    local pieDimen = graphHeight
    local pieRadius = pieDiameter / 2

    -- Check, filter and sort data
    local fieldname = icu.case(data.fieldnames[column] or "total", SILE.settings:get("document.language"), "upper")

    data = pl.tablex.filter(data, function (row)
      local value = tonumber(row[column])
      if value and value < 0 then
        SU.error("Negative values are not allowed in piechart")
      end
      return value and value > 0
    end)
    if #data == 0 then
      SU.error("No valid data for piechart")
    end
    table.sort(data, function(a, b)
      return (tonumber(a[column]) or 0) > (tonumber(b[column]) or 0)
    end)
    local totalValue = 0
    for _, entry in ipairs(data) do
      totalValue = totalValue + (tonumber(entry[column]) or 0)
    end

    local cut = 0
    data = pl.tablex.filter(data, function (row)
      local val = tonumber(row[column]) or 0
      if val < cutoff * totalValue then
        cut = cut + (tonumber(row[column]) or 0)
        return false
      end
      return true
    end)
    if #data == 0 then
      SU.error("No valid data for piechart after cutoff")
    end
    if cut > 0 then
      data[#data+1] = pl.tablex.copy(data[#data]) -- hack to keep structure
      data[#data][1] = luautf8.char(0x2026) -- ellipsis
      data[#data].cut = true
      data[#data][column] = tostring(cut)
    end

    -- Color function
    local colorFn
    local H, S, L
    if gradient then
      local startcolor = Color("#4cb252") -- nice greenish color
      H, S, L = startcolor:toHsl()
      colorFn = function (h, s, l, index)
        if data[index].cut then
          return SILE.types.color("200")
        end
        local cscale = 0.6 * (1.0 - l) / #data
        return Color.fromHsl(h, s, l + cscale * (index - 1))
      end
    else
      local startcolor = Color("#b2524c") -- nice reddish color
      H, S, L = startcolor:toHsl()
      colorFn = function (h, s, l, index)
        if data[index].cut then
          return SILE.types.color("200")
        end
        local cscale = 0.6 * (1.0 - l) / #data
        local hscale = 1 / #data
        return Color.fromHsl(h + hscale * (index - 1), s, l + cscale * (index - 1))
      end
    end

    -- Build inner content
    -- Internal portion of the piechart contains the total value and a legend
    -- We reserve space for the legend and the total value, with some padding
    local maxTextSz = 0.70710678 -- sqrt(2)/2 (for 45°)
       * 0.95 * pieInnerRatio * pieDiameter
    local innerBottomBox = scaleContent({ fieldname }, 0.8 * maxTextSz, 0.3 * maxTextSz)
    local totalString = formatLocalNumber(totalValue, decimals)
    local innerTopBox = scaleContent({ totalString }, maxTextSz, 0.7 * maxTextSz)

    local graphics = PathRenderer()

    -- Build piechart sectors
    local start = math.pi / 7 -- arbitrary start angle
    local paths = {}
    for row, v in ipairs(data) do
      local fillcolor = colorFn(H, S, L, row)
      local value = tonumber(v[column]) or 0

      local angle = value / totalValue * 2 * math.pi
      local roff = standout and row == 1 and offsetRatio * pieDiameter or 0
      local midAngle = (start + angle/2)
      local path = graphics:pieSector(roff * math.cos(midAngle), -roff*math.sin(midAngle), pieRadius, start, angle, pieInnerRatio, {
        fill = fillcolor,
        stroke = SILE.types.color("white"),
        strokeWidth = 0.4,
      })
      paths[#paths+1] = path
      start = start + angle
    end

    -- Build labels in a table
    -- first construct the box at current font size and compute the total height
    local legends = {}
    local maxLabelHeight = 0
    for _, entry in ipairs(data) do
      local value = tonumber(entry[column]) or 0
      if percentage then
        local vp = value / totalValue * 100
        value = formatLocalNumber(vp, decimals) .. nnsp .. "%"
      else
        value = formatLocalNumber(value, decimals)
      end
      legends[#legends+1] = entry[1] .. " (" .. value .. ")"
      local shaped = SILE.typesetter:makeHbox({ legends[#legends] })
      maxLabelHeight = SU.max(maxLabelHeight, shaped.height:tonumber())
    end
    -- Rebuild final scaled labels and dots for the legend
    local labelBs = 1.2 -- arbitrary pseudo baseline skip
    local totLabelHeight = labelBs * maxLabelHeight * #legends
    local labelFontRatio = SU.min(1, pieDiameter / totLabelHeight)
    local fontSz = SILE.settings:get("font.size")
    local labelDiameter = 0.5 * maxLabelHeight * labelFontRatio
    local maxLabelWidth = 0
    for i, label in ipairs(legends) do
      -- reshape the label at the new font size, slighty smaller for better effect
      SILE.call("font", { size = 0.9 * fontSz * labelFontRatio }, function ()
        label = SILE.typesetter:makeHbox({ label })
      end)
      local fillcolor = colorFn(H, S, L, i)
      local dot = graphics:circle(0, 0, labelDiameter, {
        fill = fillcolor,
        stroke = "none",
      })
      maxLabelWidth = SU.max(maxLabelWidth, label.width:tonumber())
      legends[i] = { label = label, dot = dot }
    end

    --local pieWidth --= pieHeight -- FIXME
    local graphWidth = pieDiameter  + 2 * labelDiameter + maxLabelWidth + 0.05 * pieDimen

    SILE.typesetter:pushHbox({
      width = SILE.types.length(graphWidth),
      height = SILE.types.length(graphHeight),
      depth = SILE.types.length(),
      outputYourself = function (box, typesetter, line)
        local outputWidth = SU.rationWidth(box.width, box.width, line.ratio)
        local saveX = typesetter.frame.state.cursorX
        local saveY = typesetter.frame.state.cursorY

        -- output piechart
        SILE.outputter:drawSVG(table.concat(paths, " "),
          saveX + pieDiameter/2, saveY - pieDiameter/2, pieDimen, 0, 1)

        -- Output inner content
        typesetter.frame.state.cursorX = saveX + pieDiameter/2 - innerTopBox.width:tonumber()/2

        local innerTopHeight = innerTopBox.height:absolute() + innerTopBox.depth:absolute()
        typesetter.frame.state.cursorY = saveY - (pieDiameter - maxTextSz) / 2
          - (0.7 * maxTextSz - innerTopHeight) / 2
        innerTopBox:outputYourself(typesetter, line)
        typesetter.frame.state.cursorX = saveX + pieDiameter/2 - innerBottomBox.width:tonumber()/2
        typesetter.frame.state.cursorY = saveY - (pieDiameter - maxTextSz) / 2
          - 0.7 * maxTextSz - innerBottomBox.depth:absolute()
        innerBottomBox:outputYourself(typesetter, line)

        -- output legend vertically at the right side of the graph
        local legendX = saveX + pieDiameter --+ 0.5 * maxTextSz
        local legendY = saveY
        for i, legend in ipairs(legends) do
          local ipos = #legends - i
          -- small circle
          local lx = legendX + labelDiameter + 0.05 * pieDimen
          local ly = legendY - ipos * maxLabelHeight * labelFontRatio * labelBs
          SILE.outputter:drawSVG(
            legend.dot,
            lx,
            ly,
            labelDiameter, labelDiameter, 1
          )
          typesetter.frame.state.cursorX = lx + labelDiameter
          typesetter.frame.state.cursorY = ly - 0.25 * legend.label.height:absolute()
          legend.label:outputYourself(typesetter, line)
        end

        typesetter.frame.state.cursorX = saveX
        typesetter.frame.state.cursorY = saveY
        typesetter.frame:advanceWritingDirection(outputWidth)
      end
    })
  end, "Draw a piechart")

end

function package:registerRawHandlers ()

  self:registerRawHandler("piechart", function(options, content)
    local csvdata = SU.ast.contentToString(content):gsub("^%s", ""):gsub("%s$", "")
    options._parsed_table_ = readCsvString(csvdata)
    SILE.call("piechart", options)
  end)

end

package.documentation = [[
\begin{document}
\use[module=packages.piecharts]
The \autodoc:package{piecharts} package provides the \autodoc:command{\piechart[csvfile=<file>]} command, which takes a CSV file as input and draws a pie chart from it.

The CSV data should have at least two columns, the first one being the labels and the second one the values.
The first row of the CSV data is expected to contain the column names.
Empty or null values are skipped, and negative values are not allowed.

The \autodoc:parameter{column=<number>} option may be used to specify which column to use for the values, when there are more than two columns.
When set, the \autodoc:parameter{cutoff=<number>} option specifies a cutoff value, expressed as a percentage of the total value, below which the values are grouped together and displayed as a single pie sector.

\medskip
\begin{center}
\begin[type=piechart,gradient=true,height=6em]{raw}
Player,Score
Mario,55
Luigi,23
Peach,12
Bowser,10
\end{raw}
\glue[width=1.5em plus 1em minus 1em]
\begin[type=piechart,percentage=true,standout=true,cutoff=0.07,height=8em]{raw}
Player,Votes
Geralt,27
Ciri,25
Yennefer,23
Triss,17
Vesemir,15
Lambert,9
Eskel,7
Philippa,3
Bonhart,1
\end{raw}
\end{center}

\smallskip
Two parameters control the visual appearance of the pie chart:

\begin{itemize}
\item{The \autodoc:parameter{height=<measurement>} option (defaulting to 4em) allows to specify the height of the pie chart.

Note that the width cannot be specified, as the labels on the right side of the pie chart will scaled to fit the available vertical space.}
\item{The \autodoc:parameter{gradient=<boolean>} option (defaulting to false) allows to specify the type of color scheme to use.

When set to false, each sector of the pie chart will be colored with a different shade of color. When set to true, a single color will be used, varying in intensity for each sector.}
\end{itemize}

The other options control the appearance of the labels and the legend:

\begin{itemize}
\item{The \autodoc:parameter{decimals=<number>} option (defaulting to 0) allows to specify the number of decimals to display for the values, when they are not integers.}
\item{The \autodoc:parameter{standout=<boolean>} option (defaulting to false) allows to specify whether the first value should be highlighted, that is displayed as slightly extruded from the pie chart.}
\item{The \autodoc:parameter{percentage=<boolean>} option (defaulting to false) allows to specify whether the values should be displayed as percentages.}
\end{itemize}

Including raw CSV content from within a document in SIL syntax is also possible,
using a \code{raw} environment of type \code{piechart}.
It is what is used in the examples above.

\end{document}
]]

return package
