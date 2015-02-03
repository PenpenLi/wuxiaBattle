--[[
 --
 -- add by vicky
 -- 2014.11.01
 --
 --]]

local ChongzhiRewardItem = class("ChongzhiRewardItem", function()
	return CCTableViewCell:new()
end)


function ChongzhiRewardItem:getContentSize()
	local proxy = CCBProxy:create()
	local rootnode = {}

	CCBuilderReaderLoad("shop/shop_chongzhi_vipReward_item.ccbi", proxy, rootnode)
	local contentSize = rootnode["reward"]:getContentSize()

	return CCSizeMake(contentSize.width + 15, contentSize.height)
end


function ChongzhiRewardItem:refreshItem(param)
	-- dump(param)

	local itemData = param.itemData

	-- 图标
	local rewardIcon = self._rootnode["reward_icon"]
	rewardIcon:removeAllChildrenWithCleanup(true) 
	ResMgr.refreshIcon({
        id = itemData.id, 
        resType = itemData.iconType, 
        itemBg = rewardIcon, 
        iconNum = itemData.num, 
        isShowIconNum = false, 
        numLblSize = 22, 
        numLblColor = ccc3(0, 255, 0), 
        numLblOutColor = ccc3(0, 0, 0) 
    })

	-- 属性图标 
	local canhunIcon = self._rootnode["reward_canhun"]
	local suipianIcon = self._rootnode["reward_suipian"]
	canhunIcon:setVisible(false)
	suipianIcon:setVisible(false)
	if itemData.type == 3 then
		-- 装备碎片
		suipianIcon:setVisible(true) 
	elseif itemData.type == 5 then
		-- 残魂(武将碎片)
		canhunIcon:setVisible(true) 
	end

	-- 名称
	local nameKey = "reward_name"
	local nameColor = ccc3(255, 255, 255)
	if itemData.iconType == ResMgr.ITEM or itemData.iconType == ResMgr.EQUIP then 
		nameColor = ResMgr.getItemNameColor(itemData.id)
	elseif itemData.iconType == ResMgr.HERO then 
		nameColor = ResMgr.getHeroNameColor(itemData.id)
	end

	local nameLbl = ui.newTTFLabelWithShadow({
        text = itemData.name,
        size = 20,
        color = nameColor,
        shadowColor = ccc3(0,0,0),
        font = FONTS_NAME.font_fzcy,
        align = ui.TEXT_ALIGN_LEFT
        })
		
	nameLbl:setPosition(-nameLbl:getContentSize().width/2, nameLbl:getContentSize().height/2)
	self._rootnode[nameKey]:removeAllChildren()
    self._rootnode[nameKey]:addChild(nameLbl) 

end


function ChongzhiRewardItem:create(param)
	local proxy = CCBProxy:create()
	self._rootnode = {} 

	local node = CCBuilderReaderLoad("shop/shop_chongzhi_vipReward_item.ccbi", proxy, self._rootnode)
	local contentSize = self._rootnode["reward"]:getContentSize()
	node:setPosition(contentSize.width * 0.7, self:getContentSize().height * 0.5)
	self:addChild(node) 

	self:refreshItem(param)

	return self
end

function ChongzhiRewardItem:refresh(param)
	self:refreshItem(param)
end


return ChongzhiRewardItem
