local self = {}
mUI.Parsers = self

function self:resolveAxes(axis)
    if axis == "x" then return "w" end
    if axis == "y" then return "h" end

    return axis
end

function self:resolveUnits(num)
    if num:sub(-2,-1) == "px" then return num:sub(1,-3) end
    error("Unknown units for "..num.."!")
end

function self:Size(str,axis)
    local size
    if str:sub(-1,-1) == "%" then
        size = mUI.ArithmeticParser:Evaluate(str:sub(1,-2))/100
    else
        return mUI.ArithmeticParser:Evaluate(self:resolveUnits(str))
    end

    if size then
        if axis then
            size = size * mUI.ViewManager:GetCurrentView().real[self:resolveAxes(axis)]
        else
            local currentView = mUI.ViewManager:GetCurrentView()

            size = size * (currentView.real.w^2 + currentView.real.h^2)^0.5
        end

        return size
    else
        error("Cannot parse size "..str)
    end
end

function self:Color(str)
    if str:match("rgb%(.-,.-,.-%)") then
        local r,g,b = str:match("rgb%((.-),(.-),(.-)%)")

        return Color(mUI.ArithmeticParser:Evaluate(r),mUI.ArithmeticParser:Evaluate(g),mUI.ArithmeticParser:Evaluate(b))
    elseif str:match("rgba%(.-,.-,.-,.-%)") then
        local r,g,b,a = str:match("rgba%((.-),(.-),(.-),(.-)%)")

        return Color(mUI.ArithmeticParser:Evaluate(r),mUI.ArithmeticParser:Evaluate(g),mUI.ArithmeticParser:Evaluate(b),mUI.ArithmeticParser:Evaluate(a)*255)
    elseif str:match("hsv%(.-,.-,.-%)") then
        local h,s,v = str:match("hsv%((.-),(.-),(.-)%)")

        return HSVToColor(mUI.ArithmeticParser:Evaluate(h),mUI.ArithmeticParser:Evaluate(s),mUI.ArithmeticParser:Evaluate(v))
    else
        error("Cannot parse color "..str)
    end
end

function self:TextAlign(str)
    return _G["TEXT_ALIGN_"..str:upper()] or TEXT_ALIGN_LEFT
end

local fontCache = {}
function self:Font(data)
    if not data["font"] then error("Expected a font attribute but found none!") end
    if not data["font-size"] then error("Expected a font-size attribute but found none!") end
    local fontUID = data["font"]..(mUI.Parsers:Size(data["font-size"]))..(data["font-weight"] or "500")
    if not fontCache[fontUID] then
        surface.CreateFont(fontUID,{
        	font = data["font"],
        	size = (mUI.Parsers:Size(data["font-size"])),
        	weight = mUI.Parsers:Size(data["font-weight"] or "500px"),
        	blursize = 0,
        	scanlines = 0,
        	antialias = true,
        	underline = false,
        	italic = false,
        	strikeout = false,
        	symbol = false,
        	rotary = false,
        	shadow = false,
        	additive = false,
        	outline = false
        })
        fontCache[fontUID] = true
    end
    return fontUID
end
