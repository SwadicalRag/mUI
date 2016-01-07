require("bxml")
require("lustache")
require("larith")

if mUI then
    for _,template in ipairs(mUI.activeTemplates) do
        for _,pnl in pairs(template.panels) do
            pnl:Remove()
        end
    end
    mUI:trapCursorOrKeyboard(false,false)
end

mUI = mUI or {}

function mUI:trapCursorOrKeyboard(mouse_status,keyboard_status)
    if not IsValid(self.PlaceholderPanel) then return end
    local show = (mouse_status or keyboard_status) and true
    mouse_status,keyboard_status = mouse_status and true,keyboard_status and true
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

mUI.Cursor = "user"
function mUI:SetCursor(cursor)
    if not IsValid(self.PlaceholderPanel) then return end
    if cursor ~= self.Cursor then
        self.Cursor = cursor
        return self.PlaceholderPanel:SetCursor(cursor)
    end
end

mUI.templates = mUI.templates or {}
mUI.activeTemplates = mUI.activeTemplates or {}

function mUI:FromTemplate(name)
    local results = self.FS:SearchFile(name,true,false)
    if #results > 0 then
        local template = {}
        template.data = {}
        template.id = ("%x"):format(math.random(1,10^6))
        template.contents = self.FS:Read(results[1])

        function template:buildTemplate()
            self.data = self:GetData()

            for _,p in pairs(self.panels) do
                p:Remove()
            end
            self.panels = {}

            self.template = lustache:render(self.contents,self.data)
            self.XML = bXML:Parse(self.template)
        end

        template.lastDataTime = 0
        template.templateUpdateInterval = 60
        function template:getDataInternal()
            if (SysTime() - self.lastDataTime) > self.templateUpdateInterval then
                self:buildTemplate()

                self.lastDataTime = SysTime()
            end

            return self.data
        end

        function template:GetData()
            return {}
        end

        template.update = template.buildTemplate

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

        function template:getNodeUserClass(node)
            if node.attributes.class then return "."..node.attributes.class else return false end
        end

        function template:isNodeUserClass(node,match)
            return self:getNodeUserClass(node) and (self:getNodeUserClass(node) == match)
        end

        function template:getNodeUserID(node)
            if node.attributes.id then return "#"..node.attributes.id else return false end
        end

        function template:isNodeUserID(node,match)
            return self:getNodeUserID(node) and (self:getNodeUserID(node) == match)
        end

        function template:traverseNodeText(node,match,txt)
            if (node.tag == match) or self:isNodeUserClass(node,match) or self:isNodeUserID(node,match) then
                if txt then
                    node.text = txt
                else
                    return node.text
                end
            end

            for _,child in ipairs(node.children) do
                local ret = self:traverseNodeText(child,match,txt)

                if ret ~= nil then return ret end
            end
        end

        function template:traverseNodeAttributes(node,match,k,v)
            if (node.tag == match) or self:isNodeUserClass(node,match) or self:isNodeUserID(node,match) then
                if v ~= nil then
                    node.attributes[k] = v
                else
                    return node.attributes[k]
                end
            end

            for _,child in ipairs(node.children) do
                local ret = self:traverseNodeAttributes(child,match,k,v)

                if ret ~= nil then return ret end
            end
        end

        function template:GetText(match)
            self:getDataInternal()
            for _,child in ipairs(self.XML.children) do
                local ret = self:traverseNodeText(child,match)
                if ret ~= nil then return ret end
            end
        end

        function template:SetText(match,txt)
            self:getDataInternal()
            for _,child in ipairs(self.XML.children) do
                self:traverseNodeText(child,match,txt)
            end
        end

        function template:GetAttribute(match,key)
            self:getDataInternal()
            for _,child in ipairs(self.XML.children) do
                local ret = self:traverseNodeAttributes(child,match,key)
                if ret ~= nil then return ret end
            end
        end

        function template:SetAttribute(match,key,val)
            self:getDataInternal()
            for _,child in ipairs(self.XML.children) do
                self:traverseNodeAttributes(child,match,key,val)
            end
        end

        --TODO: remove
        function template:nodeTableToObject(node)
            local obj = {}
            obj.node = node

            function obj:GetAttribute(k)
                return self.node.attributes[k]
            end

            function obj:SetAttribute(k,v)
                self.node.attributes[k] = v
            end

            return obj
        end

        template.listeners = {}
        function template:runNodeEvent(node,event,...)
            local class,id = self:getNodeUserClass(node),self:getNodeUserID(node)
            if class then
                self.listeners[class] = self.listeners[class] or {}
                if self.listeners[class][event] then pcall(self.listeners[class][event],self:nodeTableToObject(node),...) end
            end
            if id then
                self.listeners[id] = self.listeners[id] or {}
                if self.listeners[id][event] then pcall(self.listeners[id][event],self:nodeTableToObject(node),...) end
            end
            self.listeners[node.tag] = self.listeners[node.tag] or {}
            if self.listeners[node.tag][event] then pcall(self.listeners[node.tag][event],self:nodeTableToObject(node),...) end
        end

        function template:Listen(id,event,func)
            self.listeners[id] = self.listeners[id] or {}
            self.listeners[id][event] = func
        end

        template.panels = {}
        function template:bindPanel(node,class)
            node.autoMouseEvents = true
            if not IsValid(self.panels[node.id]) then
                self.panels[node.id] = vgui.Create(class,mUI.PlaceholderPanel)
                self.panels[node.id].node = node
                self.panels[node.id].template = template
                self.panels[node.id]:SetMouseInputEnabled(true)
                self.panels[node.id]:SetKeyboardInputEnabled(true)
                local oPaint = self.panels[node.id].Paint
                self.panels[node.id].Paint = function(...)
                    if node.attributes.CURSOR then
                        self.panels[node.id]:SetCursor(node.attributes.CURSOR)
                    else
                        self.panels[node.id]:SetCursor("user")
                    end
                    if oPaint then
                        oPaint(...)
                    end
                end

                self.panels[node.id].OnCursorEntered = function(...)
                    self:runNodeEvent(node,"onCursorEntered")
                end
                self.panels[node.id].OnCursorExited = function(...)
                    self:runNodeEvent(node,"onCursorExited")
                end
                self.panels[node.id].OnMousePressed = function(...) -- Y U NO WORK??!?!
                    --self:runNodeEvent(node,"onClick",...)
                end
                self.panels[node.id].OnMouseReleased = function(...)
                    self:runNodeEvent(node,"onClickEnd",...)
                end
            end

            return self.panels[node.id]
        end

        self.activeTemplates[#self.activeTemplates+1] = template

        return template
    else
        error("Template "..path.." does not exist")
    end
end

mUI.parsers = mUI.parsers or {}
mUI.renderers = mUI.renderers or {}
mUI.renderContext = mUI.renderContext or {}
mUI.renderContext.original = mUI.renderContext.original or {
    w = ScrW(),
    h = ScrH(),
    x = 0,
    y = 0
}
mUI.renderContext.contextStack = mUI.renderContext.contextStack or {mUI.renderContext.original}
mUI.renderContext.viewPort = mUI.renderContext.viewPort or mUI.renderContext.original

function mUI.renderContext:popViewPort()
    self.contextStack[#self.contextStack] = nil
    local viewPort = self.contextStack[#self.contextStack] or self.original
    self.viewPort = viewPort
    cam.End2D()
    render.SetViewPort(viewPort.x,viewPort.y,viewPort.w,viewPort.h)
end

function mUI.renderContext:pushViewPort(x,y,w,h)
    local viewPort = {}
    self.viewPort = viewPort
    self.contextStack[#self.contextStack+1] = viewPort
    viewPort.w = w or self.original.w
    viewPort.h = h or self.original.h
    viewPort.x = x
    viewPort.y = y
    render.SetViewPort(x,y,viewPort.w,viewPort.h)
    cam.Start2D()
end

function mUI.parsers.color(colorStr,node)
    if colorStr:find("^rgba%(.-%)$") then
        return Color(colorStr:match("^rgba%(([%d%.]-),([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    elseif colorStr:find("^rgb(.-)$") then
        return Color(colorStr:match("^rgb%(([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    elseif colorStr:sub(1,1) == "#" then
        if #colorStr == 9 then
            local r,g,b,a = colorStr:match("#(..)(..)(..)(..)")

            return Color(tonumber(r,16),tonumber(g,16),tonumber(b,16),tonumber(a,16))
        elseif #colorStr == 7 then
            local r,g,b = colorStr:match("#(..)(..)(..)")

            return Color(tonumber(r,16),tonumber(g,16),tonumber(b,16))
        elseif #colorStr == 5 then
            local r,g,b,a = colorStr:match("#(.)(.)(.)(.)")

            return Color(tonumber(r,16),tonumber(g,16),tonumber(b,16),tonumber(a,16))
        elseif #colorStr == 4 then
            local r,g,b = colorStr:match("#(.)(.)(.)")

            return Color(tonumber(r,16),tonumber(g,16),tonumber(b,16))
        elseif #colorStr == 1 then
            return Color(tonumber(colorStr,16),tonumber(colorStr,16),tonumber(colorStr,16))
        else
            error("Bad color attribute!")
        end
    end
end

function mUI.parsers.unit(str,WH)
    if str:sub(-1,-1) == "%" then
        return larith:Evaluate(str:sub(1,-2)) / 100 * mUI.renderContext.viewPort[WH]
    else
        local unit,num = str:sub(-2,-1),larith:Evaluate(str:sub(1,-3))
        if unit == "px" then
            return num
        else
            --TODO: Fancy units
            return num
        end
    end
end

function mUI.parsers.size(attributes,field,isRelativeToViewPort)
    local fieldWH,size = (field == "w" or field == "x") and "w" or "h"

    if (field ~= fieldWH) and (fieldWH == "w") then
        if attributes.left and attributes.right then
            size = mUI.renderContext.viewPort.w * 0.5 - mUI.parsers.unit(attributes.left,"w") + mUI.parsers.unit(attributes.right,"w") - mUI.parsers.size(attributes,"w")/2
        elseif attributes.left then
            size = mUI.parsers.unit(attributes.left,"w")
        elseif attributes.right then
            size = mUI.renderContext.viewPort.w - mUI.parsers.unit(attributes.right,"w") - mUI.parsers.size(attributes,"w")
        else
            error("One of 'left' or 'right' must be in a node ("..(attributes.id or attributes.class or "???")..")")
        end
    elseif(field ~= fieldWH) then
        if attributes.top and attributes.bottom then
            size = mUI.renderContext.viewPort.h * 0.5 - mUI.parsers.unit(attributes.top,"h") + mUI.parsers.unit(attributes.bottom,"h") - mUI.parsers.size(attributes,"h")/2
        elseif attributes.top then
            size = mUI.parsers.unit(attributes.top,"h")
        elseif attributes.bottom then
            size = mUI.renderContext.viewPort.h - mUI.parsers.unit(attributes.bottom,"h") - mUI.parsers.size(attributes,"h")
        else
            error("One of 'top' or 'bottom' must be in a node ("..(attributes.id or attributes.class or "???")..")")
        end
    else
        size = mUI.parsers.unit(attributes[field],fieldWH)
    end


    if field == fieldWH or isRelativeToViewPort then
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
    local fontUID = data["font"]..(larith:Evaluate(data["font-size"]))..(data["font-weight"] or "500")
    if not fontCache[fontUID] then
        surface.CreateFont(fontUID,{
        	font = data["font"],
        	size = (larith:Evaluate(data["font-size"])),
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

function mUI:isMouseInViewPort(viewPort,mouseX,mouseY)
    local x1 = (viewPort.x <= mouseX)
    local x2 = ((viewPort.x + viewPort.w) >= mouseX)
    local y1 = (viewPort.y <= mouseY)
    local y2 = ((viewPort.y + viewPort.h) >= mouseY)
    return x1 and x2 and y1 and y2
end

function mUI:isMouseInChildrenViewPort(node)
    local mouseX,mouseY = gui.MousePos()

    local inViewPort = false
    for _,child in ipairs(node.children) do
        if child.attributes.x and child.attributes.y and child.attributes.w and child.attributes.h then
            self.renderContext:pushViewPort(
                self.parsers.size(child.attributes,"x"),
                self.parsers.size(child.attributes,"y"),
                self.parsers.size(child.attributes,"w"),
                self.parsers.size(child.attributes,"h")
            )
            inViewPort = inViewPort or (self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY) and not child.attributes.UNCLICKABLE)
            inViewPort = inViewPort or self:isMouseInChildrenViewPort(child)
            self.renderContext:popViewPort()
            if inViewPort then return true end
        end
    end
    return false
end

mUI.mouseIsOver = false
function mUI:doMouseChecks(template,node)
    local mouseX,mouseY = gui.MousePos()

    if not node.autoMouseEvents and self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY) and not self:isMouseInChildrenViewPort(node) and not node.attributes.UNCLICKABLE then
        self.mouseIsOver = node.id
        if node.attributes.CURSOR then
            self:SetCursor(node.attributes.CURSOR)
        else
            self:SetCursor("user")
        end
        if not template:getNodeAttribute(node,"onCursorEntered") then
            template:runNodeEvent(node,"onCursorEntered")
            template:setNodeAttribute(node,"onCursorEntered",true)
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
        if template:getNodeAttribute(node,"onCursorEntered") then
            mUI.mouseIsOver = false
            template:runNodeEvent(node,"onCursorExited")
            template:setNodeAttribute(node,"onCursorEntered",false)
        end
    end

    if not self.mouseIsOver then
        self:SetCursor("user")
    end
end

local blurMat = Material("pp/blurscreen")
local function blur(x,y,factor)
    surface.SetMaterial(blurMat)
    surface.SetDrawColor(0,0,0,150)

    for i=1,factor do
        blurMat:SetFloat("$blur",i/3*factor)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x-10,-y-10,mUI.renderContext.original.w+20,mUI.renderContext.original.h+20)
    end
end

function mUI:renderNode(template,node)
    if self.renderers[node.tag] then
        self.renderers[node.tag](template,node)
    else
        error("Unknown render node "..node)
    end
end

function mUI:parseRenderNode(template,node)
    if node.attributes.BLUR then
        self.renderContext:pushViewPort(
            self.parsers.size(node.attributes,"x"),
            self.parsers.size(node.attributes,"y"),
            self.parsers.size(node.attributes,"w"),
            self.parsers.size(node.attributes,"h")
        )
        blur(
            self.parsers.size(node.attributes,"x"),
            self.parsers.size(node.attributes,"y"),
            larith:Evaluate((node.attributes.BLUR ~= "") and node.attributes.BLUR or 6)
        )
        self.renderContext:popViewPort()
    end
    self:renderNode(template,node)

    local totalW,totalH = 0,0
    local overrideW,overrideH = 0,0
    for _,child in ipairs(node.children) do
        self.renderContext:pushViewPort(
            self.parsers.size(node.attributes,"x") + (node.attributes.RELATIVE_X and totalW or 0) + overrideW,
            self.parsers.size(node.attributes,"y") + (node.attributes.RELATIVE_Y and totalH or 0) + overrideH,
            self.parsers.size(node.attributes,"w"),
            self.parsers.size(node.attributes,"h")
        )

        if node.attributes.RELATIVE_X then
            totalW = totalW + self.parsers.size(child.attributes,"w") + self.parsers.size(child.attributes,"x",true)
        end

        if node.attributes.RELATIVE_Y then
            totalH = totalH +  self.parsers.size(child.attributes,"h") + self.parsers.size(child.attributes,"y",true)
        end

        self:doMouseChecks(template,node)

        self:parseRenderNode(template,child)
        self.renderContext:popViewPort()
    end
end

hook.Add("VGUIMousePressed","swadical.mUI.panelOverride",function(clickedPanel,code)
    for _,template in ipairs(mUI.activeTemplates) do
        for _,pnl in pairs(template.panels) do
            if clickedPanel == pnl then
                pnl.template:runNodeEvent(pnl.node,"onClick",code)
            end
        end
    end
end)

function mUI:Render(template)
    template:getDataInternal()

    for _,p in pairs(template.panels) do
        if IsValid(p) then
            p:SetAlpha(p.OldAlpha or 255)
            p:Show()
        end
    end

    self:trapCursorOrKeyboard(template.XML.attributes.TRAP_MOUSE and true,template.XML.attributes.TRAP_KEYBOARD and true)

    for _,child in ipairs(template.XML.children) do
        self:parseRenderNode(template,child)
    end

    template.lastDrewAt = mUI.frameID
    function template:idle()
        if template.XML.children.TRAP_MOUSE then
            mUI:trapCursorOrKeyboard(false,false)
        end

        for _,p in pairs(template.panels) do
            if IsValid(p) then
                p.OldAlpha = p:GetAlpha()
                p:SetAlpha(0)
                p:Hide()
            end
        end

        self.idle = nil
    end
end

function mUI:RegisterRenderer(name,fn)
    self.renderers[name] = fn
end

mUI:RegisterRenderer("Box",function(template,node)
    draw.RoundedBox(larith:Evaluate(node.attributes.cornerRadius or 0),mUI.parsers.size(node.attributes,"x",true),mUI.parsers.size(node.attributes,"y",true),mUI.parsers.size(node.attributes,"w",true),mUI.parsers.size(node.attributes,"h",true),mUI.parsers.color(node.attributes.color))
end)

mUI:RegisterRenderer("Text",function(template,node)
    draw.SimpleText(node.text,mUI.parsers.font(node.attributes),mUI.parsers.size(node.attributes,"x",true),mUI.parsers.size(node.attributes,"y",true),mUI.parsers.color(node.attributes.color),mUI.parsers.textAlign(node.attributes["font-horizontal-align"] or "left"),mUI.parsers.textAlign(node.attributes["font-vertical-align"] or "top"))
end)

mUI:RegisterRenderer("ProfilePicture",function(template,node)
    template:bindPanel(node,"AvatarImage"):SetSteamID(node.attributes.steamID64 or util.SteamIDTo64(node.attributes.steamID),larith:Evaluate(node.attributes.avatarSize or 128))
    template:bindPanel(node,"AvatarImage"):SetPos(mUI.parsers.size(node.attributes,"x",false),mUI.parsers.size(node.attributes,"y",false))
    template:bindPanel(node,"AvatarImage"):SetSize(mUI.parsers.size(node.attributes,"w",false),mUI.parsers.size(node.attributes,"h",false))
end)

mUI.frameID = 0
hook.Add("DrawOverlay","swadical.mUI.dermaOverride",function()
    for _,template in ipairs(mUI.activeTemplates) do
        if template.idle and (template.lastDrewAt ~= mUI.frameID) then
            template:idle()
        end
    end
    mUI.frameID = mUI.frameID + 1
end)

hook.Add("DrawOverlay","swadical.mUI.autoRender",function()
    if not IsValid(mUI.PlaceholderPanel) then
        mUI.PlaceholderPanel = vgui.Create("DPanel")
        mUI.PlaceholderPanel:Dock(FILL)
        mUI.Trapped = false
        mUI.keyboardTrapped = false
        mUI.cursorTrapped = false
        mUI.PlaceholderPanel.Paint = function()end
    end

    for _,template in ipairs(mUI.activeTemplates) do
        if template.draw then
            mUI:Render(template)
        end
    end
end)

return mUI
