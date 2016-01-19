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
    local line,col = 0,0
    local tempBuffer1
    local tempBuffer2

    local escapeSequences = {
        nbsp = " ",
        lt = "<",
        gt = ">",
        amp = "&",
        quot = "\"",
        apos = "'"
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
            elseif char:match("[A-Za-z0-9]") then
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
            if char:match("[A-Za-z0-9]") then
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
