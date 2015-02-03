
--
-- Created by IntelliJ IDEA.
-- User: douzi
-- Date: 6/26/14
-- Time: 3:27 PM
-- To change this template use File | Settings | File Templates.
--
require("data.data_item_money")


local LevelGradeItem = class("LevelGradeItem", function()
    return display.newNode()
end)


function LevelGradeItem:ctor(param) 
    self:setNodeEventEnabled(true) 

    self._lianzhanCnt = param.lianzhanCnt 
    self._secWait = param.secWait 

    self.isPressed = false

    local _grade = param.grade
    local _silver = param.silver or 0
    local _xiahun = param.xiahun or 0
    local _desc   = param.desc or "desc"

    local _lianzhanFight = param.lianzhanFight 
    local _fight   = param.fight 
    local _star = param.star 
    local _needGold = param.needGold 

    local proxy = CCBProxy:create()
    local rootnode = {}

    local node = CCBuilderReaderLoad("ccbi/battle/level_grade.ccbi", proxy, rootnode)
    local _sz = node:getContentSize()
    self:setContentSize(_sz)
    self:addChild(node)

    rootnode["silverLabel"]:setString(tostring(_silver))
    rootnode["xiahunLabel"]:setString(tostring(_xiahun))
    rootnode["discLabel"]:setString(tostring(_desc))

       
    rootnode["silverLabelname"]:setString(data_item_money[param.coinType[1]].name .. ": ")
    rootnode["xiahunLabelname"]:setString(data_item_money[param.coinType[2]].name .. ": ")


    self._clearCD_node = rootnode["clearCD_node"]
    self._fight10Btn = rootnode["fight10Btn"]
    self._fightBtn = rootnode["fightBtn"] 
    local itemBg = rootnode["itemBg"] 

    rootnode["tag_item_" .. _grade]:setVisible(true)

    local _passed = false       -- 此类型是否通过 
    local _abovePass = true     -- 上一类型是否通过 

    if _star >= _grade  then 
        _passed = true  
    elseif _grade > 1 then 
        if (_grade - 1) > _star then
            _abovePass = false 
        end
    end

    self._passed = _passed

    if _passed then
        rootnode["gray_node"]:setVisible(false)

        if self._lianzhanCnt <= 0 then
            self._fight10Btn:setVisible(false)
        else

            self._fight10Btn:setVisible(true)
            self._fight10Btn:addHandleOfControlEvent(function(eventName,sender) 
                self:setBtnDisabled() 
                GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
                if _lianzhanFight then
                    _lianzhanFight(_grade)
                end 
            end, CCControlEventTouchUpInside)

            if self._secWait > 0 then
                self._clearCD_node:setVisible(true)
                rootnode["goldNumLbl"]:setString(_needGold)
                self._fight10Btn:setTitleForState(CCString:create(tostring(format_time(self._secWait))), CCControlStateNormal)
                resetctrbtnimage(self._fight10Btn, "#levelinfo_btn_zhantimes_wait.png")  

            else
                self._fight10Btn:setTitleForState(CCString:create(self._lianzhanCnt ), CCControlStateNormal)
                resetctrbtnimage(self._fight10Btn, "#levelinfo_btn_zhantimes.png")  
            end

            self:schedule(function()
                if self._secWait > 0 then 
                    self._secWait = self._secWait - 1
                    if self._secWait <= 0 then
                        self:updateBtnMsg(self._lianzhanCnt)
                    else
                        self._fight10Btn:setTitleForState(CCString:create(tostring(format_time(self._secWait))), CCControlStateNormal)
                    end
                end
            end, 1)
        end

    else

        if not _abovePass then 
            self._fightBtn:setEnabled(false)
        end

        self._fight10Btn:setVisible(false)

        if _grade > 1 and not _abovePass then
            local iconKey = "tag_icon_" .. _grade
            rootnode[iconKey]:setColor(ccc3(100,100,100))

            local icon
            if _grade == 2 then
                icon = display.newGraySprite("#levelinfo_normal_icon.png",{0.1, 0.3, 0.5, 0.1})
            elseif _grade == 3 then
                icon = display.newGraySprite("#levelinfo_hard_icon.png",{0.1, 0.3, 0.5, 0.1})
            end

            icon:setPosition(rootnode[iconKey]:getPosition())
            rootnode["gray_node"]:addChild(icon)
        else 
            rootnode["gray_node"]:setVisible(false)
        end
    end 

    self._fightBtn:addHandleOfControlEvent(function(eventName,sender)
        self:setBtnDisabled() 
        GameAudio.playSound(ResMgr.getSFX(SFX_NAME.u_queding))
        if(self.isPressed == false) then
            self.isPressed =  true
            ResMgr.createMaskLayer()
            ResMgr.removeMaskLayer()
            if _fight then
                PostNotice(NoticeKey.REMOVE_TUTOLAYER)
                _fight(_grade,_passed)
                self.isPressed = false
            end
        end

    end, CCControlEventTouchUpInside)

   
    local btn = rootnode["fightBtn"]
    TutoMgr.addBtn("niujiacunliebiao1_btn_guankaxinxi1",btn)

end


function LevelGradeItem:setBtnEnabled(b) 
    if self._fightBtn ~= nil then
        self._fightBtn:setEnabled(b)
    end

    if self._fight10Btn ~= nil then 
        self._fight10Btn:setEnabled(b)
    end
end


function LevelGradeItem:setBtnDisabled()
    self:setBtnEnabled(false)
    self:performWithDelay(function()
        self:setBtnEnabled(true)
    end, 1.5)
end


function LevelGradeItem:buyUpdate(lianzhanCnt)
    if self._passed == true then
        self._lianzhanCnt = lianzhanCnt or self._lianzhanCnt
        self._fight10Btn:setVisible(true)
    end
end



function LevelGradeItem:updateBtnMsg(lianzhanCnt)
    self._secWait = 0
    local curNum = lianzhanCnt or self._lianzhanCnt
    self._lianzhanCnt = curNum
    self._clearCD_node:setVisible(false)
    if self._passed == true then
        if self._lianzhanCnt > 0 then
            self._fight10Btn:setVisible(true)
        end

        if self._lianzhanCnt > 0 then 
            self._fight10Btn:setTitleForState(CCString:create("战" .. self._lianzhanCnt .. "次"), CCControlStateNormal)
            resetctrbtnimage(self._fight10Btn, "#levelinfo_btn_zhantimes_wait.png")  
        else
            self._fight10Btn:setVisible(false)
        end
    end
end


function LevelGradeItem:onExit()
    TutoMgr.removeBtn("niujiacunliebiao1_btn_guankaxinxi1")
    self:unscheduleUpdate()
end



return LevelGradeItem
