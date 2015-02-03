--[[
 --
 -- add by vicky
 -- 2014.09.18 
 --
 --]]


local RewardCenterCellItem = class("RewardCenterCellItem", function()
		return CCTableViewCell:new()
end) 


function RewardCenterCellItem:getContentSize()
	local proxy = CCBProxy:create()
    local rootNode = {}

    CCBuilderReaderLoad("reward/reward_center_item_reward.ccbi", proxy, rootNode) 
    return rootNode["item_node"]:getContentSize()
end 


function RewardCenterCellItem:create(param)
	-- dump(param)
	local viewSize = param.viewSize 
	local itemData = param.itemData 

    local proxy = CCBProxy:create()
    self._rootnode = {}
    local node = CCBuilderReaderLoad("reward/reward_center_item_reward.ccbi", proxy, self._rootnode)
    node:setPosition(node:getContentSize().width * 0.5, viewSize.height * 0.5)
	self:addChild(node)
  	
  	self:refreshItem(itemData)

	return self  
end 


function RewardCenterCellItem:refreshItem(itemData)
	-- dump(itemData)
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
	local nameColor = ccc3(255, 255, 255) 
	if itemData.iconType == ResMgr.HERO then 
		nameColor = ResMgr.getHeroNameColor(itemData.id)
	elseif itemData.iconType == ResMgr.ITEM or itemData.iconType == ResMgr.EQUIP then 
		nameColor = ResMgr.getItemNameColor(itemData.id) 
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
	self._rootnode["reward_name"]:removeAllChildren()
    self._rootnode["reward_name"]:addChild(nameLbl)

end 


function RewardCenterCellItem:refresh(param)
	self:refreshItem(param.itemData)
end


return RewardCenterCellItem
