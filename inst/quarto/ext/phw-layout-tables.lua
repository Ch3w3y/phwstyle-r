-- Quarto lays each captioned figure or table out in a full-width table. Left
-- to itself that table takes the reference document's data-table style, whose
-- cell padding crops a picture as wide as the text and whose rules frame it.
-- Quarto marks those captions with the ImageCaption paragraph style.

-- Pandoc before 3.4 (Quarto 1.5) ignores custom-style on a table.
local styles_tables = PANDOC_VERSION >= { 3, 4 }

local function holds_float_caption(tbl)
  local found = false
  pandoc.Blocks({ tbl }):walk({
    RawInline = function(raw)
      if raw.format == "openxml" and raw.text:find("ImageCaption", 1, true) then
        found = true
      end
    end
  })
  return found
end

local function single_cell(tbl)
  local rows = #tbl.bodies == 1 and tbl.bodies[1].body or {}
  if #tbl.colspecs == 1 and #rows == 1 and #tbl.head.rows == 0 and #tbl.foot.rows == 0 then
    return rows[1].cells[1].contents
  end
end

function Table(tbl)
  if not holds_float_caption(tbl) then
    return nil
  end
  if styles_tables then
    tbl.attr.attributes["custom-style"] = "LayoutTable"
    return tbl
  end
  return single_cell(tbl)
end
