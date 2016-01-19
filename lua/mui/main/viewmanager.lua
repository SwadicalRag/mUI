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

function mUI:cancelView(view,newView)
    render.SetScissorRect(view.x,view.y,view.x+view.w,view.y+view.h,false)
    cam.End2D()
end

function mUI:applyView(view)
    cam.Start2D()
    render.SetViewPort(view.x,view.y,view.w,view.h)
    render.SetScissorRect(view.x,view.y,view.x+view.w,view.y+view.h,true)
end

function mUI:PushView(x,y,w,h)
    self.viewStack[#self.viewStack + 1] = {
        x = x,
        y = y,
        w = w,
        h = h
    }

    self:applyView(self.viewStack[#self.viewStack])
end

function mUI:PopView(x,y,w,h)
    self:cancelView(self.viewStack[#self.viewStack])
    self.viewStack[#self.viewStack] = nil
    self:applyView(self.viewStack[#self.viewStack])
end
