local function update()
    mUI.activeTemplates = {}
    local template = mUI:FromTemplate("simplescoreboard.xml")

    function template:GetData()
        local players = {}
        for i,ply in ipairs(player.GetAll()) do
            players[i] = {
                nick = ply:Nick(),
                ping = ply:Ping(),
                height = i*20
            }
        end

        return {
            serverName = GetHostName(),
            players = players,
            gamemode = engine.ActiveGamemode(),
            map = game.GetMap()
        }
    end

    template:Listen("#main1","onMouseOver",function()print("MOUSE IN")end)
    template:Listen("#main1","onMouseOverEnd",function()print("MOUSE OUT")end)
    template:Listen("#main1","onClick",function(n)print("MOUSE CLICK",n)end)

    local shouldDraw = false
    hook.Add("ScoreboardShow","mUI.simplescoreboard",function()
        shouldDraw = true
        return true
    end)

    hook.Add("ScoreboardHide","mUI.simplescoreboard",function()
        shouldDraw = false
        return true
    end)

    hook.Add("HUDDrawScoreBoard","mUI.simplescoreboard",function()
        if not shouldDraw then return end
        mUI:Render(template)
        return true
    end)
end

hook.Add("mUI.Ready","scoreboard",update)
hook.Add("mUI.Update","scoreboard",update)
