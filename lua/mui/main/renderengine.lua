local self = {}
mUI.RenderEngine = self

self.events = {}
function self:Listen(event,id,callback)
    self.events[event] = self.events[event] or {}
    self.events[event][id] = callback
end

function self:Emit(event,...)
    self.events[event] = self.events[event] or {}
    for id,listener in pairs(self.events[event]) do
        listener(...)
    end
end

self.renderers = {}
function self:registerRenderer(identifier,callback)
    self.renderers[identifier] = callback
end

function self:renderInternal(tag)
    if self.renderers[tag.identifier] then
        xpcall(self.renderers[tag.identifier],function(err)
            ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n"..err.."\n")
        end,tag)
    else
        ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n")
    end
end

function self:walk(tag)
    self:Emit("PreRender",tag)
    self:renderInternal(tag)
    self:Emit("PostRender",tag)

    for _,child in ipairs(tag.children) do
        self:walk(child)
    end
end

function self:Render(template)
    for _,child in ipairs(template.children) do
        self:walk(child)
    end
end
