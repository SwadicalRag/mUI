mUI = {}

mUI.Logger = banana.New("Logger")
mUI.Logger:SetTag("mUI")

mUI.Logger:Log("Initialising...")

mUI.Loader = banana.New("Loader")

mUI.Loader:LoadFolderRecursive("/mui/dependencies/")

mUI.Loader:LoadFile("/mui/main/init.lua")
