local fontCache = {}
local function getFont(data)
    if not data["font"] then error("Expected a font attribute but found none!") end
    if not data["font-size"] then error("Expected a font-size attribute but found none!") end
    local fontUID = data["font"]..(mUI.Parsers:Size(data["font-size"]))..(data["font-weight"] or "500")
    if not fontCache[fontUID] then
        surface.CreateFont(fontUID,{
        	font = data["font"],
        	size = (mUI.Parsers:Size(data["font-size"])),
        	weight = mUI.Parsers:Size(data["font-weight"] or "500px"),
        	blursize = 0,
        	scanlines = 0,
        	antialias = true,
        	underline = false,
        	italic = false,
        	strikeout = false,
        	symbol = false,
        	rotary = false,
        	shadow = false,
        	additive = false,
        	outline = false
        })
        fontCache[fontUID] = true
    end
    return fontUID
end

mUI.RenderEngine:registerRenderer("Text",function(tag)
    draw.SimpleText(tag.text,getFont(tag.attributes),tag.renderData.x,tag.renderData.y,tag.renderData.color,mUI.Parsers:TextAlign(tag.attributes["font-horizontal-align"] or "left"),mUI.Parsers:TextAlign(tag.attributes["font-vertical-align"] or "top"))
end)
