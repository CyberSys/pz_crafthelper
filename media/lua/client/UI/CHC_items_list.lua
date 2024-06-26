CHC_items_list = ISScrollingListBox:derive('CHC_items_list')

-- region create

function CHC_items_list:initialise()
    ISScrollingListBox.initialise(self)
end

-- endregion

-- region update
function CHC_items_list:update()
    if self.needmmb and Mouse.isMiddleDown() then
        self:onMMBDown()
        self.needmmb = false
    end
end

-- endregion

-- region render

function CHC_items_list:prerender()
    CHC_view._list.prerender(self)
end

function CHC_items_list:render()
    self:setStencilRect(0, 0, self.width, self.height)
    CHC_view._list.render(self)
    self:clearStencilRect()
end

function CHC_items_list:doDrawItem(y, item, alt)
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    local clr = {
        txt = item.text,
        x = self.shouldShowIcons and (self.itemheight + 5) or 15,
        y = y,
        r = 1,
        g = 1,
        b = 1,
        a = 0.9,
        font = self.font,
    }

    -- region icons
    if self.shouldShowIcons then
        -- CHC_main.common.cacheTex(itemObj)
        local itemIcon = item.item.texture
        if itemIcon then
            if item.item.textureMult then
                self:drawTextureScaled(itemIcon, 3, clr.y, self.itemheight, self.itemheight, 1)
            else
                self:drawTextureScaledAspect(itemIcon, 3, clr.y, self.itemheight, self.itemheight, 1)
            end
        end
        self:drawRect(self.itemheight + 3, clr.y, 1, self.itemheight, 0.1, 1, 1, 1)
        clr.x = clr.x + 5
    end
    --endregion

    --region text

    self:drawText(clr.txt, clr.x, clr.y + itemPadY, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion

    --region favorite handler
    local textures = {
        default = self.favorite.star.tex,
        checked = self.favorite.checked.tex,
        notChecked = self.favorite.notChecked.tex,
    }
    CHC_main.common.drawFavoriteStar(self, y, item, textures, item.item.favorite)
    --endregion

    --region filler
    local sc = { x = 0, y = y, w = self.width, h = item.height - 1, a = 0.2, r = 0.75, g = 0.5, b = 0.5 }
    local bc = { x = sc.x, y = sc.y, w = sc.w, h = sc.h + 1, a = 0.1, r = 1, g = 1, b = 1 }
    -- fill selected entry
    if self.selected == item.index then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, sc.a, sc.r, sc.g, sc.b);
    end
    -- border around entry
    self:drawRectBorder(bc.x, bc.y, bc.w, bc.h, bc.a, bc.r, bc.g, bc.b);

    if item.index == self.mouseoverselected then
        self:drawRect(sc.x, sc.y, sc.w, sc.h, 0.2, 0.5, sc.g, sc.b)
    end
    --endregion
end

-- endregion

-- region logic

-- region event handlers
function CHC_items_list:onMouseDownObj(x, y)
    local row = self:rowAt(x, y)
    if row == -1 then return end
    if CHC_view._list.isMouseOverFavorite(self, x) then
        self:addToFavorite(row)
    end
end

function CHC_items_list:onMouseWheel(del)
    CHC_view._list.onMouseWheel(self, del)
    return true
end

function CHC_items_list:onMMBDown()
    if self.onmiddlemousedown then
        self:onmiddlemousedown()
    end
end

function CHC_items_list:onMouseMove(dx, dy)
    ISScrollingListBox.onMouseMove(self, dx, dy)
    if not self.needmmb then self.needmmb = true end
end

function CHC_items_list:onMouseMoveOutside(x, y)
    ISScrollingListBox.onMouseMoveOutside(self, x, y)
    if self.needmmb then self.needmmb = false end
end

-- endregion

function CHC_items_list:addToFavorite(selectedIndex, fromKeyboard)
    if fromKeyboard == true then
        selectedIndex = self.selected
    end
    local selectedItem = self.items[selectedIndex]
    if not selectedItem then return end
    local parent = self.parent

    local isFav = CHC_menu.playerModData.CHC_item_favorites[selectedItem.item.fullType] == true
    isFav = not isFav
    selectedItem.item.favorite = isFav
    CHC_menu.playerModData.CHC_item_favorites[selectedItem.item.fullType] = isFav or nil
    if not isFav and parent.ui_type == 'fav_items' then
        self:removeItemByIndex(selectedIndex)
    end
    parent.needUpdateFavorites = true
end

-- endregion

function CHC_items_list:new(args)
    local o = {}

    o = ISScrollingListBox:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true

    o.favorite = {
        star = { tex = CHC_window.icons.item.favorite.default },
        checked = { tex = CHC_window.icons.item.favorite.checked },
        notChecked = { tex = CHC_window.icons.item.favorite.unchecked }
    }
    o.favorite.star.height = o.favorite.star.tex:getHeight()
    o.favorite.checked.height = o.favorite.checked.tex:getHeight()
    o.favorite.notChecked.height = o.favorite.notChecked.tex:getHeight()
    o.onmiddlemousedown = args.onmiddlemousedown
    o.needmmb = false
    o.modData = CHC_menu.playerModData

    o.yScroll = 0
    o.needUpdateScroll = true
    o.needUpdateMousePos = true
    o.shouldShowIcons = CHC_settings.config.show_icons

    return o
end
