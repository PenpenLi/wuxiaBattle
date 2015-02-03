--[[
 --
 -- add by vicky
 -- 2014.12.30
 --
 --]]


 -- 帮派职位 
 GUILD_JOB_TYPE = {
 	normal = 0, 	-- 0:普通人员1:长老2:副帮主3:帮主
 	elder = 1, 
 	assistant = 2, 
 	leader = 3 
 }

 -- 帮派职务名称 
 GUILD_JOB_NAME = {
 	"成员", 
 	"长老", 
 	"副帮主", 
 	"帮主", 
 }


 -- 建筑ID:1大殿，2作坊，3商店，4后山地洞，5青龙堂，6白虎堂, 7副本
 GUILD_BUILD_TYPE = {
 	dadian = 1, 
 	zuofang = 2, 
 	shop = 3, 
 	houshandidong = 4, 
 	qinglong = 5, 
 	baihu = 6, 
 	fuben = 7 
 }

 -- 建筑名称 
 GUILD_BUILD_NAME = { 
 	"帮派大殿", 
 	"帮派作坊", 
 	"帮派商店", 
 	"后山地洞", 
 	"青龙堂", 
 	"白虎堂", 
 	"帮派副本", 
 }

 -- 帮派福利类型  
 GUILD_FULIITEM_TYPE = {
    weekly = 1,         -- 每周福利 
    barbecue = 2,       -- 烧烤大会  
 }


 -- 福利是否已开启状态  0已开启1未开启2已结束 
 GUILD_FULI_OPEN_TYPE = {
 	hasOpen = 0, 	-- 已开启
 	notOpen = 1, 	-- 未开启
 	hasEnd  = 2, 	-- 已结束 
 }


 -- 作坊工作类型 overtimeflag：是否加班生产0是1否
 GUILD_ZF_WORK_TYPE = {
	fast   = 0, 	-- 加班生产 
 	normal = 1, 	-- 普通生产
 }


 -- 青龙堂 今日挑战状态 【1-未开启 2-进行中 3-结束】 
 GUILD_QL_CHALLENGE_STATE = {
 	notOpen = 1, 
 	hasOpen = 2, 
 	hasEnd = 3, 
 }









