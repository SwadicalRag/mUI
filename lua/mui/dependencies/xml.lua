local self = {}
mUI.XML = self

local TOKENIZER = {
    IDLE = 0,
    IDENTIFIER = 1,
    CARRIAGERETURN = 2,
    QUOTED_SINGLE = 3,
    QUOTED_DOUBLE = 4,
    ESCAPED = 5
}

function self:Tokenize(str)
    local mode = TOKENIZER.IDLE
    local tokens = {}
    local line,col = 1,0
    local tempBuffer1
    local tempBuffer2

    local escapeSequences = {
        nbsp = " ",
        lt = "<",
        gt = ">",
        amp = "&",
        quot = "\"",
        apos = "'",
        nl = "\n" -- because
    }

    for char in str:gmatch("(.)") do
        col = col + 1
        ::parser::
        if mode == TOKENIZER.IDLE then
            if char == "\n" then
                tokens[#tokens + 1] = {
                    type = "NewLine",
                    data = char,
                    line = line,
                    col = col
                }
                line = line + 1
                col = 0
            elseif char == "\r" then
                tokens[#tokens + 1] = {
                    type = "NewLine",
                    data = char,
                    line = line,
                    col = col
                }
                mode = TOKENIZER.CARRIAGERETURN
            elseif char == "<" then
                tokens[#tokens + 1] = {
                    type = "TagOpen",
                    data = char,
                    line = line,
                    col = col
                }
            elseif char == " " then
                if tokens[#tokens].type == "Whitespace" then
                    tokens[#tokens].data = tokens[#tokens].data..char
                else
                    tokens[#tokens + 1] = {
                        type = "Whitespace",
                        data = char,
                        line = line,
                        col = col
                    }
                end
            elseif char == "\t" then
                if tokens[#tokens].type == "Tab" then
                    tokens[#tokens].data = tokens[#tokens].data..char
                else
                    tokens[#tokens + 1] = {
                        type = "Tab",
                        data = char,
                        line = line,
                        col = col
                    }
                end
            elseif char == ">" then
                tokens[#tokens + 1] = {
                    type = "TagClose",
                    data = char,
                    line = line,
                    col = col
                }
            elseif char == "/" then
                tokens[#tokens + 1] = {
                    type = "Slash",
                    data = char,
                    line = line,
                    col = col
                }
            elseif char == "=" then
                tokens[#tokens + 1] = {
                    type = "Equals",
                    data = char,
                    line = line,
                    col = col
                }
            elseif char == "\"" then
                tokens[#tokens + 1] = {
                    type = "Quote",
                    data = char,
                    line = line,
                    col = col
                }
                tokens[#tokens + 1] = {
                    type = "Text",
                    data = "",
                    line = line,
                    col = col
                }
                mode = TOKENIZER.QUOTED_DOUBLE
            elseif char == "'" then
                tokens[#tokens + 1] = {
                    type = "Quote",
                    data = char,
                    line = line,
                    col = col
                }
                tokens[#tokens + 1] = {
                    type = "Text",
                    data = "",
                    line = line,
                    col = col
                }
                mode = TOKENIZER.QUOTED_SINGLE
            elseif char == "&" then
                if not (tokens[#tokens] and tokens[#tokens].type == "Identifier") then
                    tokens[#tokens + 1] = {
                        type = "Identifier",
                        data = "",
                        line = line,
                        col = col
                    }
                end
                tempBuffer1 = ""
                tempBuffer2 = mode
                mode = TOKENIZER.ESCAPED
            elseif char:match("[^<>\r\n =]") then
                tokens[#tokens + 1] = {
                    type = "Identifier",
                    data = char,
                    line = line,
                    col = col
                }
                mode = TOKENIZER.IDENTIFIER
            else
                error("Unexpected character: "..char.." at line "..line.." col "..col)
            end
        elseif mode == TOKENIZER.IDENTIFIER then
            if char:match("[^<>\r\n =]") then
                tokens[#tokens].data = tokens[#tokens].data..char
            else
                mode = TOKENIZER.IDLE
                goto parser
            end
        elseif mode == TOKENIZER.CARRIAGERETURN then
            if char == "\n" then
                tokens[#tokens].data = tokens[#tokens].data..char
                mode = TOKENIZER.IDLE
                line = line + 1
                col = 0
            else
                error("Malformed carriage return at line "..line.." col "..col)
            end
        elseif (mode == TOKENIZER.QUOTED_SINGLE) then
            if char:match("[^'\r\n&]") then
                tokens[#tokens].data = tokens[#tokens].data..char
            elseif char == "&" then
                tempBuffer1 = ""
                tempBuffer2 = mode
                mode = TOKENIZER.ESCAPED
            elseif char == "'" then
                tokens[#tokens + 1] = {
                    type = "Quote",
                    data = char,
                    line = line,
                    col = col
                }
                mode = TOKENIZER.IDLE
            else
                error("Malformed quoted text at line "..line.." col "..col)
            end
        elseif (mode == TOKENIZER.QUOTED_DOUBLE) then
            if char:match("[^\"\r\n&]") then
                tokens[#tokens].data = tokens[#tokens].data..char
            elseif char == "&" then
                tempBuffer1 = ""
                tempBuffer2 = mode
                mode = TOKENIZER.ESCAPED
            elseif char == "\"" then
                tokens[#tokens + 1] = {
                    type = "Quote",
                    data = char,
                    line = line,
                    col = col
                }
                mode = TOKENIZER.IDLE
            else
                error("Malformed quoted text at line "..line.." col "..col)
            end
        elseif (mode == TOKENIZER.ESCAPED) then
            if char == ";" then
                if tempBuffer1:sub(1,1) == "#" then
                    if tempBuffer1:sub(2,2) == "x" then
                        if tonumber(tempBuffer1:sub(3,-1) or "",16) then
                            tokens[#tokens].data = tokens[#tokens].data..string.char(tonumber(tempBuffer1:sub(3,-1),16))
                            mode = tempBuffer2
                        else
                            error("Invalid numeric hex escape sequence at line "..line.." col "..col)
                        end
                    elseif tonumber(tempBuffer1:sub(2,-1) or "") then
                        tokens[#tokens].data = tokens[#tokens].data..string.char(tonumber(tempBuffer1:sub(2,-1)))
                        mode = tempBuffer2
                    else
                        error("Invalid numeric escape sequence at line "..line.." col "..col)
                    end
                elseif escapeSequences[tempBuffer1] then
                    tokens[#tokens].data = tokens[#tokens].data..escapeSequences[tempBuffer1]
                    mode = tempBuffer2
                else
                    error("Invalid escape sequence \"&"..tempBuffer1..";\" at line "..line.." col "..col)
                end
            elseif tokens[#tokens - 1].data == char then
                error("Unterminated escape sequence at line "..line.." col "..col)
            else
                tempBuffer1 = tempBuffer1..char
            end
        end
    end

    if mode ~= TOKENIZER.IDLE then
        error("Unexpected EOF!")
    end

    return tokens
end

local PARSER = {
    IDLE = 0,
    TAG_NEED_IDENT = 1,
    TAG_NEED_CLOSE = 2,
    IDENT_NEED_EQUALS = 3,
    IDENT_NEED_QUOTE = 4,
    IDENT_NEED_DEFINE = 5,
    IDENT_NEED_QUOTE_CLOSE = 6,
    TAG_CLOSE_IDENT = 7,
    TAG_NEED_CLOSE_ONLY = 8
}

self.Parsers = {}
function self.Parsers.Whitespace()end
function self.Parsers.NewLine(parser,token)
    parser.currentNode.text = parser.currentNode.text:sub(1,-1-#token.data)
end
function self.Parsers.Tab(parser,token)
    parser.currentNode.text = parser.currentNode.text:sub(1,-1-#token.data)
end

function self.Parsers.TagOpen(parser,token)
    assert(parser.mode == PARSER.IDLE,"Unexpected tag opening at line "..token.line.." col "..token.col.."!")
    parser.mode = PARSER.TAG_NEED_IDENT

    parser.isInBody = false
    parser.tempBuffer1 = parser:newChild(token)
end

function self.Parsers.Slash(parser,token)
    if parser.isInBody then return end
    assert(parser.mode == PARSER.TAG_NEED_IDENT,"Unexpected slash at line "..token.line.." col "..token.col.."!")

    parser.tempBuffer1 = nil
    parser.mode = PARSER.TAG_CLOSE_IDENT
end

function self.Parsers.Identifier(parser,token)
    if parser.mode == PARSER.TAG_NEED_IDENT then
        parser.mode = PARSER.TAG_NEED_CLOSE

        parser.tempBuffer1.identifier = token.data
    elseif parser.mode == PARSER.TAG_NEED_CLOSE then
        assert(token.data:match("[A-Za-z0-9%-]"),"Token contains non alphanumeric symbols!")
        parser.tempBuffer2 = token.data
        parser.mode = PARSER.IDENT_NEED_EQUALS
    elseif parser.mode == PARSER.TAG_CLOSE_IDENT then
        assert(parser.currentNode.identifier == token.data,"Tag "..token.data.." was unexpectedly closed at line "..token.line.." col "..token.col.."!")
        parser.mode = PARSER.TAG_NEED_CLOSE_ONLY
    elseif parser.mode == PARSER.IDLE then

    else
        error("Unexpected identifier at line "..token.line.." col "..token.col.."!")
    end
end

function self.Parsers.Equals(parser,token)
    if parser.isInBody then return end
    assert(parser.mode == PARSER.IDENT_NEED_EQUALS,"Unexpected '=' at line "..token.line.." col "..token.col.."!")
    parser.mode = PARSER.IDENT_NEED_QUOTE
end

function self.Parsers.Text(parser,token)
    assert(parser.mode == PARSER.IDENT_NEED_DEFINE,"Unexpected text at line "..token.line.." col "..token.col.."!")
    parser.mode = PARSER.IDENT_NEED_QUOTE_CLOSE

    parser.tempBuffer1.attributes[parser.tempBuffer2] = token.data
    parser.tempBuffer2 = nil
end

function self.Parsers.Quote(parser,token)
    if parser.mode == PARSER.IDENT_NEED_QUOTE then
        parser.mode = PARSER.IDENT_NEED_DEFINE
    elseif parser.mode == PARSER.IDENT_NEED_QUOTE_CLOSE then
        parser.mode = PARSER.TAG_NEED_CLOSE
    else
        error("Unexpected quote at line "..token.line.." col "..token.col.."!")
    end
end

function self.Parsers.TagClose(parser,token)
    assert((parser.mode == PARSER.TAG_NEED_CLOSE) or (parser.mode == PARSER.TAG_NEED_CLOSE_ONLY),"Unexpected tag closing at line "..token.line.." col "..token.col.."!")

    if parser.mode == PARSER.TAG_NEED_CLOSE_ONLY then
        parser:popChild()
    else
        parser:pushChild(parser.tempBuffer1)
        parser.tempBuffer1 = nil
    end
    parser.isInBody = true
    parser.mode = PARSER.IDLE
end

function self:ParseTokens(tokens)
    local parser = {}
    parser.tempBuffer1 = nil -- for reference
    parser.tempBuffer2 = nil
    parser.mode = PARSER.IDLE
    parser.idx = 1

    function parser:advanceIdx()
        self.idx = self.idx + 1
    end

    function parser:getRelativeToken(relative)
        return tokens[self.idx + relative]
    end

    function parser:expect(type)
        return self:getRelativeToken(1) and (self:getRelativeToken(1).type == type)
    end

    function parser:is(type)
        return self:getRelativeToken(0) and (self:getRelativeToken(0).type == type)
    end

    function parser:newChild(token)
        local child = {
            text = "",
            children = {},
            attributes = {},
            parent = self.currentNode,
            identifier = "",
            token = token
        }
        return child
    end

    function parser:pushChild(child)
        self.currentNode.children[#self.currentNode.children+1] = child
        self.currentNode = child or self.currentNode
    end

    function parser:popChild()
        self.currentNode = self.currentNode.parent or self.currentNode
    end

    function parser:updateText(child,text)
        if self.isInBody and not self:is "TagOpen" then
            child.text = child.text..text
        end
    end

    parser.AST = {
        text = "",
        children = {},
        attributes = {},
        parent = false,
        identifier = "main",
        token = false
    }
    parser.isInBody = true
    parser.currentNode = parser.AST

    for _,token in ipairs(tokens) do
        parser:updateText(parser.currentNode,token.data)
        self.Parsers[token.type](parser,token)

        parser:advanceIdx()
    end

    if parser.currentNode ~= parser.AST then
        error("Tag "..parser.currentNode.identifier.." was not closed! (line "..parser.currentNode.token.line.." col "..parser.currentNode.token.col..")")
    end

    return parser.AST
end

function self:Parse(xml)
    return self:ParseTokens(self:Tokenize(xml))
end
