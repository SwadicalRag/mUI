local self = banana.Define("UITemplate")

function self:__ctor()
    self.uid = ("%X"):format(math.random(1,10^6))
end

function self:SetXMLAST(AST)
    self.AST = AST
end

function self:Render()
    return mUI.RenderEngine:Render(self.AST,self)
end

function self:BindPanel(tag,type)
    return mUI.DBase:BindPanel(self.uid.."."..tag._id,type)
end
