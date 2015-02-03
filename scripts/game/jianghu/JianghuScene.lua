--
-- Created by IntelliJ IDEA.
-- User: douzi
-- Date: 14-8-4
-- Time: 下午4:12
-- To change this template use File | Settings | File Templates.
--

require("data.data_star_star")
require("data.data_item_nature")
require("data.data_mingjiang_mingjiang")
require("data.data_starachieve_starachieve")
require("data.data_shangxiansheding_shangxiansheding")
require("data.data_error_error")
local JianghuScene = class("JianghuScene", function()
    return require("game.BaseScene").new({
        contentFile = "jianghulu/jianghulu_scene.ccbi",
        bgImage    = "ui_common/jianghulu_bg.jpg",
        topFile = "public/top_frame_other.ccbi",
        isOther = true,
        scaleMode  = 1
    })
end)

local HEROTYPE = {
    HAOJIE = 1,
    GAOSHO = 2,
    XINXIU = 3
}

function JianghuScene:ctor()
     ResMgr.removeBefLayer()
--    dump(self._rootnode)
    local bShow = false
    self._rootnode["popBtn"]:addNodeEventListener(cc.MENU_ITEM_CLICKED_EVENT, function(tag)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        local tmpW = self._rootnode["propNode"]:getContentSize().width * 0.8
        if bShow then
            bShow = false
        else
            tmpW = -tmpW
            bShow = true
        end
        self._rootnode["propNode"]:runAction(transition.sequence({
            CCMoveBy:create(0.2, ccp(tmpW, 0)),
            CCCallFunc:create(function()
                if bShow then
                    self._rootnode["popBtn"]:setNormalSpriteFrame(display.newSpriteFrame("jianghulu_sq_2.png"))
                    self._rootnode["popBtn"]:setSelectedSpriteFrame(display.newSpriteFrame("jianghulu_sq_1.png"))
                else
                    self._rootnode["popBtn"]:setNormalSpriteFrame(display.newSpriteFrame("jianghulu_left_btn_2.png"))
                    self._rootnode["popBtn"]:setSelectedSpriteFrame(display.newSpriteFrame("jianghulu_left_btn_1.png"))
                end
            end)
        }))
    end)

    self._rootnode["heroShowBtn"]:addHandleOfControlEvent(function(a, b, c, d)

--        dump(self._groupHerosData)
--        self._rootnode["heroShowBtn"]:setEnabled(false)
--        self._rootnode["heroTargetBtn"]:setEnabled(false)

        local scene = require("game.jianghu.HeroShowScene").new({
            listData = self._groupHerosData,
            viewType = self._viewType,
            stars    = self._stars,
            listener = function(viewType, id, index)
                self._viewType = viewType
                self._index    = {row = index.row, col = index.col}
                self:refresh()
            end
        })
        display.wrapSceneWithTransition(scene, "turnOffTiles", 0.2)
        push_scene(scene)
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
    end, CCControlEventTouchUpInside)

    self._rootnode["heroTargetBtn"]:addHandleOfControlEvent(function()
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        self._rootnode["heroShowBtn"]:setEnabled(false)
        self._rootnode["heroTargetBtn"]:setEnabled(false)
        push_scene(require("game.jianghu.HeroAchieveScene").new(self._stars))
    end, CCControlEventTouchUpInside)

    self._rootnode["sendAllBtn"]:addHandleOfControlEvent(function()
--

        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        if #self._giftData <= 0 then
            show_tip_label(data_error_error[2100003].prompt)
            return
        end

        self._rootnode["heroShowBtn"]:setEnabled(false)
        self._rootnode["heroTargetBtn"]:setEnabled(false)
        self._rootnode["sendAllBtn"]:setEnabled(false)

        local box = require("utility.MsgBox").new({
            size = CCSizeMake(500, 300),
            content = "一键赠送最多50个好感礼物，达到上限后不会继续使用，您确定一键赠送吗？",
            leftBtnName = "取消",
            rightBtnName = "确定",
            leftBtnFunc = function()
                self._rootnode["heroShowBtn"]:setEnabled(true)
                self._rootnode["heroTargetBtn"]:setEnabled(true)
                self._rootnode["sendAllBtn"]:setEnabled(true)
            end,
            rightBtnFunc = function()
                self._rootnode["heroShowBtn"]:setEnabled(true)
                self._rootnode["heroTargetBtn"]:setEnabled(true)
                self._rootnode["sendAllBtn"]:setEnabled(true)
                self:sendGift()
            end
        })
        self:addChild(box, 101)

    end, CCControlEventTouchUpInside)

    self._rootnode["onShopBtn"]:addHandleOfControlEvent(function()
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        GameStateManager:ChangeState(GAME_STATE.STATE_SHOP, true)
    end, CCControlEventTouchUpInside)

    self._rootnode["onBattleBtn"]:addHandleOfControlEvent(function()
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding)) 
        GameStateManager:ChangeState(GAME_STATE.STATE_ARENA)
    end, CCControlEventTouchUpInside)
--
    self._giftData = {}
--    for i = 1, 10 do
--        table.insert(self._giftData, i)
--    end

    RequestHelper.jianghu.list({
        callback = function(data)
--            dump(data)
            if #data["0"] > 0 then
                show_tip_label(data["0"])
            else

                self._heroData = data["1"]
                self._showHero = data["3"]
                self._stars = data["4"]
                self:groupHero()
                self:refreshGift(data["2"])
                self:refresh(self._showHero)
            end
        end
    })
    self:initGiftList()
    self:initPropertyList()
    self:initTouchNode()

    self._groupHerosData = {}
    for _, v in pairs(HEROTYPE) do
        self._groupHerosData[v] = {}
    end

    if (display.widthInPixels / display.heightInPixels) > 0.67 then
        local posX, posY = self._rootnode["imageNode"]:getPosition()
        self._rootnode["imageNode"]:setPosition(posX, posY - 90)
    end

    local rect = self._rootnode["blueBar"]:getTextureRect()
    self._rootnode["blueBar"]:setTextureRect(CCRectMake(rect.origin.x, rect.origin.y, 0, rect.size.height))

end

function JianghuScene:refreshGift(data)
    for k, v in ipairs(data) do
        if self._giftData[k] then
            self._giftData[k].num = v.num
            self._giftData[k].resId = v.resId
        else
            table.insert(self._giftData, v)
        end
    end
    --20, 10
    if #self._giftData > #data then
        for i = #data + 1,  #self._giftData do
            table.remove(self._giftData, #data + 1)
        end
    end

    self._gitfListView:resetListByNumChange(#self._giftData)

    if #self._giftData == 0 then
        self._rootnode["emptyNode"]:setVisible(true)
    else
        self._rootnode["emptyNode"]:setVisible(false)
    end
end

function JianghuScene:initTouchNode()

    local touchNode = self._rootnode["touchNode"]
    local MOVE_OFFSET = touchNode:getContentSize().width / 3
    touchNode:setTouchEnabled(true)

    local currentNode
    local targPosX, targPosY = self._rootnode["imageSprite"]:getPosition()

    local function moveToTargetPos()
        currentNode:runAction(transition.sequence({
            CCMoveTo:create(0.2, ccp(targPosX, targPosY))
        }))
    end

    local function resetHeroImage(side)
        if side  == 1 then --左滑动
            currentNode:setPosition(display.width * 1.5, targPosY)
        elseif side == 2 then  --右滑动
            currentNode:setPosition(-display.width * 0.5, targPosY)
        end
        currentNode:runAction(CCMoveTo:create(0.2, ccp(targPosX, targPosY)))
    end

    local offsetX = 0
    local function onTouchBegan(event)

        local sz = touchNode:getContentSize()
        if self._index and (CCRectMake(0, 0, sz.width, sz.height):containsPoint(touchNode:convertToNodeSpace(ccp(event.x, event.y)))) then
            local rect = CCRectMake(0, 0, self._rootnode["propNode"]:getContentSize().width,  self._rootnode["propNode"]:getContentSize().height)
            if rect:containsPoint(self._rootnode["propNode"]:convertToNodeSpace(ccp(event.x, event.y))) then
                return false
            else
                currentNode = self._rootnode["imageSprite"]
                offsetX = event.x
                return true
            end
        end
        return false
    end

    local function onTouchMove(event)
        local posX, posY = currentNode:getPosition()
        currentNode:setPosition(posX + event.x - event.prevX, posY)
    end

    local function onTouchEnded(event)
        offsetX = event.x - offsetX
        if offsetX >= MOVE_OFFSET  then
            if self._groupHerosData[self._viewType][self._index.row][self._index.col - 1] then
                self._index.col = self._index.col - 1
                self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                resetHeroImage(2)
            else
                if self._groupHerosData[self._viewType][self._index.row - 1] and self._groupHerosData[self._viewType][self._index.row - 1][5]then
                    self._index.row = self._index.row - 1
                    self._index.col = 5
                    self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                    resetHeroImage(2)
                else
                    local item = self._groupHerosData[self._viewType - 1]

                    if item and item[#item] and item[#item][#item[#item]] then
                        self._viewType = self._viewType - 1

                        self._index.row = #item
                        self._index.col = #item[#item]
                        self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                        resetHeroImage(2)
                    else
                        printf("hello")
                        moveToTargetPos()
                    end

                end

            end
        elseif offsetX <= -MOVE_OFFSET then
            if self._groupHerosData[self._viewType][self._index.row][self._index.col + 1] then
                self._index.col = self._index.col + 1
                self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                resetHeroImage(1)
            else
                if self._groupHerosData[self._viewType][self._index.row + 1] and  self._groupHerosData[self._viewType][self._index.row + 1][1] then
                    self._index.row = self._index.row + 1
                    self._index.col = 1
                    self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                    resetHeroImage(1)
                else
                    local item = self._groupHerosData[self._viewType + 1]
                    if item and item[1] and item[1][1] then
                        self._viewType = self._viewType + 1

                        self._index.row = 1
                        self._index.col = 1
                        self:refresh(self._groupHerosData[self._viewType][self._index.row][self._index.col].resId)
                        resetHeroImage(1)
                    else
                        moveToTargetPos()
                    end
                end
            end
        else
            moveToTargetPos()
        end
    end

    touchNode:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(event)
        if event.name == "began" then
            return onTouchBegan(event)
        elseif event.name == "moved" then
            onTouchMove(event)
        elseif event.name == "ended" then
            onTouchEnded(event)
        end
    end)
end


function JianghuScene:groupHero()
    --  按品质分组
    local heroGroup = {}
    heroGroup[HEROTYPE.HAOJIE] = {}   --豪杰
    heroGroup[HEROTYPE.GAOSHO] = {}   --高手
    heroGroup[HEROTYPE.XINXIU] = {}   --新秀

    for _, v in ipairs(self._heroData) do
        local _cardInfo = ResMgr.getCardData(v.resId)
        if _cardInfo.star then
            if  _cardInfo.star[1] == 5 then
                if _cardInfo.hero == 1 then
                    table.insert(heroGroup[HEROTYPE.HAOJIE], v)
                else
                    table.insert(heroGroup[HEROTYPE.GAOSHO], v)
                end
            elseif _cardInfo.star[1] == 4 then
                table.insert(heroGroup[HEROTYPE.XINXIU], v)
            else
                assert(false, "只能存在4，5星的hero")
            end
        end
    end

    --  5个一组
    for _, heroType in pairs(HEROTYPE) do
        local t = self._groupHerosData[heroType]
        for k, v in ipairs(heroGroup[heroType]) do
            if k % 5 == 1 then
                table.insert(t, {})
            end
            table.insert(t[#t], v)

            if v.resId == self._showHero then
                self._viewType = heroType
                self._index = {row = #t, col = #t[#t]}
            end
        end
    end
end

function JianghuScene:refreshExpBar(info)

    if info.level > checkint(self._rootnode["lvLabel"]:getString()) then
        self._propertyListView:resetCellNum(#self._propertyData)
    end

    if info.level - 3 > 0 then
        if info.level + 3 < data_shangxiansheding_shangxiansheding[7].level then
            self._propertyListView:setContentOffset(ccp(0, self._propertyListView:minContainerOffset().y + (info.level - 3) * 37))
        else
            self._propertyListView:setContentOffset(ccp(0, self._propertyListView:minContainerOffset().y + 23 * 37))
        end
    end

    local size = self._rootnode["barBg"]:getTextureRect().size
    local rect = self._rootnode["blueBar"]:getTextureRect()
    local card = ResMgr.getCardData(info.resId)

    local maxExp = data_mingjiang_mingjiang[info.level + 1]["arr_exp"][card["star"][1] - 3]


    self._rootnode["expLabel"]:setString(string.format("%d/%d", info.curExp, maxExp))
    self._rootnode["lvLabel"]:setString(tostring(info.level))

    local w = size.width * (info.curExp / maxExp)
    self._rootnode["blueBar"]:setTextureRect(CCRectMake(rect.origin.x, rect.origin.y, w, size.height))


--    直接升级几率=1/（当前等级+2）+当前经验/升级所需经验/（当前等级+2）
    local prop = 1 / (info.level + 2) + info.curExp / maxExp / (info.level + 2)
    self._rootnode["propLabel"]:setString(string.format("%.2f%%", prop * 100))
end

function JianghuScene:refresh()
    if self._index == nil then
        return
    end

    local info = self._groupHerosData[self._viewType][self._index.row][self._index.col]

    local card = ResMgr.getCardData(info.resId)
    local heroImg = card["arr_body"][1]
    local heroPath = CCFileUtils:sharedFileUtils():fullPathForFilename(ResMgr.getLargeImage(heroImg, ResMgr.HERO))
    self._rootnode["imageSprite"]:setDisplayFrame(display.newSprite(heroPath):getDisplayFrame())

    self._rootnode["heroNameLabel"]:setString(card.name)
    self._rootnode["propTitleLabel"]:setString(string.format("%s属性加成", card.name))

    local heroInfo
    for k, v in ipairs(data_star_star) do
        if v.card == info.resId then
            heroInfo = v
            break
        end
    end

    if heroInfo then
        if #self._propertyData >  #heroInfo.arr_nature then
            for i = #heroInfo.arr_nature, #self._propertyData do
                table.remove(self._propertyData, #heroInfo.arr_nature + 1)
            end
        end

        for k, v in ipairs(heroInfo.arr_nature) do

            if self._propertyData[k] then
                self._propertyData[k].id = v
                self._propertyData[k].val = heroInfo.arr_num[k]
            else
                table.insert(self._propertyData, {
                    id = v,
                    val = heroInfo.arr_num[k]
                })
            end
        end
        self._propertyListView:resetCellNum(#self._propertyData)
    end

    self:refreshExpBar(info)
end

function JianghuScene:showNewAchieve(stars)
    --恭喜达成
    local str
    local preAchive
    for k, v in ipairs(data_starachieve_starachieve) do
        if v.good <= self._stars then
            preAchive = v
        end
    end

    self._stars = stars
    local curAchieve
    for k, v in ipairs(data_starachieve_starachieve) do
        if v.good <= self._stars then
            curAchieve = v
        end
    end

    if preAchive and curAchieve then
        if preAchive.id ~= curAchieve.id then
--            show_tip_label("恭喜新成就达成")
            str = "恭喜新成就达成"
        end
    end
    return str
end

function JianghuScene:showTip(msg)

    local act = {}
    for k, v in ipairs(msg) do
        table.insert(act, CCCallFunc:create(function()
            show_tip_label(v, 1)
        end))
        table.insert(act, CCDelayTime:create(1))
    end

    if msg.propValue then
        for k, v in pairs(msg.propValue) do
            table.insert(act, CCCallFunc:create(function()
                show_tip_label(string.format("%s +%d",data_item_nature[k].nature, v), 1)
            end))
            table.insert(act, CCDelayTime:create(1))
        end
    end

    if #act > 0 then
        self:runAction(transition.sequence(act))
    end
end

function JianghuScene:sendGift(cell)

--    data_mingjiang_mingjiang
    if self._groupHerosData[self._viewType][self._index.row][self._index.col].level >= data_shangxiansheding_shangxiansheding[7].level then
        show_tip_label("此侠客好感度已经达到最大开放等级")
        return
    else
        local effect = ResMgr.createArma({
            resType = ResMgr.UI_EFFECT,
            armaName = "qunxialu_songli",
            isRetain = false,
            finishFunc = function()

            end
        })
        effect:setPosition(self._rootnode["imageSprite"]:getContentSize().width / 2, self._rootnode["imageSprite"]:getContentSize().height * 0.3)
        self._rootnode["imageSprite"]:addChild(effect, 10)

        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_jianghulu))
    end

    if self._index and #self._groupHerosData[self._viewType] > 0 and self._groupHerosData[self._viewType][self._index.row][self._index.col].resId then
        local t, gifId
        if cell then
            local idx = cell:getIdx() + 1
            gifId = self._giftData[idx].resId
            t = 2
        else
            t = 1
        end

        RequestHelper.jianghu.send({
            cardId = self._groupHerosData[self._viewType][self._index.row][self._index.col].resId,
            itemId = gifId,
            multi  = t,
            callback = function(data)
--                dump(data)
                if #data["0"] > 0 then
                    show_tip_label(data["0"])
                else
                    local msg = {}
                    local hero = self._groupHerosData[self._viewType][self._index.row][self._index.col]

                    if hero.level < data["1"]["level"] then
                        local starInfo
                        for k, v in ipairs(data_star_star) do
                            if v.card == hero.resId then
                                starInfo = v
                                break
                            end
                        end

                        if starInfo then
                            local propValue = {}
                            for k = hero.level + 1, data["1"]["level"] do
                                if propValue[starInfo.arr_nature[k]] then
                                    propValue[starInfo.arr_nature[k]] = propValue[starInfo.arr_nature[k]] + starInfo.arr_num[k]
                                else
                                    propValue[starInfo.arr_nature[k]] = starInfo.arr_num[k]
                                end
                            end
                            msg.propValue = propValue
                        end
                    end

                    self._groupHerosData[self._viewType][self._index.row][self._index.col].curExp = data["1"]["curExp"]
                    self._groupHerosData[self._viewType][self._index.row][self._index.col].level = data["1"]["level"]
                    self:refreshExpBar(self._groupHerosData[self._viewType][self._index.row][self._index.col])


                    if data["2"][1] > 0 then
--                        table.insert(msg, string.format("送礼暴击，好感度+%d", data["2"][1]))
                        local effect = ResMgr.createArma({
                            resType = ResMgr.UI_EFFECT,
                            armaName = "jianghulu_songlibaoji",
                            isRetain = false,
                            finishFunc = function()

                            end
                        })
                        effect:setPosition(self._rootnode["imageSprite"]:getContentSize().width / 2, self._rootnode["imageSprite"]:getContentSize().height * 0.3)
                        self._rootnode["imageSprite"]:addChild(effect, 10)
                    else
                        if data["2"][1] > 0 or data["2"][2] > 0 then
                            table.insert(msg, string.format("好感+%d，好感度提升", data["1"].addExp))
                        else
                            table.insert(msg, string.format("好感+%d", data["1"].addExp))
                        end
                    end

                    local achieve = self:showNewAchieve(data["3"])
                    if achieve then
                        table.insert(msg, achieve)
                    end
                    self:showTip(msg)

                    -- 单次送礼
                    if cell then
                        local idx = cell:getIdx() + 1
                        self._giftData[idx].num = self._giftData[idx].num - 1
                        if self._giftData[idx].num > 0 then
                            cell:refresh({
                                itemData = self._giftData[idx]
                            })
                        else
                            table.remove(self._giftData, idx)
                            self._gitfListView:resetListByNumChange(#self._giftData)
                        end
                    else
                        self:refreshGift(data["4"])
                    end

                    if #self._giftData == 0 then
                        self._rootnode["emptyNode"]:setVisible(true)
                    else
                        self._rootnode["emptyNode"]:setVisible(false)
                    end
                end
            end
        })
    else
        show_tip_label("没有可送礼的侠客")
    end
end

function JianghuScene:initGiftList()
    self._gitfListView = require("utility.TableViewExt").new({
        size        = CCSizeMake(self._rootnode["giftScrollView"]:getContentSize().width, self._rootnode["giftScrollView"]:getContentSize().height),
        createFunc  = function(idx)
            idx = idx + 1
            local item = require("game.jianghu.HeroGiftItem").new()
            return item:create({
                viewSize = self._rootnode["giftScrollView"]:getContentSize(),
                idx      = idx,
                itemData = self._giftData[idx]
            })
        end,
        refreshFunc = function(cell, idx)
            idx = idx + 1
            cell:refresh({
                idx = idx,
                itemData = self._giftData[idx]
            })
        end,
        cellNum   = #self._giftData,
        cellSize  = require("game.jianghu.HeroGiftItem").new():getContentSize(),
        touchFunc = function(cell)
            self:sendGift(cell)
        end
    })
    self._gitfListView:setPosition(0, 0)
    self._rootnode["giftScrollView"]:addChild(self._gitfListView)
end

function JianghuScene:initPropertyList()
    self._propertyData = {}
    self._propertyListView = require("utility.TableViewExt").new({
        size        = CCSizeMake(self._rootnode["propertyListView"]:getContentSize().width, self._rootnode["propertyListView"]:getContentSize().height),
        direction  = kCCScrollViewDirectionVertical,
        createFunc  = function(idx)
            idx = idx + 1
            local item = require("game.jianghu.PropertyItem").new()
            return item:create({
                viewSize = self._rootnode["propertyListView"]:getContentSize(),
                itemData = self._propertyData[idx],
                idx      = idx,
                heroLv   = self._groupHerosData[self._viewType][self._index.row][self._index.col].level
            })
        end,
        refreshFunc = function(cell, idx)
            idx = idx + 1
            cell:refresh({
                idx = idx,
                itemData = self._propertyData[idx],
                heroLv   = self._groupHerosData[self._viewType][self._index.row][self._index.col].level
            })
        end,
        cellNum   = #self._propertyData,
        cellSize  = require("game.jianghu.PropertyItem").new():getContentSize()
    })
    self._propertyListView:setTouchSwallowEnabled(false)
    self._propertyListView:setPosition(0, 0)
    self._rootnode["propertyListView"]:addChild(self._propertyListView)
end

function JianghuScene:onEnter()
    game.runningScene = self
    self._rootnode["heroShowBtn"]:setEnabled(true)
    self._rootnode["heroTargetBtn"]:setEnabled(true)
        self:regNotice()

    PostNotice(NoticeKey.UNLOCK_BOTTOM)
end

function JianghuScene:onExit()
        self:unregNotice()

end

return JianghuScene

