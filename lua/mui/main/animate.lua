local self = {}
mUI.Animate = self

self.animations = {}
self.easing = {}

function self:hook()
    hook.Add("PreRender","mUI.Animator",function()
        for id,animData in pairs(self.animations) do
            local eased = self.easing[animData.easing](SysTime()-animData.startTime,animData.startVal,animData.change,animData.duration)
            local minVal,maxVal = math.min(animData.startVal,animData.endVal),math.max(animData.startVal,animData.endVal)
            eased = math.min(math.max(eased,minVal),maxVal)
            animData.callback(eased)

            if animData.removeOnDead and (eased == animData.endVal) then self.animations[id] = nil end
        end
    end)
end

function self:Update(id,from,to)
    if self.animations[id] then
        self.animations[id].startVal = from
        self.animations[id].endVal = to
        self.animations[id].change = to-from
    end
end

function self:Run(id,from,to,duration,easing,callback,dontRemoveOnDead)
    if not self.easing[easing] then error("Unknown easing method "..easing) end
    self.animations[id] = {
        startVal = from,
        endVal = to,
        change = to-from,
        startTime = SysTime(),
        easing = easing,
        callback = callback,
        duration = duration,
        removeOnDead = not dontRemoveOnDead
    }
end

function self:LiveEase(from,to,fac)
    if not from then return to end
    return from + (to-from)/(fac or 5)
end

-- adapted from Penner's Easing Equations and https://github.com/EmmanuelOga/easing/

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin

function self.easing.linear(t,start,change,duration)
    return change * t / duration + start
end


function self.easing.inQuad(t,start,change,duration)
    t = t / duration
    return change * pow(t,2) + start
end


function self.easing.outQuad(t,start,change,duration)
    t = t / duration
    return -change * t * (t - 2) + start
end


function self.easing.inOutQuad(t,start,change,duration)
    t = t / duration * 2

    if t < 1 then
        return change / 2 * pow(t,2) + start
    else
        return -change / 2 * ((t - 1) * (t - 3) - 1) + start
    end
end


function self.easing.outInQuad(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outQuad(t * 2,start,change / 2,duration)
    else
        return self.easing.inQuad((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inCubic(t,start,change,duration)
    t = t / duration
    return change * pow(t,3) + start
end


function self.easing.outCubic(t,start,change,duration)
    t = t / duration - 1
    return change * (pow(t,3) + 1) + start
end


function self.easing.inOutCubic(t,start,change,duration)
    t = t / duration * 2

    if t < 1 then
        return change / 2 * t * t * t + start
    else
        t = t - 2
        return change / 2 * (t * t * t + 2) + start
    end
end


function self.easing.outInCubic(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outCubic(t * 2,start,change / 2,duration)
    else
        return self.easing.inCubic((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inQuart(t,start,change,duration)
    t = t / duration
    return change * pow(t,4) + start
end


function self.easing.outQuart(t,start,change,duration)
    t = t / duration - 1
    return -change * (pow(t,4) - 1) + start
end


function self.easing.inOutQuart(t,start,change,duration)
    t = t / duration * 2

    if t < 1 then
        return change / 2 * pow(t,4) + start
    else
        t = t - 2
        return -change / 2 * (pow(t,4) - 2) + start
    end
end


function self.easing.outInQuart(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outQuart(t * 2,start,change / 2,duration)
    else
        return self.easing.inQuart((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inQuint(t,start,change,duration)
    t = t / duration
    return change * pow(t,5) + start
end


function self.easing.outQuint(t,start,change,duration)
    t = t / duration - 1
    return change * (pow(t,5) + 1) + start
end


function self.easing.inOutQuint(t,start,change,duration)
    t = t / duration * 2

    if t < 1 then
        return change / 2 * pow(t,5) + start
    else
        t = t - 2
        return change / 2 * (pow(t,5) + 2) + start
    end
end


function self.easing.outInQuint(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outQuint(t * 2,start,change / 2,duration)
    else
        return self.easing.inQuint((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inSine(t,start,change,duration)
    return -change * cos(t / duration * (pi / 2)) + change + start
end


function self.easing.outSine(t,start,change,duration)
    return change * sin(t / duration * (pi / 2)) + start
end


function self.easing.inOutSine(t,start,change,duration)
    return -change / 2 * (cos(pi * t / duration) - 1) + start
end


function self.easing.outInSine(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outSine(t * 2,start,change / 2,duration)
    else
        return self.easing.inSine((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inExpo(t,start,change,duration)
    if t == 0 then
        return start
    else
        return change * pow(2,10 * (t / duration - 1)) + start - change * 0.001
    end
end


function self.easing.outExpo(t,start,change,duration)
    if t == duration then
        return start + change
    else
        return change * 1.001 * (-pow(2,-10 * t / duration) + 1) + start
    end
end


function self.easing.inOutExpo(t,start,change,duration)
    if t == 0 then
        return start
    end


    if t == duration then
        return start + change
    end

    t = t / duration * 2

    if t < 1 then
        return change / 2 * pow(2,10 * (t - 1)) + start - change * 0.0005
    else
        t = t - 1
        return change / 2 * 1.0005 * (-pow(2,-10 * t) + 2) + start
    end
end


function self.easing.outInExpo(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outExpo(t * 2,start,change / 2,duration)
    else
        return self.easing.inExpo((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inCirc(t,start,change,duration)
    t = t / duration
    return (-change * (sqrt(1 - pow(t,2)) - 1) + start)
end


function self.easing.outCirc(t,start,change,duration)
    t = t / duration - 1
    return (change * sqrt(1 - pow(t,2)) + start)
end


function self.easing.inOutCirc(t,start,change,duration)
    t = t / duration * 2

    if t < 1 then
        return -change / 2 * (sqrt(1 - t * t) - 1) + start
    else
        t = t - 2
        return change / 2 * (sqrt(1 - t * t) + 1) + start
    end
end


function self.easing.outInCirc(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outCirc(t * 2,start,change / 2,duration)
    else
        return self.easing.inCirc((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end


function self.easing.inElastic(t,start,change,duration,a,p)
    if t == 0 then
        return start
    end

    t = t / duration

    if t == 1 then
        return start + change
    end


    if not p then
        p = duration * 0.3
    end

    local s

    if not a or a < abs(change) then
        a = change
        s = p / 4
    else
        s = p / (2 * pi) * asin(change / a)
    end

    t = t - 1
    return -(a * pow(2,10 * t) * sin((t * duration - s) * (2 * pi) / p)) + start
end


function self.easing.outElastic(t,start,change,duration,a,p)
    if t == 0 then
        return start
    end

    t = t / duration

    if t == 1 then
        return start + change
    end


    if not p then
        p = duration * 0.3
    end

    local s

    if not a or a < abs(change) then
        a = change
        s = p / 4
    else
        s = p / (2 * pi) * asin(change / a)
    end

    return a * pow(2,-10 * t) * sin((t * duration - s) * (2 * pi) / p) + change + start
end


function self.easing.inOutElastic(t,start,change,duration,a,p)
    if t == 0 then
        return start
    end

    t = t / duration * 2

    if t == 2 then
        return start + change
    end


    if not p then
        p = duration * (0.3 * 1.5)
    end


    if not a then
        a = 0
    end

    local s

    if not a or a < abs(change) then
        a = change
        s = p / 4
    else
        s = p / (2 * pi) * asin(change / a)
    end


    if t < 1 then
        t = t - 1
        return -0.5 * (a * pow(2,10 * t) * sin((t * duration - s) * (2 * pi) / p)) + start
    else
        t = t - 1
        return a * pow(2,-10 * t) * sin((t * duration - s) * (2 * pi) / p) * 0.5 + change + start
    end
end


function self.easing.outInElastic(t,start,change,duration,a,p)
    if t < duration / 2 then
        return self.easing.outElastic(
            t * 2,
            start,
            change / 2,
            duration,
            a,
            p
        )
    else
        return self.easing.inElastic(
            (t * 2) - duration,
            start + change / 2,
            change / 2,
            duration,
            a,
            p
        )
    end
end


function self.easing.inBack(t,start,change,duration,s)
    if not s then
        s = 1.70158
    end

    t = t / duration
    return change * t * t * ((s + 1) * t - s) + start
end


function self.easing.outBack(t,start,change,duration,s)
    if not s then
        s = 1.70158
    end

    t = t / duration - 1
    return change * (t * t * ((s + 1) * t + s) + 1) + start
end


function self.easing.inOutBack(t,start,change,duration,s)
    if not s then
        s = 1.70158
    end

    s = s * 1.525
    t = t / duration * 2

    if t < 1 then
        return change / 2 * (t * t * ((s + 1) * t - s)) + start
    else
        t = t - 2
        return change / 2 * (t * t * ((s + 1) * t + s) + 2) + start
    end
end


function self.easing.outInBack(t,start,change,duration,s)
    if t < duration / 2 then
        return self.easing.outBack(t * 2,start,change / 2,duration,s)
    else
        return self.easing.inBack((t * 2) - duration,start + change / 2,change / 2,duration,s)
    end
end


function self.easing.outBounce(t,start,change,duration)
    t = t / duration

    if t < 1 / 2.75 then
        return change * (7.5625 * t * t) + start
    elseif t < 2 / 2.75 then
        t = t - (1.5 / 2.75)
        return change * (7.5625 * t * t + 0.75) + start
    elseif t < 2.5 / 2.75 then
        t = t - (2.25 / 2.75)
        return change * (7.5625 * t * t + 0.9375) + start
    else
        t = t - (2.625 / 2.75)
        return change * (7.5625 * t * t + 0.984375) + start
    end
end


function self.easing.inBounce(t,start,change,duration)
    return change - self.easing.outBounce(duration - t,0,change,duration) + start
end


function self.easing.inOutBounce(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.inBounce(t * 2,0,change,duration) * 0.5 + start
    else
        return self.easing.outBounce(t * 2 - duration,0,change,duration) * 0.5 + change * .5 + start
    end
end


function self.easing.outInBounce(t,start,change,duration)
    if t < duration / 2 then
        return self.easing.outBounce(t * 2,start,change / 2,duration)
    else
        return self.easing.inBounce((t * 2) - duration,start + change / 2,change / 2,duration)
    end
end
