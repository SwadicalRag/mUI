mUI.RenderEngine:Listen("Scrolled","handleScroll",function(tag,step)
    local template = tag.template

    template.scrollOverrides = template.scrollOverrides or {}

    if tag.scroller then
        tag = tag.scroller
        template.scrollOverrides[tag._id] = template.scrollOverrides[tag._id] or {x=0,y=0}
        if (tag.attributes.dir == "x") and tag.maxX and (tag.renderData.w < tag.maxX) then
            template.scrollOverrides[tag._id].x = math.max(math.min(template.scrollOverrides[tag._id].x + step,0),tag.renderData.w-tag.maxX)
        elseif (tag.attributes.dir == "y") and tag.maxY and (tag.renderData.h < tag.maxY) then
            template.scrollOverrides[tag._id].y = math.max(math.min(template.scrollOverrides[tag._id].y + step,0),tag.renderData.h-tag.maxY)
        end
    end
end)

mUI.RenderEngine:registerRenderer("Scroll",function(tag,template)
    mUI.MouseUtils:PushRect(tag,tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
    tag.scroller = tag
    for _,child in ipairs(tag.children) do
        child.scroller = tag
    end

    tag.template.scrollOverrides = tag.template.scrollOverrides or {}
    tag.template.scrollOverrides[tag._id] = tag.template.scrollOverrides[tag._id] or {}
    local scrollOverride = tag.template.scrollOverrides[tag._id] or {}

    scrollOverride.x = scrollOverride.x or 0
    scrollOverride.maxX = scrollOverride.maxX or tag.maxX or 0
    scrollOverride.y = scrollOverride.y or 0
    scrollOverride.maxY = scrollOverride.maxY or tag.maxY or 0

    if tag.attributes.dir == "x" and (scrollOverride.maxX <= tag.renderData.w) then return end
    if tag.attributes.dir == "y" and (scrollOverride.maxY <= tag.renderData.h) then return end

    draw.NoTexture()
    surface.SetDrawColor(tag.renderData.bgColor)
    if tag.attributes.dir == "x" then
        surface.DrawRect(tag.renderData.x,tag.renderData.h-5+tag.renderData.y,tag.renderData.w,5)
    else
        surface.DrawRect(tag.renderData.w-5+tag.renderData.x,tag.renderData.y,5,tag.renderData.h)
    end

    surface.SetDrawColor(tag.renderData.barColor)
    if tag.attributes.dir == "x" then
        surface.DrawRect(tag.renderData.x-scrollOverride.x/scrollOverride.maxX*tag.renderData.w,tag.renderData.h-5+tag.renderData.y,tag.renderData.w/scrollOverride.maxX*tag.renderData.w,5)
    else
        surface.DrawRect(tag.renderData.w-5+tag.renderData.x,tag.renderData.y-scrollOverride.y/scrollOverride.maxY*tag.renderData.h,5,tag.renderData.h/scrollOverride.maxY*tag.renderData.h)
    end
end)

mUI.RenderEngine:Listen("PreRender","inheritScroll",function(tag)
    if not tag.scroller then return end
    for _,child in ipairs(tag.children) do
        child.scroller = tag.scroller
    end
end)
