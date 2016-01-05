local bXML = {}

local TAG_OPEN,TAG_CLOSE,TAG_OPEN_AND_CLOSE,TAG_INFO = 0,1,2,3

-- Internal: do not call
function bXML:parseTag(str,data,tagStack)
    local tag,args = str:match("^%s*(%S+)%s*(.*)$")
    local tagFirstChar = tag:sub(1,1)

    if tagFirstChar == "!" then
        data._data[tag:sub(2,-1)] = args
        return TAG_INFO
    elseif tagFirstChar == "/" then
        if tagStack[#tagStack].tag == tag:sub(2,-1) then
            tagStack[#tagStack] = nil

            return TAG_CLOSE
        else
            error("Tag "..tag.." was closed unexpectedly")
        end
    else
        local tbl = {
            _data = {}
        }
        tagStack[#tagStack+1] = {
            tag = tag,
            data = tbl
        }

        for key,val in args:gmatch("(%S+)%s*=%s*(%b\"\")") do
            tbl._data[key] = val:sub(2,-2)
        end

        data[tag] = tbl

        if tag:match("/%s*$") then
            tagStack[#tagStack] = nil

            return TAG_OPEN_AND_CLOSE
        end

        return TAG_OPEN,tbl
    end
end

function bXML:parseTagGroup(str,data,tagStack)
    for tag in str:gmatch("<(.-)>") do
        local target
        if tagStack[#tagStack] then
            target = tagStack[#tagStack].data
        else
            target = data
        end
        self:parseTag(tag,target,tagStack)
    end

    if #tagStack > 0 then
        error("Unclosed tag "..tagStack[#tagStack].tag)
    end


    return data
end

function bXML:Parse(str)
    return self:parseTagGroup(str,{},{})
end

function bXML:Create(tbl)
    error("Unimplemented")
end

_G.bXML = bXML

return bXML
