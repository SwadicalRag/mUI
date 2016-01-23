mUI.RenderEngine:Listen("PreRender","viewManager",function(tag,template)
    tag.renderData = {}

    if template.tagOverride[tag._id] then
        for k,v in pairs(template.tagOverride[tag._id]) do
            tag.attributes[k] = v
        end
    end

    -- x from tag
    if tag.attributes.left and tag.attributes.right then
        tag.renderData.x = tag.renderData.x or 0
        tag.renderData.x = tag.renderData.x + mUI.ViewManager:GetCurrentView().w/2 - mUI.Parsers:Size(tag.attributes.w,"w")/2 - mUI.Parsers:Size(tag.attributes.left,"x") + mUI.Parsers:Size(tag.attributes.right,"x")
    elseif tag.attributes.left then
        tag.renderData.x = tag.renderData.x or 0
        tag.renderData.x = tag.renderData.x + mUI.Parsers:Size(tag.attributes.left,"x")
    elseif tag.attributes.right then
        tag.renderData.x = tag.renderData.x or 0
        tag.renderData.x = tag.renderData.x + mUI.ViewManager:GetCurrentView().w - mUI.Parsers:Size(tag.attributes.right,"x") - mUI.Parsers:Size(tag.attributes.w,"w")
    end

    -- y from tag
    if tag.attributes.top and tag.attributes.bottom then
        tag.renderData.y = tag.renderData.y or 0
        tag.renderData.y = tag.renderData.y + mUI.ViewManager:GetCurrentView().h/2 - mUI.Parsers:Size(tag.attributes.h,"h")/2 - mUI.Parsers:Size(tag.attributes.top,"y") + mUI.Parsers:Size(tag.attributes.bottom,"y")
    elseif tag.attributes.top then
        tag.renderData.y = tag.renderData.y or 0
        tag.renderData.y = tag.renderData.y + mUI.Parsers:Size(tag.attributes.top,"y")
    elseif tag.attributes.bottom then
        tag.renderData.y = tag.renderData.y or 0
        tag.renderData.y = tag.renderData.y + mUI.ViewManager:GetCurrentView().h - mUI.Parsers:Size(tag.attributes.bottom,"y") - mUI.Parsers:Size(tag.attributes.h,"h")
    end

    -- w/h from tag
    if tag.attributes.w then
        tag.renderData.w = mUI.Parsers:Size(tag.attributes.w,"w")
    end
    if tag.attributes.h then
        tag.renderData.h = mUI.Parsers:Size(tag.attributes.h,"h")
    end

    -- x/y/w/h from radius tag + adjustments
    if tag.attributes.radius then
        tag.renderData.radius = mUI.Parsers:Size(tag.attributes.radius)
        tag.renderData.x = tag.renderData.x - tag.renderData.radius
        tag.renderData.y = tag.renderData.y - tag.renderData.radius
        tag.renderData.w = tag.renderData.radius*2
        tag.renderData.h = tag.renderData.radius*2
    end

    -- internal use only
    tag.renderData.canRenderChildren = tag.renderData.x and tag.renderData.y and tag.renderData.w and tag.renderData.h and true

    -- colours
    if tag.attributes.color then
        tag.renderData.color = mUI.Parsers:Color(tag.attributes.color)
    end

    if tag.attributes.bgColor then
        tag.renderData.bgColor = mUI.Parsers:Color(tag.attributes.bgColor)
    end

    if tag.attributes.barColor then
        tag.renderData.barColor = mUI.Parsers:Color(tag.attributes.barColor)
    end

    --alpha override
    if tag.attributes.color and tag.attributes.alpha then
        tag.renderData.color.a = mUI.ArithmeticParser:Evaluate(tag.attributes.alpha)
    end

    -- relative x/y
    tag.renderData.consumedX = 0
    tag.renderData.consumedY = 0

    local child,parent = tag,tag.parent

    local currentlyConsumedX = (child.renderData.x or 0) + (child.renderData.w or 0)
    local currentlyConsumedY = (child.renderData.y or 0) + (child.renderData.h or 0)

    if (parent.attributes.relative == "x") then
        child.renderData.x = parent.renderData.consumedX
    end

    if (parent.attributes.relative == "y") then
        child.renderData.y = parent.renderData.consumedY
    end

    if (child.attributes.ghosted ~= "1") and parent.renderData then
        parent.renderData.consumedX = parent.renderData.consumedX + currentlyConsumedX
        parent.renderData.consumedY = parent.renderData.consumedY + currentlyConsumedY
    end

    -- scrolling x/y
    if tag.template.scrollOverrides and tag.template.scrollOverrides[tag.parent._id] then
        local scrollOverride = tag.template.scrollOverrides[tag.parent._id]
        tag.renderData.x = tag.renderData.x or 0
        tag.renderData.x = tag.renderData.x + scrollOverride.x

        tag.renderData.y = tag.renderData.y or 0
        tag.renderData.y = tag.renderData.y + scrollOverride.y

        if tag.scroller and (parent.identifier == "Scroll") then
            tag.scroller.maxX = parent.renderData.consumedX
            tag.scroller.maxY = parent.renderData.consumedY
            scrollOverride.maxX = parent.renderData.consumedX
            scrollOverride.maxY = parent.renderData.consumedY
        end
    end
end,0)

mUI.RenderEngine:Listen("EnterChild","viewManager",function(parent)
    mUI.ViewManager:PushView(parent.renderData.x,parent.renderData.y,parent.renderData.w,parent.renderData.h)
end,0)

mUI.RenderEngine:Listen("ExitChild","viewManager",function(parent)
    mUI.ViewManager:PopView()
end,0)

mUI.RenderEngine:Listen("MouseEvent","templateTrigger",function(tag,enum)
    tag.template:MouseEvent(tag,enum)
end)
