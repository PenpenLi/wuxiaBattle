
local SDKKYCom = {}

local SDK_GLOBAL_NAME = "sdk.SDKKYCom"
local SDK_CLASS_NAME = "SDKKYCom"

local sdk = "".. SDK_GLOBAL_NAME --cc.PACKAGE_NAME[SDK_GLOBAL_NAME]

local function onEnterPlatform()
    dump("============onEnterPlatform===========")
    CCDirector:sharedDirector():pause()
end

local function onLeavePlatform()
    dump("===========onLeavePlatform============")
    CCDirector:sharedDirector():resume()
end

--[[
    NSString* appKey = @"cfd705e2321e5fc125e44aedf31bd0b8ce109d5435e30e64";
    
    [[SDKKYCom sharedInstance] init:100892 appKey:appKey delegate:self isDebug:true];
]]
function SDKKYCom.initPlatform( appId, appKey, isDebug)

    local function  logout( ... )
        -- game.player:deleteUID() 
        GameStateManager:ChangeState( GAME_STATE.STATE_VERSIONCHECK )
    end
    CCNotificationCenter:sharedNotificationCenter():registerScriptObserver(display.newNode(), logout, "SDKKY_NOT_LOGINED")
    local args = { appId = appId, appKey = appKey, isDebug = isDebug}

    luaoc.callStaticMethod(SDK_CLASS_NAME, "initPlatform", args)
end

--[[--

初始化

初始化完成后，可以使用：

    SDKKYCom.addCallback() 添加回调处理函数

支持的事件包括：

-   SDKNDCOM_LEAVE_PLATFORM 用户离开 TONGBU 平台
-   SDKNDCOM_GUEST_LOGINED 以游客身份登录
-   SDKNDCOM_GUEST_REGISTERED 游客转为正式用户成功
-   SDKNDCOM_LOGINED 正常登录
-   SDKNDCOM_NOT_LOGINED 登录失败
-   SDKNDCOM_HAS_ASSOCIATE 设备上有关联的 TONGBU 账号，不能以游客方式登录
-   SDKNDCOM_UNKNOWN_LOGIN_ERROR 未知登录错误
-   SDKNDCOM_INVALID_APPID_OR_APPKEY 无效的 appId 或 appKey
-   SDKNDCOM_INVALID_APPID 无效的 appId
-   SDKNDCOM_SESSION_INVALID session 失效

]]
function SDKKYCom.init()
    -- if sdk then return end
    
    local sdk_ = {callbacks = {}}
    sdk = sdk_
    -- __FRAMEWORK_GLOBALS__[SDK_GLOBAL_NAME] = sdk
    SDK_GLOBAL_NAME = sdk 

    local function callback(event)
        dump("## SDKKYCom CALLBACK, event " .. tostring(event))

        for name, callback in pairs(sdk.callbacks) do
            callback(event)
        end
        onLeavePlatform()
    end
    dump(sdk.callbacks)
    luaoc.callStaticMethod(SDK_CLASS_NAME, "registerScriptHandler", {listener = callback})
end

--[[--

清理

]]
function SDKKYCom.cleanup()
    sdk.callbacks = {}
    luaoc.callStaticMethod(SDK_CLASS_NAME, "unregisterScriptHandler")
end

--[[--

添加指定名称回调处理函数

用法:

    local function callback(event)
        print(event)
    end

    -- 回调函数名称用于区分不同场合使用的回调函数，removeCallback() 也需要使用同样的名称才能移除回调函数
    SDKKYCom.addCallback("mycallback", callback)

]]
function SDKKYCom.addCallback(name, callback)

    sdk.callbacks[name] = callback
end

--[[--

删除指定名称的回调函数

]]
function SDKKYCom.removeCallback(name)
    sdk.callbacks[name] = nil
end

--[[--

普通登录

]]
function SDKKYCom.login()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "login")
end

--[[--

登录(支持游客登录)

]]
function SDKKYCom.loginEx()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "loginEx")
end

--[[--

注销

]]
function SDKKYCom.logout(cleanAutoLogin)
    if cleanAutoLogin then
        cleanAutoLogin = 1
    else
        cleanAutoLogin = 0
    end
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "logout", {clean = cleanAutoLogin})
end

--[[--

游客账户转正式账户

]]
function SDKKYCom.guestRegister()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "guestRegister")
end

--[[--

判断用户登录状态

]]
function SDKKYCom.isLogined()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "isLogined")
    assert(ok, string.format("SDKKYCom.isLogined() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

判断用户登录状态

返回三种值：

-   SDKNDCOM_NOT_LOGINED 未登录
-   SDKNDCOM_GUEST_LOGINED 游客登录
-   SDKNDCOM_LOGINED 正常登录

]]
function SDKKYCom.getCurrentLoginState()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getCurrentLoginState")
    assert(ok, string.format("SDKKYCom.getCurrentLoginState() - call API failure, error code: %s", tostring(ret)))
    if ret == 0 then
        return "SDKNDCOM_NOT_LOGINED"
    elseif ret == 1 then
        return "SDKNDCOM_GUEST_LOGINED"
    else
        return "SDKNDCOM_LOGINED"
    end
end

--[[--

获得已登录用户的信息

返回值是一个表格，包括：

-   uin
-   sessionId
-   nickname 可能为空
-   headCheckSum 头像图片的校验值

]]
function SDKKYCom.getUserinfo()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getUserinfo")
    assert(ok, string.format("SDKKYCom.getUserinfo() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

切换账户

]]
function SDKKYCom.switchAccount()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "switchAccount")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.switchAccount() - call API failure, error code: %s", tostring(ret)))
end

--[[--

切换账户，进入账号管理列表

]]
function SDKKYCom.enterAccountManager()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "enterAccountManager")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.enterAccountManager() - call API failure, error code: %s", tostring(ret)))
end

--[[--

用户反馈

]]
function SDKKYCom.userFeedback()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "userFeedback")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.userFeedback() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

进入平台中心

]]
function SDKKYCom.enterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "enterPlatform")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.enterPlatform() - call API failure, error code: %s", tostring(ret)))
end


--[[--

进入18183论坛

]]
function SDKKYCom.enterAppBBS()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "enterAppBBS")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.enterAppBBS() - call API failure, error code: %s", tostring(ret)))
end


--[[--

进入暂停页面

]]
function SDKKYCom.pause()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "pause")
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.pause() - call API failure, error code: %s", tostring(ret)))
end


--[[
    91 tool bar
]]

function SDKKYCom.showToolbar( ... )
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "showToolbar")
    assert(ok, string.format("SDKKYCom.showToolbar() - call API failure, error code: %s", tostring(ret)))
    return ret
end

function SDKKYCom.HideToolbar( ... )
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "HideToolbar")
    assert(ok, string.format("SDKKYCom.HideToolbar() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

代币充值

参数：

-   coins 要充值多少代币，例如 1000 表示需要充值 1000 金币；如果 coins 不提供或为 0，表示不限制充值数量

调用后返回一个数组，包含：

-   orderId 订单 Id，用于发送到服务器进行验证
-   error 错误代码，为 0 表示没有发生错误

]]
function SDKKYCom.payForKYCoins(param)
    onEnterPlatform()
    local args = {
        price = tostring(param.price), 
        coins = checknumber(param.coins), 
        orderId = param.orderId, 
        name = param.name, 
        accId = param.accId, 
        gameId = tostring(param.gameId), 
        md5Key = tostring(param.md5Key), 
        payDescription = param.payDescription 
    }
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "payForKYCoins", args)
    if not ok then onLeavePlatform() end
    assert(ok, string.format("SDKKYCom.payForKYCoins() - call API failure, error code: %s", tostring(ret)))
    return ret
end

-- --[[
--     同步购买
-- ]]
-- function SDKKYCom.Buy91Coins( coins, price )
--     onEnterPlatform()
--     local args = {coins = checknumber(coins),price = checknumber(price)}
--     dump(args)
--     local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "buy91Coins", args)
--     if not ok then onLeavePlatform() end
--     assert(ok, string.format("SDKKYCom.buy91Coins() - call API failure, error code: %s", tostring(ret)))
--     return ret
-- end

-- --[[
--     异步购买
-- ]]
-- function SDKKYCom.BuyAsyn91Coins( coins, price )
--     onEnterPlatform()
--     local args = {coins = checknumber(coins),price = checknumber(price)}
--     dump(args)
--     local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "buyAysn91Coins", args)
--     if not ok then onLeavePlatform() end
--     assert(ok, string.format("SDKKYCom.buyAysn91Coins() - call API failure, error code: %s", tostring(ret)))
--     return ret
-- end

function SDKKYCom.getAvatar(uin, callback, imageType, checksum)
    assert(type(uin) == "string", format("SDKKYCom.getAvatar() - invalid uin %s", tostring(uin)))
    assert(type(callback) == "function", "SDKKYCom.getAvatar() - invalid callback")
    if not imageType then imageType = "middle" end
    local args = {uin = uin, type = imageType, checksum = checksum, callback = callback}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getAvatar", args)
    assert(ok, string.format("SDKKYCom.getAvatar() - call API failure, error code: %s", tostring(ret)))
end

function SDKKYCom.share(message, image)
    onEnterPlatform()
    assert(type(message) == "string", format("SDKKYCom.share() - invalid message %s", tostring(message)))
    local args = {message = message, image = image}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "share", args)
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKKYCom.share() - call API failure, error code: %s", tostring(ret)))
end

function SDKKYCom.localNotification(message, delay)
    assert(type(message) == "string", string.format("SDKKYCom.localNotification() - invalid message %s", tostring(message)))
    assert(type(delay) == "number" and delay > 0, string.format("SDKKYCom.localNotification() - invalid delay %s", tostring(delay)))
    local args = {message = message, delay = delay}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "localNotification", args)
    assert(ok, string.format("SDKKYCom.localNotification() - call API failure, error code: %s", tostring(ret)))
end

function SDKKYCom.cleanLocalNotification()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "cleanLocalNotification", args)
    assert(ok, string.format("SDKKYCom.cleanLocalNotification() - call API failure, error code: %s", tostring(ret)))
end

return SDKKYCom
