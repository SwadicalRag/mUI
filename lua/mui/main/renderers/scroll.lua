mUI.RenderEngine:Listen("Scrolled","handleScroll",function(tag,step)
    local template = tag.template

    template.scrollOverrides = template.scrollOverrides or {}

    if tag.scroller then
        tag = tag.scroller
        template.scrollOverrides[tag._id] = template.scrollOverrides[tag._id] or {x=0,y=0}
        if (tag.attributes.dir == "x") and (tag.renderData.w < tag.maxX) then
            template.scrollOverrides[tag._id].x = math.max(math.min(template.scrollOverrides[tag._id].x + step,0),tag.renderData.w-tag.maxX)
        elseif (tag.attributes.dir == "y") and (tag.renderData.h < tag.maxY) then
            template.scrollOverrides[tag._id].y = math.max(math.min(template.scrollOverrides[tag._id].y + step,0),tag.renderData.h-tag.maxY)
        end
    end
end)

mUI.RenderEngine:registerRenderer("Scroll",function(tag,template)
    mUI.MouseUtils:PushRect(tag,tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
    tag.scroller = tag
    tag.maxX = 0
    tag.maxY = 0
    for _,child in ipairs(tag.children) do
        child.scroller = tag
    end
end)

mUI.RenderEngine:Listen("PreRender","inheritScroll",function(tag)
    if not tag.scroller then return end
    for _,child in ipairs(tag.children) do
        child.scroller = tag.scroller
    end
end)
