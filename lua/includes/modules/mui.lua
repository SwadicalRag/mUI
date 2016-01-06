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

        function template:getNodeUserID(node)
            if node.data.id then return "#"..node.data.id else return false end
        end

        function template:traverseNodeIDs(node,match,k,v)
            if self:getNodeUserID(node) and self:getNodeUserID(node) == match then
                if v ~= nil then
                    node.data[k] = v
                else
                    return node.data[k]
                end
            end

            for _,v in ipairs(node.children) do
                local ret = self:traverseNodeIDs(v.data,match,k,v)

                if ret ~= nil then return ret end
            end
        end

        function template:traverseNodeClasses(node,match,k,v)
            if self:getNodeUserClass(node) and self:getNodeUserClass(node) == match then
                if v ~= nil then
                    node.data[k] = v
                else
                    return node.data[k]
                end
            end

            for _,v in ipairs(node.children) do
                local ret = self:traverseNodeClasses(v.data,match,k,v)

                if ret ~= nil then return ret end
            end
        end

        function template:traverseNodeTags(node,tag,match,k,v)
            if tag == match then
                if v ~= nil then
                    node.data[k] = v
                else
                    return node.data[k]
                end
            end

            for _,v in ipairs(node.children) do
                local ret = self:traverseNodeTags(v.data,v.tag,match,k,v)

                if ret ~= nil then return ret end
            end
        end

        function template:traverseNodeText(node,tag,match,txt)
            if (tag == match) or (self:getNodeUserClass(node) and self:getNodeUserClass(node) == match) or (self:getNodeUserID(node) and self:getNodeUserID(node) == match) then
                if txt then
                    node.text = txt
                else
                    return node.text
                end
            end

            for _,v in ipairs(node.children) do
                local ret = self:traverseNodeText(v.data,v.tag,match,txt)

                if ret ~= nil then return ret end
            end
        end

        function template:GetText(match)
            self:getDataInternal()
            for _,v in ipairs(self.XML.children) do
                self:traverseNodeText(v.data,v.tag,match)
            end
        end

        function template:SetText(match,txt)
            self:getDataInternal()
            for _,v in ipairs(self.XML.children) do
                local ret = self:traverseNodeText(v.data,v.tag,match,txt)
                if ret ~= nil then return ret end
            end
        end

        function template:GetAttribute(match,key)
            self:getDataInternal()
            for _,v in ipairs(self.XML.children) do
                local ret = self:traverseNodeClasses(v.data,match,key)
                if ret ~= nil then return ret end
            end

            for _,v in ipairs(self.XML.children) do
                local ret = self:traverseNodeClasses(v.data,match,key)
                if ret ~= nil then return ret end
            end

            for _,v in ipairs(self.XML.children) do
                local ret = self:traverseNodeTags(v.data,v.tag,match,key)
                if ret ~= nil then return ret end
            end
        end

        function template:SetAttribute(match,key,val)
            self:getDataInternal()
            for _,v in ipairs(self.XML.children) do
                self:traverseNodeClasses(v.data,match,key,val)
            end

            for _,v in ipairs(self.XML.children) do
                self:traverseNodeClasses(v.data,match,key,val)
            end
        end

        function template:getNodeUserClass(node)
            if node.data.class then return "."..node.data.class else return false end
        end

        function template:nodeTableToObject(node)
            local obj = {}
            obj.node = node

            function obj:GetAttribute(k)
                return self.node.data[k]
            end

            function obj:SetAttribute(k,v)
                self.node.data[k] = v
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
                    if node.data.CURSOR then
                        self.panels[node.id]:SetCursor(node.data.CURSOR)
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

function mUI.parsers.size(data,field,ignore)
    local fieldWH,size = (field == "w" or field == "x") and "w" or "h"

    if (field ~= fieldWH) and (fieldWH == "w") then
        if data.left and data.right then
            size = mUI.renderContext.viewPort.w * 0.5 - mUI.parsers.unit(data.left,"w") + mUI.parsers.unit(data.right,"w") - mUI.parsers.size(data,"w")/2
        elseif data.left then
            size = mUI.parsers.unit(data.left,"w")
        elseif data.right then
            size = mUI.renderContext.viewPort.w - mUI.parsers.unit(data.right,"w") - mUI.parsers.size(data,"w")
        else
            error("One of 'left' or 'right' must be in a node ("..(data.id or data.class or "???")..")")
        end
    elseif(field ~= fieldWH) then
        if data.top and data.bottom then
            size = mUI.renderContext.viewPort.h * 0.5 - mUI.parsers.unit(data.top,"h") + mUI.parsers.unit(data.bottom,"h") - mUI.parsers.size(data,"h")/2
        elseif data.top then
            size = mUI.parsers.unit(data.top,"h")
        elseif data.bottom then
            size = mUI.renderContext.viewPort.h - mUI.parsers.unit(data.bottom,"h") - mUI.parsers.size(data,"h")
        else
            error("One of 'top' or 'bottom' must be in a node ("..(data.id or data.class or "???")..")")
        end
    else
        size = mUI.parsers.unit(data[field],fieldWH)
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

function mUI:renderNode(template,name,node)
    if self.renderers[name] then
        self.renderers[name](template,node.data,node.text,node.id,node)
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
            ok = ok or (self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY) and not child.data.data.UNCLICKABLE)
            ok = ok or self:isMouseInChildrenViewPort(child.data,child.tag)
            self.renderContext:popViewPort()
            if ok then
                return true
            end
        end
    end
    return false
end

mUI.mouseIsOver = false
function mUI:doMouseChecks(node,template)
    local mouseX,mouseY = gui.MousePos()

    if not node.autoMouseEvents and self:isMouseInViewPort(self.renderContext.viewPort,mouseX,mouseY) and not self:isMouseInChildrenViewPort(node) and not node.data.UNCLICKABLE then
        self.mouseIsOver = node.id
        if node.data.CURSOR then
            self:SetCursor(node.data.CURSOR)
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

function mUI:parseRenderNode(name,tbl,template)
    if tbl.data.BLUR then
        self.renderContext:pushViewPort(
            self.parsers.size(tbl.data,"x"),
            self.parsers.size(tbl.data,"y"),
            self.parsers.size(tbl.data,"w"),
            self.parsers.size(tbl.data,"h")
        )
        blur(
            self.parsers.size(tbl.data,"x"),
            self.parsers.size(tbl.data,"y"),
            larith:Evaluate((tbl.data.BLUR ~= "") and tbl.data.BLUR or 6)
        )
        self.renderContext:popViewPort()
    end
    self:renderNode(template,name,tbl)

    local totalW,totalH = 0,0
    local overrideW,overrideH = 0,0
    for _,data in ipairs(tbl.children) do
        self.renderContext:pushViewPort(
            self.parsers.size(tbl.data,"x") + (tbl.data.RELATIVE_X and totalW or 0) + overrideW,
            self.parsers.size(tbl.data,"y") + (tbl.data.RELATIVE_Y and totalH or 0) + overrideH,
            self.parsers.size(tbl.data,"w"),
            self.parsers.size(tbl.data,"h")
        )

        if tbl.data.RELATIVE_X then
            totalW = totalW + self.parsers.size(data.data.data,"w") + self.parsers.size(data.data.data,"x",true)
        end

        if tbl.data.RELATIVE_Y then
            totalH = totalH +  self.parsers.size(data.data.data,"h") + self.parsers.size(data.data.data,"y",true)
        end

        self:doMouseChecks(tbl,template)

        self:parseRenderNode(data.tag,data.data,template)
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

    self:trapCursorOrKeyboard(template.XML.data.TRAP_MOUSE and true,template.XML.data.TRAP_KEYBOARD and true)

    for _,data in ipairs(template.XML.children) do
        self:parseRenderNode(data.tag,data.data,template)
    end

    template.lastDrewAt = mUI.frameID
    function template:idle()
        if template.XML.data.TRAP_MOUSE then
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

mUI:RegisterRenderer("Box",function(template,data,text,id)
    draw.RoundedBox(larith:Evaluate(data.cornerRadius or 0),mUI.parsers.size(data,"x",true),mUI.parsers.size(data,"y",true),mUI.parsers.size(data,"w",true),mUI.parsers.size(data,"h",true),mUI.parsers.color(data.color))
end)

mUI:RegisterRenderer("Text",function(template,data,text,id)
    draw.SimpleText(text,mUI.parsers.font(data),mUI.parsers.size(data,"x",true),mUI.parsers.size(data,"y",true),mUI.parsers.color(data.color),mUI.parsers.textAlign(data["font-horizontal-align"] or "left"),mUI.parsers.textAlign(data["font-vertical-align"] or "top"))
end)

mUI:RegisterRenderer("ProfilePicture",function(template,data,text,id,node)
    template:bindPanel(node,"AvatarImage"):SetSteamID(data.steamID64 or util.SteamIDTo64(data.steamID),larith:Evaluate(data.avatarSize or 128))
    template:bindPanel(node,"AvatarImage"):SetPos(mUI.parsers.size(data,"x",false),mUI.parsers.size(data,"y",false))
    template:bindPanel(node,"AvatarImage"):SetSize(mUI.parsers.size(data,"w",false),mUI.parsers.size(data,"h",false))
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
