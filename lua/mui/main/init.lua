mUI.ArithmeticParser = banana.New("StringArithmeticParser")

mUI.Loader:LoadFile("/mui/main/viewmanager.lua")

mUI.Loader:LoadFile("/mui/main/template.lua")

mUI.Loader:LoadFile("/mui/main/renderengine.lua")

mUI.Loader:LoadFolderRecursive("/mui/main/renderers/")
