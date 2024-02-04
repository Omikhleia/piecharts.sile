--- Pie charts for the SILE typesetting system
--
-- @copyright License: MIT (c) 2024 Omikhleia, Didier Willis
--

-- Converts an RGB (Red, Green, Blue) SILE color
-- to HSL (Hue, Saturation, Lightness) with with h, s, l in 0..1
local function rgbToHsl (color)
  local r, g, b = color.r, color.g, color.b
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s
  local l = (max + min) / 2

  if min == max then
    -- achromatic
    h = 0
    s = 0
  else
    local d = max - min
    s = l > 0.5 and (d / (2 - max - min)) or (d / (max + min))
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else -- max == b
      h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h, s, l
end

-- Small helper for HSL to RGB (see below)
local function hue2rgb (p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1/6 then return p + (q - p) * 6 * t end
  if t < 1/2 then return q end
  if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
  return p
end
-- Converts an HSL (Hue, Saturation, Lightness) with with h, s, l in 0..1
-- to RGB (Red, Green, Blue) SILE
local function hslToRgb (h, s, l)
  local r, g, b;

  if s == 0 then
    -- achromatic
    r = l
    g = l
    b = l
  else
    local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end
  return { r = r, g = g, b = b }
end

local function colorToHsl (color)
  if color.r then
    return rgbToHsl(color)
  end
  if color.k then
    -- First convert CMYK to RGB
    local kr = (1 - color.k)
    return rgbToHsl({
      r = (1 - color.c) * kr,
      g = (1 - color.m) * kr,
      b = (1 - color.y) * kr,
    })
  end
  if color.l then
    -- First convert Grayscale to RGB
    return rgbToHsl({
      r = color.l,
      g = color.l,
      b = color.l,
    })
  end
  SU.error("Invalid color specification")
end

return {
  rgbToHsl = rgbToHsl,
  hslToRgb = hslToRgb,
  colorToHsl = colorToHsl
}
