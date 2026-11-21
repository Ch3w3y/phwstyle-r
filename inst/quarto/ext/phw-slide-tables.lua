-- Quarto's PowerPoint writer draws a table chunk with a tbl- label only when
-- the table is a picture, so it drops a flextable's slide table or a pandoc
-- table and leaves the slide empty. Such a float is replaced by its own
-- blocks, outside any Div, where pandoc draws a raw slide table and starts a
-- new slide at each horizontal rule between the pages of a long one. A
-- flextable from phwstyle already holds the chunk's tbl-cap as its top row;
-- a pandoc table takes the float's caption as its own.

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

local function is_slide_table(block)
  return block.t == "RawBlock" and block.format == "openxml" and block.text:find("<a:tbl>", 1, true) ~= nil
end

function FloatRefTarget(float)
  if float.type ~= "Table" then
    return nil
  end
  local blocks = flatten(pandoc.Blocks({ float.content }), pandoc.Blocks({}))
  local found = false
  for _, block in ipairs(blocks) do
    if block.t == "Table" then
      found = true
      if #block.caption.long == 0 then
        block.caption.long = pandoc.Blocks({ pandoc.Plain(pandoc.utils.stringify(float.caption_long)) })
      end
    elseif is_slide_table(block) then
      found = true
    end
  end
  if found then
    return blocks
  end
end
