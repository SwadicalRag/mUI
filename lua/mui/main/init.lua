mUI.ArithmeticParser = banana.New("StringArithmeticParser")

mUI.Loader:LoadFile("/mui/main/viewmanager.lua")
mUI.Loader:LoadFile("/mui/main/template.lua")
mUI.Loader:LoadFile("/mui/main/parsing.lua")

mUI.Loader:LoadFile("/mui/main/renderengine.lua")
mUI.Loader:LoadFile("/mui/main/mouse.lua")
mUI.Loader:LoadFile("/mui/main/derma_base.lua")
mUI.Loader:LoadFolderRecursive("/mui/main/renderers/")

mUI.Loader:LoadFile("/mui/main/setup.lua")
mUI.Loader:LoadFile("/mui/main/animate.lua")
mUI.Animate:hook()
