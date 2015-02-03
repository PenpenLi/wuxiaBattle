--
-- Author: Daneil
-- Date: 2015-01-15 22:15:29
--
local fightRes = {
    normal   =  "#fuchou_n.png",
    pressed  =  "#fuchou_p.png",
    disabled =  "#fuchou_p.png"
}

local BiwuEnemyItem = class("BiwuEnemyItem", function()
    return CCTableViewCell:new()
end)

function BiwuEnemyItem:create(param)
    
	--初始化界面
	self:setUpView(param)
	return self
end

function BiwuEnemyItem:refresh(param)
	self.data = param.cellData
	self:removeAllChildren()
    local padding = { 
		left  = 20,
		right = 20,
		top   = 20,
		down  = 20
	}

	local viewSize = param.viewSize

	--外边大的背景框
	self:setContentSize(param.viewSize)
    local bng = display.newScale9Sprite("#arena_itemBg_4.png", 0, 0, 
                            		cc.size(viewSize.width,viewSize.height))
    bng:setAnchorPoint(cc.p(0,0))
    self:addChild(bng)

    --标题背景
    
    local titleBng = display.newScale9Sprite("#arena_name_bg_4.png", 0, 0, 
                            		cc.size(viewSize.width - padding.left - padding.right , viewSize.height * 0.18))
    titleBng:setAnchorPoint(cc.p(0,0))
    titleBng:setPosition(cc.p(viewSize.width * 0.02, viewSize.height * 0.7))
    bng:addChild(titleBng)

    --角色名字
    local nameDis = ui.newTTFLabel({text = self.data.name, 
    	font = FONTS_NAME.font_fzcy, 
    	align = ui.TEXT_ALIGN_LEFT,
        size = 22,color = ccc3(110,0,0)})
    nameDis:setAnchorPoint(cc.p(0,0.5))
    nameDis:setPosition(titleBng:getContentSize().width * 0.25, 
    titleBng:getContentSize().height * 0.5)
    titleBng:addChild(nameDis)



    --战力title
    display.newSprite("#friend_zhandouli.png")
    	:pos(titleBng:getContentSize().width * 0.8, 
    	titleBng:getContentSize().height * 0.5)
    	:addTo(titleBng)
	--战力数值
	ui.newTTFLabel({text = self.data.attack, 
    	font = FONTS_NAME.font_fzcy, 
    	align = ui.TEXT_ALIGN_LEFT,
        size = 22,color = ccc3(216,30,0)})
		:pos(titleBng:getContentSize().width * 0.92, 
    	titleBng:getContentSize().height * 0.5)
		:addTo(titleBng)


    --背景箭头
    local arrowBng = display.newSprite("#arena_lv_bg_4.png")
    arrowBng:setAnchorPoint(cc.p(0,0))
    titleBng:addChild(arrowBng)

    --等级
    local levelDis = ui.newTTFLabel({text = "LV:"..self.data.level, 
    	font = FONTS_NAME.font_fzcy, 
    	align = ui.TEXT_ALIGN_LEFT,
        size = 22,color = ccc3(255,255,255)})
    levelDis:setAnchorPoint(cc.p(0,0.5))
    levelDis:setPosition(arrowBng:getContentSize().width * 0.2, 
    arrowBng:getContentSize().height * 0.5)
    arrowBng:addChild(levelDis)


    --头像大背景
    local heroBng = display.newScale9Sprite("#arena_itemInner_bg_1.png", 0, 0, 
                            		cc.size(viewSize.width * 0.7 , 
                            				viewSize.height * 0.65 ))
    heroBng:setAnchorPoint(cc.p(0,0))
    heroBng:setPosition(cc.p(viewSize.width * 0.01, viewSize.height * 0.05))
    bng:addChild(heroBng)


    for i = 1,#self.data.cards do
    	local head = self:createHeroView(i, heroBng)
    end
    
    local fuchouBtn = display.newSprite(fightRes.normal)  
    fuchouBtn:setPosition(cc.p(viewSize.width * 0.85, viewSize.height * 0.5))  
    bng:addChild(fuchouBtn)
    addTouchListener(fuchouBtn, function (sender,eventType)
    	if eventType == EventType.began then
    		sender:setScale(1.1)
    	elseif eventType == EventType.ended then
    		sender:setScale(1)
            GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
            if param.times == 0 then
        		show_tip_label("您的挑战次数为0")
        		return 
        	end
        	BiwuController.sendFightData(BiwuConst.ENEMY,self.data.role_id,TabIndex.CHOUREN)
            GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
        elseif eventType == EventType.cancel then
        	sender:setScale(1)
        end
    end)
end

function BiwuEnemyItem:setUpView(param)
	self:refresh(param)  
end

function BiwuEnemyItem:createHeroView(index,node)
	local i = index
    local marginTop  = 10
    local marginLeft = 10
    local offset = 100

	local icon = ResMgr.refreshIcon(
    {
        id = self.data.cards[i].resId, 
        resType = ResMgr.HERO, 
        cls = self.data.cards[i].cls
    }) 
    
    icon:setAnchorPoint(cc.p(0,0.5)) 
    icon:setPosition((node:getContentSize().width / 5) * (i)  - 20 + 10 * (i-1) , node:getContentSize().height/2)
    icon:setAnchorPoint(cc.p(0.5,0.5))
    node:addChild(icon)
    return icon
end

function BiwuEnemyItem:refreshHeroIcons()
	
end

return BiwuEnemyItem



