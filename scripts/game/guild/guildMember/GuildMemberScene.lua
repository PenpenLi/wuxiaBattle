--[[
 --
 -- add by vicky
 -- 2015.01.07 
 --
 --]]

 require("data.data_config_union_config_union") 
 require("data.data_error_error") 

 local MAX_ZORDER = 100 

 -- 列表类型
 local SHOWTYPE = {
    none = 0, 
 	normal = 1,   -- 帮派成员列表 
 	verify = 2,   -- 审核列表 
 }

 -- 捐献类型  
 local COIN_TYPE = {
    silver = 0, 
    gold = 1, 
 }

 -- 排序类型
 local SORT_TYPE = {
    none = 0, 
    normal = 1,     -- 默认排序(按等级排序)
    time = 2,       -- 时间排序 
 }

 -- type= 0 同意，type=1拒绝
 local HANDLE_TYPE = {
    accept = 0, 
    reject = 1, 
 }


 local GuildMemberScene = class("GuildMemberScene", function() 
    local bottomFile = "guild/guild_bottom_frame_normal.ccbi" 
    local jopType = game.player:getGuildMgr():getGuildInfo().m_jopType  
    if jopType ~= GUILD_JOB_TYPE.normal then 
        bottomFile = "guild/guild_bottom_frame.ccbi" 
    end 

    return require("game.guild.utility.GuildBaseScene").new({
        contentFile = "guild/guild_list_bg.ccbi",
        topFile = "guild/guild_guildMember_up_tab.ccbi",
        bottomFile = bottomFile, 
        adjustSize = CCSizeMake(0, -50)
        }) 
 end) 


 function GuildMemberScene:handleApply(cell, handleType)
    local guildMgr = game.player:getGuildMgr()
    local guildInfo = guildMgr:getGuildInfo()

    RequestHelper.Guild.handleApply({  
        unionId = guildInfo.m_id,  
        applyRoleId = cell:getRoleId(), 
        type = handleType, 
        errback = function(data)
            cell:setBtnEnabled(true) 
        end, 
        callback = function(data)
            dump(data)
            if data.err ~= "" then 
                dump(data.err) 
                cell:setBtnEnabled(true) 
            else 
                local rtnObj = data.rtnObj 
                cell:setBtnEnabled(true) 
                if rtnObj.success == 0 then 
                    guildInfo.m_nowRoleNum = guildInfo.m_nowRoleNum + 1 
                    self:removeItemFromVerifyList(cell:getRoleId()) 
                    self._verifyChanged = true 
                    self:setVerifySortType(self._verifySortType) 
                end 
            end 
        end, 
        })
 end 


 function GuildMemberScene:refuseAll()
    RequestHelper.Guild.refuseAll({  
        errback = function(data)
            self._rootnode["reject_total_btn"]:setEnabled(true) 
        end, 
        callback = function(data)
            dump(data)
            if data.err ~= "" then 
                dump(data.err) 
                self._rootnode["reject_total_btn"]:setEnabled(true) 
            else 
                local rtnObj = data.rtnObj 
                if rtnObj.success == 0 then 
                    self._timeListData = {} 
                    self._verifyListData = {} 
                    self:setVerifySortType(self._verifySortType) 
                end 
                self._rootnode["reject_total_btn"]:setEnabled(true) 
            end 
        end, 
        })
 end 


 function GuildMemberScene:ctor(param) 
    local showType = param.showType 
    local data = param.data 
    -- dump(data, "帮派成员", 6) 

    self._verifySortType = SORT_TYPE.none 
    -- 审核列表是否变化过(即玩家是否审核过) 
    self._verifyChanged = false    

    local jopType = game.player:getGuildMgr():getGuildInfo().m_jopType  
    if jopType == GUILD_JOB_TYPE.normal then 
        self._rootnode["btn2"]:setVisible(false) 
    else
        self._rootnode["btn2"]:setVisible(true)  
    end 

    self._rootnode["tag_search_node"]:setVisible(false) 

 	local _bg = display.newSprite("ui_common/common_bg.png") 
    local _bgW = display.width
    local _bgH = display.height - self._rootnode["bottomMenuNode"]:getContentSize().height - self._rootnode["topFrameNode"]:getContentSize().height
    _bg:setPosition(_bgW / 2, _bgH / 2 + self._rootnode["bottomMenuNode"]:getContentSize().height)
    _bg:setScaleX(_bgW / _bg:getContentSize().width)
    _bg:setScaleY(_bgH / _bg:getContentSize().height)
    self:addChild(_bg, 0) 

    -- 返回
 	self._rootnode["backBtn"]:addHandleOfControlEvent(function(eventName,sender)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        GameStateManager:ChangeState(GAME_STATE.STATE_GUILD) 
    end, CCControlEventTouchUpInside)  

    -- 按时间排序 
    self._rootnode["sort_time_btn"]:addHandleOfControlEvent(function(eventName,sender)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        self:setVerifySortType(SORT_TYPE.time) 
    end, CCControlEventTouchUpInside)

    -- 默认排序 
    self._rootnode["sort_normal_btn"]:addHandleOfControlEvent(function(eventName,sender)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 

        self:setVerifySortType(SORT_TYPE.normal) 
    end, CCControlEventTouchUpInside)

    -- 一键拒绝 
    self._rootnode["reject_total_btn"]:addHandleOfControlEvent(function(eventName,sender)
        self._rootnode["reject_total_btn"]:setEnabled(false) 
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        if (self._verifyListData ~= nil and #self._verifyListData > 0) or (self._timeListData ~= nil and #self._timeListData > 0) then 
            self:refuseAll() 
        else
            self._rootnode["reject_total_btn"]:setEnabled(true)  
        end 
    end, CCControlEventTouchUpInside)


    self:createTab() 
    self:setShowType(showType, data)  	
 end  


 function GuildMemberScene:selectedTab(tag) 
    for i = 1, 2 do
        if tag == i then
            self._rootnode["tab" ..tostring(i)]:selected()
            self._rootnode["btn" ..tostring(i)]:setZOrder(10)
        else
            self._rootnode["tab" ..tostring(i)]:unselected()
            self._rootnode["btn" ..tostring(i)]:setZOrder(0)
        end
    end
 end
 

 function GuildMemberScene:createTab()  
    local function onTabBtn(tag)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_yeqian)) 
        self:setShowType(tag) 
    end

    --初始化选项卡
    local function initTab()
        for i = 1, 2 do
            self._rootnode["tab" ..tostring(i)]:addNodeEventListener(cc.MENU_ITEM_CLICKED_EVENT, onTabBtn)
        end
        self:selectedTab(1)
    end

    initTab() 
 end


 function GuildMemberScene:setShowType(showType, data) 
    self._showType = showType 
    self:selectedTab(self._showType)

    local guildMgr = game.player:getGuildMgr() 

    if self._showType == SHOWTYPE.normal then 

        -- 若数据为nil或者审核列表更改过，则重新请求数据 
        if data == nil or self._verifyChanged == true then 
            self._verifyChanged = false 
            guildMgr:RequestShowAllMember(function(data)
                    self:setShowType(self._showType, data) 
                end)
        else 
            self._rootnode["tag_verify_node"]:setVisible(false) 
            self:createNormalList(data)
            self:reloadListView(self._showType, self._normalListData, 0)   
        end 

    elseif self._showType == SHOWTYPE.verify then 

        if data == nil then 
            guildMgr:RequestShowApplyList(function(data)
                    self:setShowType(self._showType, data) 
                end)
        else
            self._rootnode["tag_verify_node"]:setVisible(true)  
            self._rootnode["sort_time_btn"]:setVisible(true) 
            self._rootnode["sort_normal_btn"]:setVisible(false)  

            self:createVerifyList(data) 
            self:setVerifySortType(SORT_TYPE.normal) 
        end 
    end 
 end 


 -- 根据排序类型重新排列 
 function GuildMemberScene:setVerifySortType(sortType)
    self._verifySortType = sortType 
    if self._verifySortType == SORT_TYPE.normal then 
        self._rootnode["sort_normal_btn"]:setVisible(false) 
        self._rootnode["sort_time_btn"]:setVisible(true) 

        if self._verifyListData == nil then 
            self._verifyListData = {}
        end 
        self:reloadListView(SHOWTYPE.verify, self._verifyListData, 0) 

    elseif self._verifySortType == SORT_TYPE.time then 
        self._rootnode["sort_normal_btn"]:setVisible(true)  
        self._rootnode["sort_time_btn"]:setVisible(false) 

        self._timeListData = {} 
        local indexList = {} 

        -- 根据时间排序 
        local function getItemByTime(time)
            local maxTime = time 
            local curIndex = -1 
            for i, v in ipairs(self._verifyListData) do 
                if self:getIsHasAdd(i, indexList) == false then 
                    if v.createTime >= maxTime then 
                        maxTime = v.createTime 
                        curIndex = i 
                        break 
                    end 
                end 
            end 
            local itemData
            if curIndex ~= -1 then 
                itemData = self._verifyListData[curIndex] 
                table.insert(indexList, curIndex) 
            end 
            return itemData 
        end 

        for i = 1, #self._verifyListData do 
            local itemData 
            if i == 1 then 
                itemData = getItemByTime(-1) 
            else
                itemData = getItemByTime(self._timeListData[#self._timeListData].createTime) 
            end 

            if itemData ~= nil then 
                table.insert(self._timeListData, itemData) 
            end 
        end 

        self:reloadListView(SHOWTYPE.verify, self._timeListData, 0) 
    end 
 end 


 function GuildMemberScene:getOnlineStr(curTime, lastTime)
    local str = "" 
    local disTime = curTime - lastTime 
    local onlineTime = 9 * 60 
    local t = 24 * 60 * 60 
    local bIsOnline = false 

    if disTime <= onlineTime then 
        str = "在线" 
        bIsOnline = true 
    else 
        local disDay = curTime/t - lastTime/t 
        disDay = math.floor(disDay) 
        if disDay <= 0 then 
            str = "离线" 
        elseif disDay <= data_config_union_config_union[1].guild_online_day_max then 
            str = "离线" .. disDay .. "天"
        else
            str = "离线超过" .. data_config_union_config_union[1].guild_online_day_max .. "天"
        end 
    end 

    -- dump(str)
    return bIsOnline, str 
 end


 function GuildMemberScene:getIsHasAdd(index, indexList)
    local bHas = false 
    for i, v in ipairs(indexList) do 
        if v == index then 
            bHas = true 
            break 
        end 
    end 
    return bHas 
 end 


 -- 根据竞技场排名、职务、在线与否排名 
 function GuildMemberScene:createNormalList(data) 
    self._normalListData = {} 
    local rtnObj = data.rtnObj 
    -- 毫秒 
    local nowTime = rtnObj.nowTime 
    nowTime = nowTime / 1000 

    local roleUnionList = rtnObj.roleUnionList 

    -- dump(roleUnionList, "roleUnionList", 4) 

    local function getBuildStr(itemData)
        local str = "" 
        -- 1:捐献 0:未捐献
        if itemData.todayIsCon == 1 then 
            if itemData.conType == COIN_TYPE.silver then 
                str = "今日捐献" .. tostring(itemData.costMoney) .. "银币" 
            elseif itemData.conType == COIN_TYPE.gold then 
                str = "今日捐献" .. tostring(itemData.costMoney) .. "元宝" 
            end 

        elseif itemData.todayIsCon == 0 then 
            local t = 24 * 60 * 60 
            if itemData.lastContributionTime ~= nil then 
                local disDay = nowTime/t - itemData.lastContributionTime/(1000 * t) 
                disDay = math.floor(disDay) 
                if disDay > 0 then 
                    str = tostring(disDay) .. "天未捐献" 
                else
                    str = "今日未捐献" 
                end 
            end 
        end 
        return str 
    end 

    local rankIndexList = {} 
    -- 按竞技场排名 
    local function getItemByRank(rank) 
        local maxRank = rank 
        local curIndex = -1 
        for i, v in ipairs(roleUnionList) do 
            if self:getIsHasAdd(i, rankIndexList) == false and v.rank >= maxRank then 
                maxRank = v.rank 
                curIndex = i 
            end 
        end 
        local itemData
        if curIndex ~= -1 then 
            table.insert(rankIndexList, curIndex) 
            itemData = roleUnionList[curIndex] 
            itemData.isSelf = game.player:checkIsSelfByAcc(roleUnionList[curIndex].roleAcc)  
            itemData.isOnline, itemData.onlineStr = self:getOnlineStr(nowTime, itemData.hertLastTime)
            itemData.buildStr = getBuildStr(itemData) 
        end 
        return itemData 
    end 

    local rankListData = {} 
    for i = 1, #roleUnionList do 
        local itemData = getItemByRank(-1) 
        if itemData ~= nil then 
            table.insert(rankListData, itemData) 
        end 
    end 

    -- dump(rankListData, "rankListData", 4) 

    local tmpListdata = {} 
    local tmpIndexList = {} 
    -- 按照职务排序，展示顺序：自己、帮主、副帮主、长老、普通成员 
    local function addItemdata(jopType) 
        local bFind = false 
        for i, v in ipairs(rankListData) do 
            if self:getIsHasAdd(i, tmpIndexList) == false then 
                if jopType == -1 then 
                    if v.isSelf == true then 
                        bFind = true 
                    end 
                elseif v.jopType == jopType then 
                    bFind = true 
                end 
                if bFind == true then 
                    table.insert(tmpIndexList, i)
                    table.insert(tmpListdata, v) 
                    break 
                end 
            end 
        end 
    end 
    -- 一主、一副、两老
    -- 玩家自己
    addItemdata(-1) 
    -- 帮主
    addItemdata(GUILD_JOB_TYPE.leader) 
    -- 副帮主
    addItemdata(GUILD_JOB_TYPE.assistant) 
    -- 长老
    addItemdata(GUILD_JOB_TYPE.elder) 
    addItemdata(GUILD_JOB_TYPE.elder) 

    -- 普通成员
    for i = 1, #rankListData do 
        addItemdata(GUILD_JOB_TYPE.normal) 
    end 

    -- dump(tmpListdata, "tmpListdata", 4) 

    local indexList = {} 
    -- 根据是否在线排序 
    local function createByOnline(isOnline)
        for i, v in ipairs(tmpListdata) do 
            if self:getIsHasAdd(i, indexList) == false and v.isOnline == isOnline then 
                table.insert(indexList, i) 
                table.insert(self._normalListData, v) 
            end 
        end     
    end

    createByOnline(true) 
    createByOnline(false) 
    
 end 


 function GuildMemberScene:createVerifyList(data) 
    self._verifyListData = {} 
    local rtnObj = data.rtnObj 
    local nowTime = rtnObj.nowTime 
    nowTime = nowTime / 1000 
    local applyList = rtnObj.applyList 

    local function getTimeStr(itemData) 
        local str = "" 
        local t = 24 * 60 * 60 
        local disDay = nowTime/t - itemData.createTime/t 
        disDay = math.floor(disDay) 
        if disDay <= 0 then 
            str = "今天"
        else
            str = tostring(disDay) .. "天前" 
        end 
        return str 
    end 

    for i, v in ipairs(applyList) do 
        local itemData = v 
        itemData.timeStr = getTimeStr(itemData) 
        itemData.isOnline, itemData.onlineStr = self:getOnlineStr(nowTime, itemData.hertLastTime) 
        table.insert(self._verifyListData, itemData) 
    end 
 end 


 function GuildMemberScene:reloadListView(showType, listData, lastPosIndex) 
 	if self._listViewTable ~= nil then 
        self._listViewTable:removeFromParentAndCleanup(true)
        self._listViewTable = nil
    end 
    self._bHasShowFormLayer = false 

    local boardWidth = self._rootnode["listView"]:getContentSize().width
    local boardHeight = self._rootnode["listView"]:getContentSize().height 
    local itemFile 
    if showType == SHOWTYPE.normal then 
        itemFile = "game.guild.guildMember.GuildMemberNormalItem" 
    elseif showType == SHOWTYPE.verify then 
        itemFile = "game.guild.guildMember.GuildMemberVerifyItem" 
        boardHeight = boardHeight - self._rootnode["tag_verify_node"]:getContentSize().height 
    end 
    
    local lisetViewSize = CCSizeMake(boardWidth, boardHeight) 

    local guildMgr = game.player:getGuildMgr() 
    local guildInfo = guildMgr:getGuildInfo() 

    -- 创建 
    local function createFunc(index)
        local item = require(itemFile).new() 
        return item:create({
	        	id = index + 1, 
                itemData = listData[index + 1], 
                viewSize = lisetViewSize, 
                jobFunc = function(cell) 
                    local itemData = listData[cell:getIdx() + 1] 
                    local layer = require("game.guild.guildMember.GuildMemberJobLayer").new({
                        itemData = itemData, 
                        title = "帮务", 
                        parentScene = self 
                        }) 
                    game.runningScene:addChild(layer, MAX_ZORDER) 
	            end, 
                acceptFunc = function(cell)
                    if guildInfo.m_nowRoleNum >= guildInfo.m_roleMaxNum then 
                        show_tip_label(data_error_error[2900020].prompt) 
                    else 
                        self:handleApply(cell, HANDLE_TYPE.accept) 
                    end 
                end, 
                rejectFunc = function(cell)
                    self:handleApply(cell, HANDLE_TYPE.reject)
                end  
            })
    end

    -- 刷新 
    local function refreshFunc(cell, index) 
        cell:refresh(listData[index + 1]) 
    end 

    self._rootnode["touchNode"]:setTouchEnabled(true)
    local posX = 0
    local posY = 0
    self._rootnode["touchNode"]:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(event)
        posX = event.x
        posY = event.y
    end)

    local cellContentSize = require(itemFile).new():getContentSize() 

    self._listViewTable = require("utility.TableViewExt").new({
        size        = lisetViewSize, 
        direction   = kCCScrollViewDirectionVertical,
        createFunc  = createFunc,
        refreshFunc = refreshFunc,
        cellNum     = #listData, 
        cellSize    = cellContentSize, 
        touchFunc   = function(cell)
            local idx = cell:getIdx() + 1 
            
            if listData[idx].isSelf == false and self._bHasShowFormLayer == false then 
                self._bHasShowFormLayer = true 
                local icon = cell:getPlayerIcon()
                local pos = icon:convertToNodeSpace(ccp(posX, posY))
                if CCRectMake(0, 0, icon:getContentSize().width, icon:getContentSize().height):containsPoint(pos) then
                    local layer = require("game.form.EnemyFormLayer").new(1, listData[idx].roleAcc, function()
                            self._bHasShowFormLayer = false 
                        end) 
                    layer:setPosition(0, 0) 
                    game.runningScene:addChild(layer, MAX_ZORDER) 
                end
            end 
        end
    })

    self._rootnode["listView"]:addChild(self._listViewTable) 

    -- 新请求到得item置顶显示
    local pageCount = (self._listViewTable:getViewSize().height) / cellContentSize.height  -- 当前每页显示的个数 
    if lastPosIndex + 1 > pageCount then 
        local maxMove = #listData - pageCount   
        if maxMove < 0 then maxMove = 0 end 
        if lastPosIndex > maxMove then lastPosIndex = maxMove end 
        local curIndex = maxMove - lastPosIndex 

        self._listViewTable:setContentOffset(CCPoint(0, -(curIndex * cellContentSize.height))) 
    end 
 end 


 function GuildMemberScene:removeItemFromVerifyList(roleId) 
    local function removeData(listData)
        for i, v in ipairs(listData) do 
            if v.roleId == roleId then 
                table.remove(listData, i) 
                break 
            end 
        end 
        return listData 
    end 
    if self._verifyListData ~= nil then 
        self._verifyListData = removeData(self._verifyListData)  
    end 

    if self._timeListData ~= nil then 
        self._timeListData = removeData(self._timeListData) 
    end 
 end 


 function GuildMemberScene:removeItemFromNormalList(roleId) 
    local index = 0 
    for i, v in ipairs(self._normalListData) do 
        if v.roleId == roleId then 
            table.remove(self._normalListData, i) 
            index = i 
            break 
        end 
    end 
    return index 
 end 


 function GuildMemberScene:forceReloadNormalListView(index)
    if self._normalListData == nil then 
        self._normalListData = {} 
    end 
    self:reloadListView(SHOWTYPE.normal, self._normalListData, index) 
 end 


 function GuildMemberScene:onEnter()
 	game.runningScene = self 
 	self:regNotice() 
 end 


 function GuildMemberScene:onExit() 
 	self:unregNotice() 
 end 


 return GuildMemberScene 
