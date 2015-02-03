--
-- Created by IntelliJ IDEA.
-- User: douzi
-- Date: 14-6-17
-- Time: 上午10:30
-- To change this template use File | Settings | File Templates.


local HeroSellCell = class("HeroSellCell", function()
    -- display.addSpriteFramesWithFile("ui/ui_equip.plist", "ui/ui_equip.png")
    display.addSpriteFramesWithFile("ui/ui_submap.plist", "ui/ui_submap.png")
    display.addSpriteFramesWithFile("ui/ui_common_button.plist", "ui/ui_common_button.png")

    return CCTableViewCell:new()
end)

function HeroSellCell:getContentSize()
    local sprite = display.newSprite("#herolist_board.png")
    return sprite:getContentSize()
end

local baseStateStr = {"生命","攻击","物防","法防","最终伤害","最终免伤"} --这玩意可前台写死了，有事找后台和策划

function HeroSellCell:create(param)
    self.cellId       = param.id
    local _viewSize = param.viewSize
    self.cellIndex = self.cellId
    self.list = param.listData
    print("dddddd")
    dump(self.list)

    self.objId = self.list[self.cellId+1]["_id"]
    dump(self.list)
    local lvl = self.list[self.cellId+1]["level"]
    local pos = self.list[self.cellId+1]["pos"]
    
    local sel = self.list[self.cellId+1]["sel"]
    --道具品质
    local star = self.list[self.cellId+1]["star"] or 0
    local itemId = self.list[self.cellId+1]["resId"]

     local baseState = self.list[self.cellId+1]["base"]
     local cls = self.list[self.cellId + 1]["cls"]

    --icon图标
    
    local headName = "icon/"..ResMgr.getCardData(itemId)["arr_icon"][cls+1]..".png"

    local sellSilver = ResMgr.getCardData(itemId)["price"]
    --道具名称
    local nameStr = ResMgr.getCardData(itemId)["name"]

    local changeSoldMoney = param.changeSoldMoney

    local addSellItem  = param.addSellItem
    local removeSellItem = param.removeSellItem

    self.bg = display.newSprite("#herolist_board.png")
    self:addChild(self.bg)
    self.bg:setPosition(_viewSize.width/2 , self.bg:getContentSize().height / 2)

    local boardHeight = self.bg:getContentSize().height
    local boardWidth  = self.bg:getContentSize().width
    
    local creatXiLianLayer = param.createXiLianListener
    local creatQianghuaLayer = param.createQiangHuaListener  
 

    self.headIcon = display.newSprite(headName)
    self.headIcon:setPosition(self.headIcon:getContentSize().width/2, self:getContentSize().height*0.6)
    
    self.bg:addChild(self.headIcon)

    local bgWidth = self.bg:getContentSize().width
    local bgHeight = self.bg:getContentSize().height
    
    -- weapon name
    self.itemName = ui.newTTFLabel({
        x = self.headIcon:getContentSize().width*0.4,
        y = self:getContentSize().height*0.85,
        align = ui.TEXT_ALIGN_LEFT,
        text = nameStr,
        font = FONTS_NAME.font_fzcy,
        color = FONT_COLOR.PURPLE,
        size = 32

    })
    self.itemName:setAnchorPoint(ccp(0,0.5))
    self.itemName:setPosition(boardWidth*0.2,boardHeight*0.5)


    self.bg:addChild(self.itemName)

    self.lvIcon = display.newSprite("#equip_lv.png")
    self.lvIcon:setPosition(bgWidth*0.05,bgHeight*0.25)
    self.bg:addChild(self.lvIcon)

    -- weapon lv
    self.weaponLv = ui.newTTFLabel({
        x = self.lvIcon:getPositionX() + self.lvIcon:getContentSize().width*0.4,
        y = self.lvIcon:getPositionY() ,-- self.headIcon:getContentSize().height/2,
        align = ui.TEXT_ALIGN_LEFT,
        text = lvl,
        font = FONTS_NAME.font_fzcy,
      
        size = 26

    })
    self.bg:addChild(self.weaponLv)

    local equipInfoBg = display.newScale9Sprite("#equip_info_bg.png")
    equipInfoBg:setPosition(bgWidth*0.65,bgHeight*0.3)
    equipInfoBg:setContentSize(CCSize(210,60))
    self.bg:addChild(equipInfoBg)

    


    self.costSilver = ui.newTTFLabel({
        text = "银币:",
        -- color = FONT_COLOR.DARK_RED,
        font = FONTS_NAME.font_fzcy,
        size =22,
        align = ui.TEXT_ALIGN_RIGHT
    })
    self.costSilver:setAnchorPoint(ccp(0,0.5))
    self.costSilver:setPosition(boardWidth*0.5, boardHeight*0.3)
    self.bg:addChild(self.costSilver)

    self.costNum = ui.newTTFLabel({
        text = sellSilver,
        -- color = FONT_COLOR.DARK_RED,
        font = FONTS_NAME.font_fzcy,
        size = 22,
        align = ui.TEXT_ALIGN_RIGHT
    })
    self.costNum:setAnchorPoint(ccp(0,0.5))
    self.costNum:setPosition(self.costSilver:getPositionX()+self.costSilver:getContentSize().width, self.costSilver:getPositionY())
    self.bg:addChild(self.costNum)

    
    for i=1,star do
        local stars = display.newSprite("#f_win_star.png")
        stars:setPosition(boardWidth*0.5  + 0.6*(i-1)*stars:getContentSize().width, self:getContentSize().height*0.65) 
        stars:setScale(0.6)
        self.bg:addChild(stars)
    end

     self.selBtn = nil 
    self.unseleBtn = nil 

    local function selFunc()
         self.selBtn:setVisible(false)
            self.unseleBtn:setVisible(true)
            changeSoldMoney(0-sellSilver) 
            removeSellItem(self.objId)
    end

    local function unSelFunc()
        self.selBtn:setVisible(true)
            self.unseleBtn:setVisible(false)
            changeSoldMoney(sellSilver)
            addSellItem(self.objId)
    end

    self.selBtn = ui.newImageMenuItem({
        image = "#herolist_selected.png",
        listener = selFunc
        })
    self.selBtn:setVisible(false)
    self.selBtn:setPosition(bgWidth*0.9,bgHeight*0.45)
    self.bg:addChild(ui.newMenu({self.selBtn}))


    self.unseleBtn = ui.newImageMenuItem({
        image = "#herolist_select_bg.png",
        listener = unSelFunc
        })
    self.unseleBtn:setPosition(bgWidth*0.9,bgHeight*0.45)
    self.bg:addChild(ui.newMenu({self.unseleBtn}))

    
    if sel == true then
        unSelFunc()
    end


    return self
end

function HeroSellCell:runEnterAnim(  )
    -- local delayTime = self.cellIndex*0.15
    -- local sequence = transition.sequence({
    --     CCCallFuncN:create(function ( )
    --         self:setPosition(CCPoint((self.bg:getContentSize().width/2 + display.width/2),self.bg:getPositionY()))
    --     end),
    --     CCDelayTime:create(delayTime),CCMoveBy:create(0.3, CCPoint(-(self:getContentSize().width/2 + display.width/2), 0))})
    -- self:runAction(sequence)
end

function HeroSellCell:refresh(id)
    self.cellId       = id
    local lvl = self.list[self.cellId+1]["level"]
    local pos = self.list[self.cellId+1]["pos"]
    local itemId = self.list[self.cellId+1]["resId"]
    local cls = self.list[self.cellId + 1]["cls"]
    print ("iteem "..itemId)
    --icon图标
    local headName = "icon/"..ResMgr.getCardData(itemId)["arr_icon"][cls+1]..".png"

    local sellSilver = ResMgr.getCardData(itemId)["price"]
    --道具名称
    local nameStr = ResMgr.getCardData(itemId)["name"]

    -- self.headIcon:setSpriteFrame(frame)

    self.weaponLv:setString(lvl)
    self.itemName:setString(nameStr)
    
end

return HeroSellCell

