--- Pie charts for the SILE typesetting system
--
-- @copyright License: MIT (c) 2024 Omikhleia, Didier Willis
--
local arcToBezierCurves = require("piecharts.arc")

local _r = function(number)
  -- integers should stay, and round floats as some PDF readers do not like
  -- double precision.
  return math.floor(number) == number and math.floor(number) or tonumber(string.format("%.5f", number))
end

local pdfColorHelper = function(color, stroke)
  local colspec
  local colop
  if color.r then -- RGB
    colspec = table.concat({ _r(color.r), _r(color.g), _r(color.b) }, " ")
    colop = stroke and "RG" or "rg"
  elseif color.c then -- CMYK
    colspec = table.concat({ _r(color.c), _r(color.m), _r(color.y), _r(color.k) }, " ")
    colop = stroke and "K" or "k"
  elseif color.l then -- Grayscale
    colspec = _r(color.l)
    colop = stroke and "G" or "g"
  else
    SU.error("Invalid color specification")
  end
  return colspec .. " " .. colop
end

local pdfPathHelper = function(x, y, segments)
  local paths = { { _r(x), _r(y), "m" } }
  for i = 1, #segments do
    local s = segments[i]
    if #s == 2 then
      -- line
      paths[#paths + 1] = { _r(s[1]), _r(s[2]), "l" }
    else
      -- bezier curve
      paths[#paths + 1] = { _r(s[1] ), _r(s[2]), _r(s[3]), _r(s[4]), _r(s[5]), _r(s[6]), "c" }
    end
  end
  for i, v in ipairs(paths) do
    paths[i] = table.concat(v, " ")
  end
  return table.concat(paths, " ")
end

local draw = function (drawable)
  local o = drawable.options
  if o.stroke == "none" then
    if o.fill then
      -- Fill only
      return table.concat({
        drawable.path,
        pdfColorHelper(o.fill, false),
        "f"
      }, " ")
    else
      SU.error("Drawable has neither stroke nor fill")
    end
  elseif o.fill then
    -- Stroke and fill
    return table.concat({
      drawable.path,
      pdfColorHelper(o.stroke, true),
      pdfColorHelper(o.fill, false),
      _r(o.strokeWidth), "w",
      "b" -- B open, b close
    }, " ")
  else
    -- Stroke only
    return table.concat({
      drawable.path,
      pdfColorHelper(o.stroke, true),
      _r(o.strokeWidth), "w",
      "S"
    }, " ")
  end
end

local pieSector = function (x, y, radius, startAngle, arcAngle, ratio, options)
  ratio = ratio or 0.6
  local s1 = arcToBezierCurves(x, y, radius, radius, startAngle, arcAngle)

  local s2 = arcToBezierCurves(x, y, ratio*radius, ratio*radius, startAngle + arcAngle, -arcAngle)
  table.insert(s1, s2[1])
  for i = 1, #s2 do
    table.insert(s1, s2[i])
  end
  table.insert(s1, s2[#s2])
  return draw({
    path = pdfPathHelper(s1[1][1], s1[1][2], s1),
    options = options,
  })
end

local circle = function (x, y, radius, options)
  local s1 = arcToBezierCurves(x, y, radius, radius, 0, 2 * math.pi)
  return draw({
    path = pdfPathHelper(x, y, s1),
    options = options,
  })
end

return {
  pieSector = pieSector,
  circle = circle
}
