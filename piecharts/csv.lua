--- Pie charts for the SILE typesetting system
--
-- License: GPL-3.0-or-later
--
-- Copyright (C) 2024-2025 Didier Willis
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

-- CSV support is straight-forward with Penlight :)

local function readCsv (file)
  local data, err = pl.data.read(file, {
    csv = true,
    no_convert = true,
  })
  if not data then
    SU.error("Failure to read CSV content (" .. err .. ")")
  end
  return data
end

local function readCsvFile (filename)
  local file = SILE.resolveFile(filename) or SU.error("Cannot find file: " .. filename)
  return readCsv(file)
end

local function readCsvString (text)
  -- pl.data.read() expects a file-like object, not a string.
  -- But we can avoid creating a temporary file:
  --   local file = io.tmpfile() or SU.error("Cannot create temporary file")
  --   file:write (text)
  --   file:seek ("set", 0) -- back to start
  -- As Penlight natively supports file-like objects created from strings:
  local file = pl.stringio.open(text)
  return readCsv(file)
end

return {
  readCsvFile = readCsvFile,
  readCsvString = readCsvString,
}
