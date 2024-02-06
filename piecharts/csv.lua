--- Pie charts for the SILE typesetting system
--
-- @copyright License: MIT (c) 2024 Omikhleia, Didier Willis
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
  -- pl.data.read expects a file-like object, not a string.
  -- But we can avoid creating a temporary file:
  --   local file = io.tmpfile() or SU.error("Cannot create temporary file")
  --   file:write (text)
  --   file:seek ("set", 0) -- back to start
  -- As Penlight supports file-like objects created from strings:
  local file = pl.stringio.open(text)
  return readCsv(file)
end

return {
  readCsvFile = readCsvFile,
  readCsvString = readCsvString,
}
