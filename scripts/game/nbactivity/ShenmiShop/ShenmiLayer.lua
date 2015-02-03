--[[
 --
 -- add by vicky
 -- 2014.10.08
 --
 --]]


require("data.data_card_card")
require("data.data_item_item")
require("data.data_error_error")

local MAX_ZODER = 1001
local TIME = 2 * 60 * 60

local RefreshType = {
    None = 0,
    Free = 1,	 -- 免费刷新
    Token = 2, 	 -- 刷新令
    Gold = 3 	 -- 元宝
}


local ShenmiLayer = class("ShenmiLayer", function()
    return display.newNode()
end)


function ShenmiLayer:getList(bRefresh)
    local refresh = 2 
    if bRefresh == true then
        refresh = 1
    end
    RequestHelper.shenmi.getData({
        refresh = refresh,
        callback = function(data) 
            dump(data) 
            if data["0"] ~= "" then 
                dump(data["0"]) 
            else 
                if bRefresh == true then 
                    if self._refreshType == RefreshType.Gold then 
                        game.player:setGold(self._refreshNum - self._goldcost)
                        PostNotice(NoticeKey.CommonUpdate_Label_Gold) 
                    else 
                        local curRefreshType = data["5"] 
                        if curRefreshType == RefreshType.Gold then 
                            show_tip_label(data_error_error[2400010].prompt) 
                        end 
                    end 
                end 

                self:init(data) 
            end
        end
    })
end 


function ShenmiLayer:ctor(param)
    local viewSize = param.viewSize
    self:setNodeEventEnabled(true)
    self._hunyuNum = 0
    self._time = TIME
    self._goldcost = 20
    self._goldRefreshTimes = 0 -- 今日元宝可刷新次数
    self._refreshNum = 0
    self._refreshType = RefreshType.None
    self._vipFreeTimes = 2

    local proxy = CCBProxy:create()
    self._rootnode = {}

    -- dump(viewSize.height)
    -- dump(viewSize.width)

    -- 创建UI
    local contentNode = CCBuilderReaderLoad("nbhuodong/shenmi_layer.ccbi", proxy, self._rootnode, self, viewSize)
    self:addChild(contentNode)

    -- 背景图
    local bgSprite = display.newSprite("bg/smShop_bg.jpg")
    local scaleX = viewSize.width / bgSprite:getContentSize().width
    local scaleY = viewSize.height / bgSprite:getContentSize().height
    if scaleX < 1.0 then
        scaleX = 1.0
    end

    if scaleY < 1.0 then
        scaleY = 1.0
    end

    bgSprite:setScaleX(scaleX)
    bgSprite:setScaleY(scaleY)
    self._rootnode["bg_node"]:addChild(bgSprite)

    -- 神秘小妹
    local girlSprite = display.newSprite("#smShop_girl.png")
    girlSprite:setPosition(-display.cx + girlSprite:getContentSize().width/2, 0)
    self._rootnode["bg_node"]:addChild(girlSprite)

    -- 兑换列表 背景
    local listHeigt = viewSize.height - self._rootnode["bottom_node"]:getContentSize().height - self._rootnode["title_node"]:getContentSize().height
    local listSize = CCSizeMake(viewSize.width * 0.71, listHeigt * 0.96)
    self._listViewSize = CCSizeMake(listSize.width * 0.98, listSize.height * 0.96)

    local listBg = display.newScale9Sprite("#sm_list_bg.png", 0, 0, listSize)
    listBg:setAnchorPoint(1.0, 0)
    listBg:setPosition(self._rootnode["listView_node"]:getContentSize().width, 0)
    self._rootnode["listView_node"]:addChild(listBg)

    self._listViewNode = display.newNode()
    self._listViewNode:setContentSize(self._listViewSize)
    self._listViewNode:setAnchorPoint(1.0, 0)
    self._listViewNode:setPosition(self._rootnode["listView_node"]:getContentSize().width - 5, listSize.height * 0.02)
    self._rootnode["listView_node"]:addChild(self._listViewNode)


    self._rootnode["lianhuaBtn"]:addHandleOfControlEvent(function(eventName, sender)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        GameStateManager:ChangeState(GAME_STATE.STATE_LIANHUALU)
    end, CCControlEventTouchUpInside)

    self._rootnode["refreshBtn"]:addHandleOfControlEvent(function(eventName, sender)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        self:Refresh()
    end, CCControlEventTouchUpInside)

    self._rootnode["hunyu_num"]:setString(tostring(self._hunyuNum))
    self._rootnode["time_lbl"]:setString(tostring(format_time(self._time)))
    self._rootnode["cost_gold"]:setString(tostring(self._goldcost))
    self:updateRefreshMsg()
    -- self:getList(false)
end


function ShenmiLayer:updateRefreshMsg()
    -- 更新UI
    if self._refreshNum > 0 and self._refreshType ~= RefreshType.Gold then 
        if self._refreshType == RefreshType.Free and self._refreshNum >= self._vipFreeTimes then
            self._rootnode["freeLimit"]:setVisible(true)
        else
            self._rootnode["freeLimit"]:setVisible(false)
        end

        if self._refreshType == RefreshType.Free then
            self._rootnode["refresh_free_lbl"]:setString(tostring(self._refreshNum))
            self._rootnode["free_node"]:setVisible(true)
            self._rootnode["shuaxinling_node"]:setVisible(false)
            self._rootnode["gold_node"]:setVisible(false)

        elseif self._refreshType == RefreshType.Token then
            self._rootnode["refresh_shuaxinling_lbl"]:setString(tostring(self._refreshNum))

            self._rootnode["shuaxinling_node"]:setVisible(true)
            self._rootnode["gold_node"]:setVisible(false)
            self._rootnode["free_node"]:setVisible(false) 
        end 
    elseif self._refreshType == RefreshType.Gold then
        self._rootnode["freeLimit"]:setVisible(false)

        game.player:setGold(self._refreshNum)

        self._rootnode["refresh_gold_lbl"]:setString(tostring(self._goldRefreshTimes))

        self._rootnode["gold_node"]:setVisible(true)
        self._rootnode["shuaxinling_node"]:setVisible(false)
        self._rootnode["free_node"]:setVisible(false)
    end

end


function ShenmiLayer:init(data)
    local listAry = data["1"]
    self._time = data["2"] 			-- 倒计时
    self._goldcost = data["6"]		-- 金币刷新花费数
    self._vipFreeTimes = data["7"]	       -- 免费刷新上限
    -- 元宝刷新次数上限
    self._goldRefreshTimes = data["8"] or self._goldRefreshTimes

    self:updateHunYuNum(data["3"])	       -- 魂玉数
    self:updateRefreshNum(data["4"], data["5"])   -- 刷新数、刷新类型

    local itemDataList = {}
    for i, v in ipairs(listAry) do
        local iconType = ResMgr.getResType(v.type)
        local item
        if iconType == ResMgr.HERO then
            item = data_card_card[v.itemId]
        else
            item = data_item_item[v.itemId]
        end

        table.insert(itemDataList, {
            dataId = v.id, 		-- 编号id
            id = v.itemId, 		-- 物品id
            type = v.type,
            num = v.num,
            moneyType = v.money,
            price = v.price,
            limitNum = v.upLimit,
            iconType = iconType,
            name = item.name,
            describe = item.describe or "",
        })
    end

    -- dump(itemDataList)

    self:createListView(itemDataList)
end


-- 兑换列表
function ShenmiLayer:createListView(itemDataList)
    local itemDataList = itemDataList
    local function exchangeFunc(cell)
        local index = cell:getIdx() + 1
        local itemData = itemDataList[index]

        local function confirmExchangeFunc()
            -- 判断兑换需要的物品是否足够
            if itemData.moneyType == 1 and game.player:getGold() < itemData.price then
                show_tip_label(data_error_error[100004].prompt)
                cell:updateExchangeBtn(true) 
                return
            elseif itemData.moneyType == 2 and game.player:getSilver() < itemData.price then
                show_tip_label(data_error_error[1407].prompt)
                cell:updateExchangeBtn(true) 
                return
            elseif itemData.moneyType == 10 and self._hunyuNum < itemData.price then
                show_tip_label(data_error_error[1500].prompt)
                cell:updateExchangeBtn(true) 
                return
            end

            -- 判断背包空间是否足，如否则提示扩展空间
            local bagObj = {}
            local function extendBag(data)
                -- 更新第一个背包，先判断当前拥有数量是否小于上限，若是则接着提示下一个背包类型需要扩展，否则更新cost和size
                if bagObj[1].curCnt < data["1"] then
                    table.remove(bagObj, 1)
                else
                    bagObj[1].cost = data["4"]
                    bagObj[1].size = data["5"]
                end

                if #bagObj > 0 then
                    game.runningScene:addChild(require("utility.LackBagSpaceLayer").new({
                        bagObj = bagObj,
                        callback = function(data)
                            extendBag(data)
                        end}), MAX_ZODER)
                end
            end

            -- 确认兑换 请求
            RequestHelper.shenmi.exchange({
                id = itemData.dataId,
                callback = function(data)
                    dump(data) 
                    
                    cell:updateExchangeBtn(true) 

                    if string.len(data["0"]) > 0 then
                        CCMessageBox(data["0"], "Error")
                    else
                        -- 更新背包状态
                        bagObj = data["1"]
                        if #bagObj > 0 then
                            game.runningScene:addChild(require("utility.LackBagSpaceLayer").new({
                                bagObj = bagObj,
                                callback = function(data)
                                    extendBag(data)
                                end}), MAX_ZODER)
                        else
                            if itemData.moneyType == 1 then
                                game.player:setGold(game.player:getGold() - itemData.price)
                                PostNotice(NoticeKey.CommonUpdate_Label_Gold)
                            elseif itemData.moneyType == 2 then
                                game.player:setSilver(game.player:getSilver() - itemData.price)
                                PostNotice(NoticeKey.CommonUpdate_Label_Silver)
                            end
                            -- 弹出购买的物品确认框
                            local cellDatas = {}
                            table.insert(cellDatas, itemData)
                            game.runningScene:addChild(require("game.Huodong.rewardInfo.RewardInfoMsgBox").new({
                                    cellDatas = cellDatas, 
                                    num = 1  
                                }), MAX_ZODER)

                            -- 更新魂玉数
                            self:updateHunYuNum(data["2"])

                            -- 更新兑换次数
                            itemData.limitNum = data["3"]
                            cell:updateExchangeNum(itemData.limitNum)

                        end
                    end 
                end
            })
        end

        if itemData.moneyType == 1 then
            game.runningScene:addChild(require("game.nbactivity.ShenmiShop.ShenmiGoldMsgBox").new({
                itemData = itemData,
                confirmFunc = function()
                    confirmExchangeFunc()
                end, 
                cancelFunc = function()
                    cell:updateExchangeBtn(true) 
                end  
            }), MAX_ZODER)
        else 
            confirmExchangeFunc() 
        end 

    end

    -- 点击图标，显示道具详细信息
    local function onInformation(cell)
        local index = cell:getIdx() + 1
        local icon_data = itemDataList[index]
        local itemInfo = require("game.Huodong.ItemInformation").new({
            id = icon_data.id,
            type = icon_data.type,
            name = icon_data.name,
            describe = icon_data.describe, 
            endFunc = function() 
                cell:setIconTouchEnabled(true) 
            end
        })

        game.runningScene:addChild(itemInfo, MAX_ZODER) 
    end

    local function createFunc(index)
        local item = require("game.nbactivity.ShenmiShop.ShenmiCell").new()
        return item:create({
            viewSize = self._listViewSize,
            itemData = itemDataList[index + 1],
            exchangeFunc = function(cell)
                exchangeFunc(cell)
            end,
            informationFunc = function(cell)
                onInformation(cell)
            end
        })
    end

    local function refreshFunc(cell, index)
        cell:refresh(itemDataList[index + 1])
    end

    self._exchangeItemList = require("utility.TableViewExt").new({
        size        = self._listViewSize,
        direction   = kCCScrollViewDirectionVertical,
        createFunc  = createFunc,
        refreshFunc = refreshFunc,
        cellNum     = #itemDataList,
        cellSize    = require("game.nbactivity.ShenmiShop.ShenmiCell").new():getContentSize()
    })

    self._listViewNode:removeAllChildren()
    self._listViewNode:addChild(self._exchangeItemList, MAX_ZODER)

end


function ShenmiLayer:updateHunYuNum(num) 
    if num ~= nil then 
        self._hunyuNum = num 
    end 

    -- 更新UI
    self._rootnode["hunyu_num"]:setString(tostring(self._hunyuNum))
end


function ShenmiLayer:updateRefreshNum(num, refreshtype)
    self._refreshNum = num or self._refreshNum
    self._refreshType = refreshtype or self._refreshType

    self:updateRefreshMsg()
end


function ShenmiLayer:Refresh()
    -- 判断是免费刷新、刷新令、元宝
    if self._refreshType == RefreshType.Gold then
        -- 弹出花费元宝提示
        if self._goldRefreshTimes <= 0 then
            show_tip_label(data_error_error[2400005].prompt)
        elseif self._refreshNum < self._goldcost then
            show_tip_label(data_error_error[100004].prompt)
        else 
            -- local refreshMsgBox = require("game.nbactivity.ShenmiShop.ShenmiRefreshGoldMsgBox").new({
            --     costNum = self._goldcost,
            --     refreshNum = self._goldRefreshTimes,
            --     confirmFunc = function()
            --         self._goldRefreshTimes = self._goldRefreshTimes - 1
            --         self:getList(true)
            --     end
            -- })
            -- game.runningScene:addChild(refreshMsgBox, MAX_ZODER) 

            self._goldRefreshTimes = self._goldRefreshTimes - 1 
            self:getList(true) 
        end
    else 
        self:getList(true)
    end
end


function ShenmiLayer:onEnter()
    self:getList(false)
    local function updateTime()
        if self._time ~= nil and self._time > 0 then
            self._time = self._time - 1
            self._rootnode["time_lbl"]:setString(tostring(format_time(self._time)))
            if self._time <= 0 then
                RequestHelper.shenmi.checkTime({
                    callback = function(data)
                        dump(data)
                        if data["0"] ~= "" then
                            CCMessageBox(data["0"], "Error")
                        else
                            -- 根据返回的时间倒计时
                            self._time = data["1"]
                            self:updateRefreshNum(data["2"], RefreshType.Free)
                        end
                    end
                })
            end
        end
    end

    self.scheduler = require("framework.scheduler")
    self._schedule = self.scheduler.scheduleGlobal(updateTime, 1, false)

    local touchMaskLayer = require("utility.TouchMaskLayer").new({
        btns = {
            self._rootnode["refreshBtn"],
            self._rootnode["lianhuaBtn"],
        },
        contents = {
            CCRectMake(self._listViewNode:convertToWorldSpace(ccp(0, 0)).x, self._listViewNode:convertToWorldSpace(ccp(0, 0)).y,
                self._listViewNode:getContentSize().width, self._listViewNode:getContentSize().height),
            CCRectMake(0, 0, display.width, game.runningScene:getBottomHeight()),
            CCRectMake(0, display.height - game.runningScene:getTopHeight(), display.width, game.runningScene:getTopHeight()),
        }
    })
    game.runningScene:addChild(touchMaskLayer)
end


function ShenmiLayer:onExit()
    if self._schedule ~= nil then
        self.scheduler.unscheduleGlobal(self._schedule)
    end
    game.runningScene:removeChildByTag(1234)

    CCTextureCache:sharedTextureCache():removeUnusedTextures()
end


return ShenmiLayer


