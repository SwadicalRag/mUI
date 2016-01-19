local self = {}
mUI.ViewManager = self

self.defaultView = {
    x = 0,
    y = 0,
    w = ScrW(),
    h = ScrH()
}
self.viewStack = {
    self.defaultView
}

function self:cancelView(view,newView)
    render.SetScissorRect(view.x,view.y,view.x+view.w,view.y+view.h,false)
    cam.End2D()
    render.SetViewPort(newView.x,newView.y,newView.w,newView.h)
end

function self:applyView(view)
    render.SetViewPort(view.x,view.y,view.w,view.h)
    cam.Start2D()
    render.SetScissorRect(view.x,view.y,view.x+view.w,view.y+view.h,true)
end

function self:PushView(x,y,w,h)
    local currentView = self.viewStack[#self.viewStack]
    local newView = {
        x = currentView.x + x,
        y = currentView.y + y,
        w = w,
        h = h
    }

    local max_x = currentView.x + currentView.w
    local max_y = currentView.y + currentView.h

    newView.w = math.min(newView.x + newView.w,max_x) - newView.x
    newView.h = math.min(newView.y + newView.h,max_y) - newView.y

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
