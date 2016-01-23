local imageCache = {}

local function loadImage(url,ext)
    imageCache[url] = false
    http.Fetch(url,function(data)
        local fname = ("mUI.imgcache.%08x.%s"):format(util.CRC(data),ext or "png")
        file.Write(fname,data)
        imageCache[url] = Material("../data/"..fname)
    end)
end

mUI.RenderEngine:registerRenderer("Image",function(tag,template)
    mUI.MouseUtils:PushRect(tag,tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)

    surface.SetDrawColor(255,255,255,255)
    if imageCache[tag.attributes.src] == false then
        surface.DrawRect(tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
        draw.SimpleText("Loading...",mUI.Parsers:Font{font="Lucida Console",['font-size']="2%"},tag.renderData.x+tag.renderData.w/2,tag.renderData.y+tag.renderData.h/2,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    elseif imageCache[tag.attributes.src] then
        surface.SetMaterial(imageCache[tag.attributes.src])
        surface.DrawTexturedRect(tag.renderData.x,tag.renderData.y,tag.renderData.w,tag.renderData.h)
    else
        loadImage(tag.attributes.src,tag.attributes.ext)
    end
end)
