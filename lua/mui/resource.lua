local function shareFonts()
    local files,_ = file.Find("resource/fonts/*","GAME")

    for _,fileName in ipairs(files) do
        resource.AddFile("resource/fonts/"..fileName)
    end
end

shareFonts()
