larith = {}

function larith:Evaluate(str)
    if tonumber(str) then return tonumber(str) end
    if not str:match("^[%s%d%-%+%*%/]+$") then error("Cannot parse "..str) end

    ::mulDiv::
    str = str:gsub("([%d%.]+)%s*([%*%/])%s*([%d%.]+)",function(n1,op,n2)
        if op == "*" then
            return tonumber(n1) * tonumber(n2)
        else
            return tonumber(n1) / tonumber(n2)
        end
    end)

    if str:match("([%d%.]+)%s*([%*%/])%s*([%d%.]+)") then goto mulDiv end

    ::addSub::
    str = str:gsub("([%d%.]+)%s*([%+%-])%s*([%d%.]+)",function(n1,op,n2)
        if op == "+" then
            return tonumber(n1) + tonumber(n2)
        else
            return tonumber(n1) - tonumber(n2)
        end
    end)

    if str:match("([%d%.]+)%s*([%+%-])%s*([%d%.]+)") then goto addSub end

    return tonumber(str)
end

return larith
