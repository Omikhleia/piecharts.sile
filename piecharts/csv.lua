--- Pie charts for the SILE typesetting system
--
-- @copyright License: MIT (c) 2024 Omikhleia, Didier Willis
--

-- CSV support is straight-forward with Penlight :)
local function readCsvFile (file)
  local data, err = pl.data.read(file, {
    csv = true,
    no_convert = true,
  })
  if not data then
    SU.error("Failure to open CSV file " .. file .. " (" .. err .. ")")
  end
  return data
end

return {
  readCsvFile = readCsvFile,
}
