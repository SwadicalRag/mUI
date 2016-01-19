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
            if axis == self:resolveAxes(axis) then
                --size = size * mUI.ViewManager.defaultView[self:resolveAxes(axis)]
                size = size * mUI.ViewManager:GetCurrentView()[self:resolveAxes(axis)]
            else
                size = size * mUI.ViewManager:GetCurrentView()[self:resolveAxes(axis)]
            end
        else
            local currentView = mUI.ViewManager:GetCurrentView()

            size = size * (currentView.x^2 + currentView.y^2)^0.5
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
