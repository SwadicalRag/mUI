require("bon")
require("tfs")

if SERVER then
    AddCSLuaFile("includes/modules/bon.lua")
    AddCSLuaFile("includes/modules/tfs.lua")
    AddCSLuaFile("includes/modules/lustache.lua")
    AddCSLuaFile("includes/modules/larith.lua")
    AddCSLuaFile("includes/modules/bxml.lua")
    AddCSLuaFile("includes/modules/mui.lua")

    local TemplateFS

    local function recurseTemplateDir(path,loc)
        local files,folders = file.Find(path.."*",loc)

        for _,fileName in ipairs(files) do
            TemplateFS:Write(fileName,file.Read(path..fileName,loc))
        end

        for _,folderName in ipairs(folders) do
            TemplateFS:CreateDir(folderName)
            TemplateFS:ChangeDir(folderName)
            recurseTemplateDir(path..folderName.."/",loc)
            TemplateFS:ChangeDir("..")
        end
    end

    util.AddNetworkString("swadical.mUI.templateSender")

    local function buildTemplateFS()
        TemplateFS = TFS.New("Templates")
        recurseTemplateDir("templates/","GAME")

        local serialized = bON.serialize(TemplateFS:ToData())
        local compressed = util.Compress(serialized)

        net.Start("swadical.mUI.templateSender")
            net.WriteData(compressed,#compressed)
        net.Broadcast()
    end

    concommand.Add("mui_buildfs",buildTemplateFS)
    buildTemplateFS()

    timer.Create("swadical.mUI.rebuild",0.5,0,buildTemplateFS)

    hook.Add("PlayerInitialSpawn","swadical.mUI.templateSender",function(ply)
        local serialized = bON.serialize(TemplateFS:ToData())
        local compressed = util.Compress(serialized)

        net.Start("swadical.mUI.templateSender")
            net.WriteData(compressed,#compressed)
        net.Send(ply)
    end)
else
    if not OKss then
        include("includes/modules/mui.lua")
        OKss = true
    end
    net.Receive("swadical.mUI.templateSender",function(len)
        mUI.FS = TFS.FromData(bON.deserialize(util.Decompress(net.ReadData(len))))
        hook.Run("mUI.Ready",mUI)

        mUI.activeTemplates = {}
        local template = mUI:FromTemplate("simplescoreboard.xml")
        template:SetDraw(true)
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
    end)
end
