local btnGetRes = {
    normal   =  "#btn_get_n.png",
    pressed  =  "#btn_get_p.png",
    disabled =  "#btn_get_p.png"
}

local GiftGetOkPopup = import(".GiftGetOkPopup")
local GiftGetItemView = class("GiftGetItemView", function()
    return display.newLayer("GiftGetItemView")
end)

function GiftGetItemView:ctor(size,data,mainscene,parent)
    self:setContentSize(size)
    self._leftToRightOffset = 10
    self._topToDownOffset = 2
    self._frameSize = size

    self._containner = nil
    self._padding = {
        left  = 20,
        right = 20,
        top   = 15,
        down  = 20
    }
    self._data = data
    self:setUpView()
    self._mainMenuScene = mainscene
    self._parent = parent
    --控件
    self._icon = nil
end


function GiftGetItemView:setUpView()
    self._containner =  display.newScale9Sprite("#reward_item_bg.png", 0, 0, 
        cc.size(self._frameSize.width - self._leftToRightOffset * 2, 
            self._frameSize.height - self._topToDownOffset * 2))
        :pos(self._frameSize.width / 2, self._frameSize.height / 2)
    local containnerSize = self._containner:getContentSize()
    self._containner:setAnchorPoint(cc.p(0.5,0.5))
    self:addChild(self._containner)

    --15积分可领取背景
    local titleBngHeight = 40
    local titleBng = display.newScale9Sprite("#heroinfo_cost_st_bg.png" , 0 , 0 ,
        cc.size(containnerSize.width - self._padding.left - self._padding.right,titleBngHeight))
        :pos(self._padding.left , containnerSize.height - self._padding.top)
        :addTo(self._containner)
    titleBng:setAnchorPoint(cc.p(0,1))
    local titleBngSize = titleBng:getContentSize()  

    display.newSprite("#reward_item_title_bg.png") 
        :pos(0, titleBngSize.height / 2)
        :addTo(titleBng)
        :setAnchorPoint(cc.p(0,0.5))

    --15积分文字
    local marginLeft = 20
    local dislabel = ui.newTTFLabel({text = self._data.jifen.."积分可领取", size = 20, font = FONTS_NAME.font_fzcy, align = ui.TEXT_ALIGN_LEFT})
        :pos(marginLeft, titleBngSize.height / 2)
        :addTo(titleBng)
    dislabel:setAnchorPoint(cc.p(0,0.5))

    --按钮
    local getBtn
    getBtn = cc.ui.UIPushButton.new(btnGetRes)
        :onButtonClicked(function()
            RequestHelper.dialyTask.getGift({
                id = self._data.id,
                callback = function(data)
                    dump(data)
                    if data["0"] ~= "" then
                        dump(data["0"]) 
                    else 
                        display.newSprite("#getok.png") 
                        :pos(getBtn:getPosition())
                        :addTo(self._containner)
                        :setAnchorPoint(cc.p(1,0.5))
                        getBtn:setVisible(false)


                        --插入奖励领取
                        TaskModel:getInstance():insertReword(self._data.id)
                        for k,v in pairs(self._giftData) do
                            if v.id == 1 then     --元宝
                                game.player:setGold(game.player.m_gold + v.num)
                            end
                            if v.id == 2 then --银币
                                game.player:setSilver(game.player.m_silver  + v.num)
                            end
                        end
                        --刷新界面
                        self._mainMenuScene:refreshPlayerBoard()
                        self._parent:update()

                        -- 弹出得到奖励提示框
                        local title = "恭喜您获得如下奖励："
                        local msgBox = require("game.Huodong.RewardMsgBox").new({
                            title = title, 
                            cellDatas = TaskModel:getInstance():getGiftList(self._data.id)
                            })
                        CCDirector:sharedDirector():getRunningScene():addChild(msgBox,1000)
                    end
                end 
                }) 


        end)
        :pos(containnerSize.width - self._padding.right , containnerSize.height / 2)

    getBtn:setAnchorPoint(cc.p(1,0.5))

    local completetag = display.newSprite("#getok.png") 
                        :pos(getBtn:getPosition())
    completetag:setAnchorPoint(cc.p(1,0.5))

    local hasGet = TaskModel:getInstance():getJifenState(self._data.id)
    if hasGet then
        self._containner:addChild(completetag)
    else 
        self._containner:addChild(getBtn)
    end


    local getBtnSize = getBtn:getContentSize()
    
    local isGet = TaskModel:getInstance():checkRewordable(self._data.id)
    
    getBtn:setButtonEnabled(isGet)


    --道具框
    local marginTop   = 5
    local offset      = 10
    local marginRight = 120
    local itemsViewBngs = display.newScale9Sprite("#heroinfo_title_bg.png" , 0 , 0 ,
        cc.size(containnerSize.width - self._padding.left - self._padding.right - marginRight - offset,
            containnerSize.height - self._padding.top - self._padding.down - titleBngHeight - marginTop))
        :pos(self._padding.left , self._padding.down)
        :addTo(self._containner)
    itemsViewBngs:setAnchorPoint(cc.p(0,0))
    
    self._giftData = TaskModel:getInstance():getGiftList(self._data.id)
    for i=1, #self._giftData do
        self:createItem(i,itemsViewBngs,itemsViewBngs:getContentSize())
    end
    
end

function GiftGetItemView:setData()

end

function GiftGetItemView:createItem(index,itemsViewBngs,containnerSize)
    local marginTop  = 10
    local marginLeft = 20
    local offset = 120

    if self._giftData[index].type == 6 then
    	self._icon = ResMgr.refreshIcon(
	    {
	        id = 1, 
	        resType = 3, 
	        iconNum = self._giftData[index].num, 
	        isShowIconNum = true, 
	        numLblSize = 22, 
	        numLblColor = ccc3(0, 255, 0), 
	        numLblOutColor = ccc3(0, 0, 0) 
	    }) 

    else
    	self._icon = ResMgr.refreshIcon(
	    {
	        id = self._giftData[index].id, 
	        resType = self._giftData[index].iconType, 
	        iconNum = self._giftData[index].num, 
	        isShowIconNum = false, 
	        numLblSize = 22, 
	        numLblColor = ccc3(0, 255, 0), 
	        numLblOutColor = ccc3(0, 0, 0) 
	    }) 

    end
    
    self._icon:setAnchorPoint(cc.p(0,0.5)) 
    self._icon:setPosition(cc.p(self._padding.left + (index - 1) * offset, containnerSize.height / 2 + marginTop))
    local iconSize = self._icon:getContentSize()
    local iconPosX = self._icon:getPositionX()
    local iconPosY = self._icon:getPositionY()
    

    -- 名称
    local nameColor = ccc3(255, 255, 255) 
    if self._giftData[index].iconType == ResMgr.HERO then 
        nameColor = ResMgr.getHeroNameColor(self._giftData[index].id)
    elseif self._giftData[index].iconType == ResMgr.ITEM or self._giftData[index].iconType == ResMgr.EQUIP then 
        nameColor = ResMgr.getItemNameColor(self._giftData[index].id) 
    end 

    ui.newTTFLabelWithShadow({
        text = self._giftData[index].name,
        size = 20,
        color = nameColor,
        shadowColor = ccc3(0,0,0),
        font = FONTS_NAME.font_fzcy,
        align = ui.TEXT_ALIGN_CENTER
        })
        :pos(iconSize.width /2 , -20)
        :addTo(self._icon)
        :setAnchorPoint(cc.p(0,1))

    local tag
    -- 装备碎片
    if self._giftData[index].type == 3 then
    	tag = display.newSprite("#sx_suipian.png")
    elseif self._giftData[index].type == 5 then
    	-- 残魂(武将碎片)
    	tag = display.newSprite("#sx_canhun.png")
    end
    if tag then
    	self._icon:addChild(tag)
    	tag:setRotation(-20)
    	tag:setPosition(cc.p(40,75))
    end
    

    if self._giftData[index].type == 6 then
    	local iconSp = require("game.Spirit.SpiritIcon").new({
            resId = self._giftData[index].id,
            bShowName = true,
            bNum = self._giftData[index].num,
    	})
    	itemsViewBngs:addChild(iconSp)
    	iconSp:setAnchorPoint(cc.p(0,0.5)) 
    	iconSp:setPosition(self._icon:getPositionX(),self._icon:getPositionY() - 10)
    else
    	itemsViewBngs:addChild(self._icon)
    end
    
    
end

return GiftGetItemView
    
    
