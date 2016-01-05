require("bxml")
require("lustache")
include("larith.lua")

mUI = mUI or {}

mUI.templates = {}
mUI.activeTemplates = {}

function mUI:FromTemplate(name)
    local results = self.FS:SearchFile(name,true,false)
    if #results > 0 then
        local template = {}
        template.contents = self.FS:Read(results[1])

        function template:buildTemplate()
            self.template = lustache:render(self.contents,self.data)
            self.XML = bXML:Parse(self.template)
        end

        template.lastDataTime = 0
        template.templateUpdateInterval = 0.1
        function template:getDataInternal()
            if (SysTime() - self.lastDataTime) > self.templateUpdateInterval then
                self.data = self:GetData()
                self:buildTemplate()

                self.lastDataTime = SysTime()
            end

            return self.data
        end

        function template:GetData()
            return {}
        end

        function template:SetDraw(val)
            self.draw = val
        end

        self.activeTemplates[#self.activeTemplates+1] = template

        return template
    else
        error("Template "..path.." does not exist")
    end
end

mUI.parsers = {}
mUI.renderers = {}
mUI.renderContext = {}
mUI.renderContext.original = {
    w = ScrW(),
    h = ScrH(),
    x = 0,
    y = 0
}
mUI.renderContext.contextStack = {mUI.renderContext.original}
mUI.renderContext.viewPort = mUI.renderContext.original

function mUI.renderContext:popViewPort()
    self.contextStack[#self.contextStack] = nil
    local viewPort = self.contextStack[#self.contextStack] or self.original
    self.viewPort = viewPort
    --print("POP")
    --render.SetViewPort(viewPort.x,viewPort.y,viewPort.w,viewPort.h)
end

function mUI.renderContext:pushViewPort(x,y,w,h)
    local viewPort = {}
    self.viewPort = viewPort
    self.contextStack[#self.contextStack+1] = viewPort
    viewPort.w = w or self.original.w
    viewPort.h = h or self.original.h
    viewPort.x = x
    viewPort.y = y
    --render.SetViewPort(x,y,viewPort.w,viewPort.h)
end

function mUI.parsers.color(colorStr)
    if colorStr:find("^rgba%(.-%)$") then
        return Color(colorStr:match("^rgba%(([%d%.]-),([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    elseif colorStr:find("^rgb(.-)$") then
        return Color(colorStr:match("^rgb%(([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    else
        error("Bad color string")
    end
end

function mUI.parsers.size(data,field,ignore)
    local sizeStr = data[field]
    if not sizeStr then return end
    local fieldWH = (field == "w" or field == "x") and "w" or "h"
    local size
    if sizeStr:find("%%$") then
        size = larith:Evaluate(sizeStr:match("^([%d%.]+)%%$")) / 100 * mUI.renderContext.viewPort[fieldWH]
    else
        size = larith:Evaluate(sizeStr)
    end

    if field == fieldWH or ignore then
        return size
    else
        print(sizeStr)
        return size + mUI.renderContext.viewPort[field]
    end
end

function mUI.parsers.textAlign(data)
    return _G["TEXT_ALIGN_"..data:upper()] or TEXT_ALIGN_LEFT
end

local fontCache = {}
function mUI.parsers.font(data)
    local fontUID = data["font"]..data["font-size"]..(data["font-weight"] or "500")
    if not fontCache[fontUID] then
        surface.CreateFont(fontUID,{
        	font = data["font"],
        	size = larith:Evaluate(data["font-size"]),
        	weight = larith:Evaluate(data["font-weight"] or "500"),
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

function mUI:renderNode(name,data,text)
    if self.renderers[name] then
        self.renderers[name](self.renderers,data,text)
    else
        error("Unknown render node "..data)
    end
end

function mUI:parseRenderNode(name,tbl)
    self:renderNode(name,tbl.data,tbl.text)

    for _,data in ipairs(tbl.children) do
        local restore = self.renderContext:pushViewPort(
            self.parsers.size(tbl.data,"x"),
            self.parsers.size(tbl.data,"y"),
            self.parsers.size(tbl.data,"w"),
            self.parsers.size(tbl.data,"h")
        )
        self:parseRenderNode(data.tag,data.data)
        self.renderContext:popViewPort()
    end
end

function mUI:Render(template)
    template:getDataInternal()
    for _,data in ipairs(template.XML.children) do
        self:parseRenderNode(data.tag,data.data)
    end
end

function mUI:RegisterRenderer(name,fn)
    self.renderers[name] = fn
end

mUI:RegisterRenderer("Box",function(renderers,data)
    draw.RoundedBox(larith:Evaluate(data.cornerRadius or 0),mUI.parsers.size(data,"x"),mUI.parsers.size(data,"y"),mUI.parsers.size(data,"w"),mUI.parsers.size(data,"h"),mUI.parsers.color(data.color))
end)

mUI:RegisterRenderer("Text",function(renderers,data,text)
    draw.SimpleText(text,mUI.parsers.font(data),mUI.parsers.size(data,"x"),mUI.parsers.size(data,"y"),mUI.parsers.color(data.color),mUI.parsers.textAlign(data["font-horizontal-align"] or "left"),mUI.parsers.textAlign(data["font-vertical-align"] or "top"))
end)

hook.Add("DrawOverlay","swadical.mUI.autoRender",function()
    for _,template in ipairs(mUI.activeTemplates) do
        if template.draw then
            mUI:Render(template)
        end
    end
end)

return mUI
