--
-- Created by IntelliJ IDEA.
-- User: douzi
-- Date: 14-6-17
-- Time: 下午1:56
-- To change this template use File | Settings | File Templates.
--

require("utility.ResMgr")

local IconSprite = class("IconSprite", function()
    return display.newNode()
end)

require("data.data_item_item")

function IconSprite:ctor(param)
    local _id = param.id
    local _num = param.num
    local _bShowName = param.bShowName

    local itemInfo = data_item_item[_id]

    local itemType = 1
    if(data_item_item[_id].type <= 3 ) then
        itemType = ResMgr.EQUIP
    elseif(data_item_item[_id].type == 5) then    
        itemType = ResMgr.HERO
    else
        itemType = ResMgr.ITEM    
    end
    local sprite = ResMgr.getIconSprite({
        id = _id,
        resType = itemType
    })
--    display.newSprite(ResMgr.getIconImage( data_item_item[_id].icon, itemType))
    self:addChild(sprite)
    self:setContentSize(sprite:getContentSize())


    if _bShowName then
        local s = ""
        if _num ~= 0 then
            s = tostring(_num)
        end

        local nameLabel = ui.newTTFLabelWithOutline({
            text = itemInfo.name,
            font = FONTS_NAME.font_fzcy,
            size = 20,
            color = NAME_COLOR[data_item_item[_id].quality],
            align = ui.TEXT_ALIGN_CENTER,
        })
        nameLabel:setPosition(sprite:getContentSize().width / 2, -nameLabel:getContentSize().height / 2)
        sprite:addChild(nameLabel)

        local numLabel = ui.newTTFLabelWithOutline({
            text = s,
            font = FONTS_NAME.font_fzcy,
            size = 20,
            color = FONT_COLOR.GREEN,
            align = ui.TEXT_ALIGN_CENTER,
        })
        numLabel:setPosition(sprite:getContentSize().width - numLabel:getContentSize().width*0.6, numLabel:getContentSize().height*0.55)
        sprite:addChild(numLabel)
    end
end

return IconSprite

