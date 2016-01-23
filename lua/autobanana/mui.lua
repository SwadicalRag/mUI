mUI = {}

mUI.Logger = banana.New("Logger")
mUI.Logger:SetTag("mUI")

mUI.Logger:Log("Initialising...")

mUI.Loader = banana.New("Loader")
mUI.Loader:SetTag("mUILoader")

mUI.Loader:LoadFolderRecursive("/mui/dependencies/")

mUI.Loader:LoadFile("/mui/sync.lua")
if CLIENT then
    mUI.Loader:LoadFolder("/mui/classes/")
    mUI.Loader:LoadFile("/mui/main/init.lua")
else
    mUI.Loader:LoadFile("/mui/resource.lua")
    mUI.Loader:ShareFolderRecursive("/mUI/main/")
    mUI.Loader:ShareFolder("/mUI/classes/")
end

mUI.Logger:Log("Initialisation complete!")
