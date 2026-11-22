-- A phwstyle table too long for a revealjs slide continues on further
-- slides, with a horizontal rule between its parts. Pandoc starts a slide
-- only at a rule outside any Div, so the code cell holding such a table is
-- replaced by its own blocks. A table chunk with a tbl- label is a float that
-- holds the numbered caption and the cross-reference target: it keeps the
-- first part, and the parts that continue go after it, outside the float.

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

local function is_html_table(block)
  return block.t == "RawBlock" and block.format == "html" and block.text:find("<table", 1, true) ~= nil
end

local function first_rule(blocks)
  for i, block in ipairs(blocks) do
    if block.t == "HorizontalRule" then
      return i
    end
  end
end

local function has_html_table(blocks)
  for _, block in ipairs(blocks) do
    if is_html_table(block) then
      return true
    end
  end
  return false
end

local function split_float(float)
  if float.type ~= "Table" then
    return nil
  end
  local blocks = flatten(pandoc.Blocks({ float.content }), pandoc.Blocks({}))
  local rule = first_rule(blocks)
  if not rule or not has_html_table(blocks) then
    return nil
  end
  local first, rest = pandoc.Blocks({}), pandoc.Blocks({})
  for i, block in ipairs(blocks) do
    (i < rule and first or rest):insert(block)
  end
  -- Quarto drops the float it passed in when it is returned in a list, so
  -- the first part goes in a new float.
  local out = pandoc.Blocks({ quarto.FloatRefTarget({
    identifier = float.identifier,
    classes = float.classes,
    attributes = float.attributes,
    type = float.type,
    content = first,
    caption_long = float.caption_long,
    caption_short = float.caption_short,
    parent_id = float.parent_id,
  }) })
  out:extend(rest)
  return out
end

local function lift_cell(div)
  if not div.classes:includes("cell") then
    return nil
  end
  local blocks = pandoc.Blocks({})
  for _, block in ipairs(div.content) do
    if block.t == "Div" and block.classes:includes("cell-output-display") then
      flatten(block.content, blocks)
    else
      blocks:insert(block)
    end
  end
  if first_rule(blocks) and has_html_table(blocks) then
    return blocks
  end
end

return {
  { FloatRefTarget = split_float },
  { Div = lift_cell },
}
