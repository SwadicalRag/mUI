local self = {}
mUI.RenderEngine = self

self.events = {}
function self:Listen(event,id,callback,priority)
    self.events[event] = self.events[event] or {}

    for _,data in ipairs(self.events[event]) do
        if data.id == id then
            data.callback = callback
            data.priority = priority or 100
            return
        end
    end

    self.events[event][#self.events[event]+1] = {
        callback = callback,
        id = id,
        priority = priority or 100
    }
end

function self:Emit(event,...)
    self.events[event] = self.events[event] or {}

    table.sort(self.events[event],function(t1,t2)
        return t1.priority < t2.priority
    end)

    for _,data in ipairs(self.events[event]) do
        if data.callback(...) then return end
    end
end

self.renderers = {}
function self:registerRenderer(identifier,callback)
    self.renderers[identifier] = callback
end

function self:registerInternalTag(identifier)
    self.renderers[identifier] = false
end

function self:protectedTagCall(tag,fn,...)
    return xpcall(fn,function(err)
        ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n"..err.."\n")
    end,...)
end

function self:renderInternal(tag,template)
    if self.renderers[tag.identifier] then
        self:protectedTagCall(tag,self.renderers[tag.identifier],tag,template)
    else
        ErrorNoHalt("Unable to render "..tag.identifier.." at line "..tag.token.line.." col "..tag.token.col.."\n")
    end
end

function self:walk(tag,template)
    tag.template = template
    if self.renderers[tag.identifier] == false then return end
    self:protectedTagCall(tag,self.Emit,self,"PreRender",tag,template)
    if mUI.ViewManager:IsNullView() then return end
    self:renderInternal(tag,template)
    self:protectedTagCall(tag,self.Emit,self,"PostRender",tag,template)

    if tag.renderData.canRenderChildren then
        self:protectedTagCall(tag,self.Emit,self,"EnterChild",tag,template)
        for _,child in ipairs(tag.children) do
            self:protectedTagCall(tag,self.Emit,self,"OnChild",child,tag,template)
            self:walk(child,template)
        end
        self:protectedTagCall(tag,self.Emit,self,"ExitChild",tag,template)
    end
end

function self:Render(base,template)
    for _,child in ipairs(base.children) do
        self:walk(child,template)
    end
    if #mUI.ViewManager.viewStack ~= 1 then error("View stack leak!!")mUI.ViewManager.viewStack = {mUI.ViewManager.defaultView} end
end
