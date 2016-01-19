local self = {}
mUI.Template = self

function self:Load(id)
    if mUI.FS:Exists("/templates/"..id..".xml") then
        local Template = banana.New("UITemplate")
        Template:SetXMLAST(mUI.XML:Parse(mUI.FS:Read("/templates/"..id..".xml")))
        return Template
    end
end

function self:LoadString(str)
    local Template = banana.New("UITemplate")
    Template:SetXMLAST(mUI.XML:Parse(str))
    return Template
end
