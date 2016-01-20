local self = {}
mUI.Template = self

function self:Load(id)
    if mUI.FS:Exists("/templates/"..id..".xml") then
        local Template = banana.New("UITemplate")
        Template:SetXML(mUI.FS:Read("/templates/"..id..".xml"))
        Template:Update()
        return Template
    else
        return false
    end
end

function self:LoadString(str)
    local Template = banana.New("UITemplate")
    Template:SetXMLAST(mUI.XML:Parse(str))
    return Template
end
