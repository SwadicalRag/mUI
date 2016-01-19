mUI.RenderEngine:Listen("PreRender","viewManager",function(tag)
    tag.renderData = {}

    if tag.attributes.left and tag.attributes.right then
        tag.renderData.x = mUI.ViewManager:GetCurrentView().w/2 - mUI.Parsers:Size(tag.attributes.left,"x") + mUI.Parsers:Size(tag.attributes.right,"x")
    elseif tag.attributes.left then
        tag.renderData.x = mUI.Parsers:Size(tag.attributes.left,"x")
    elseif tag.attributes.right then
        tag.renderData.x = mUI.ViewManager:GetCurrentView().w - mUI.Parsers:Size(tag.attributes.right,"x") - mUI.Parsers:Size(tag.attributes.w,"w")
    end

    if tag.attributes.top and tag.attributes.bottom then
        tag.renderData.x = mUI.ViewManager:GetCurrentView().h/2 - mUI.Parsers:Size(tag.attributes.top,"y") + mUI.Parsers:Size(tag.attributes.bottom,"y")
    elseif tag.attributes.top then
        tag.renderData.y = mUI.Parsers:Size(tag.attributes.top,"y")
    elseif tag.attributes.bottom then
        tag.renderData.y = mUI.ViewManager:GetCurrentView().h - mUI.Parsers:Size(tag.attributes.bottom,"y") - mUI.Parsers:Size(tag.attributes.h,"h")
    end

    if tag.attributes.w then
        tag.renderData.w = mUI.Parsers:Size(tag.attributes.w,"w")
    end
    if tag.attributes.h then
        tag.renderData.h = mUI.Parsers:Size(tag.attributes.h,"h")
    end

    tag.renderData.canRenderChildren = tag.renderData.x and tag.renderData.y and tag.renderData.w and tag.renderData.h and true

    if tag.attributes.color then
        tag.renderData.color = mUI.Parsers:Color(tag.attributes.color)
    end
end)

mUI.RenderEngine:Listen("EnterChild","viewManager",function(parent)
    mUI.ViewManager:PushView(parent.renderData.x,parent.renderData.y,parent.renderData.w,parent.renderData.h)
end)

mUI.RenderEngine:Listen("ExitChild","viewManager",function(parent)
    mUI.ViewManager:PopView()
end)
