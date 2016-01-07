local bXML = {}

local TAG_OPEN,TAG_CLOSE,TAG_OPEN_AND_CLOSE,TAG_INFO = 0,1,2,3

bXML.metas = {}

bXML.metas.node = {
    __tostring = function(self)
        return "bXML Node ["..self.id.." @ line "..self.line.."]"
    end
}

bXML.metas.attributes = {
    __tostring = function(self)
        return "bXML Node Attributes ["..self._parent.id.." @ line "..self._parent.line.."]"
    end
}

bXML.metas.children = {
    __tostring = function(self)
        return "bXML Node Children ["..self.parent.id.." @ line "..self.parent.line.."]"
    end
}

local function countNewlines(str,pos)
    local count = 1

    for _ in str:sub(1,pos):gmatch("\r?\n") do
        count = count + 1
    end

    return count
end

-- Internal: do not call
function bXML:parseTag(str,node,tagStack,tagStart,tagFinish,stringXML,tagCountLookup)
    local tag,args = str:match("^%s*(%S+)%s*(.*)$")
    local tagFirstChar = tag:sub(1,1)

    if tagFirstChar == "!" then
        node.attributes[tag:sub(2,-1)] = args
        return TAG_INFO
    elseif tagFirstChar == "/" then
        if tagStack[#tagStack].tag == tag:sub(2,-1) then
            tagStack[#tagStack].node.text = stringXML:sub(tagStack[#tagStack].tagFinish+1,tagStart-1) or ""
            tagStack[#tagStack] = nil

            return TAG_CLOSE
        else
            error("Tag "..tag.." was closed unexpectedly")
        end
    else
        tagCountLookup[tag] = tagCountLookup[tag] or 0
        tagCountLookup[tag] = tagCountLookup[tag] + 1

        local newNode = setmetatable({
            text = "",
            id = tag.."#"..tagCountLookup[tag],
            tag = tag,
            line = countNewlines(stringXML,tagStart),
            parent = node
        },self.metas.node)

        newNode.attributes = setmetatable({},self.metas.attributes)
        newNode.attributes._parent = node

        newNode.children = setmetatable({},self.metas.children)
        newNode.children.parent = node

        tagStack[#tagStack+1] = {
            tag = tag,
            node = newNode,
            tagFinish = tagFinish,
            tagStart = tagStart
        }

        for key,val in args:gmatch("(%S+)%s*=%s*(%b\"\")") do
            newNode.attributes[key] = val:sub(2,-2)
        end

        node.children[#node.children+1] = newNode

        if args:match("/%s*$") then
            tagStack[#tagStack] = nil

            return TAG_OPEN_AND_CLOSE
        end

        return TAG_OPEN,tbl
    end
end

local function ifind(str,match,patterns)
    local lastpos = 1
    return function()
        local args = {str:find(match,lastpos,patterns)}
        if #args == 0 then return end
        lastpos = args[2]+1
        return unpack(args)
    end
end

function bXML:parseTagGroup(str,data,tagStack,tagCountLookup)
    for tagStart,tagFinish,tag in ifind(str,"<(.-)>") do
        local target = tagStack[#tagStack] and tagStack[#tagStack].node or data

        self:parseTag(tag,target,tagStack,tagStart,tagFinish,str,tagCountLookup)
    end

    if #tagStack > 0 then
        error("Unclosed tag "..tagStack[#tagStack].tag)
    end


    return data
end

function bXML:Parse(str)
    return self:parseTagGroup(str,setmetatable({
        attributes = setmetatable({},self.metas.attributes),
        text = str,
        children = setmetatable({},self.metas.children),
        id = "main",
        tag = "__main__" -- internal use only
    },self.metas.node),{},{})
end

_G.bXML = bXML

return bXML
