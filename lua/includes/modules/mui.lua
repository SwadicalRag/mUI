require("bxml")
require("lustache")

mUI = mUI or {}

mUI.templates = {}
mUI.activeTemplates = {}

function mUI:FromTemplate(name)
    local results = self.FS:SearchFile(name,true,false)
    if #results > 0 then
        local template = {}
        template.contents = self.FS:Read(results[1])

        function template:buildTemplate()
            self.template = lustache:render(self.contents,self.data)
            self.XML = bXML:Parse(self.template)
        end

        template.lastDataTime = 0
        template.templateUpdateInterval = 0.1
        function template:getDataInternal()
            if (SysTime() - self.lastDataTime) > self.templateUpdateInterval then
                self.data = self:GetData()
                self:buildTemplate()

                self.lastDataTime = SysTime()
            end

            return self.data
        end

        function template:GetData()
            return {}
        end

        function template:SetDraw(val)
            self.draw = val
        end

        self.activeTemplates[#self.activeTemplates+1] = template

        return template
    else
        error("Template "..path.." does not exist")
    end
end

mUI.renderers = {}
function mUI:renderNode(name,data)
    if self.renderers[name] then
        self.renderers[name](self.renderers,data)
    else
        error("Unknown render node "..data)
    end
end

function mUI:parseRenderNode(name,tbl)
    self:renderNode(name,tbl._data)

    for name,data in pairs(tbl) do
        if name == "_data" then continue end
        self:parseRenderNode(name,data)
    end
end

function mUI:Render(template)
    template:getDataInternal()
    for name,data in pairs(template.XML) do
        if name == "_data" then continue end
        self:parseRenderNode(name,data)
    end
end

function mUI:RegisterRenderer(name,fn)
    self.renderers[name] = fn
end

function mUI:parseColor(colorStr)
    if colorStr:find("^rgba%(.-%)$") then
        return Color(colorStr:match("^rgba%(([%d%.]-),([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    elseif colorStr:find("^rgb(.-)$") then
        return Color(colorStr:match("^rgb%(([%d%.]-),([%d%.]-),([%d%.]-)%)$"))
    else
        error("Bad color string")
    end
end

mUI:RegisterRenderer("Box",function(renderers,data)
    draw.RoundedBox(tonumber(data.cornerRadius or 0),tonumber(data.x),tonumber(data.y),tonumber(data.w),tonumber(data.h),mUI:parseColor(data.color))
end)
hook.Add("DrawOverlay","swadical.mUI.autoRender",function()
    for _,template in ipairs(mUI.activeTemplates) do
        if template.draw then
            mUI:Render(template)
        end
    end
end)

return mUI
