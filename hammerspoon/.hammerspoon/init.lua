---@diagnostic disable: undefined-global
-- ══════════════════════════════════════════════════════
--  Nord Workflow - 一键借还系统 (Hammerspoon)
-- ══════════════════════════════════════════════════════
local AS_PATH = "/opt/homebrew/bin/aerospace"

local borrowHistory = {}

-- ══════════════════════════════════════════════════════
--  幽灵工作区配置
-- ══════════════════════════════════════════════════════
local GHOST_WS = "ghost"
local PASSWORD = "command123"
local LAST_WS = "1"
local inGhost = false -- 授权状态追踪

-- 异步执行命令（不阻塞）
local function asyncExec(cmd)
	hs.task.new("/bin/sh", nil, { "-c", cmd }):start()
end

local function getCurrentWorkspace()
	local f = io.popen(AS_PATH .. " list-workspaces --focused")
	if not f then
		return "1"
	end
	local ws = (f:read("*a") or ""):gsub("%s+", "")
	f:close()
	return ws ~= "" and ws or "1"
end

local function enterGhostWorkspace()
	local button, input = hs.dialog.textPrompt("受限区域", "请输入访问密码：", "", "确认", "取消", true)
	if button == "取消" then
		return
	end
	if input == PASSWORD then
		LAST_WS = getCurrentWorkspace()
		inGhost = true
		asyncExec(AS_PATH .. " workspace " .. GHOST_WS)
		hs.alert.show("已进入幽灵工作区", 1.5)
	else
		hs.alert.show("密码错误", 1.5)
	end
end

local function leaveGhostWorkspace()
	inGhost = false
	asyncExec(AS_PATH .. " workspace " .. LAST_WS)
	hs.alert.show("已离开幽灵工作区", 1.5)
end

-- ctrl-0：进入 / 离开幽灵工作区
hs.hotkey.bind({ "ctrl" }, "0", function()
	if inGhost then
		leaveGhostWorkspace()
	else
		enterGhostWorkspace()
	end
end)

-- 防止从 AeroSpace 菜单绕过密码直接进入幽灵区
local ghostWatcher = hs.timer.new(0.5, function()
	if inGhost then
		return
	end
	if getCurrentWorkspace() == GHOST_WS then
		asyncExec(AS_PATH .. " workspace " .. LAST_WS)
		hs.alert.show("禁止直接访问", 1.5)
	end
end)
ghostWatcher:start()

-- ══════════════════════════════════════════════════════
--  一键借还系统
-- ══════════════════════════════════════════════════════

-- 获取所有窗口信息
local function getAeroChoices()
	local f_current = io.popen(AS_PATH .. " list-workspaces --focused")
	local currentWS = "1"
	if f_current then
		currentWS = (f_current:read("*a") or ""):gsub("%s+", "")
		f_current:close()
	end

	local choices = {}
	local f =
		io.popen(AS_PATH .. " list-windows --all --format '%{window-id}#%{app-name}#%{window-title}#%{workspace}'")
	if not f then
		return choices
	end
	local output = f:read("*a")
	f:close()

	for line in output:gmatch("[^\r\n]+") do
		local parts = {}
		for part in (line .. "#"):gmatch("(.-)#") do
			table.insert(parts, part)
		end
		local id, app, title, ws = parts[1], parts[2], parts[3], parts[4]
		if id and id ~= "" then
			local wsClean = ws:gsub("%s+", "")
			local isCurrent = (wsClean == currentWS)
			local tag = ""
			if title:find("学习") then
				tag = " [学习]"
			end
			if title:find("娱乐") then
				tag = " [娱乐]"
			end
			local displayInfo = isCurrent and " (当前区)" or " (区 " .. wsClean .. ")"
			table.insert(choices, {
				text = app .. tag .. displayInfo,
				subText = title,
				winID = id,
				originWS = wsClean,
				order = isCurrent and 2 or 1,
			})
		end
	end

	table.sort(choices, function(a, b)
		return a.order < b.order
	end)
	return choices
end

-- Alt + Shift + Space：一键借还
hs.hotkey.bind({ "alt", "shift" }, "space", function()
	local f_win = io.popen(AS_PATH .. " list-windows --focused --format '%{window-id}#%{app-name}#%{workspace}'")
	if not f_win then
		return
	end
	local win_output = f_win:read("*a")
	f_win:close()

	local focusedID, appName, currentWS = win_output:match("(%d+)#(.-)#(%d+)")
	if focusedID then
		focusedID = focusedID:gsub("%s+", "")
	end
	if currentWS then
		currentWS = currentWS:gsub("%s+", "")
	end

	local targetWS = nil
	if focusedID then
		targetWS = borrowHistory[focusedID]
		-- Kitty 兜底：不在区 1 时默认归还到区 1
		if not targetWS and appName and appName:lower():find("kitty") and currentWS ~= "1" then
			targetWS = "1"
		end
	end

	if targetWS then
		-- 归还
		asyncExec(AS_PATH .. " move-node-to-workspace --window-id " .. focusedID .. " " .. targetWS)
		borrowHistory[focusedID] = nil
		hs.alert.show("已归还至区 " .. targetWS)
	else
		-- 借调
		local choices = getAeroChoices()
		local chooser = hs.chooser.new(function(choice)
			if not choice then
				return
			end
			borrowHistory[choice.winID] = choice.originWS
			asyncExec(AS_PATH .. " move-node-to-workspace --window-id " .. choice.winID .. " " .. currentWS)
			hs.timer.doAfter(0.1, function()
				asyncExec(AS_PATH .. " workspace " .. currentWS)
				hs.timer.doAfter(0.05, function()
					asyncExec(AS_PATH .. " focus --window-id " .. choice.winID)
				end)
			end)
			hs.alert.show("已借调: " .. choice.text)
		end)
		chooser:bgDark(true)
		chooser:placeholderText("搜索要借调的窗口 (对准已借调窗口按快捷键可归还)")
		chooser:choices(choices)
		chooser:show()
	end
end)

-- ══════════════════════════════════════════════════════
--  基础维护
-- ══════════════════════════════════════════════════════
hs.hotkey.bind({ "alt" }, "r", hs.reload)
hs.alert.show("Nord Workflow Ready")
