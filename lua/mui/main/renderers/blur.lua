local blurMat = Material("pp/blurscreen")
local function blur(x,y,factor)
    surface.SetMaterial(blurMat)
    surface.SetDrawColor(0,0,0,150)

    for i=1,factor do
        blurMat:SetFloat("$blur",i/3*factor)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-10,-10,mUI.ViewManager.defaultView.w+20,mUI.ViewManager.defaultView.h+20)
    end
end

mUI.RenderEngine:Listen("PreRender","blur",function(tag)
    if tag.attributes.blur then
        mUI.ViewManager:PushWeirdView(0,0,ScrW(),ScrH(),tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
        blur(tag.renderData.x,tag.renderData.y,mUI.ArithmeticParser:Evaluate(tag.attributes.blur))
        mUI.ViewManager:PopView()
    end
end)
