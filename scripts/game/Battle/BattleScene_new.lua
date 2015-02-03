
require("data.data_level_level")

local RESULT_ZORDER = 3000
local LEVELUP_ZORDER = 3001


local BattleScene = class("BattleScene",function ()

	return display.newScene("BattleScene")
end)

function BattleScene:sendReq(curWave)
print("curWave"..curWave)
	RequestHelper.sendNormalBattle({
		id = self.levelID,
		type = self.gradeID,
		callback = function(data)
			print("normal zhandou ")
			-- dump(data)
			-- dump(data["2"][1].f1)
			-- dump(data["2"][1].f2)
			-- dump(data["2"][1].d.rounds)
			-- dump(data["2"][1].d.rounds[1].smallList)

			for i, v in ipairs(data["2"][1].d.rounds) do 
				dump("=================")
				dump(v.n)
				for j, d in ipairs(v.smallList) do 
					for k, l in ipairs(d.fightVOList) do 
						dump(l.props) 
					end 
				end 
			end 

			-- 副本副本 战斗胜利则扣除体力，战斗失败则不扣除体力 
			local endData = data["2"][1].d["end"] 
			local win = endData["win"] 
			if win ~= nil and win == 1 then 
				game.player:setStrength(game.player.m_strength - self.needPower)  
			end 

			self.battleLayer:battleCallBack(data)
			
		end
		})
end


function BattleScene:result(data)
	self.battleData = data["2"][1]
	local submapID = game.player.m_cur_normal_fuben_ID --获取当前副本ID
	print("normal id"..submapID)

	local win = self.battleData.d["end"]["win"] 

	self.rewardItem = data["3"]
	self.rewardCoin = data["4"]

	local beforeLevel 
	local curlevel 
	local curExp 

	local function checkExp( data )
	    beforeLevel = game.player.getLevel()  -- 之前等级
	    curlevel = data["5"] or beforeLevel 
	    curExp = data["6"] or 0 


	    -- 当前等级的最大exp,读表
	    game.player:updateMainMenu({
	        lv = curlevel, 
	        exp = curExp,
	        maxExp = data_level_level[curlevel].exp
	        })

	end 
	
	checkExp(data)

	local resultLayer = require("game.Battle.BattleResult").new({
		win = win,
		rewardItem = self.rewardItem,
		rewardCoin = self.rewardCoin,
		levelName = data_battle_battle[self.levelID].name,
		gradeID = self.gradeID,
		star = self.star,
		maxStar = data_battle_battle[self.levelID].star, 
		jumpFunc = function()
		print("jumpfunc")
			
		end,
		curLv = curlevel,
		befLv = beforeLevel
		})

	resultLayer:setJumpFunc(function() 
		local submapID = game.player.m_cur_normal_fuben_ID 
        local clickedBigMapId = data_field_field[submapID].world 
        
		RequestHelper.getLevelList({
                    id = clickedBigMapId, 
                    callback = function(data)
                        -- dump(data)           
                        local bgName = "bigmap_1"
                        if data["0"] == "" then

                        	local isOpenNewBigmap = false 
                        	if game.player:getBattleData().cur_bigMapId ~= 0 and  data["1"] > game.player:getBattleData().cur_bigMapId then 
                        		isOpenNewBigmap = true 
                        	end 

                        	game.player:setBattleData({
		                        cur_bigMapId = data["1"], 
		                        new_subMapId = data["2"], 
		                        isOpenNewBigmap = isOpenNewBigmap 
		                    })

                            -- self._curLevel = {
                            --     bigMap = data["1"],  --大地图
                            --     subMap = data["2"],  --小地图
                            --     level  = data["3"]   --小关卡
                            -- }
                            -- self._subMap = data["4"]        

                            -- 大地图背景    
                            -- 默认为最大关卡地图，否则根据选择显示
                            -- local mapId = bigMapID or data["1"]
                            -- bgName = data_world_world[mapId].background

                            -- 世界地图背景音乐
                            -- local soundName = ResMgr.getSound(data_world_world[data["1"]].bgm)
                            -- GameAudio.playMusic(soundName, true)
                            
                            -- 打到的最大关卡
                            game.player.m_maxLevel = data["3"]
                            -- print("data[3].."..data[3])

                            -- initBg(bgName)
                            -- init()
                            -- initLevelChoose()
                             GameStateManager:ChangeState( GAME_STATE.STATE_SUBMAP, {submapID = submapID, subMap = data["4"]}) 

                        else

                        end

                    end
                })
		end)

	self:addChild(resultLayer,RESULT_ZORDER)	

	self:checkIsLevelup({
		beforeLevel = beforeLevel, 
		curlevel = curlevel, 
		curExp = curExp 
		}) 
 
end

-- 判断是否升级
function BattleScene:checkIsLevelup(param) 
 	local beforeLevel = param.beforeLevel
 	local curlevel = param.curlevel 

    -- 判断是否升级
    if beforeLevel < curlevel then
    	local curExp = param.curExp 
        local curNail = game.player:getNaili()
        self:addChild(require("game.Shengji.ShengjiLayer").new({level = beforeLevel, uplevel = curlevel, naili = curNail, curExp = curExp}), LEVELUP_ZORDER)
    end
end


function BattleScene:ctor(levelID, gradeID, star, needPower,isPassed)
    game.runningScene = self
	display.addSpriteFramesWithFile("ui/ui_battle.plist", "ui/ui_battle.png")

	self.levelID = levelID
	self.gradeID = gradeID
	self.star = star
	self.needPower = needPower or 0 
	self.isPassed = isPassed or false	

	self.reqFunc = function(curWave)
		self:sendReq(curWave)
	end

	self.resultFunc = function(data)
		self:result(data)
	end

	self.battleLayer = require("game.Battle.BattleLayer").new({
		fubenType = NORMAL_FUBEN,
		fubenId = self.levelID,
		reqFunc = self.reqFunc,
		resultFunc = self.resultFunc,
		star = star,
		isPassed = self.isPassed
		})
	self:addChild(self.battleLayer)

	
    -- if(GAME_DEBUG == true) then
    --     ResMgr.showTextureCache(  )
    -- end

end

function BattleScene:onExit( ... )
	CCTextureCache:sharedTextureCache():removeUnusedTextures()
	-- display.removeUnusedSpriteFrames()
	-- print("BattleScene:onExit")
	self:removeAllChildren()
end

return BattleScene