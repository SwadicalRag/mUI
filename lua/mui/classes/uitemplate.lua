local self = banana.Define("UITemplate")

function self:__ctor()
    self.uid = ("%X"):format(math.random(1,10^6))
end

function self:SetXML(XML)
    self.XML = XML
end

function self:GetData()
    return {}
end

function self:Update()
    self:SetXMLAST(mUI.XML:Parse(mUI.lustache:render(self.XML,self:GetData())))
end

function self:SetXMLAST(AST)
    self.AST = AST

    self.TrapsCursor = #self:FindTags("TrapCursor") > 0
    self.TrapsKeyboard = #self:FindTags("TrapKeyboard") > 0
end

function self:Render()
    if self.Visible then
        if not self.ManuallyUpdated then self:Update() end
        return mUI.RenderEngine:Render(self.AST,self)
    end
end

function self:Show()
    self.Visible = true

    mUI.DBase:TrapCursor(self.TrapsCursor)
    mUI.DBase:TrapKeyboard(self.TrapsKeyboard)
end

function self:Hide()
    self.Visible = false

    if self.TrapsCursor then
        mUI.DBase:TrapCursor(false)
    end

    if self.TrapsKeyboard then
        mUI.DBase:TrapKeyboard(false)
    end
end

function self:SetVisible(status)
    if status then self:Show() else self:Hide() end
end

function self:BindPanel(tag,type)
    return mUI.DBase:BindPanel(self.uid.."."..tag._id,type)
end

function self:findTagLoop(search,tbl)
    local buffer = {}
    local firstChar,theRest = search:sub(1,1),search:sub(2,-1)
    if firstChar == "#" then
        if tbl.attributes.id == theRest then
            buffer[#buffer+1] = tbl
        end
    elseif firstChar == "." then
        if tbl.attributes.class == theRest then
            buffer[#buffer+1] = tbl
        end
    elseif tbl.identifier == search then
        buffer[#buffer+1] = tbl
    end

    for _,child in ipairs(tbl.children) do
        local matches = self:findTagLoop(search,child)

        for _,match in ipairs(matches) do
            buffer[#buffer+1] = match
        end
    end

    return buffer
end

function self:FindTags(search)
    return self:findTagLoop(search,self.AST)
end

function self:findTagInternalLoop(_id,tbl)
    if tbl._id == _id then
        return tbl
    end

    for _,child in ipairs(tbl.children) do
        local match = self:findTagInternalLoop(_id,child)

        if match then return match end
    end

    return false
end

function self:findTagInternal(_id)
    return self:findTagInternalLoop(_id,self.AST)
end

function self:ForEachTag(query,callback)
    local results = self:FindTags(query)

    for _,tag in ipairs(results) do
        callback(tag)
    end
end

self.tagOverride = {}
function self:GetAttribute(query,attr)
    local tag = self:FindTags(query)[1]

    if tag then
        if self.tagOverride[tag._id] then
            return self.tagOverride[tag._id][attr] or tag.attributes[attr]
        else
            return tag.attributes[attr]
        end
    else
        return false
    end
end

function self:SetAttribute(query,attr,val)
    self:ForEachTag(query,function(tag)
        self.tagOverride[tag._id] = self.tagOverride[tag._id] or {}
        self.tagOverride[tag._id][attr] = val
    end)
end

function self:SetManualUpdated(status)
    self.ManuallyUpdated = status
end

self.ClickListeners = {}
function self:MouseEvent(tag,enum)
    if tag.attributes.id and self.ClickListeners["#"..tag.attributes.id] then
        self.ClickListeners["#"..tag.attributes.id](tag,enum)
    elseif tag.attributes.class and self.ClickListeners["."..tag.attributes.class] then
        self.ClickListeners["."..tag.attributes.class](tag,enum)
    elseif self.ClickListeners[tag.identifier] then
        self.ClickListeners[tag.identifier](tag,enum)
    end
end

function self:OnClick(query,callback)
    self.ClickListeners[query] = callback
end
