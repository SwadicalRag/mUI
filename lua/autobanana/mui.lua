mUI = {}

mUI.Logger = banana.New("Logger")
mUI.Logger:SetTag("mUI")

mUI.Logger:Log("Initialising...")

mUI.Loader = banana.New("Loader")
mUI.Loader:SetTag("mUILoader")

mUI.Loader:LoadFolderRecursive("/mui/dependencies/")

mUI.Loader:LoadFile("/mui/sync.lua")
if CLIENT then
    mUI.Loader:LoadFile("/mui/main/init.lua")
    mUI.Loader:LoadFolder("/mui/dependencies/")
    mUI.Loader:LoadFolder("/mui/classes/")
else
    mUI.Loader:ShareFolder("/mUI/main/")
    mUI.Loader:ShareFolder("/mUI/classes/")
end

mUI.Logger:Log("Initialisation complete!")
