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

function self:protectedTagCall(tag,fn,...)
    return xpcall(fn,function(err)
        ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n"..err.."\n")
    end,...)
end

function self:renderInternal(tag)
    if self.renderers[tag.identifier] then
        self:protectedTagCall(tag,self.renderers[tag.identifier],tag)
    else
        ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n")
    end
end

function self:walk(tag)
    self:protectedTagCall(tag,self.Emit,self,"PreRender",tag)
    self:renderInternal(tag)
    self:protectedTagCall(tag,self.Emit,self,"PostRender",tag)

    if tag.renderData.canRenderChildren then
        self:protectedTagCall(tag,self.Emit,self,"EnterChild",tag)
        for _,child in ipairs(tag.children) do
            self:walk(child)
        end
        self:protectedTagCall(tag,self.Emit,self,"ExitChild",tag)
    end
end

function self:Render(template)
    for _,child in ipairs(template.children) do
        self:walk(child)
    end
    if #mUI.ViewManager.viewStack ~= 1 then error("View stack leak!!")mUI.ViewManager.viewStack = {mUI.ViewManager.defaultView} end
end
