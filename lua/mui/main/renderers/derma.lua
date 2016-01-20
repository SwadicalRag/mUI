mUI.RenderEngine:registerRenderer("Avatar",function(tag,template)
    mUI.MouseUtils:PushRect(tag,tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)

    local pnl = template:BindPanel(tag,"AvatarImage")
    pnl:SetSteamID(tag.attributes.steamID64 or util.SteamIDTo64(tag.attributes.steamID),mUI.ArithmeticParser:Evaluate(tag.attributes.avatarSize or 128))
    pnl:SetPos(tag.renderData.x,tag.renderData.y)
    pnl:SetSize(tag.renderData.w,tag.renderData.h)

    pnl:Render()
end)
