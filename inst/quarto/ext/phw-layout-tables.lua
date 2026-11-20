-- Quarto lays each captioned figure or table out in a full-width table. Left
-- to itself that table takes the reference document's data-table style, whose
-- cell padding crops a picture as wide as the text and whose rules frame it.
-- Quarto marks those captions with the ImageCaption paragraph style.

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

function Table(tbl)
  if holds_float_caption(tbl) then
    tbl.attr.attributes["custom-style"] = "LayoutTable"
    return tbl
  end
end
