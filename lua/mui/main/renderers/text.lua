mUI.RenderEngine:registerRenderer("Text",function(tag)
    draw.SimpleText(tag.text,mUI.Parsers:Font(tag.attributes),tag.renderData.x,tag.renderData.y,tag.renderData.color,mUI.Parsers:TextAlign(tag.attributes["font-horizontal-align"] or "left"),mUI.Parsers:TextAlign(tag.attributes["font-vertical-align"] or "top"))
end)
