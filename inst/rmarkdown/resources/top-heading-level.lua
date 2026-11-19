-- Make the top heading level used in the document level 1, so a report
-- whose sections are `##` headings is numbered 1, 2, ... and not 0.1, 0.2.
local top = nil

return {
  {
    Header = function(h)
      if top == nil or h.level < top then top = h.level end
    end,
  },
  {
    Header = function(h)
      h.level = h.level - (top - 1)
      return h
    end,
  },
}
