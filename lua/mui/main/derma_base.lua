if mUI.DBase then
    mUI.DBase:RemoveAllPanels()
end

local self = {}
mUI.DBase = self

self.panels = {}
function self:RemoveAllPanels()
    if IsValid(self.basePanel) then
        self.basePanel:Remove()
        self.basePanel = nil
    end

    for id,pnl in pairs(self.panels) do
        if IsValid(pnl) then
            pnl:Remove()
        end
    end

    self.panels = {}
end

function self:BindPanel(id,type)
    if not self.panels[id] then
        local pnl = vgui.Create(type,self.basePanel)
        pnl:SetPaintedManually(true)

        function pnl:Render()
            self:SetPaintedManually(false)
            local x,y = self:GetPos()
            local w,h = self:GetSize()
            self:PaintAt(x,y,w,h)
            self:SetPaintedManually(true)
        end

        self.panels[id] = pnl
    end

    return self.panels[id]
end

self.trapping = {}
function self:trapInternal()
    local isTrapping = (self.trapping.cursor or self.trapping.keyboard)
    if self.trapping.internal ~= isTrapping then
        if isTrapping then
            self.basePanel:Show()
            self.basePanel:MakePopup()
        else
            self.basePanel:Hide()
        end

        self.trapping.internal = isTrapping
    end
end

function self:TrapCursor(status)
    status = tobool(status)

    if self.trapping.cursor ~= status then
        self.trapping.cursor = status

        self:trapInternal()
        self.basePanel:SetMouseInputEnabled(status)
        self.basePanel:SetKeyboardInputEnabled(self.trapping.keyboard)
    end
end

function self:TrapKeyboard(status)
    status = tobool(status)

    if self.trapping.keyboard ~= status then
        self.trapping.keyboard = status

        self:trapInternal()
        self.basePanel:SetMouseInputEnabled(self.trapping.mouse)
        self.basePanel:SetKeyboardInputEnabled(status)
    end
end

self.cursor = "user"
function self:SetCursor(cursor)
    if self.cursor ~= cursor then
        self.basePanel:SetCursor(cursor)
        self.cursor = cursor
    end
end

function self:createBasePanel()
    self.basePanel = vgui.Create("DPanel")
    self.basePanel:Dock(FILL)
    self.trapping.internal = false
    self.trapping.keyboard = false
    self.trapping.cursor = false
    self.basePanel.Paint = function()end

    vgui.CreateFromTable {
    	Base = "Panel",
    	PerformLayout = function()
    		mUI.ViewManager:ResolutionChange(ScrW(),ScrH())
    	end
    }:ParentToHUD()
end

hook.Add("DrawOverlay","swadical.mUI.bindBP",function()
    self:createBasePanel()
    hook.Remove("DrawOverlay","swadical.mUI.bindBP")
end)
