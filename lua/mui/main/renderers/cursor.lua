mUI.RenderEngine:Listen("ProcessCursorEvents","Cursors",function(tag)
    if tag and tag.attributes.cursor then
        return mUI.DBase:SetCursor(tag.attributes.cursor)
    end
    return mUI.DBase:SetCursor("user")
end)

mUI.RenderEngine:registerInternalTag("TrapCursor")
mUI.RenderEngine:registerInternalTag("TrapKeyboard")
