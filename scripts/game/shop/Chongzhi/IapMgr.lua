--[[
 --
 -- add by vicky
 -- 2014.10.23 
 --
 --]]

 require("data.data_serverurl_serverurl")
local json = require("framework.json")
 local WAIT_CHECK_TIME = 25 -- 不清楚玩家是否已购买，等待一段时间，再请求是否已充值 
 local WAIT_TIME = 2 -- 等待时间
 local REQ_COUNT = 3 -- 请求次数

 local loadingLayer = require("utility.LoadingLayer") 
 local iapRequest = require("network.IapRequest") 

 local IapMgr = class("IapMgr", function()
 	return display.newNode() 
 end)


---
-- ios iap
--
function IapMgr:buyGoldIos( ... )
    if(device.platform == "ios") then

        -- 订单号由91生成
        if CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_91 or CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_91_OFFICIAL then 
            local ret = CSDKShell.BuyAsynCoins({
                price = self._itemData.price, 
                coins = self._itemData.basegold, 
                productName = self._itemData.productName,  
                productId = self._itemData.payitemId, 
                payDescription = tostring(game.player.m_serverID), 
                isMonthCard = self._itemData.isMonthCard 
            }) 
            dump(ret) 
            self._orderId = ret.orderId 

            iapRequest.tdRequestLog({
                orderId = self._orderId, 
                productName = self._itemData.productName, 
                price = self._itemData.price, 
                currencyType = "CNY", 
                paymentType = CSDKShell.SDK_TYPE 
            })

        -- 订单号由游戏服务器生成    
        -- if CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_PP or CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_ITOOLS or 
        --     CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_TB or CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_XY or 
        --     CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_KUAIYONG or CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_AS then 
        else
            iapRequest.getOrderID({
                payitemId = self._itemData.payitemId, 
                serverId = tostring(game.player.m_serverID), 
                callback = function(data) 
                    dump(data) 
                    if data["0"] ~= "" then 
                        dump(data.err)  
                    else 
                        self._orderId = data.rtnObj.token 

                        iapRequest.tdRequestLog({
                            orderId = self._orderId, 
                            productName = self._itemData.productName, 
                            price = self._itemData.price, 
                            currencyType = "CNY", 
                            paymentType = CSDKShell.SDK_TYPE 
                        })

                        local ret = CSDKShell.BuyAsynCoins({
                            price = self._itemData.price, 
                            coins = self._itemData.basegold, 
                            name = self._itemData.productName, 
                            orderId = self._orderId, 
                            accId = game.player.m_uid, 
                            payDescription = tostring(game.player.m_serverID),  -- 游戏分区
                            isMonthCard = self._itemData.isMonthCard ,
                            gameId = data_serverurl_serverurl[checkint(CSDKShell.getChannelID())].gameId,
                            md5Key = data_serverurl_serverurl[checkint(CSDKShell.getChannelID())].md5Key,
                        })
                    end 
                end 
                })

        end 
    end
end

local function getExtendInfo()
    local t = {
        name = game.player.getPlayerName(),
        level = game.player.getLevel(),
        serverId = tostring(game.player.m_serverID),
        serverName = game.player.m_serverName;
    }

    return json.encode(t)
end
-- android iap
function IapMgr:buyGoldAndroid( )
    if(device.platform == "android") then

--      应用宝不需要服务器请求
        if CSDKShell.GetSDKTYPE() == SDKType.ANDROID_TENCENT then
            local userInfo = CSDKShell.userInfo()
            if userInfo then
                local url = CSDKShell.getBaseUrlByChannelId()
                url = string.gsub(url, "tx/login", "tx/chengeGold")
                local info = json.decode(userInfo.sessionId)

                --支付成功后，请求服务器状态
                local function resultRequest(callfunc, payresult)
                    info.callback = function(data)
                        dump(data)
                        if data.rtnObj and data.rtnObj.token then
                            self._orderId = data.rtnObj.token
                            callfunc(payresult)
                        end
                    end
                    RequestHelper.checkGold(info, url)
                end
                --请求服务器状态
                local function firstRequest()
                    info.callback = function(data)
                        dump(data)
                        CSDKShell.BuyAsynCoins({
                            coins = self._itemData.basegold,
                            isMonthCard = tostring(self._itemData.isMonthCard)
                        }, resultRequest)
                    end
                    RequestHelper.checkGold(info, url)
                end

                firstRequest()
            end
        else
            
            iapRequest.getOrderID({
                payitemId = self._itemData.payitemId,
                serverId  = tostring(game.player.m_serverID),
                title     = tostring(self._itemData.productName),
                desc      = tostring(self._itemData.basegold),
                money     = self._itemData.price,
                callback = function(data)
                    dump(data)
                    if data["0"] ~= "" then
                        dump(data.err)
                    else
                        self._orderId = data.rtnObj.token

                        iapRequest.tdRequestLog({
                            orderId = self._orderId,
                            productName = self._itemData.productName,
                            price = self._itemData.price,
                            currencyType = "CNY",
                            paymentType = CSDKShell.SDK_TYPE
                        })

                        local userId = game.player.m_uid
                        local bIndex, eIndex = string.find(userId, "__")
                        if bIndex then
                            userId = string.sub(userId, eIndex + 1)
                        end

                        CSDKShell.BuyAsynCoins({
                            price          = self._itemData.price,
                            coins          = self._itemData.basegold,
                            productName    = self._itemData.productName,
                            productId      = self._itemData.payitemId,
                            orderId        = self._orderId,
                            accId          = userId,
                            payDescription = tostring(game.player.m_serverID),  -- 游戏分区
                            isMonthCard    = tostring(self._itemData.isMonthCard) ,
                            notifyUri      = CSDKShell.getIapNotifyUrlByChannelId(),
                            extendInfo     = getExtendInfo(),
                            
                                            -- vivo 
                            vivoOrder      = data.rtnObj.vivoOrder or "",
                            vivoSignature  = data.rtnObj.vivoSignature or "",
                            goodsID        = self._itemData.index,  -- 购买的真实id


                            -- 金立
                            submitTime = data.rtnObj.submit_time or "", 

                            -- 酷派
                            openId = game.player.m_extendData.openid or "",
                            expiresIn = game.player.m_extendData.expires_in or "", 
                            accessToken = game.player.m_extendData.access_token or "", 
                            refreshToken = game.player.m_extendData.refresh_token or "", 
                            coolpadItemId = self._itemData.coolpadItemId, 
                        })
                    end
                end
            })
        end
    end
end

---
-- 购买元宝
--
 function IapMgr:buyGold(param) 
 	self._reqCount = 0 
 	self._itemData = param.itemData 
 	self._callback = param.callback 

 	self._orderId = -1 

    if(device.platform == "ios") then
        self:buyGoldIos()
    elseif(device.platform == "android") then
        self:buyGoldAndroid()
    end


    local function event_call( event )
    	dump("########### event_call ###########")
        printf(event)
        if event == "SDKNDCOM_PAY_SUCCESS" then 
	    	self:waitReqOrder(WAIT_TIME)

	    elseif event == "SDKNDCOM_PAY_WAITCHECK" then 
	    	self:waitReqOrder(WAIT_CHECK_TIME) 

	    elseif event == "SDKNDCOM_PAY_FAILED" then 
	    	show_tip_label("服务异常或已取消购买，购买失败")
        end
    end

    CSDKShell.addEventCallBack("payEvent", event_call)
 end 


 function IapMgr:waitReqOrder(time)
 	loadingLayer.start()

    self:runAction(transition.sequence({
    	CCDelayTime:create(time), 
    	CCCallFunc:create(function()
    		-- loadingLayer.hide()
    		self:checkInquire()
		end)
	}))
 end 


 function IapMgr:checkInquire() 

    iapRequest.sendInquire({
        orderId = self._orderId, 
        callback = function(data)
        	dump("购买完成后，请求到的结果：")
            dump(data) 
            if data.err ~= "" then 
            	if CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_91 or CSDKShell.GetSDKTYPE() == CSDKShell.SDKTYPES.IOS_91_OFFICIAL then 
	            	if  self._reqCount < REQ_COUNT then 
	        			self._reqCount = self._reqCount + 1 
	            		self:waitReqOrder(WAIT_TIME)
	            	else
	            		loadingLayer.hide() 
	            	end 
	            else
	            	dump(data.err)
	            end 
            else
            	if data.rtnObj.status == "0" or data.rtnObj.status == "1" then  
            		-- 再请求一次
            		if self._reqCount < REQ_COUNT then 
            			self._reqCount = self._reqCount + 1 
	            		self:waitReqOrder(WAIT_TIME)
	            	else
	            		loadingLayer.hide()
	            	end 
    			elseif data.rtnObj.status == "2" then
            		-- 充值成功 
            		dump("充值成功")
 
            		loadingLayer.hide()
            		if self._callback ~= nil then 
                    	self._callback(data) 
                    end 
                    
                    SDKGameWorks.gameSubmitOrder({
            			payname = CSDKShell.GetSDKTYPE(), 
            			amount = tostring(self._itemData.price), 
            			user = tostring(game.player.m_uid), 
            			serverno = game.player.m_serverID, 
            			ordernumber = tostring(self._orderId), 
            			grade  = game.player:getLevel(), 
            			productdesc = self._itemData.productName, 
            			rolemark = "1",  
        			}) 

            	end 
           	end 
        end  
    })
 end 


 return IapMgr 
