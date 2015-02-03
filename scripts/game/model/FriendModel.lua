

local FriendModel = {}


FriendModel.listVec       = {}



local FRIEND_TYPE       = 1
local RECOMMEND_TYPE    = 2
local NAILI_TYPE        = 3
local REQUEST_TYPE      = 4

FRIEND_KEY = {
	NO_ONE_KEY           = 3200109,         --申请列表没有玩家
	AGREE_SUC_KEY        = 3200110,         --添加好友成功
	REJECT_SUC_KEY       = 3200111,         --拒绝好友成功
	SEND_NAILI_SUC_KEY   = 3200112,			--成功赠送对方1点耐力
	GET_NAILI_SUC_KEY    = 3200106,         --领取耐力成功
	NAI_LI_FULL_KEY      = 3200002,         --耐力已满
	GET_ALL_NAILI_KEY    = 3200113,			--领取所有耐力并回赠
	AGREE_FRIEND_KEY     = 3200114,         --接受好友
	SEND_APPLY_KEY       = 3200115,         --已申请	
	NUM_PLZ_KEY          = 3200101,			--搜索玩家id只能输入数字，请重新输入
	CANNOT_EMPTY_KEY     = 3200102,			--发送内容不能为空！
	TOO_MUCH_CHAR_KEY    = 3200103,			--输入内容超过40个字，请重新编辑
	REV_FRIEND_SUC_KEY   = 3200104,			--删除好友成功
	NO_PLAYER_KEY        = 3200105,			--您搜索的玩家不存在！
	TOO_MUCH_NAME_KEY    = 3200116,         --玩家名称不得超过七个字

	NUM_LIMIT_KEY	     = 3200004,         --我好友已满了

	FRIEND_NUM_LIMIT_KEY = 3200005,          --对方好友已满

	ALREADY_APPLY        = 2900018          --已经向好友发送请求 请耐心等待

}
FriendModel.REQ_INTERVAL = 5

FRIEND_SERACH = {
	BY_ID    = 0,
	BY_NAME  = 1
}
FriendModel.MAX_NAME_LEN      = 7
FriendModel.MAX_TEXT_LEN      = 30



function FriendModel.initReq(param)
	FriendModel.isSearch = false
    RequestHelper.friend.getFriendList({
    	callback = function(data)
    		FriendModel.rtnObj = data.rtnObj
    		FriendModel.initData()
    		param.callback()
    	end})
   
end

function FriendModel.initData()

	FriendModel.listVec[FRIEND_TYPE]    = FriendModel.rtnObj.friendList    or {}
	FriendModel.listVec[RECOMMEND_TYPE] = FriendModel.rtnObj.recommendList or {}
	FriendModel.listVec[NAILI_TYPE]     = FriendModel.rtnObj.nailiList     or {}
	FriendModel.listVec[REQUEST_TYPE]   = FriendModel.rtnObj.requestList   or {}




	FriendModel.restNailiNum = FriendModel.rtnObj.restNailiNum

	--全部排序
	FriendModel.sortAll()
end

function FriendModel.getList(index)

	return FriendModel.listVec[index] or {}
end


function FriendModel.getFriendByIndexAndAcc(index,account)
	local List = FriendModel.listVec[index]
	for k,v in pairs(List) do
		if v.account == account then
			return v
		end
	end	
end



function FriendModel.getNailiCellValue(cellData)

	return cellData.time
end




function FriendModel.updateRecommendList(param)	

	if FriendModel.isSearch  ~= true then
		 RequestHelper.friend.recommendList({
		 	num = 6,
			callback = function(data)
				FriendModel.listVec[2] = data.rtnObj
				FriendModel.updateList(RECOMMEND_TYPE)
			end
			})
	else
		--如果被搜索一次  以后就一直搜索了
		FriendModel.startSearch(1)
	end
end

function FriendModel.sendNailiReq(param)
	RequestHelper.friend.sendNaili({
        account = param.account,
		callback = function(data)
			local curFriend = FriendModel.getFriendByIndexAndAcc(FRIEND_TYPE,param.account)
			curFriend.isSendNaili = data.rtnObj.result
			ResMgr.showErr(FRIEND_KEY.SEND_NAILI_SUC_KEY) --发送耐力成功
			FriendModel.updateList(FRIEND_TYPE)
		end})
end


function FriendModel.getNailiReq(param)
	if game.player.m_energy < game.player.m_maxEnergy then
		RequestHelper.friend.getNaili({
			account = param.account,
			callback = function(data)

				game.player.m_energy = game.player.m_energy + data.rtnObj.nailiNum
				FriendModel.removeListByIndexAndAcc(NAILI_TYPE,param.account)
				ResMgr.showErr(FRIEND_KEY.GET_NAILI_SUC_KEY) --领取耐力成功

				if FriendModel.restNailiNum > 0 then
					FriendModel.restNailiNum = FriendModel.restNailiNum - 1
				end
				FriendModel.updateList(NAILI_TYPE)
			end})		
	else
		--提示 耐力已满
		ResMgr.showErr(FRIEND_KEY.NAI_LI_FULL_KEY)
	end

end

function FriendModel.removeListByIndexAndAcc(index,account)
	local List = FriendModel.getList(index)

	for i = 1,#List do
		if List[i].account == account then
			table.remove(List,i)
			break
		end
	end
	
	
end

function FriendModel.updateList(index)
	PostNotice(NoticeKey.UPDATE_FRIEND,CCInteger:create(index))
	FriendModel.updateFriendInGameModel()
end

function FriendModel.getAllNailiReq()
	if FriendModel.listVec[NAILI_TYPE] == nil or #FriendModel.listVec[NAILI_TYPE] then
		ResMgr.showErr(3200011)
		return
	end
	RequestHelper.friend.getNailiAll({
		callback = function(data)

			FriendModel.listVec[FRIEND_TYPE] = data.rtnObj.friendList
			FriendModel.listVec[NAILI_TYPE]  = data.rtnObj.nailiList  
			FriendModel.restNailiNum         = data.rtnObj.restNailiNum
			game.player.m_energy = game.player.m_energy + data.rtnObj.nailiNum

			ResMgr.showErr(FRIEND_KEY.GET_ALL_NAILI_KEY)
			FriendModel.updateList(NAILI_TYPE)
			FriendModel.updateList(FRIEND_TYPE)
		end})
end

function FriendModel.chatListReq(myAccount)
	GameRequest.friend.updateChatList({
		account = myAccount,
		callback = function(data)


		local chatData = data.rtnObj

		for i =1,#chatData do
			FriendModel.setOnlineState(chatData[i])
		end
		--将friend列表排序
		FriendModel.sortList(FRIEND_TYPE)
		FriendModel.updateList(FRIEND_TYPE)

		end})
end

function FriendModel.getChatNum()
	local chatNum = 0
	for i = 1,#FriendModel.listVec[FRIEND_TYPE] do
		if FriendModel.listVec[FRIEND_TYPE][i].isChat == 1 then
			chatNum = chatNum + 1
		end
	end
	return chatNum
end

function FriendModel.setOnlineState(data)
	local account = data.account

	-- dump(data)
	-- local friendList = 
	for i =1, #FriendModel.listVec[FRIEND_TYPE] do
		local curCellData = FriendModel.listVec[FRIEND_TYPE][i]
		if curCellData.account == account then
			curCellData.isChat = data.isChat
			curCellData.isOnline = data.isOnline
			break
		end
	end
end




function FriendModel.removeFriendReq(param)
	RequestHelper.friend.removeFriend({
		account = param.account,
		callback = function(data)
			FriendModel.removeListByIndexAndAcc(FRIEND_TYPE,param.account)
			FriendModel.updateList(FRIEND_TYPE)
			ResMgr.showErr(FRIEND_KEY.REV_FRIEND_SUC_KEY)
		end})
end



function FriendModel.applyFriendReq(param) --申请好友


	RequestHelper.friend.applyFriend({
		content = param.content,
		account = param.account,
		callback = function(data)

			local result = data.rtnObj.result 
			if result == 1 then
				ResMgr.showErr(FRIEND_KEY.SEND_APPLY_KEY)
				FriendModel.removeListByIndexAndAcc(RECOMMEND_TYPE,param.account)
				FriendModel.updateList(RECOMMEND_TYPE)	
			else
				ResMgr.showErr(FRIEND_KEY.ALREADY_APPLY)
			end		
		end})
end

FriendModel.searchType = FRIEND_SERACH.BY_ID
FriendModel.searchContent = ""
FriendModel.searchFlag = 0 

function FriendModel.startSearch(id)

 	local length = string.utf8len(FriendModel.searchContent) 
 	if length < 2 then 
 		ResMgr.showErr(FRIEND_KEY.CANNOT_EMPTY_KEY)
 		return 
 	end 

	if length > FriendModel.MAX_NAME_LEN then 
		ResMgr.showErr(FRIEND_KEY.TOO_MUCH_NAME_KEY)
		return
	end



	if FriendModel.searchType == FRIEND_SERACH.BY_ID then
		--必须全部为数字
		local n = tonumber(FriendModel.searchContent)
		if n == nil then
		 -- 不是数字
		 	ResMgr.showErr(FRIEND_KEY.NUM_PLZ_KEY)
		 	return
		end

	end

	FriendModel.searchReq(id)

end





function FriendModel.searchReq(id)
	local curFlag = 0
	if id == 1 then
		curFlag = FriendModel.searchFlag
	end

	FriendModel.isSearch = true
	RequestHelper.friend.searchFriend({
		type      = FriendModel.searchType,
        searchNum = 6,
        content   = FriendModel.searchContent,
        flag      = curFlag,
		callback = function(data)

			FriendModel.listVec[RECOMMEND_TYPE] = data.rtnObj.searchList or {}
			FriendModel.searchFlag              = data.rtnObj.flag

			if #FriendModel.listVec[RECOMMEND_TYPE] == 0 then
				ResMgr.showErr(FRIEND_KEY.NO_PLAYER_KEY)
			end

			FriendModel.checkSearchList()
		
			FriendModel.updateList(RECOMMEND_TYPE)
		end})
end

function FriendModel.checkSearchList()
	local searchList = FriendModel.listVec[RECOMMEND_TYPE]
	local friendList = FriendModel.listVec[FRIEND_TYPE]

	for i = 1,#searchList do
		for j = 1,#friendList do
			if searchList[i].account == friendList[j].account then
				searchList[i].isAdd = 1
				break
			end
		end
	end

end


function FriendModel.acceptReq(param)
	RequestHelper.friend.acceptFriend({
		account = param.account,
		callback = function(data)
			--如果当前没法加好友了，则后台会抛异常，走不到这里
			--所以这里必然是添加成功了

			local addData = FriendModel.getFriendByIndexAndAcc(REQUEST_TYPE,param.account)
			--新接受申请的这个人是不是可以赠送耐力
			addData.isSendNaili = data.rtnObj.isSendNaili or 0
			FriendModel.addDataToList(FRIEND_TYPE,addData)
			FriendModel.removeListByIndexAndAcc(REQUEST_TYPE,param.account)

			--将friend列表排序
			FriendModel.sortList(FRIEND_TYPE)

			ResMgr.showErr(FRIEND_KEY.AGREE_FRIEND_KEY)

			--更新friend列表和申请列表
			FriendModel.updateList(FRIEND_TYPE)
			FriendModel.updateList(REQUEST_TYPE)	
		end})
end

function FriendModel.sortAll()
	for i = 1,#FriendModel.listVec do
		FriendModel.sortList(i)
	end
end

function FriendModel.updateFriendInGameModel()
	local unCheckNum = 4

	for i = 1,4 do
		local dataList = FriendModel.getList(i)
		if index  == 1 then
		    local chatNum = FriendModel.getChatNum()
		    if chatNum == 0 then
		    	unCheckNum = unCheckNum - 1
		    end
		elseif index == 2 then
		    --推荐列表没有小红点，永远不更新
		    unCheckNum = unCheckNum - 1
		else
		    if #dataList == 0 then
		    	unCheckNum = unCheckNum - 1
		    end
		end
	end

	if unCheckNum == 0 then
		GameModel.friendActive = 0
	end
end

function FriendModel.sortList(index)
	local curList = FriendModel.listVec[index]
	for i =1,#curList do
		curList[i].originalRank = 1000-i
	end


	if index == NAILI_TYPE then
		table.sort(curList,function(a,b)
				return FriendModel.getNailiCellValue(a) < FriendModel.getNailiCellValue(b)
			end)
	else
		table.sort(curList,function(a,b)
				local isSort = true
				return FriendModel.getCellValue(a) > FriendModel.getCellValue(b)
				-- dump(curList)

				-- if a== nil or b == nil then
				-- 	return false
				-- elseif a == b then
				-- 	return false
				-- elseif a.isOnline ~= nil and b.isOnline ~= nil and a.isOnline > b.isOnline then
				-- 	return true
				-- -- elseif a.level ~= nil and b.level ~= nil and a.level > b.level then
				-- -- 	return true
				-- -- elseif a.battlepoint ~= nil and b.battlepoint ~= nil and a.battlepoint > b.battlepoint then
				-- -- 	return true
				-- -- elseif a.originalRank ~= nil and b.originalRank ~= nil and a.originalRank > b.originalRank then
				-- -- 	return true				
				-- else
				-- 	return false --not isSort 
				-- end				
			end)
	end

	-- dump(curList)
end

function FriendModel.getCellValue(cellData)
	local cellValue = 0
	local isOnline = cellData.isOnline    or 0
	local level    = cellData.level       or 1
	local zhanli   = cellData.battlepoint or 0
	local originalRank = cellData.originalRank or 0 


	--1在线
	cellValue = cellValue + isOnline * 1000000
	--2等级
	cellValue = cellValue + level    * 10000
	--3战斗力
	cellValue = cellValue + zhanli   / 100

	cellValue = cellValue + originalRank/100


	--id


	return cellValue
end

function FriendModel.addDataToList(index,addData)
	local curList = FriendModel.listVec[index]
	table.insert(curList, addData)
end


 
function FriendModel.rejectReq(param)
	 RequestHelper.friend.rejectFriend({
	 	account = param.account,
	 	callback = function(data)
	 		--必然成功，清空此申请账号的数据
	 		FriendModel.removeListByIndexAndAcc(REQUEST_TYPE,param.account)
	 		ResMgr.showErr(FRIEND_KEY.REJECT_SUC_KEY)	
	 		FriendModel.updateList(REQUEST_TYPE)
	 	end})
end

function FriendModel.acceptAllReq()
	if FriendModel.listVec[REQUEST_TYPE] == nil or #FriendModel.listVec[REQUEST_TYPE] == 0 then

		ResMgr.showErr(FRIEND_KEY.NO_ONE_KEY)
		return
	end

	RequestHelper.friend.acceptAll({
		callback = function(data)
			FriendModel.listVec[FRIEND_TYPE]    = data.rtnObj.friendList
			FriendModel.listVec[REQUEST_TYPE]   = data.rtnObj.requestList

			local firendLimitType  = data.rtnObj.firendLimitType

			if firendLimitType == 1 then
				ResMgr.showErr(FRIEND_KEY.NUM_LIMIT_KEY)
			elseif firendLimitType == 2 then
				ResMgr.showErr(FRIEND_KEY.FRIEND_NUM_LIMIT_KEY)
			else
				ResMgr.showErr(FRIEND_KEY.AGREE_SUC_KEY)
			end			

			FriendModel.updateList(FRIEND_TYPE)
			FriendModel.updateList(REQUEST_TYPE)
		end})
end

function FriendModel.rejectAll()
	if #FriendModel.listVec[REQUEST_TYPE] == 0 then
		ResMgr.showErr(FRIEND_KEY.NO_ONE_KEY)
		return
	end
	RequestHelper.friend.rejectAll({
		callback = function(data)
			--必然成功 直接清空全部请求list
			FriendModel.listVec[REQUEST_TYPE] = {}
			ResMgr.showErr(FRIEND_KEY.REJECT_SUC_KEY)			
			FriendModel.updateList(REQUEST_TYPE)
		end})
end



return FriendModel