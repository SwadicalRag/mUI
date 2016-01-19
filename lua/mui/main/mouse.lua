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

hook.Add("PreRender","swadical.mUI.clearRenderStack",function()
    self:ClearStack()
end)
