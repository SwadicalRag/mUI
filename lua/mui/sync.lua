if SERVER then
    local TemplateFS

    util.AddNetworkString("swadical.mUI.templateSender")
    util.AddNetworkString("swadical.mUI.templateRefresh")

    local function buildTemplateFS()
        TemplateFS = mUI.TFS.New("Templates")
        TemplateFS:CreateDir("templates")
        TemplateFS:Pack("templates/","GAME","/templates/")

        local serialized = mUI.bON.serialize(TemplateFS:ToData())
        local compressed = util.Compress(serialized)

        net.Start("swadical.mUI.templateSender")
            net.WriteData(compressed,#compressed)
        net.Broadcast()
    end

    local lastModTime = {}
    local function recurseTemplateDirRefresh(path,loc)
        local files,folders = file.Find(path.."*",loc)

        for _,fileName in ipairs(files) do
            local filePath = TemplateFS:Dir()..fileName
            lastModTime[filePath] = lastModTime[filePath] or file.Time(path..fileName,loc)

            if lastModTime[filePath] ~= file.Time(path..fileName,loc) then
                print("Autoupdated "..filePath)
                TemplateFS:Write(fileName,file.Read(path..fileName,loc))

                local serialized = mUI.bON.serialize({
                    filePath = "/templates/"..filePath,
                    data = file.Read(path..fileName,loc)
                })
                local compressed = util.Compress(serialized)

                net.Start("swadical.mUI.templateRefresh")
                    net.WriteData(compressed,#compressed)
                net.Broadcast()
            end

            lastModTime[filePath] = file.Time(path..fileName,loc)
        end

        for _,folderName in ipairs(folders) do
            TemplateFS:CreateDir(folderName)
            TemplateFS:ChangeDir(folderName)
            recurseTemplateDirRefresh(path..folderName.."/",loc)
            TemplateFS:ChangeDir("..")
        end
    end

    local function refreshTemplateFS()
        recurseTemplateDirRefresh("templates/","GAME")
    end

    concommand.Add("mui_buildfs",refreshTemplateFS)
    buildTemplateFS()
    refreshTemplateFS()

    timer.Create("swadical.mUI.rebuild",0.5,0,refreshTemplateFS)

    hook.Add("PlayerInitialSpawn","swadical.mUI.templateSender",function(ply)
        local serialized = mUI.bON.serialize(TemplateFS:ToData())
        local compressed = util.Compress(serialized)

        net.Start("swadical.mUI.templateSender")
            net.WriteData(compressed,#compressed)
        net.Send(ply)
    end)
else
    net.Receive("swadical.mUI.templateSender",function(len)
        mUI.FS = mUI.TFS.FromData(mUI.bON.deserialize(util.Decompress(net.ReadData(len))))
        hook.Run("mUI.Ready",mUI)
    end)

    net.Receive("swadical.mUI.templateRefresh",function(len)
        local update = mUI.bON.deserialize(util.Decompress(net.ReadData(len)))
        mUI.FS:Write(update.filePath,update.data)
        hook.Run("mUI.Update",update.filePath)
    end)
end
