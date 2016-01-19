local self = {}
mUI.ViewManager = self

self.defaultView = {
    x = 0,
    y = 0,
    w = ScrW(),
    h = ScrH()
}
self.defaultView.limit = self.defaultView
self.viewStack = {
    self.defaultView
}

function self:cancelView(view,newView)
    render.SetScissorRect(view.limit.x,view.limit.y,view.limit.x+view.limit.w,view.limit.y+view.limit.h,false)
    cam.End2D()
    render.SetViewPort(newView.x,newView.y,newView.w,newView.h)
end

function self:applyView(view)
    render.SetViewPort(view.x,view.y,view.w,view.h)
    cam.Start2D()
    render.SetScissorRect(view.limit.x,view.limit.y,view.limit.x+view.limit.w,view.limit.y+view.limit.h,true)
end

function self:PushView(x,y,w,h)
    local currentView = self.viewStack[#self.viewStack]
    local newView = {
        x = currentView.x + x,
        y = currentView.y + y,
        w = w,
        h = h
    }
    newView.limit = {
        x = currentView.x + x,
        y = currentView.y + y,
        w = w,
        h = h
    }

    local max_x = currentView.x + currentView.w
    local max_y = currentView.y + currentView.h

    if newView.x < currentView.x then
        newView.limit.x = currentView.x
        newView.limit.w = newView.w - (currentView.x - newView.x)
    else
        newView.w = math.min(newView.x + newView.w,max_x) - newView.x
    end

    if newView.y < currentView.y then
        newView.limit.y = currentView.y
        newView.limit.h = newView.h - (currentView.y - newView.y)
    else
        newView.h = math.min(newView.y + newView.h,max_y) - newView.y
    end

    self.viewStack[#self.viewStack + 1] = newView

    self:applyView(newView)
end

function self:PopView(x,y,w,h)
    self:cancelView(self.viewStack[#self.viewStack],self.viewStack[#self.viewStack-1] or self.defaultView)
    self.viewStack[#self.viewStack] = nil
    if #self.viewStack == 0 then self.viewStack = {self.defaultView} end
    self:applyView(self.viewStack[#self.viewStack])
end

function self:GetCurrentView()
    return self.viewStack[#self.viewStack]
end
