local bXML = {}

local TAG_OPEN,TAG_CLOSE,TAG_OPEN_AND_CLOSE,TAG_INFO = 0,1,2,3

-- Internal: do not call
function bXML:parseTag(str,data,tagStack,start,finish,all)
    local tag,args = str:match("^%s*(%S+)%s*(.*)$")
    local tagFirstChar = tag:sub(1,1)

    if tagFirstChar == "!" then
        data.data[tag:sub(2,-1)] = args
        return TAG_INFO
    elseif tagFirstChar == "/" then
        if tagStack[#tagStack].tag == tag:sub(2,-1) then
            tagStack[#tagStack].data.text = all:sub(tagStack[#tagStack].finish+1,start-1) or ""
            tagStack[#tagStack] = nil

            return TAG_CLOSE
        else
            error("Tag "..tag.." was closed unexpectedly")
        end
    else
        local tbl = {
            data = {},
            text = "",
            children = {}
        }

        tagStack[#tagStack+1] = {
            tag = tag,
            data = tbl,
            finish = finish,
            start = start
        }

        for key,val in args:gmatch("(%S+)%s*=%s*(%b\"\")") do
            tbl.data[key] = val:sub(2,-2)
        end

        data.children[#data.children+1] = {
            tag = tag,
            data = tbl
        }

        if tag:match("/%s*$") then
            tagStack[#tagStack] = nil

            return TAG_OPEN_AND_CLOSE
        end

        return TAG_OPEN,tbl
    end
end

function string.ifind(str,match,patterns)
    local lastpos = 1
    return function()
        local args = {str:find(match,lastpos,patterns)}
        if #args == 0 then return end
        lastpos = args[2]+1
        return unpack(args)
    end
end

function bXML:parseTagGroup(str,data,tagStack)
    for start,finish,tag in str:ifind("<(.-)>") do
        local target
        if tagStack[#tagStack] then
            target = tagStack[#tagStack].data
        else
            target = data
        end
        self:parseTag(tag,target,tagStack,start,finish,str)
    end

    if #tagStack > 0 then
        error("Unclosed tag "..tagStack[#tagStack].tag)
    end


    return data
end

function bXML:Parse(str)
    return self:parseTagGroup(str,{
        data = {},
        text = "",
        children = {}
    },{})
end

function bXML:Create(tbl)
    error("Unimplemented")
end

_G.bXML = bXML

return bXML
