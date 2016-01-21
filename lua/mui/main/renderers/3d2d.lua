local renderScale = 80
local headEntity
local renderPos,renderAng,renderFOV
local aDelta = CurTime()
local lastSeq = ""
local pModel = ""

local function playerAnimate()
    if not IsValid(headEntity) then return end
	--anims
	local sq = LocalPlayer():GetSequence()
	if sq ~= lastSeq then
		headEntity:ResetSequence(sq)
		lastSeq = sq
	end

	--[[
	for i=1,LocalPlayer():GetNumPoseParameters() do
		local n = LocalPlayer():GetPoseParameterName(i)
		wow:SetPoseParameter(n,LocalPlayer():GetPoseParameter(n))
	end
	]]

	headEntity:SetPoseParameter("move_x",(LocalPlayer():GetPoseParameter("move_x") * 2) - 1)
	headEntity:SetPoseParameter("move_y",(LocalPlayer():GetPoseParameter("move_y") * 2) - 1)
	headEntity:SetPoseParameter("move_yaw",(LocalPlayer():GetPoseParameter("move_yaw") * 360) - 180)
	headEntity:SetPoseParameter("body_yaw",(LocalPlayer():GetPoseParameter("body_yaw") * 180) - 90)
	headEntity:SetPoseParameter("spine_yaw",(LocalPlayer():GetPoseParameter("spine_yaw") * 180) - 90)

	headEntity:SetPlaybackRate(1)

	local ang = LocalPlayer():EyeAngles()

	headEntity:FrameAdvance(CurTime() - aDelta)
	aDelta = CurTime()
end

local function getHeadEntity()
    if pModel == LocalPlayer():GetModel() then return end
    if IsValid(headEntity) then headEntity:Remove() end
    headEntity = ents.CreateClientProp(LocalPlayer():GetModel())
    pModel = LocalPlayer():GetModel()
    headEntity:SetNoDraw(true)
    local bone = headEntity:LookupBone("ValveBiped.Bip01_Head1")

    headEntity:SetAngles(Angle(0,180,0))
    if bone then
        renderPos,renderAng = headEntity:GetBonePosition(bone)
        local headPos = renderPos
        local offset = renderAng:Forward() + renderAng:Right() * 22
        renderPos = headPos + offset
        renderAng = (headPos-renderPos):Angle()
        renderFOV = 90
    else
        -- fallback to spawnicon rendering mode
        local min,max = headEntity:GetRenderBounds()
        local size = 0
        size = math.max(size,math.abs(min.x) + math.abs(max.x))
        size = math.max(size,math.abs(min.y) + math.abs(max.y))
        size = math.max(size,math.abs(min.z) + math.abs(max.z))
        size = size * (1 - (size / 900))
        renderAng = Angle(25,40,0)
        renderPos = headEntity:GetPos() + renderAng:Forward() * size * -15 + (min + max) * 0.5
        renderFOV = 10
    end

    headEntity:ResetSequence(lastSeq)
    playerAnimate()
end
timer.Create("swadical.mUI.refreshPlayerGhost",1,0,getHeadEntity)
hook.Add("InitPostEntity","swadical.mUI.refreshPlayerGhost",getHeadEntity)
hook.Add("Think","swadical.mUI.animatePlayer",playerAnimate)

mUI.RenderEngine:registerRenderer("Portrait",function(tag)
    PrintTable(tag.renderData)
    cam.Start3D(renderPos,renderAng,renderFOV,tag.renderData.x-tag.renderData.w/2+mUI.ViewManager:GetCurrentView().x,tag.renderData.y-tag.renderData.h/2+mUI.ViewManager:GetCurrentView().y,tag.renderData.w+renderScale,tag.renderData.h+renderScale)
        cam.IgnoreZ(true)
        render.SuppressEngineLighting(true)
        headEntity:DrawModel()
        render.SuppressEngineLighting(false)
        cam.IgnoreZ(false)
    cam.End3D()
end)
