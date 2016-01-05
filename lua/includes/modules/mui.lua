require("bxml")
require("lustache")
include("larith.lua")

mUI = mUI or {}

function mUI:trapCursorOrKeyboard(mouse_status,keyboard_status)
    if not IsValid(self.PlaceholderPanel) then return end
    local show = (mouse_status or keyboard_status) and true
    if show ~= self.Trapped then
        if show then
            self.PlaceholderPanel:Show()
            self.PlaceholderPanel:MakePopup()
        else
            self.PlaceholderPanel:Hide()
        end
        self.Trapped = show
    end

    if mouse_status ~= self.cursorTrapped then
        if mouse_status then
            self.cursorTrapped = true
            self.PlaceholderPanel:SetMouseInputEnabled(true)
        else
            self.cursorTrapped = false
            self.PlaceholderPanel:SetMouseInputEnabled(false)
        end
    end

    if keyboard_status ~= self.keyboardTrapped then
        if keyboard_status then
            self.keyboardTrapped = true
            self.PlaceholderPanel:SetKeyboardInputEnabled(true)
        else
            self.keyboardTrapped = false
            self.PlaceholderPanel:SetKeyboardInputEnabled(false)
        end
    end
end

function mUI:SetCursor(...)
    if not IsValid(self.PlaceholderPanel) then return end
    return self.PlaceholderPanel:SetCursor(...)
end

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

        template.attributes = {}
        function template:setNodeAttribute(node,key,val)
            self.attributes[node.id] = self.attributes[node.id] or {}
            self.attributes[node.id][key] = val
        end

        function template:getNodeAttribute(node,key)
            self.attributes[node.id] = self.attributes[node.id] or {}
            return self.attributes[node.id][key]
        end

        function template:getNodeUserID(node)
            if node.data.id then return "#"..node.data.id else return false end
        end

        function template:getNodeUserClass(node)
            if node.data.class then return "."..node.data.class else return false end
        end

        template.listeners = {}
        function template:runNodeEvent(node,event,...)
            local class,id = self:getNodeUserClass(node),self:getNodeUserID(node)
            if class then
                self.listeners[class] = self.listeners[class] or {}
                if self.listeners[class][event] then self.listeners[class][event](...) end
            end
            if id then
                self.listeners[id] = self.listeners[id] or {}
                if self.listeners[id][event] then self.listeners[id][event](...) end
            end
        end

        function template:Listen(id,event,func)
            self.listeners[id] = self.listeners[id] or {}
            self.listeners[id][event] = func
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

function mUI:isMouseInViewPort(viewPort,mouseX,mouseY)
    local x1 = (viewPort.x <= mouseX)
    local x2 = ((viewPort.x + viewPort.w) >= mouseX)
    local y1 = (viewPort.y <= mouseY)
    local y2 = ((viewPort.y + viewPort.h) >= mouseY)
    return x1 and x2 and y1 and y2
end

function mUI:isMouseInChildrenViewPort(node,tag)
    local mouseX,mouseY = gui.MousePos()

    local ok = false
    for _,child in ipairs(node.children) do
        if child.data.data.x and child.data.data.y and child.data.data.w and child.data.data.h then
            self.renderContext:pushViewPort(
                self.parsers.size(child.data.data,"x"),
                self.parsers.size(child.data.data,"y"),
                self.parsers.size(child.data.data,"w"),
                self.parsers.size(child.data.data,"h")
            )
            ok = ok or self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY)
            ok = ok or self:isMouseInChildrenViewPort(child.data,child.tag)
            self.renderContext:popViewPort()
            if ok then
                return true
            end
        end
    end
    return false
end

function mUI:doMouseChecks(node,template)
    local mouseX,mouseY = gui.MousePos()

    if self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY) and not self:isMouseInChildrenViewPort(node) then
        if node.data.CURSOR then
            self:SetCursor(node.data.CURSOR)
        else
            self:SetCursor("user")
        end
        if not template:getNodeAttribute(node,"onMouseOver") then
            template:runNodeEvent(node,"onMouseOver")
            template:setNodeAttribute(node,"onMouseOver",true)
        else
            if input.IsMouseDown(MOUSE_LEFT) then
                if not template:getNodeAttribute(node,"MOUSE_LEFT") then
                    template:runNodeEvent(node,"onClick",MOUSE_LEFT)
                    template:setNodeAttribute(node,"MOUSE_LEFT",true)
                end
            elseif template:getNodeAttribute(node,"MOUSE_LEFT") then
                template:runNodeEvent(node,"onClickEnd",MOUSE_LEFT)
                template:setNodeAttribute(node,"MOUSE_LEFT",false)
            end

            if input.IsMouseDown(MOUSE_RIGHT) then
                if not template:getNodeAttribute(node,"MOUSE_RIGHT") then
                    template:runNodeEvent(node,"onClick",MOUSE_RIGHT)
                    template:setNodeAttribute(node,"MOUSE_RIGHT",true)
                end
            elseif template:getNodeAttribute(node,"MOUSE_RIGHT") then
                template:runNodeEvent(node,"onClickEnd",MOUSE_RIGHT)
                template:setNodeAttribute(node,"MOUSE_RIGHT",false)
            end
        end
    else
        if template:getNodeAttribute(node,"onMouseOver") then
            template:runNodeEvent(node,"onMouseOverEnd")
            template:setNodeAttribute(node,"onMouseOver",false)
        end
    end
end

function mUI:parseRenderNode(name,tbl,template)
    self:renderNode(name,tbl.data,tbl.text)

    for _,data in ipairs(tbl.children) do
        self.renderContext:pushViewPort(
            self.parsers.size(tbl.data,"x"),
            self.parsers.size(tbl.data,"y"),
            self.parsers.size(tbl.data,"w"),
            self.parsers.size(tbl.data,"h")
        )
        self:doMouseChecks(tbl,template)

        self:parseRenderNode(data.tag,data.data,template)
        self.renderContext:popViewPort()
    end
end

function mUI:Render(template)
    template:getDataInternal()

    self:trapCursorOrKeyboard(template.XML.data.TRAP_MOUSE and true,template.XML.data.TRAP_KEYBOARD and true)

    for _,data in ipairs(template.XML.children) do
        self:parseRenderNode(data.tag,data.data,template)
    end

    if template.XML.data.TRAP_MOUSE then
        timer.Create("mUI_disableCursorTrap",0.25,1,function()
            self:trapCursorOrKeyboard(false,false)
        end)
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
    if not IsValid(mUI.PlaceholderPanel) then
        mUI.PlaceholderPanel = vgui.Create("DPanel")
        mUI.PlaceholderPanel:SetAlpha(0)
        mUI.PlaceholderPanel:Dock(FILL)
        mUI.Trapped = false
        mUI.keyboardTrapped = false
        mUI.cursorTrapped = false
    end

    for _,template in ipairs(mUI.activeTemplates) do
        if template.draw then
            mUI:Render(template)
        end
    end
end)

return mUI
