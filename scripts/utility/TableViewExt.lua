--
-- Created by IntelliJ IDEA.
-- User: douzi
-- Date: 14-6-16
-- Time: 下午6:34
-- To change this template use File | Settings | File Templates.
--

local TableViewExt = class("TableViewExt", function()
    return display.newNode()
end)

--kCCScrollViewDirectionVertical     上下滑动
--kCCScrollViewDirectionHorizontal   水平滑动

function TableViewExt:onEnter()

        RegNotice(self,
        function()
            -- print("llllooooockkktable")
            -- self:setTouchEnabled(false)   
            self:setBounceable(false)   
        end,
        NoticeKey.LOCK_TABLEVIEW)

        RegNotice(self,
        function()
            -- print("unnnnnlllooockkktable")
            -- self:setTouchEnabled(true)   
            self:setBounceable(true)      
        end,
        NoticeKey.UNLOCK_TABLEVIEW)
end

function TableViewExt:onExit()
        UnRegNotice(self,NoticeKey.LOCK_TABLEVIEW)
        UnRegNotice(self,NoticeKey.UNLOCK_TABLEVIEW)
end


function TableViewExt:ctor(param)
    local _viewSize    = param.size          --可视区域
    local _direction   = param.direction or kCCScrollViewDirectionHorizontal    --滑动方向
    local _createFunc  = param.createFunc    --创建节点函数
    local _refreshFunc = param.refreshFunc   --刷新节点函数
    local _cellNum     = param.cellNum  or 0   --节点个数
    local _cellSize    = param.cellSize      --每个节点大小
    local _touchFunc   = param.touchFunc
    local _scrollFunc  = param.scrollFunc

    self:setNodeEventEnabled(true)

    assert(_createFunc, "createFunc is nil")
    assert(_refreshFunc, "refreshFunc is nil")
    assert(_cellSize, "cellSize is nil")

    local tableView = CCTableView:create(_viewSize)
    tableView:setDirection(_direction)
    self:addChild(tableView)

    self.getContentSize = function()
        return _viewSize
    end

    if _direction == kCCScrollViewDirectionVertical then
        tableView:setVerticalFillOrder(kCCTableViewFillTopDown)
    end

    local function scrollViewDidScroll(view)
        if _scrollFunc ~= nil then 
            _scrollFunc()
        end
    end

    local function scrollViewDidZoom(view)
--        printf("scrollViewDidZoom")
    end

    local function tableCellTouched(view, cells)

        if _touchFunc then
            _touchFunc(cells)
        end
    end

    local function cellSizeForTable(view, idx)
        -- printf("cell size x = %f, y = %f", _cellSize.width, _cellSize.height)
        return _cellSize.height, _cellSize.width
    end

    local function tableCellAtIndex(view, idx)
        local cell = view:dequeueCell()
        if nil == cell then
            cell = safe_call(c_func(_createFunc, idx))
            if cell == nil then
                cell = CCTableViewCell:new()
            end
        else
            safe_call(c_func(_refreshFunc, cell, idx))
        end
        return cell
    end

    local function numberOfCellsInTableView(t)
        return _cellNum
    end

    tableView:registerScriptHandler(scrollViewDidScroll, CCTableView.kTableViewScroll)
    tableView:registerScriptHandler(scrollViewDidZoom, CCTableView.kTableViewZoom)
    tableView:registerScriptHandler(tableCellTouched, CCTableView.kTableCellTouched)
    tableView:registerScriptHandler(cellSizeForTable, CCTableView.kTableCellSizeForIndex)
    tableView:registerScriptHandler(tableCellAtIndex, CCTableView.kTableCellSizeAtIndex)
    tableView:registerScriptHandler(numberOfCellsInTableView, CCTableView.kNumberOfCellsInTableView)
    tableView:reloadData()
--    tableView:setTouchSwallowEnabled(true)

    self.setTouchSwallowEnabled = function(_, b)
        tableView:setTouchSwallowEnabled(b)
    end

    self.getCellNum = function(_)
        return _cellNum
    end

    self.reloadData = function(_)
        tableView:reloadData()
    end

    self.cellAtIndex = function(_, idx)
        return tableView:cellAtIndex(idx)
    end

    self.reloadCell = function(_, idx, cellData)
        local cell = tableView:cellAtIndex(idx)
        if cell then
            cell:refresh(cellData)
        end
    end

    self.resetListByNumChange = function(_,num)
    --如果列表中的cell数目发生了变化，则重置所有数据
        local beginNum = _cellNum
        local endNum = num
        if beginNum == endNum then
            self:reArrangeCell(num)
        else
            self:resetCellNum(num,false,false)
        end
        
    end

    self.resetCellNum = function(_, num, bSetOffset,isArrange)
    local isArr = isArrange
    if isArr == false then
        local offset
        if bSetOffset then
             offset = tableView:getContentOffset()
        end

        _cellNum = num
        tableView:reloadData()

        if bSetOffset then
             tableView:setContentOffset(offset)
        end
    else
       self:reArrangeCell(num)
   end

    end

    self.reArrangeCell = function(_,num)
        local offset = tableView:getContentOffset()
        local beginNum = _cellNum
        local endNum = num


        if _direction == kCCScrollViewDirectionVertical then
            local offHeight = _cellSize.height
            offset.y = offset.y + offHeight * (beginNum - endNum)           
        else
            local offWidth = _cellSize.width
            offset.x = offset.x - offWidth * (beginNum - endNum)
        end

         _cellNum = num

         --reloadData会调用didscroll方法，所以在这段期间 要禁用记录页面记忆
        PageMemoModel.isAllowRecord = false
        tableView:reloadData()
        tableView:setContentOffset(offset)
        PageMemoModel.isAllowRecord  = true
    end

    self.getDirection = function(_)
        
        return tableView:getDirection()
    end

    self.setContentOffset = function(_, offset, animated)
        tableView:setContentOffset(offset, animated)
    end

    self.dequeueCell = function(_)
        return tableView:dequeueCell()
    end

    self.getViewSize = function(_)
        return _viewSize
    end

    self.maxContainerOffset = function(_)
        return tableView:maxContainerOffset()
    end

    self.minContainerOffset = function(_)
        return tableView:minContainerOffset()
    end

    self.getContentOffset = function(_)
        return tableView:getContentOffset()
    end
    self.getContainer = function(_)
        return tableView:getContainer()
    end

    self.setDirection = function (_, dir )
        tableView:setDirection(dir)
    end

    self.setBounceable = function(_,isBounce)
        tableView:setBounceable(isBounce)
    end

    self.setTouchEnabled = function ( _, touched )
        tableView:setTouchEnabled(touched)
    end

    self.unscheduleAllSelectors = function(_)
        tableView:unscheduleAllSelectors()
    end

end

return TableViewExt
