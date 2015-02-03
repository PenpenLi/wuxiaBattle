--
--                   _ooOoo_
--                  o8888888o
--                  88" . "88
--                  (| -_- |)
--                  O\  =  /O
--               ____/`---'\____
--             .'  \\|     |//  `.
--            /  \\|||  :  |||//  \
--           /  _||||| -:- |||||-  \
--           |   | \\\  -  /// |   |
--           | \_|  ''\---/''  |   |
--           \  .-\__  `-`  ___/-. /
--         ___`. .'  /--.--\  `. . __
--      ."" '<  `.___\_<|>_/___.'  >'"".
--     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
--     \  \ `-.   \_ __\ /__ _/   .-` /  /
--======`-.____`-.___\_____/___.-`____.-'======
--                   `=---='
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--                 Buddha bless
--
-- 日期：14-10-17
--

local SpiritShowItem = class("SpiritShowItem", function()
    return CCTableViewCell:new()
end)

function SpiritShowItem:getContentSize()
    return CCSizeMake(display.width, 152)
end

function SpiritShowItem:ctor()

end

function SpiritShowItem:create(param)
    local _itemData = param.itemData
    local _viewSize = param.viewSize

    local proxy = CCBProxy:create()
    self._rootnode = {}
    self._bg = CCBuilderReaderLoad("spirit/spirit_show_item.ccbi", proxy, self._rootnode)
    self._bg:setPosition(_viewSize.width / 2, self._bg:getContentSize().height / 2)
    self:addChild(self._bg)


    self:refresh(param)
    return self
end

function SpiritShowItem:refresh(param)
    local _itemData = param.itemData

    for i = 1, 5 do
        self._rootnode[string.format("headIcon_%d", i)]:removeAllChildrenWithCleanup(true)
        if _itemData[i] then
            local name = string.format("headIcon_%d", i)
            local icon = require("game.Spirit.SpiritIcon").new({
                id = _itemData[i].data._id,
                resId = _itemData[i].data.resId,
                lv = _itemData[i].data.level,
                exp = _itemData[i].data.curExp or 0,
                bShowName = true,
                bShowNameBg = true,
                bShowLv = true
            })
            icon:setPosition(self._rootnode[name]:getContentSize().width / 2, self._rootnode[name]:getContentSize().height / 2)
            self._rootnode[name]:addChild(icon)
        end
    end

end

return SpiritShowItem

