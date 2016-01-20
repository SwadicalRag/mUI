mUI.RenderEngine:registerRenderer("Box",function(tag)
    mUI.MouseUtils:PushRect(tag,tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
    draw.NoTexture()
    surface.SetDrawColor(tag.renderData.color)
    surface.DrawRect(tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
end)


local function drawCircle(x,y,radius,seg)
	local cir = {}

	table.insert(cir,{x = x,y = y,u = 0.5,v = 0.5 })
	for i = 0,seg do
		local a = math.rad((i / seg) * -360)
		table.insert(cir,{x = x + math.sin(a) * radius,y = y + math.cos(a) * radius,u = math.sin(a) / 2 + 0.5,v = math.cos(a) / 2 + 0.5 })
	end

	local a = math.rad(0) -- This is need for non absolute segment counts
	table.insert(cir,{x = x + math.sin(a) * radius,y = y + math.cos(a) * radius,u = math.sin(a) / 2 + 0.5,v = math.cos(a) / 2 + 0.5 })

	surface.DrawPoly(cir)
end

mUI.RenderEngine:registerRenderer("Circle",function(tag)
    mUI.MouseUtils:PushCircle(tag,tag.renderData.x+tag.renderData.radius,tag.renderData.y+tag.renderData.radius,tag.renderData.radius)
	draw.NoTexture()
    surface.SetDrawColor(tag.renderData.color)
    drawCircle(tag.renderData.x+tag.renderData.radius,tag.renderData.y+tag.renderData.radius,tag.renderData.radius,32)
end)

mUI.RenderEngine:Listen("PreRender","CircleStencil",function(tag)
    if tag.identifier == "Circle" then
        render.ClearStencil()
        render.SetStencilEnable(true)

        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)

        render.SetStencilReferenceValue(1)
    end
end)

mUI.RenderEngine:Listen("EnterChild","CircleStencil",function(tag)
    if tag.identifier == "Circle" then
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)

        return true
    end
end,0)

mUI.RenderEngine:Listen("ExitChild","CircleStencil",function(tag)
    if tag.identifier == "Circle" then
        render.SetStencilEnable(false)

        return true
    end
end,0)
