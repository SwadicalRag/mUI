local self = {}
mUI.MouseUtils = self

self.renderStack = {}
function self:ClearStack()
    self.renderStack = {}
end

function self:PushRect(tag,x,y,w,h)
    self.renderStack[#self.renderStack+1] = {
        type = "rect",
        x = x + mUI.ViewManager:GetCurrentView().x,
        y = y + mUI.ViewManager:GetCurrentView().y,
        w = w,
        h = h,
        view = mUI.ViewManager:GetCurrentView(),
        tag = tag
    }
end

function self:PushCircle(tag,x,y,rad)
    self.renderStack[#self.renderStack+1] = {
        type = "circle",
        x = x + mUI.ViewManager:GetCurrentView().x,
        y = y + mUI.ViewManager:GetCurrentView().y,
        rad = rad,
        view = mUI.ViewManager:GetCurrentView(),
        tag = tag
    }
end

function self:GetMouseTag()
    local x,y = gui.MousePos()
    local tag = false

    for _,drawOp in ipairs(self.renderStack) do
        if x >= drawOp.view.limit.x
        and x < (drawOp.view.limit.x + drawOp.view.limit.w)
        and y >= drawOp.view.limit.y
        and y < (drawOp.view.limit.y + drawOp.view.limit.h) then
            if drawOp.type == "rect" then
                if x >= drawOp.x
                and x < (drawOp.x + drawOp.w)
                and y >= drawOp.y
                and y < (drawOp.y + drawOp.h) then
                    tag = drawOp.tag
                end
            elseif drawOp.type == "circle" then
                if ((drawOp.x - x)^2 + (drawOp.y - y)^2)^0.5 < drawOp.rad then
                    tag = drawOp.tag
                end
            end
        end
    end

    return tag
end

function self:Scrolled(step)
    local active = self:GetMouseTag()
    if active then
        mUI.RenderEngine:Emit("Scrolled",active,step)
    end
end

hook.Add("Move","swadical.mUI.cursor",function()
    mUI.RenderEngine:Emit("ProcessCursorEvents",self:GetMouseTag())
end)

hook.Add("PreRender","swadical.mUI.clearRenderStack",function()
    self:ClearStack()
end)

self.scrollStep = 2
hook.Add("Move","swadical.mUI.scrollListener",function()
    if input.WasMousePressed(MOUSE_WHEEL_UP) or input.WasMousePressed(MOUSE_WHEEL_DOWN) then
        self:Scrolled((input.WasMousePressed(MOUSE_WHEEL_UP) and 1 or -1) * self.scrollStep)
    end
end)

function self:MouseEvent(enum)
    if input.WasMousePressed(enum) then
        local active = self:GetMouseTag()
        if active then
            mUI.RenderEngine:Emit("MouseEvent",active,enum)
        end
    end
end

hook.Add("Move","swadical.mUI.clickListener",function()
    self:MouseEvent(MOUSE_LEFT)
    self:MouseEvent(MOUSE_RIGHT)
    self:MouseEvent(MOUSE_MIDDLE)
end)
