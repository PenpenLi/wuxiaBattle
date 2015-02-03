--[[
 --
 -- add by vicky
 -- 2014.11.28 
 --
 --]]

 require("data.data_error_error") 
 require("data.data_item_item") 
 require("data.data_card_card") 
 require("data.data_touzi_touzi") 
 require("data.data_config_config") 

 local MAX_ZORDER = 1111 

 local DengjiTouziLayer = class("DengjiTouziLayer", function()
 		return display.newNode() 
 	end) 


 function DengjiTouziLayer:getStatusData() 
    RequestHelper.dengjiTouzi.getData({
        callback = function(data)
            dump(data) 
            if data.err ~= "" then 
                dump(data.err) 
            else 
                self:initData(data) 
            end 
        end 
        }) 
 end 


 function DengjiTouziLayer:buyFunc() 
    local buyBtn = self._rootnode["buyBtn"] 

    local function confirmBuyFunc() 
        RequestHelper.dengjiTouzi.buy({
            callback = function(data)
                dump(data) 
                if data.err ~= "" then 
                    dump(data.err) 
                    buyBtn:setEnabled(true) 
                else 
                    local rtnObj = data.rtnObj 
                    if rtnObj.result == 1 then 
                        show_tip_label(data_error_error[1500505].prompt) 
                        buyBtn:setEnabled(false) 
                        self._hasBuy = true 
                        game.player:updateMainMenu({gold = rtnObj.gold})  

                        self:initRewardListView()
                    else 
                        buyBtn:setEnabled(true) 
                    end 
                end 
            end 
            }) 
    end 
 
    local msgBox = require("game.nbactivity.DengjiTouzi.DengjiTouziBuyMsgbox").new({
            needGold = self._needGold, 
            confirmListen = function() 
                if game.player:getGold() < self._needGold then 
                    show_tip_label(data_error_error[100004].prompt) 
                    buyBtn:setEnabled(true) 
                else 
                    confirmBuyFunc() 
                end 
            end, 
            cancelListen = function()
                buyBtn:setEnabled(true) 
            end  
        })
    game.runningScene:addChild(msgBox, MAX_ZORDER) 

 end 


 function DengjiTouziLayer:ctor(param)
 	local viewSize = param.viewSize 
 	local proxy = CCBProxy:create()
 	self._rootnode = {} 
 	
    local node = CCBuilderReaderLoad("nbhuodong/dengjiTouzi_layer.ccbi", proxy, self._rootnode, self, viewSize)
    self:addChild(node) 

    self._needGold = data_config_config[1]["jijincost"] 
    self._needVipLv = data_config_config[1]["jijinvip"] 
    self._rootnode["needGold_lbl"]:setString(tostring(self._needGold)) 

    local listBgHeight = viewSize.height - self._rootnode["title_icon"]:getContentSize().height + 10 
    local listBg = display.newScale9Sprite("#month_item_bg_bg.png", 0, 0, CCSize(viewSize.width, listBgHeight))
    listBg:setAnchorPoint(0.5, 0) 
    listBg:setPosition(display.width/2, 0) 
    node:addChild(listBg) 
    self._listViewSize = CCSizeMake(viewSize.width * 0.98, listBgHeight - 25) 

    self._listViewNode = display.newNode() 
    self._listViewNode:setContentSize(self._listViewSize) 
    self._listViewNode:setAnchorPoint(0.5, 0.5) 
    self._listViewNode:setPosition(display.width/2, listBgHeight/2) 
    listBg:addChild(self._listViewNode) 

    dump(self._listViewNode:getContentSize().width) 
    dump(self._listViewNode:getContentSize().height) 

    self:getStatusData() 
 end 


 function DengjiTouziLayer:initData(data) 
    game.player:setVip(data.rtnObj.vip) 
    self._hasGetAry = data.rtnObj.hasGet 
    self._curLevel = data.rtnObj.lv 
    self._hasBuy = false 
    if data.rtnObj.hasBuy == 1 then 
        self._hasBuy = true 
        self._rootnode["buyBtn"]:setEnabled(false) 
    end 

    -- 充值按钮 
    local chongzhiBtn = self._rootnode["chongzhiBtn"] 
    chongzhiBtn:addHandleOfControlEvent(function(eventName, sender) 
        local chongzhiLayer = require("game.shop.Chongzhi.ChongzhiLayer").new()
        game.runningScene:addChild(chongzhiLayer, MAX_ZORDER) 
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
    end, CCControlEventTouchUpInside) 

    -- 购买按钮 
    local buyBtn = self._rootnode["buyBtn"] 
    buyBtn:addHandleOfControlEvent(function(eventName, sender) 
        if self._hasBuy == false then 
            local bHasOpen, prompt = OpenCheck.getOpenLevelById(OPENCHECK_TYPE.DengjiTouzi_buy, game.player:getLevel(), game.player:getVip()) 
            if not bHasOpen then 
                show_tip_label(prompt) 
            else 
                buyBtn:setEnabled(false) 
                self:buyFunc() 
            end 
        end 
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
    end, CCControlEventTouchUpInside) 

    self._rewardDatas = {} 
    for i, v in ipairs(data_touzi_touzi) do 
        local iconType = ResMgr.getResType(v.type) 
        local item = data_item_item[v.itemid] 
        table.insert(self._rewardDatas, {
            id = v.itemid, 
            name = item.name or "", 
            describe = item.describe or "", 
            iconType = iconType, 
            num = v.num or 0, 
            type = v.type, 
            level = v.level 
            })
    end 

    self:initRewardListView() 
 end 


 function DengjiTouziLayer:getReward(cell)
    RequestHelper.dengjiTouzi.getReward({
        lv = cell:getLevel(), 
        callback = function(data)
            dump(data)
            if data.err ~= "" then 
                dump(data.err) 
            else
                -- result:   领取结果 1-成功 2-失败
                local rtnObj = data.rtnObj
                local result = rtnObj.result 

                if result == 1 then 
                    table.insert(self._hasGetAry, cell:getLevel()) 
                    cell:getReward(self._hasGetAry) 

                    -- 弹出得到奖励提示框
                    local title = "恭喜您获得如下奖励："
                    local msgBox = require("game.Huodong.RewardMsgBox").new({
                        title = title, 
                        cellDatas = {self._rewardDatas[cell:getIdx() + 1]}    
                        })

                    game.runningScene:addChild(msgBox, MAX_ZORDER)
                end 
            end 
        end
    })
 end 


 function DengjiTouziLayer:initRewardListView()  
    if self._listTable ~= nil then 
        self._listTable:removeFromParentAndCleanup(true) 
    end 

    -- 创建 
    local function createFunc(index) 
    	local item = require("game.nbactivity.DengjiTouzi.DengjiTouziItem").new()
    	return item:create({
    		viewSize = self._listViewSize, 
    		itemData = self._rewardDatas[index + 1], 
            hasGetAry = self._hasGetAry, 
            curLevel = self._curLevel, 
            hasBuy = self._hasBuy, 
            rewardListener = function(cell) 
                if cell:getLevel() > game.player:getLevel() then 
                    show_tip_label(data_error_error[1900002].prompt) 
                else
                    self:getReward(cell) 
                end 
            end
    		})
    end

    -- 刷新 
    local function refreshFunc(cell, index)
    	cell:refresh(self._rewardDatas[index + 1])
    end

    local cellContentSize = require("game.nbactivity.DengjiTouzi.DengjiTouziItem").new():getContentSize()

    self._listTable = require("utility.TableViewExt").new({
    	size        = self._listViewSize, 
        direction   = kCCScrollViewDirectionVertical, 
        createFunc  = createFunc, 
        refreshFunc = refreshFunc, 
        cellNum   	= #self._rewardDatas, 
        cellSize    = cellContentSize 
    	})

    self._listTable:setPosition(0, 0)
    self._listViewNode:addChild(self._listTable) 
 end


 return DengjiTouziLayer 

