local self = banana.Define("UITemplate")

function self:SetXMLAST(AST)
    self.AST = AST
end

function self:Render()
    return mUI.RenderEngine:Render(self.AST)
end
