CHC_recipes_list = ISScrollingListBox:derive('CHC_recipes_list')

-- region create
function CHC_recipes_list:initialise()
    ISScrollingListBox.initialise(self)
end

-- endregion

-- region render

function CHC_recipes_list:prerender()
    CHC_view._list.prerender(self)
end

function CHC_recipes_list:render()
    self:setStencilRect(0, 0, self.width, self.height)
    CHC_view._list.render(self)
    self:clearStencilRect()
end

function CHC_recipes_list:doDrawItem(y, item, alt)
    local recipe = item.item
    local itemPadY = self.itemPadY or (item.height - self.fontSize) / 2

    local clr = {
        txt = item.text,
        x = self.shouldShowIcons and (self.itemheight) or 15,
        y = y,
        a = 0.9,
        font = self.curFontData.font
    }

    -- region icons
    if self.shouldShowIcons then
        local resultItem = recipe.recipeData.result
        if resultItem then
            local tex = resultItem.texture
            if tex then
                local texW = self.fontSize
                if texW > item.height then texW = item.height end
                texW = texW - 2
                if resultItem.textureMult then
                    self:drawTextureScaled(tex, 3, clr.y, self.itemheight, self.itemheight, 1)
                else
                    self:drawTextureScaledAspect(tex, 3, clr.y, self.itemheight, self.itemheight, 1)
                end
                self:drawRect(self.itemheight + 3, clr.y, 1, self.itemheight, 0.1, 1, 1, 1)
            end
        end
        clr.x = clr.x + 5
    end
    --endregion

    --region text
    if recipe.isSynthetic then
        -- known but cant craft, white text
        clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
    elseif recipe.isEvolved then
        if recipe.valid then
            -- can 'craft', green text
            clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
        else
            clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
        end
    else
        if recipe.valid then
            clr['r'], clr['g'], clr['b'] = 0, 0.7, 0
        elseif recipe.known then
            clr['r'], clr['g'], clr['b'] = 0.9, 0.9, 0.9
        else
            clr['r'], clr['g'], clr['b'] = 0.7, 0, 0
        end
    end
    self:drawText(clr.txt, clr.x, clr.y + itemPadY, clr.r, clr.g, clr.b, clr.a, clr.font)
    --endregion

    --region favorite handler
    local textures = {
        default = self.favoriteStar,
        checked = self.favCheckedTex,
        notChecked = self.favNotCheckedTex,
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

function CHC_recipes_list:onMouseWheel(del)
    CHC_view._list.onMouseWheel(self, del)
    return true
end

function CHC_recipes_list:onMouseDownObj(x, y)
    local row = self:rowAt(x, y)
    if row == -1 then return end
    if CHC_view._list.isMouseOverFavorite(self, x) then
        self:addToFavorite(row)
    end
end

function CHC_recipes_list:onMouseUpOutside(x, y)
    ISScrollingListBox.onMouseUpOutside(self, x, y)
end

function CHC_recipes_list:addToFavorite(selectedIndex, fromKeyboard)
    if fromKeyboard == true then
        selectedIndex = self.selected
    end
    local selectedItem = self.items[selectedIndex]
    if not selectedItem then return end
    local allr = getPlayerCraftingUI(0).categories
    local fav_idx;
    local parent = self.parent

    --find 'Favorite' category
    for i, v in ipairs(allr) do
        if v.category == getText('IGUI_CraftCategory_Favorite') then
            fav_idx = i
            break
        end
    end
    if not fav_idx then return end
    local recipe = selectedItem.item
    recipe.favorite = not recipe.favorite
    CHC_menu.playerModData[recipe.favStr] = recipe.favorite
    if recipe.favorite then
        allr[fav_idx].recipes.items[#allr[fav_idx].recipes.items + 1] = selectedItem
    else
        if parent.ui_type == 'fav_recipes' then
            self:removeItemByIndex(selectedIndex)
        end
    end
    parent.needUpdateFavorites = true
end

-- endregion


function CHC_recipes_list:new(args)
    local o = {}

    o = ISScrollingListBox:new(args.x, args.y, args.w, args.h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.9 }
    o.anchorTop = true
    o.anchorBottom = true
    o.backRef = args.backRef
    o.modData = CHC_menu.playerModData

    o.favoriteStar = CHC_window.icons.recipe.favorite.default
    o.favCheckedTex = CHC_window.icons.recipe.favorite.checked
    o.favNotCheckedTex = CHC_window.icons.recipe.favorite.unchecked
    o.mouseX = 0
    o.mouseY = 0
    o.yScroll = 0
    o.fontSize = getTextManager():getFontHeight(o.font)


    o.shouldDrawMod = CHC_settings.config.show_recipe_module
    o.shouldShowIcons = CHC_settings.config.show_icons
    o.curFontData = CHC_main.common.fontSizeToInternal[CHC_settings.config.list_font_size]
    o.fontSize = getTextManager():getFontHeight(o.curFontData.font)

    o.needUpdateScroll = false
    o.needUpdateMousePos = false
    o.needUpdateRecipeState = false
    return o
end
