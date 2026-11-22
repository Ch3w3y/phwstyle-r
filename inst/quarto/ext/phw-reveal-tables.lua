-- A phwstyle table too long for a revealjs slide continues on further
-- slides, with a horizontal rule between its parts. Pandoc starts a slide
-- only at a rule outside any Div, so the code cell holding such a table is
-- replaced by its own blocks.

local function flatten(blocks, out)
  for _, block in ipairs(blocks) do
    if block.t == "Div" then
      flatten(block.content, out)
    else
      out:insert(block)
    end
  end
  return out
end

function Div(div)
  if not div.classes:includes("cell") then
    return nil
  end
  local blocks = flatten(div.content, pandoc.Blocks({}))
  local rule, table = false, false
  for _, block in ipairs(blocks) do
    if block.t == "HorizontalRule" then
      rule = true
    elseif block.t == "RawBlock" and block.format == "html" and block.text:find("<table", 1, true) then
      table = true
    end
  end
  if rule and table then
    return blocks
  end
end
