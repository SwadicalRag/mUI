local blurMat = Material("pp/blurscreen")
local function blur(x,y,factor)
    surface.SetMaterial(blurMat)
    surface.SetDrawColor(0,0,0,150)

    local defaultView = mUI.ViewManager.defaultView
    local currentView = mUI.ViewManager:GetCurrentView()

    for i=1,factor do
        blurMat:SetFloat("$blur",i/3*factor)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-currentView.x-10,-currentView.y-10,defaultView.w+20,defaultView.h+20)
    end
end

mUI.RenderEngine:Listen("EnterChild","blur",function(tag)
    if tag.attributes.blur then
        blur(tag.renderData.x,tag.renderData.y,mUI.ArithmeticParser:Evaluate(tag.attributes.blur))
    end
end,1)
