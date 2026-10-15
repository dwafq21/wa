-- ============================================================================
-- ANTI-CHEAT BYPASS - FULL original (all pieces, per-game gated).
-- South Bronx: thread-killer + spoofed heartbeat + AC script/signal kill
-- BlockSpin:  __index/__newindex/traceback/info/fenv evasion suite
-- Universal / Road To Riches / Street Life / The Bronx / Town: DTC+Kill hook
-- Every block is pcall-guarded so a missing executor API can never break
-- the rest of the script. Runs first, before the main GUI.
-- ============================================================================
(function()
	if LPH_OBFUSCATED == nil then
		local assert = assert
		local type = type
		local setfenv = setfenv
		local _g = (type(getfenv) == "function" and getfenv(0)) or _G

		-- Use rawset so MoonVeil does not intercept these names as built-in macros
		local function _passnum(v)
			if v == nil then
				return 0
			end
			return v
		end

		local function _passstr(v)
			if v == nil then
				return ""
			end
			return v
		end

		local function _passfunc(f)
			return f
		end

		rawset(_g, "LPH_ENCNUM", _passnum)
		rawset(_g, "LPH_NUMENC", _passnum)
		rawset(_g, "LPH_ENCSTR", _passstr)
		rawset(_g, "LPH_STRENC", _passstr)
		rawset(_g, "LPH_ENCFUNC", _passfunc)
		rawset(_g, "LPH_FUNCENC", _passfunc)
		rawset(_g, "LPH_JIT", _passfunc)
		rawset(_g, "LPH_JIT_MAX", _passfunc)
		rawset(_g, "LPH_NO_VIRTUALIZE", _passfunc)
		rawset(_g, "LPH_NO_UPVALUES", _passfunc)
		rawset(_g, "LPH_CRASH", function()
			game:Shutdown()

			while true do
			end
		end)
		rawset(_g, "LRM_IsUserPremium", false)
		rawset(_g, "LRM_LinkedDiscordID", "0")
		rawset(_g, "LRM_ScriptName", "Bleh Hub")
		rawset(_g, "LRM_TotalExecutions", 0)
		rawset(_g, "LRM_SecondsLeft", math.huge)
		rawset(_g, "LRM_UserNote", "Developer")
	end

	local Game_Name = (game.PlaceId == 4991214437 and "Town")
		or (game.PlaceId == 18642421777 and "The Bronx")
		or (game.PlaceId == 16472538603 and "The Bronx")
		or (game.PlaceId == 13643807539 and "South Bronx")
		or (game.PlaceId == 93612682780562 and "South Bronx")
		or (game.PlaceId == 14413475235 and "South Bronx")
		or (game.PlaceId == 104715542330896 and "BlockSpin")
		or (game.PlaceId == 71600459831333 and "Street Life")
		or "Universal"

	if type(getexecutorname) ~= "function" and type(identifyexecutor) == "function" then
		getexecutorname = identifyexecutor
	end

	local Solara = false

	pcall(function()
		if type(getexecutorname) == "function" then
			local name = tostring(getexecutorname())
			Solara = string.match(name, "Solara") == "Solara" or string.match(name, "Xeno") == "Xeno"
		end
	end)

	local cloneref = cloneref or function(...)
		return ...
	end

	local Services = setmetatable({}, {
		__index = LPH_NO_VIRTUALIZE(function(self, service, key)
			if Solara and (service == "VirtualInputManager") and (Game_Name == "The Bronx") then
				return {
					SendKeyEvent = function()
					end,
				}
			end

			return cloneref(game:GetService(service))
		end),
	})

	-- ============================================================================
	-- South Bronx part 1: locates + kills anti-cheat threads, spoofed heartbeat
	-- ============================================================================
	if Game_Name == "South Bronx" and not Solara then
		pcall(function()
			local _getallthreads = LPH_JIT_MAX(function()
				local threads = {}

				for i, v in getreg() do
					if type(v) == "thread" then
						table.insert(threads, v)
					end
				end

				return threads
			end)

			local _gettenv = LPH_JIT_MAX(function(Thread)
				return getfenv(debug.info(Thread, 1, "f"))
			end)

			if gettenv then
				_gettenv = gettenv
			end

			local Filter_Nil_Instances = LPH_JIT_MAX(function(Name)
				local Found = nil

				for _, Object in getnilinstances() do
					if tostring(Object):find(Name) then
						Found = Object
					end
				end

				return Found
			end)

			local Filter_Table = LPH_JIT_MAX(function(Table, Name)
				local Found, Index = nil, nil

				for _, Object in Table do
					if tostring(_):lower():find(tostring(Name):lower()) then
						Found = Object
						Index = _
					end
				end

				return Found, Index
			end)

			local Search_Threads = LPH_JIT_MAX(function(Table, Variable)
				local Threads = {}

				for NO, _thread in pairs(Table) do
					local T_ENV = _gettenv(_thread)

					if T_ENV[Variable] then
						table.insert(Threads, _thread)
					end
				end

				return Threads
			end)

			local Get_AntiCheat_Threads = LPH_JIT_MAX(function()
				local Threads = _getallthreads()
				local WeHaveAHacker = Search_Threads(Threads, "WeHaveAHacker")

				if WeHaveAHacker[1] then
					return WeHaveAHacker
				end
			end)

			local AntiCheat_Threads = {}
			local AntiCheat_Encoded = {
				[1] = "iFPjbrlufvSzsYurCCdWeFbPeNBWzxywGWLNpzgQVVvkLaoDJjImgWFETWVzc2FnZVR5cGU=",
				[2] = "AjimhYxuTcBxLtetPTqLQKsdsjDiWNpsPSoXToFfvftufSnLTemZUVKTWVzc2FnZVUlZm8=",
				[3] = "VFevcWxuZHlvFWejJERNXupJDNxvjnIBPHBNZgSMHNOeQURICksIFETWVzc2FnZVR5cGU=",
				[4] = "RJLHPqjgyYwiGKfgSdISiCpvzGmdJKBkWUMMZHxtipCmivjZdXzDWsTWVzc2FnZUlDHbIdA==",
			}

			local Anti_Cheat_Script = Filter_Nil_Instances("?")

			if not Anti_Cheat_Script then
				repeat
					task.wait()
					Anti_Cheat_Script = Filter_Nil_Instances("?")
				until Anti_Cheat_Script ~= nil
			end

			local AntiCheat_Function, Function_Index = Filter_Table(getsenv(Anti_Cheat_Script), "HPv")

			if not AntiCheat_Function then
				repeat
					task.wait()
					Anti_Cheat_Script = Filter_Nil_Instances("?")
					AntiCheat_Function, Function_Index = Filter_Table(getsenv(Anti_Cheat_Script), "HPv")
				until AntiCheat_Function ~= nil
			end

			local Killable_Threads = { [1] = true, [3] = true, [4] = true }

			local XVNP_L = LPH_JIT_MAX(function(...)
				local Random_Message = AntiCheat_Encoded[math.random(1, #AntiCheat_Encoded)]
				return AntiCheat_Function(Random_Message)
			end)

			Services.RunService.RenderStepped:Connect(LPH_JIT_MAX(function()
				AntiCheat_Threads = Get_AntiCheat_Threads()

				if AntiCheat_Threads then
					for i = 1, #AntiCheat_Threads do
						local Thread = AntiCheat_Threads[i]

						if Thread and Killable_Threads[i] == true then
							task.cancel(Thread)
						end
					end
				end

				XVNP_L()
			end))

			task.wait(0)
		end)
	end

	-- ============================================================================
	-- BlockSpin: anti-executor / anti-cheat evasion hooks
	-- ============================================================================
	if Game_Name == "BlockSpin" and not Solara then
		pcall(function()
			local Required = {
				"hookfunction",
				"getconnections",
				"isexecutorclosure",
				"hookmetamethod",
				"getrenv",
			}

			for _, v in next, Required do
				-- skip (do not kick) if the executor cannot provide a needed API
				if not getgenv()[v] and not _G[v] and not getfenv(0)[v] then
					return
				end
			end

			pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Ozzypig/repr/refs/heads/master/repr.lua"))()
			end)

			local OldDebugTraceback, OldDebugInfo, OldFenv = debug.traceback, debug.info, getfenv

			local BlacklistedRemoteArgumentNeedles = {
				"invalid_entry",
				"replicate_bil",
			}

			local BlacklistedCallerNeedles = {
				"Obfuscated",
			}

			if not shared.Hooking then
				shared.Hooking = {}
			end

			if not shared.Hooking.IncludeInStackFunctions then
				shared.Hooking.IncludeInStackFunctions = {}
			end

			shared.SafeHook = function(Original, Replacement)
				shared.Hooking.IncludeInStackFunctions[Original] = true
				return hookfunction(Original, Replacement)
			end

			local CoreGui = game:GetService("CoreGui")
			local RobloxGuis = {
				"RobloxGui",
				"TeleportGui",
				"RobloxPromptGui",
				"RobloxLoadingGui",
				"PlayerList",
				"RobloxNetworkPauseNotification",
				"PurchasePrompt",
				"HeadsetDisconnectedDialog",
				"ThemeProvider",
				"DevConsoleMaster",
			}

			local function FilterTable(InputTable)
				local OldContext = getthreadcontext()
				setthreadcontext(7)

				local Filtered = {}
				local GameInstance = game

				for Index, Value in ipairs(InputTable) do
					if typeof(Value) ~= "Instance" then
						table.insert(Filtered, Value)
					else
						if Value == CoreGui or Value == GameInstance then
							-- Insert only the default Roblox GUIs
							for _, GuiName in pairs(RobloxGuis) do
								local GuiInstance = CoreGui:FindFirstChild(GuiName)

								if GuiInstance then
									table.insert(Filtered, GuiInstance)
								end
							end

							if Value == GameInstance then
								for _, Child in pairs(GameInstance:GetChildren()) do
									if Child ~= CoreGui then
										table.insert(Filtered, Child)
									end
								end
							end
						else
							if not CoreGui:IsAncestorOf(Value) then
								table.insert(Filtered, Value)
							else
								-- Only include if it's a descendant of one of the default GUIs
								for _, DefaultGuiName in pairs(RobloxGuis) do
									local DefaultGuiInstance = CoreGui:FindFirstChild(DefaultGuiName)

									if DefaultGuiInstance then
										if Value == DefaultGuiInstance or DefaultGuiInstance:IsAncestorOf(Value) then
											table.insert(Filtered, Value)
											break
										end
									end
								end
							end
						end
					end
				end

				setthreadcontext(OldContext)
				return Filtered
			end

			local BlacklistedAssets = {}
			local ContentProvider = game:GetService("ContentProvider")

			local function ValidTraceback(s)
				local dotPos = string.find(s, "%.")
				local colonPos = string.find(s, ":")

				if not dotPos then
					return false
				end

				if not colonPos then
					return true
				end

				return dotPos < colonPos
			end

			local function TracebackLines(str)
				local pos = 1

				return function()
					if not pos then
						return nil
					end

					local p1, p2 = string.find(str, "\r?\n", pos)
					local line

					if p1 then
						line = str:sub(pos, p1 - 1)
						pos = p2 + 1
					else
						line = str:sub(pos)
						pos = nil
					end

					return line
				end
			end

			OldDebugTraceback = shared.SafeHook(getrenv().debug.traceback, function()
				if checkcaller() then
					return OldDebugTraceback()
				end

				local Traceback = OldDebugTraceback()
				local NewTraceback = {}

				for Line in TracebackLines(Traceback) do
					if not ValidTraceback(Line) then
						continue
					end

					table.insert(NewTraceback, Line)
				end

				return table.concat(NewTraceback, "\n")
			end)

			OldDebugInfo = shared.SafeHook(getrenv().debug.info, function(...)
				local ToInspect, LevelOrInfo, _ThreadInfo = ...

				if
					checkcaller()
					or typeof(ToInspect) == "function"
					or typeof(ToInspect) == "thread"
					or not pcall(function(LevelOrInfo) -- Validate arguments
						OldDebugInfo(function()
						end, LevelOrInfo)
					end, LevelOrInfo)
				then
					return OldDebugInfo(...)
				end

				local ReconstructedConstructedStack = {}

				for Level = 2, 19997 do
					local Function, Source, Line, Name, NumberOfArgs, Varargs = OldDebugInfo(Level, "fslna")

					if not Function or not Source or not Line or not Name then
						break
					end

					if isexecutorclosure(Function) and not shared.Hooking.IncludeInStackFunctions[Function] then
						continue
					end

					table.insert(ReconstructedConstructedStack, {
						f = Function,
						s = Source,
						l = Line,
						n = Name,
						a = { NumberOfArgs, Varargs },
					})
				end

				local InfoLevel = ReconstructedConstructedStack[ToInspect]

				if not InfoLevel then
					-- Max level is 19997 so this guarantees that it will return nothing
					return OldDebugInfo(3e4, LevelOrInfo)
				end

				local ReturnResult = {}

				for idx, info in string.split(LevelOrInfo, "") do
					local Value = InfoLevel[info]

					if typeof(Value) == "table" then
						for _, v in Value do
							table.insert(ReturnResult, v)
						end

						continue
					end

					table.insert(ReturnResult, Value)
				end

				return table.unpack(ReturnResult, 1, #ReturnResult)
			end)

			OldFenv = shared.SafeHook(getrenv().getfenv, function(...)
				if checkcaller() then
					return OldFenv(...)
				end

				local ToInspect = ...

				if ToInspect == 0 then
					return getrenv()
				elseif ToInspect == nil then
					return OldFenv(...)
				end

				local Success, ResultingEnv = pcall(function()
					if typeof(ToInspect) == "number" then
						return OldFenv(ToInspect + 3)
					end

					return OldFenv(ToInspect)
				end)

				if not Success then
					return OldFenv(...)
				end

				if typeof(ToInspect) == "function" then
					if typeof(ResultingEnv["getgenv"]) == "function" and isexecutorclosure(ResultingEnv["getgenv"]) then
						return getrenv()
					end

					return ResultingEnv
				end

				local ReconstructedConstructedStack = {}

				for Level = 2, 19997 do
					local StackInfoSuccess, Data = pcall(function()
						return {
							Environement = OldFenv(Level + 3),
							Function = OldDebugInfo(Level + 3, "f"),
						}
					end)

					if not StackInfoSuccess or not Data then
						break
					end

					local Environement = Data.Environement

					if typeof(Environement["getgenv"]) == "function" and isexecutorclosure(Environement["getgenv"]) then
						Environement = getrenv()
					end

					table.insert(ReconstructedConstructedStack, Environement)
				end

				local InfoLevel = ReconstructedConstructedStack[ToInspect]

				if not InfoLevel then
					-- Max level is 19997 so this guarantees that it will return error
					return OldFenv(3e4)
				end

				return InfoLevel
			end)

			-- Disable all blacklisted connections

			local BlacklistedSignals = {
				game:GetService("LogService").MessageOut,
				game:GetService("ScriptContext").Error,
			}

			local DummySignals = {}

			for _, Signal in next, BlacklistedSignals do
				for _, Connection in next, getconnections(Signal) do
					-- dawg why does volcano return a thread for Connection.Function
					if
						(Connection.Function and type(Connection.Function) == "function" and isexecutorclosure(Connection.Function))
						or Connection.Function == nil -- CoreScript connections return nil for Function
					then
						continue
					else
						Connection:Disable()
					end
				end
			end

			local OldIndex

			OldIndex = hookmetamethod(game, "__index", function(Self, Key)
				if checkcaller() then
					return OldIndex(Self, Key)
				end

				local Result = OldIndex(Self, Key)

				for _, BlacklistedSignal in next, BlacklistedSignals do
					if Result == BlacklistedSignal then
						if not DummySignals[BlacklistedSignal] then
							DummySignals[BlacklistedSignal] = Instance.new("BindableEvent").Event
						end

						return DummySignals[BlacklistedSignal]
					end
				end

				return Result
			end)

			local OldNewIndex

			OldNewIndex = hookmetamethod(game, "__newindex", function(Self, Key, Value)
				local AssetIndexes = {
					["MeshID"] = true,
					["TextureID"] = true,
					["MeshId"] = true,
					["TextureId"] = true,
					["Image"] = true,
					["SoundId"] = true,
					["AnimationId"] = true,
				}

				if AssetIndexes[Key] then
					local AssetId = Value

					if typeof(AssetId) == "string" then
						AssetId = tonumber(AssetId:match("%d+"))
					end

					if AssetId and not BlacklistedAssets[AssetId] then
						-- Check if the asset is already loaded so we don't accidentally blacklist a legitimate asset
						local AssetLoaded = false

						if
							ContentProvider:GetAssetFetchStatus("rbxassetid://" .. AssetId)
							== Enum.AssetFetchStatus.Success
						then
							AssetLoaded = true
						end

						if checkcaller() then
							if not AssetLoaded then
								BlacklistedAssets[AssetId] = true
							end
						else
							if BlacklistedAssets[AssetId] then
								-- The game is doing a sanity check where it intentionally loads a blacklisted asset
								-- to see if the executor is blocking it. We need to remove it from the blacklist
								-- so it doesn't get blocked.
								BlacklistedAssets[AssetId] = nil
							end
						end
					end
				end

				if Key == "CanCollide" and (not checkcaller()) then
					local Name = debug.info(3, "n")

					if Name and Name:match("Obfuscated") then
						return coroutine.yield()
					end
				end

				return OldNewIndex(Self, Key, Value)
			end)

			-- Now that we will proxy and record all assets the executor uses, we can load the hook.

			local OldPreloadAsync

			OldPreloadAsync = shared.SafeHook(ContentProvider.PreloadAsync, function(Self, Assets, OriginalCallback)
				if Self ~= ContentProvider or type(Assets) ~= "table" or type(OriginalCallback) ~= "function" then --note: callback can be nil but in that case it's useless anyways
					return OldPreloadAsync(Self, Assets, OriginalCallback)
				end

				--check for any errors that I might've missed (such as table being {[2] = "something"} which causes "Unable to cast to Array")
				local err

				task.spawn(function() --TIL calling a C yield function inside a C yield function is a bad idea ("cannot resume non-suspended coroutine")
					local s, e = pcall(OldPreloadAsync, Self, Assets)

					if not s and e then
						err = e
					end
				end)

				if err then
					return OldPreloadAsync(Self, Assets) --don't pass the callback, just in case
				end

				Assets = FilterTable(Assets)
				return OldPreloadAsync(Self, Assets, OriginalCallback)
			end)

			local Sprint_Module = require(game:GetService("ReplicatedStorage").Modules.Game.Sprint)
			local Function_Table_UpValue = debug.getupvalue(Sprint_Module.loaded, 11)

			local _getfenv

			_getfenv = hookfunction(getrenv().getfenv, LPH_NO_VIRTUALIZE(function(level)
				if debug.traceback():find("validity_check") then
					return setmetatable({}, {
						__index = function(...)
							return nil
						end,
					})
				end

				return _getfenv(level)
			end))

			getgenv().Send_Remote = Function_Table_UpValue.send
		end)
	end

	-- ============================================================================
	-- Universal / Road To Riches / Street Life / The Bronx / Town: Detect/Kill hook
	-- ============================================================================
	if Game_Name == "Universal" or Game_Name == "Road To Riches" or Game_Name == "Street Life" or Game_Name == "The Bronx" or (Game_Name == "Town" and not Solara) then
		pcall(function()
			local DTC

			LPH_NO_VIRTUALIZE(function()
				for Index, Value in next, getgc(true) do
					if type(Value) == "table" then
						local Detected = rawget(Value, "Detected")
						local Kill = rawget(Value, "Kill")

						if type(Detected) == "function" and not DTC then
							DTC = Detected
							hookfunction(Detected, function(...)
								return true
							end)
						end

						if rawget(Value, "Variables") and rawget(Value, "Process") and typeof(Kill) == "function" then
							hookfunction(Kill, function(...)
							end)
						end
					end
				end
			end)()

			local Old

			Old = hookfunction(getrenv().debug.info, LPH_NO_UPVALUES(function(...)
				local LevelOrFunc, Info = ...

				if DTC and LevelOrFunc == DTC then
					return coroutine.yield(coroutine.running())
				end

				return Old(...)
			end))
		end)
	end

	-- ============================================================================
	-- South Bronx part 2: Error signal kill, NPC loop block, Idled, gun module hook
	-- ============================================================================
	if Game_Name == "South Bronx" and not Solara then
		pcall(function()
			for Index, Value in getconnections(Services.ScriptContext.Error) do
				pcall(function()
					Value:Disable()
				end)

				pcall(function()
					Value:Disconnect()
				end)
			end

			for Index, Value in Services.ReplicatedStorage.Workspace.Homeless:GetChildren() do
				Value.Parent = Services.Workspace.Folders.HomelessPeople
			end

			for Index, Value in Services.Workspace.Folders.HomelessPeople:GetChildren() do
				Value:GetPropertyChangedSignal("Parent"):Connect(LPH_NO_VIRTUALIZE(function()
					task.wait()
					Value.Parent = Services.Workspace.Folders.HomelessPeople
				end))
			end

			for Index, Value in Services.ReplicatedStorage.Workspace.NPCs:GetChildren() do
				Value.Parent = Services.Workspace.Folders.NPCs
			end

			for Index, Value in Services.Workspace.Folders.NPCs:GetChildren() do
				Value:GetPropertyChangedSignal("Parent"):Connect(LPH_NO_VIRTUALIZE(function()
					task.wait()
					Value.Parent = Services.Workspace.Folders.NPCs
				end))
			end

			local task_wait_hook

			task_wait_hook = hookfunction(task.wait, LPH_NO_UPVALUES(function(...)
				local args = { ... }
				local traceback = debug.traceback()

				if args[1] == 2.5 and traceback:find("Loop") and traceback:find("NPCs") then
					return false
				end

				return task_wait_hook(...)
			end))

			for Index, Value in getconnections(Services.Players.LocalPlayer.Idled) do
				if Value["Disable"] then
					Value["Disable"](Value)
				end

				if Value["Disconnect"] then
					Value["Disconnect"](Value)
				end
			end

			local get_nil_instance = LPH_JIT_MAX(function(name, class)
				local found = nil

				for _, instance in getnilinstances() do
					local instanceName = instance.Name

					if class then
						if not instance:IsA(class) then
							continue
						end

						if instanceName:find(name) then
							found = instance
						end
					else
						if instanceName:find(name) then
							found = instance
						end
					end
				end

				return found
			end)

			repeat
				task.wait()
			until get_nil_instance("Gun", "ModuleScript")

			local gun_module = getsenv(get_nil_instance("Gun", "ModuleScript"))

			local old

			old = hookfunction(gun_module.x, LPH_NO_UPVALUES(function()
				return nil
			end))
		end)
	end

	-- ============================================================================
	-- South Bronx part 3: FireServer purchase-spoof freeze guard
	-- ============================================================================
	if Game_Name == "South Bronx" and not Solara then
		pcall(function()
			if type(hookfunction) ~= "function" then
				return
			end

			local Original = Instance.new("RemoteEvent", nil).FireServer
			local _FireServer
			local _Function

			_FireServer = hookfunction(Original, function(self, ...)
				local Arguments = { ... }

				if tostring(self) == "PurchaseItem" and Arguments[2] == "Shoes" and Arguments[3] == "YZ Slides" and Arguments[4] == "\255" then
					local getinfo = type(debug) == "table" and debug.getinfo

					if type(getinfo) == "function" then
						local Info = getinfo(2, "f")

						if Info and type(Info.func) == "function" then
							if not _Function then
								_Function = Info.func
							end

							if _Function ~= Info.func then
								while true do
								end

								return
							end
						end
					end
				end

				return _FireServer(self, ...)
			end)
		end)
	end
end)()

-- never block the rest of the script: flag is always registered when this runs
getgenv().AntiCheatBypass = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local genv = getgenv and getgenv() or _G

if type(genv.ACECodeSniperUnload) == "function" then
	pcall(genv.ACECodeSniperUnload)
end

local function huiParents()
	local list = {}

	if type(gethui) == "function" then
		local ok, res = pcall(gethui)

		if ok and res then
			table.insert(list, res)
		end
	end

	local ok, res = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and res then
		table.insert(list, res)
	end

	table.insert(list, playerGui)
	return list
end

for _, parent in ipairs(huiParents()) do
	pcall(function()
		local old = parent:FindFirstChild("ACECodeSniperUI")

		if old then
			old:Destroy()
		end
	end)
end

local COLORS = {
	Window = Color3.fromRGB(6, 6, 7),
	Row = Color3.fromRGB(15, 15, 17),
	Control = Color3.fromRGB(35, 35, 39),
	Log = Color3.fromRGB(10, 10, 16),
	Border = Color3.fromRGB(82, 82, 89),
	White = Color3.fromRGB(245, 245, 245),
	Text = Color3.fromRGB(190, 190, 196),
	Dim = Color3.fromRGB(120, 120, 130),
	Accent = Color3.fromRGB(245, 245, 245),
	Green = Color3.fromRGB(70, 210, 100),
	Red = Color3.fromRGB(255, 70, 70),
}

local WIN_W = 310
local WIN_H = 446
local HEADER_H = 64
local TAB_Y = 60
local PAGE_Y = 98
local CONTENT_X = 17
local CONTENT_W = 276

-- connections registered here are dropped when the gui unloads
local cleanupConnections = {}

-- one-shot restores (character state etc.) run on unload
local restoreCallbacks = {}

local function trackConnection(connection)
	table.insert(cleanupConnections, connection)
	return connection
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function label(parent, name, text, size, position, textSize, textColor, font)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = textSize
	l.TextColor3 = textColor
	l.Font = font or Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Parent = parent
	return l
end

local function pressable(button)
	local scale = Instance.new("UIScale")
	scale.Name = "PressScale"
	scale.Parent = button

	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.92 }):Play()
	end)

	local function release()
		TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	return scale
end

local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function createSwitch(parent, options)
	options = options or {}
	local size = options.size or UDim2.fromOffset(34, 18)
	local height = size.Y.Offset
	local knobSize = height - 4
	local onPos = UDim2.new(1, -(knobSize + 2), 0.5, -knobSize / 2)
	local offPos = UDim2.new(0, 2, 0.5, -knobSize / 2)

	local track = Instance.new("TextButton")
	track.Name = "Switch"
	track.Size = size
	track.Position = options.position or UDim2.new(1, -46, 0.5, -height / 2)
	track.AutoButtonColor = false
	track.Text = ""
	track.BorderSizePixel = 0
	track.ZIndex = options.zIndex or 6
	track.Parent = parent
	corner(track, height / 2)

	local trackStroke = stroke(track, COLORS.White, 1, 0.88)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(knobSize, knobSize)
	knob.BorderSizePixel = 0
	knob.ZIndex = (options.zIndex or 6) + 1
	knob.Parent = track
	corner(knob, knobSize / 2)

	pressable(track)

	local api = { state = options.state == true, Gui = track }

	local function apply(animate)
		local props = {
			BackgroundColor3 = api.state and COLORS.Accent or COLORS.Control,
		}
		local knobProps = {
			BackgroundColor3 = api.state and COLORS.Window or COLORS.White,
			Position = api.state and onPos or offPos,
		}
		local strokeProps = { Transparency = api.state and 0.62 or 0.88 }

		if animate then
			TweenService:Create(track, TWEEN_INFO, props):Play()
			TweenService:Create(knob, TWEEN_INFO, knobProps):Play()
			TweenService:Create(trackStroke, TWEEN_INFO, strokeProps):Play()
		else
			track.BackgroundColor3 = props.BackgroundColor3
			knob.BackgroundColor3 = knobProps.BackgroundColor3
			knob.Position = knobProps.Position
			trackStroke.Transparency = strokeProps.Transparency
		end
	end

	function api.Set(value, silent)
		value = value == true

		if value == api.state then
			return
		end

		api.state = value
		apply(true)

		if not silent and options.onChange then
			options.onChange(value)
		end
	end

	function api.Toggle()
		api.Set(not api.state)
	end

	track.MouseButton1Click:Connect(api.Toggle)
	apply(false)
	return api
end

-- ============================================================================
-- SILENT AIM ENGINE (original Bleh Hub silent aim, adapted for this GUI)
-- Config table + helpers + FOV/POV target picker + __namecall redirect +
-- snapline/FOV visuals. GUI rows added inside the TRIGGERBOT card below.
-- ============================================================================
if LPH_OBFUSCATED == nil then
	local assert = assert
	local type = type
	local setfenv = setfenv
	local _g = getfenv and getfenv(0) or _G

	local function _passnum(v)
		if v == nil then
			return 0
		end
		return v
	end

	local function _passstr(v)
		if v == nil then
			return ""
		end
		return v
	end

	local function _passfunc(f)
		return f
	end

	rawset(_g, "LPH_ENCNUM", _passnum)
	rawset(_g, "LPH_NUMENC", _passnum)
	rawset(_g, "LPH_ENCSTR", _passstr)
	rawset(_g, "LPH_STRENC", _passstr)
	rawset(_g, "LPH_ENCFUNC", _passfunc)
	rawset(_g, "LPH_FUNCENC", _passfunc)
	rawset(_g, "LPH_JIT", _passfunc)
	rawset(_g, "LPH_JIT_MAX", _passfunc)
	rawset(_g, "LPH_NO_VIRTUALIZE", _passfunc)
	rawset(_g, "LPH_NO_UPVALUES", _passfunc)
	rawset(_g, "LPH_CRASH", function()
		game:Shutdown()
		while true do
		end
	end)
end

local Game_Name = (game.PlaceId == 4991214437 and "Town") or (game.PlaceId == 18642421777 and "The Bronx") or (game.PlaceId == 16472538603 and "The Bronx") or (game.PlaceId == 13643807539 and "South Bronx") or (game.PlaceId == 93612682780562 and "South Bronx") or (game.PlaceId == 14413475235 and "South Bronx") or (game.PlaceId == 104715542330896 and "BlockSpin") or (game.PlaceId == 71600459831333 and "Street Life") or "Universal"

local Solara = false

pcall(function()
	if type(getexecutorname) ~= "function" and type(identifyexecutor) == "function" then
		getexecutorname = identifyexecutor
	end

	if type(getexecutorname) == "function" then
		local name = tostring(getexecutorname())
		Solara = string.match(name, "Solara") == "Solara" or string.match(name, "Xeno") == "Xeno"
	end
end)

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local mathrandom = math.random
local Mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

trackConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end))

local Config = {
	Game = {
		Ray_Systems = (Game_Name == "Road To Riches" and { "Raycast" })
			or (Game_Name == "BlockSpin" and { "Raycast" })
			or (Game_Name == "Town" and { "Raycast" })
			or (Game_Name == "Universal" and { "Raycast", "FindPartOnRay", "FindPartOnRayWithWhitelist" })
			or (Game_Name == "The Bronx" and { "FindPartOnRay" })
			or (Game_Name == "South Bronx" and { "Raycast" })
			or (Game_Name == "Street Life" and { "Raycast" })
			or (Game_Name == "Criminality" and { "Raycast" })
			or {},
	},
	Silent = {
		["Enabled"] = false,
		["Targetting"] = false,
		["TargetPart"] = { "Head" },
		["Mode"] = "nil",
		["MaxDistance"] = (Game_Name == "South Bronx") and 300 or 1000,
		["Keybind"] = nil,
		["WallCheck"] = false,
		["TeamCheck"] = false,
		["WallBang"] = false,
		["Priority"] = {},
		["Whitelisted"] = {},
		["DrawFieldOfView"] = false,
		["UseFieldOfView"] = false,
		["Radius"] = 100,
		["FieldOfViewColor"] = Color3.new(1, 1, 1),
		["FieldOfViewTransparency"] = 0.25,
		["Sides"] = 100,
		["HitChance"] = 100,
		["Snapline"] = false,
		["SnaplineColor"] = Color3.new(1, 1, 1),
		["Damage"] = 100,
		["SnaplineThickness"] = 1,
	},
	-- Aimlock (AIMBOT) - ported from the aimlock in the provided script
	-- (Aimlock > General Settings: General / Settings / Field Of View).
	Aimlock = {
		["Enabled"] = false,
		["Aiming"] = false,
		["TeamCheck"] = false,
		["WallCheck"] = false,
		["Type"] = "Camera",
		["TargetPart"] = "Head",
		["MaxDistance"] = (Game_Name == "South Bronx") and 300 or 1000,
		["Smoothness"] = 1,
		["Keybind"] = nil,
		["UseFieldOfView"] = true,
		["DrawFieldOfView"] = false,
		["Radius"] = 100,
		["Sides"] = 100,
		["FieldOfViewColor"] = Color3.new(1, 1, 1),
		["FieldOfViewTransparency"] = 0.25,
	},
}

-- function aliases (same style as the original hub)
local FindFirstChild = Workspace.FindFirstChild
local GetPlayers = Players.GetPlayers
local GetDescendants = Workspace.GetDescendants
local IsA = Workspace.IsA
local FindFirstChildOfClass = Workspace.FindFirstChildOfClass
local unpack = table.unpack or unpack

local DistanceCheck = LPH_NO_VIRTUALIZE(function(Player, Distance)
	if not Player then
		return false
	end

	if Player.Character and FindFirstChild(Player.Character, "HumanoidRootPart") then
		local Magnitude = (Camera.CFrame.Position - FindFirstChild(Player.Character, "HumanoidRootPart").Position).Magnitude
		return Distance > Magnitude
	end

	return false
end)

local WallCheck = LPH_NO_VIRTUALIZE(function(Character, TargetPart)
	TargetPart = TargetPart or (Character and FindFirstChild(Character, "Head"))
	if not Character or not TargetPart or not TargetPart:IsDescendantOf(Character) then
		return false
	end

	local LocalChar = LocalPlayer.Character
	local LocalHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")

	local Parameters = RaycastParams.new()
	Parameters.FilterDescendantsInstances = { LocalChar, Camera }
	Parameters.FilterType = Enum.RaycastFilterType.Blacklist
	Parameters.IgnoreWater = true

	local camOrigin = Camera.CFrame.Position
	local camDirection = TargetPart.Position - camOrigin
	local camResult = Workspace:Raycast(camOrigin, camDirection, Parameters)
	local camClear = (not camResult) or (camResult.Instance and camResult.Instance:IsDescendantOf(Character))

	local hrpClear = true
	if LocalHRP then
		local hrpOrigin = LocalHRP.Position
		local hrpDirection = TargetPart.Position - hrpOrigin
		local hrpResult = Workspace:Raycast(hrpOrigin, hrpDirection, Parameters)
		hrpClear = (not hrpResult) or (hrpResult.Instance and hrpResult.Instance:IsDescendantOf(Character))
	end

	return camClear and hrpClear
end)

local IsTeammate = LPH_NO_VIRTUALIZE(function(TargetPlayer)
	if not TargetPlayer then
		return false
	end

	local LocalCharacter = LocalPlayer.Character
	local TargetCharacter = TargetPlayer.Character

	if LocalCharacter and TargetCharacter then
		local LocalMatch = LocalCharacter:GetAttribute("MatchId")
		local TargetMatch = TargetCharacter:GetAttribute("MatchId")

		if LocalMatch ~= nil or TargetMatch ~= nil then
			local LocalTeam = LocalCharacter:GetAttribute("PvPTeam")
			local TargetTeam = TargetCharacter:GetAttribute("PvPTeam")
			return LocalMatch ~= nil
				and LocalMatch == TargetMatch
				and LocalTeam ~= nil
				and TargetTeam ~= nil
				and LocalTeam == TargetTeam
		end
	end

	-- Alkedion-style stage teams: Player attributes StageTeamSide (number 1/2).
	-- Both sides present -> equal side = teammate (mirrors TargetSelector.onSameTeam).
	local LocalSide = LocalPlayer:GetAttribute("StageTeamSide")
	local TargetSide = TargetPlayer:GetAttribute("StageTeamSide")
	if typeof(LocalSide) == "number" and typeof(TargetSide) == "number" then
		return LocalSide == TargetSide
	end

	if LocalPlayer.Neutral or TargetPlayer.Neutral then
		return false
	end

	return LocalPlayer.Team ~= nil and TargetPlayer.Team == LocalPlayer.Team
end)

local GetAimScreenPosition = function()
	-- FOV/target selection follows the camera crosshair, never the
	-- desktop cursor or a moving touch point.
	local Viewport = Camera.ViewportSize
	return Vector2.new(Viewport.X * 0.5, Viewport.Y * 0.5)
end

local library = { priority = {}, whitelist = {} }

local GetClosestPlayerToMouseSilent = LPH_NO_VIRTUALIZE(function()
	local PriorityPlayers = {}

	local Plrs = GetPlayers(Players)

	if library.priority[1] then
		for Index, Value in Plrs do
			if Value == LocalPlayer then
				continue
			end
			if Config.Silent.TeamCheck and IsTeammate(Value) then
				continue
			end
			if not table.find(library.priority, Value.Name) then
				continue
			end
			if table.find(library.whitelist, Value.Name) then
				continue
			end
			if (Value.Character and FindFirstChild(Value.Character, "HumanoidRootPart") and FindFirstChild(Value.Character, "Humanoid") and FindFirstChild(Value.Character, "Humanoid").Health > (Game_Name == "South Bronx" and 4 or 0)) then
				if FindFirstChildOfClass(Value.Character, "ForceField") then
					continue
				end
				if FindFirstChild(Value.Character, "Torso") and FindFirstChild(Value.Character, "Torso").Material == Enum.Material.ForceField then
					continue
				end
				if Value.Character.Parent == nil then
					continue
				end
				local TargetPart = FindFirstChild(Value.Character, "HumanoidRootPart")
				local MouseLocation = GetAimScreenPosition()
				local TargetPartPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
				local Radius = Config.Silent.UseFieldOfView and Config.Silent.Radius or 9e9
				local Magnitude = (Vector2.new(TargetPartPosition.X, TargetPartPosition.Y) - MouseLocation).Magnitude
				if not DistanceCheck(Value, Config.Silent.MaxDistance) then
					continue
				end

				if Radius > Magnitude and OnScreen and Value then
					if not Config.Silent.WallBang and (Config.Silent.WallCheck and (not WallCheck(Value.Character))) then
						continue
					end
					table.insert(PriorityPlayers, { Player = Value, Distance = Magnitude })
				end
			end
		end

		table.sort(PriorityPlayers, function(Player, PlayerTwo)
			return Player.Distance < PlayerTwo.Distance
		end)

		if PriorityPlayers[1] then
			return PriorityPlayers[1].Player
		end
	end

	local ValidPlayers = {}

	for Index, Value in Plrs do
		if Value == LocalPlayer then
			continue
		end
		if Config.Silent.TeamCheck and IsTeammate(Value) then
			continue
		end
		if table.find(library.whitelist, Value.Name) then
			continue
		end
		if (Value.Character and FindFirstChild(Value.Character, "HumanoidRootPart") and FindFirstChild(Value.Character, "Humanoid") and FindFirstChild(Value.Character, "Humanoid").Health > (Game_Name == "South Bronx" and 4 or 0)) then
			if FindFirstChildOfClass(Value.Character, "ForceField") then
				continue
			end
			if FindFirstChild(Value.Character, "Torso") and FindFirstChild(Value.Character, "Torso").Material == Enum.Material.ForceField then
				continue
			end
			if Value.Character.Parent == nil then
				continue
			end
			local TargetPart = FindFirstChild(Value.Character, "HumanoidRootPart")
			local MouseLocation = GetAimScreenPosition()
			local TargetPartPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
			local Radius = Config.Silent.UseFieldOfView and Config.Silent.Radius or 9e9
			local Magnitude = (Vector2.new(TargetPartPosition.X, TargetPartPosition.Y) - MouseLocation).Magnitude
			if not DistanceCheck(Value, Config.Silent.MaxDistance) then
				continue
			end

			if Radius > Magnitude and OnScreen and Value then
				if not Config.Silent.WallBang and (Config.Silent.WallCheck and not WallCheck(Value.Character)) then
					continue
				end
				table.insert(ValidPlayers, { Player = Value, Distance = Magnitude })
			end
		end
	end

	table.sort(ValidPlayers, function(Player, PlayerTwo)
		return Player.Distance < PlayerTwo.Distance
	end)

	if ValidPlayers[1] then
		return ValidPlayers[1].Player
	end

	return nil
end)

-- ============================================================================
-- Aimlock (AIMBOT) engine - ported from the provided script's Aimlock tab.
-- Target find + per-frame lock validation + camera / mouse aiming.
-- ============================================================================
local AimbotTarget = nil

local Move_Mouse_Function = nil

pcall(function()
	if type(mousemoverel) == "function" then
		Move_Mouse_Function = mousemoverel
	end
end)

if type(Move_Mouse_Function) ~= "function" then
	Move_Mouse_Function = nil
end

local AimPartFallbacks = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function ResolveAimPart(character)
	if not character then
		return nil
	end

	local wanted = Config.Aimlock.TargetPart

	if type(wanted) == "table" then
		wanted = wanted[1]
	end

	if type(wanted) == "string" and wanted ~= "" and FindFirstChild(character, wanted) then
		return wanted
	end

	for _, name in ipairs(AimPartFallbacks) do
		if FindFirstChild(character, name) then
			return name
		end
	end

	return nil
end

local GetClosestPlayerToMouseAimbot = LPH_NO_VIRTUALIZE(function()
	local valid = {}
	local plrs = GetPlayers(Players)

	for Index, value in plrs do
		if value == LocalPlayer then
			continue
		end

		if Config.Aimlock.TeamCheck and IsTeammate(value) then
			continue
		end

		if table.find(library.whitelist, value.Name) then
			continue
		end

		local character = value.Character

		if character and character.Parent and FindFirstChild(character, "Humanoid") and FindFirstChild(character, "Humanoid").Health > (Game_Name == "South Bronx" and 4 or 0) then
			if FindFirstChildOfClass(character, "ForceField") then
				continue
			end

			if FindFirstChild(character, "Torso") and FindFirstChild(character, "Torso").Material == Enum.Material.ForceField then
				continue
			end

			local partName = ResolveAimPart(character)
			local part = partName and FindFirstChild(character, partName)

			if part then
				local mouseLocation = GetAimScreenPosition()
				local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				local radius = Config.Aimlock.UseFieldOfView and Config.Aimlock.Radius or 9e9
				local magnitude = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude

				if DistanceCheck(value, Config.Aimlock.MaxDistance) and radius > magnitude and onScreen then
					if Config.Aimlock.WallCheck and not WallCheck(character, part) then
						continue
					end

					table.insert(valid, { Player = value, Distance = magnitude })
				end
			end
		end
	end

	table.sort(valid, function(a, b)
		return a.Distance < b.Distance
	end)

	if valid[1] then
		return valid[1].Player
	end

	return nil
end)

local function UpdateAimbotTarget()
	if not (Config.Aimlock.Enabled and Config.Aimlock.Aiming) then
		AimbotTarget = nil
		return
	end

	local locked = AimbotTarget

	if locked then
		local character = locked.Character
		local partName = character and ResolveAimPart(character)
		local part = partName and FindFirstChild(character, partName)
		local humanoid = character and FindFirstChild(character, "Humanoid")
		local stillValid = false

		if part and humanoid and humanoid.Health > 0 then
			local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
			local mouseLocation = GetAimScreenPosition()
			local inFov = (not Config.Aimlock.UseFieldOfView)
				or (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude <= Config.Aimlock.Radius

			stillValid = onScreen and inFov

			if stillValid and Config.Aimlock.WallCheck and not WallCheck(character, part) then
				stillValid = false
			end

			if stillValid and Config.Aimlock.TeamCheck and IsTeammate(locked) then
				stillValid = false
			end
		end

		if not stillValid then
			AimbotTarget = nil
		end
	end

	if not AimbotTarget then
		AimbotTarget = GetClosestPlayerToMouseAimbot()
	end
end

local function RunAimlock()
	local target = AimbotTarget

	if not target or not target.Character then
		return
	end

	local partName = ResolveAimPart(target.Character)
	local part = partName and FindFirstChild(target.Character, partName)

	if not part then
		return
	end

	local aimType = Config.Aimlock.Type

	if aimType == "Mouse" and (Mobile or not Move_Mouse_Function) then
		aimType = "Camera"
	end

	if aimType == "Mouse" and Move_Mouse_Function then
		local pos, onScreen = Camera:WorldToScreenPoint(part.Position)

		if onScreen then
			local delta = Vector2.new(pos.X, pos.Y) - GetAimScreenPosition()
			local smooth = math.max(Config.Aimlock.Smoothness or 0, 0) + 1

			pcall(Move_Mouse_Function, delta.X / smooth, delta.Y / smooth)
		end
	else
		local alpha = math.clamp(1 - ((Config.Aimlock.Smoothness or 0) / 10), 0.02, 1)

		Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, part.Position), alpha)
	end
end

-- ============================================================================
-- __namecall hook - silently redirects Raycast / FindPartOnRay to the target
-- ============================================================================
local SilentTarget = nil
local __namecall = nil

local function UpdateTarget()
	SilentTarget = GetClosestPlayerToMouseSilent()
end

pcall(function()
	if Solara then
		return
	end

	if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" or type(checkcaller) ~= "function" then
		return
	end

	__namecall = hookmetamethod(Workspace, "__namecall", LPH_NO_VIRTUALIZE(function(...)
		local Arguments = { ... }
		local Method = getnamecallmethod()

		if checkcaller() then
			return __namecall(...)
		end

		if not SilentTarget then
			return __namecall(...)
		end

		if not Config.Silent.Enabled then
			return __namecall(...)
		end

		local CallScript = nil
		pcall(function()
			CallScript = getcallingscript()
		end)

		if Game_Name == "Town" then
			if tostring(CallScript) ~= "GunScript" then
				return __namecall(...)
			end
		end

		if not (mathrandom(0, 100) <= Config.Silent.HitChance) then
			return __namecall(...)
		end

		if Game_Name == "The Bronx" then
			if not (CallScript and (CallScript.Name == "GunScript_Local" or CallScript.Name == "BulletVisualizerServerScript" or CallScript.Name == "BulletVisualizerClientScript")) then
				return __namecall(...)
			end
		end

		local RandomPart = Config.Silent.TargetPart[1] and Config.Silent.TargetPart[math.random(1, #Config.Silent.TargetPart)] or "Head"

		if Method == "Raycast" and table.find(Config.Game.Ray_Systems, "Raycast") then
			-- Do not redirect short controller/ground/camera raycasts
			local RayOrigin, RayDirection = Arguments[2], Arguments[3]
			if typeof(RayOrigin) ~= "Vector3" or typeof(RayDirection) ~= "Vector3" or RayDirection.Magnitude < 25 then
				return __namecall(...)
			end

			if Game_Name == "BlockSpin" then
				if CallScript and not (CallScript.Name == "Gun") then
					return __namecall(...)
				end
			end

			if Game_Name == "South Bronx" then
				if CallScript and CallScript.Name == "RealismClient" then
					return __namecall(...)
				end
			end

			if Config.Silent.Enabled then
				if Config.Silent.Targetting then
					local Target = SilentTarget
					if Target and Target.Character and FindFirstChild(Target.Character, RandomPart) and FindFirstChild(Target.Character, "Humanoid") and FindFirstChild(Target.Character, "Humanoid").Health ~= 0 then
						local TargetPart = FindFirstChild(Target.Character, RandomPart)
						local Origin = Arguments[2]
						local Direction = (TargetPart.Position - Origin).Unit * 1000

						Arguments[3] = Direction
					end

					if Config.Silent.WallBang and Game_Name ~= "BlockSpin" and Target and Target.Character then
						local FilterDescendantsInstances = {}

						if Target.Character then
							for Index, Value in pairs(GetDescendants(Target.Character)) do
								if IsA(Value, "Part") or IsA(Value, "BasePart") or IsA(Value, "MeshPart") then
									table.insert(FilterDescendantsInstances, Value)
								end
							end
						end

						local RaycastParams = RaycastParams.new()

						RaycastParams.FilterType = Enum.RaycastFilterType.Include
						RaycastParams.IgnoreWater = false
						RaycastParams.RespectCanCollide = false
						RaycastParams.FilterDescendantsInstances = FilterDescendantsInstances
						Arguments[4] = RaycastParams
					end

					if not Config.Silent.WallBang and Game_Name == "South Bronx" then
						local RaycastParams = RaycastParams.new()
						RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
						RaycastParams.FilterDescendantsInstances = { LocalPlayer.Character }
						Arguments[4] = RaycastParams
					end

					return __namecall(unpack(Arguments))
				end
			end
		end

		if string.find(string.lower(Method), "findpartonray") and (table.find(Config.Game.Ray_Systems, "FindPartOnRay") or table.find(Config.Game.Ray_Systems, "FindPartOnRayWithWhitelist")) then
			local Ray = Arguments[2]
			if typeof(Ray) ~= "Ray" or Ray.Direction.Magnitude < 25 then
				return __namecall(...)
			end

			if Config.Silent.Enabled then
				if Config.Silent.Targetting then
					local Target = SilentTarget
					if Target and Target.Character and FindFirstChild(Target.Character, RandomPart) and FindFirstChild(Target.Character, "Humanoid") and FindFirstChild(Target.Character, "Humanoid").Health ~= 0 then
						local TargetPart = FindFirstChild(Target.Character, RandomPart)
						local Origin = Arguments[2].Origin

						local Direction = (TargetPart.Position - Origin).Unit * 9e17

						Arguments[2] = Ray.new(Origin, Direction)

						if Config.Silent.WallBang then
							return TargetPart, TargetPart.Position, Vector3.new(0, 0, 0)
						end

						return __namecall(unpack(Arguments))
					end
				end
			end
		end

		return __namecall(...)
	end))
end)

-- ============================================================================
-- Visuals - FOV/POV circle + snapline (Drawing library)
-- ============================================================================
local function Draw(ClassName, Properties)
	local Drawing = Drawing.new(ClassName)

	for Property, Value in Properties do
		Drawing[Property] = Value
	end

	return Drawing
end

local SilentFieldOfViewOutline = nil
local SilentFieldOfView = nil
local SilentFieldOfViewFill = nil
local SilentSnaplineOutline = nil
local SilentSnapline = nil

local AimbotFieldOfViewOutline = nil
local AimbotFieldOfView = nil
local AimbotFieldOfViewFill = nil

local DrawingsAvailable = type(Drawing) == "table" or type(Drawing) == "function"

if DrawingsAvailable then
	local function tryDraw(ClassName, Properties)
		local ok, result = pcall(Draw, ClassName, Properties)
		return ok and result or nil
	end

	SilentFieldOfViewOutline = tryDraw("Circle", { Visible = false, Color = Color3.new(0, 0, 0), Radius = 100, NumSides = 100, Thickness = 4 })
	SilentFieldOfView = tryDraw("Circle", { Visible = false, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 1 })
	SilentFieldOfViewFill = tryDraw("Circle", { Visible = false, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 2, Filled = true })
	SilentSnaplineOutline = tryDraw("Line", { Visible = false, Color = Color3.new(0, 0, 0), Thickness = 3 })
	SilentSnapline = tryDraw("Line", { Visible = false, Color = Color3.new(1, 1, 1), Thickness = 1 })

	AimbotFieldOfViewOutline = tryDraw("Circle", { Visible = false, Color = Color3.new(0, 0, 0), Radius = 100, NumSides = 100, Thickness = 4 })
	AimbotFieldOfView = tryDraw("Circle", { Visible = false, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 1 })
	AimbotFieldOfViewFill = tryDraw("Circle", { Visible = false, Color = Color3.new(1, 1, 1), Radius = 100, NumSides = 100, Thickness = 2, Filled = true })

	if not (SilentSnapline and SilentFieldOfView) then
		DrawingsAvailable = false
		SilentFieldOfViewOutline = nil
		SilentFieldOfView = nil
		SilentFieldOfViewFill = nil
		SilentSnaplineOutline = nil
		SilentSnapline = nil
		AimbotFieldOfViewOutline = nil
		AimbotFieldOfView = nil
		AimbotFieldOfViewFill = nil
	end
end

-- The POV circle + snapline are rendered with BOTH renderers at once, so they
-- show on every executor:
--   1) ScreenGui frames  -> the exact same technique as the TBot POV circle
--      (real Roblox objects, render anywhere the TBot POV renders).
--   2) Drawing circles   -> the original hub's mechanism, kept identical.
-- Whichever renderer the executor supports, the visuals will appear.
local VisualGui = nil
local UiFov = nil
local UiFovFill = nil
local UiFovOutline = nil
local UiSnapline = nil
local UiSnaplineOutline = nil
local UiAimFov = nil

pcall(function()
	local targetGui = (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")) or game:GetService("CoreGui")

		VisualGui = Instance.new("ScreenGui")
		VisualGui.Name = "SilentAimVisuals"
		VisualGui.IgnoreGuiInset = true
		VisualGui.ResetOnSpawn = false
		VisualGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		VisualGui.Parent = targetGui

		UiFovFill = Instance.new("Frame")
		UiFovFill.Name = "FovFill"
		UiFovFill.AnchorPoint = Vector2.new(0.5, 0.5)
		UiFovFill.BackgroundColor3 = Color3.new(1, 1, 1)
		UiFovFill.BackgroundTransparency = 1
		UiFovFill.BorderSizePixel = 0
		UiFovFill.ZIndex = 900
		UiFovFill.Visible = false
		UiFovFill.Parent = VisualGui

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = UiFovFill

		UiFovOutline = Instance.new("Frame")
		UiFovOutline.Name = "FovOutline"
		UiFovOutline.AnchorPoint = Vector2.new(0.5, 0.5)
		UiFovOutline.BackgroundColor3 = Color3.new(0, 0, 0)
		UiFovOutline.BackgroundTransparency = 1
		UiFovOutline.BorderSizePixel = 0
		UiFovOutline.ZIndex = 900
		UiFovOutline.Visible = false
		UiFovOutline.Parent = VisualGui

		local fovOutlineCorner = Instance.new("UICorner")
		fovOutlineCorner.CornerRadius = UDim.new(1, 0)
		fovOutlineCorner.Parent = UiFovOutline
		stroke(UiFovOutline, Color3.new(0, 0, 0), 4, 0)

		UiFov = Instance.new("Frame")
		UiFov.Name = "Fov"
		UiFov.AnchorPoint = Vector2.new(0.5, 0.5)
		UiFov.BackgroundColor3 = Color3.new(1, 1, 1)
		UiFov.BackgroundTransparency = 1
		UiFov.BorderSizePixel = 0
		UiFov.ZIndex = 901
		UiFov.Visible = false
		UiFov.Parent = VisualGui

		local fovCorner = Instance.new("UICorner")
		fovCorner.CornerRadius = UDim.new(1, 0)
		fovCorner.Parent = UiFov
		stroke(UiFov, Color3.new(1, 1, 1), 1, 0)

		UiAimFov = Instance.new("Frame")
		UiAimFov.Name = "AimFov"
		UiAimFov.AnchorPoint = Vector2.new(0.5, 0.5)
		UiAimFov.BackgroundColor3 = Color3.new(1, 1, 1)
		UiAimFov.BackgroundTransparency = 1
		UiAimFov.BorderSizePixel = 0
		UiAimFov.ZIndex = 899
		UiAimFov.Visible = false
		UiAimFov.Parent = VisualGui

		local aimFovCorner = Instance.new("UICorner")
		aimFovCorner.CornerRadius = UDim.new(1, 0)
		aimFovCorner.Parent = UiAimFov
		stroke(UiAimFov, Color3.new(1, 1, 1), 1, 0)

		UiSnapline = Instance.new("Frame")
		UiSnapline.Name = "Snapline"
		UiSnapline.AnchorPoint = Vector2.new(0.5, 0.5)
		UiSnapline.BackgroundColor3 = Color3.new(1, 1, 1)
		UiSnapline.BorderSizePixel = 0
		UiSnapline.ZIndex = 903
		UiSnapline.Visible = false
		UiSnapline.Parent = VisualGui

		UiSnaplineOutline = Instance.new("Frame")
		UiSnaplineOutline.Name = "SnaplineOutline"
		UiSnaplineOutline.AnchorPoint = Vector2.new(0.5, 0.5)
		UiSnaplineOutline.BackgroundColor3 = Color3.new(0, 0, 0)
		UiSnaplineOutline.BorderSizePixel = 0
		UiSnaplineOutline.ZIndex = 902
		UiSnaplineOutline.Visible = false
		UiSnaplineOutline.Parent = VisualGui
	end)

local UseUiVisuals = not not (VisualGui and UiFov and UiFovOutline and UiSnapline and UiSnaplineOutline)

RunService:BindToRenderStep("Functions", math.huge, LPH_NO_VIRTUALIZE(function()
	pcall(function()
		if not Camera then
			Camera = Workspace.CurrentCamera
		end

		if not Camera then
			return
		end

		local MouseLocation = GetAimScreenPosition()

		pcall(UpdateTarget)

		-- AIMBOT (aimlock): pick/validate a target then aim at it
		pcall(UpdateAimbotTarget)

		if Config.Aimlock.Enabled and Config.Aimlock.Aiming then
			pcall(RunAimlock)
		end

		if UseUiVisuals then
		-- ScreenGui fallback: POV circle + snapline drawn as Gui frames
		if UiFov then
			local fovSize = UDim2.fromOffset(Config.Silent.Radius * 2, Config.Silent.Radius * 2)
			local fovPos = UDim2.fromOffset(MouseLocation.X, MouseLocation.Y)
			local fovShow = Config.Silent.UseFieldOfView and Config.Silent.DrawFieldOfView

			-- ring only: thin WHITE 1px ring, no fill, no black outline (like the TBot POV)
			if UiFovFill then
				UiFovFill.Visible = false
			end

			if UiFovOutline then
				UiFovOutline.Visible = false
			end

			UiFov.Size = fovSize
			UiFov.Position = fovPos
			UiFov.Visible = fovShow
		end

		-- AIMBOT (aimlock) FOV circle - same ring style as the SA one above.
		if UiAimFov then
			UiAimFov.Size = UDim2.fromOffset(Config.Aimlock.Radius * 2, Config.Aimlock.Radius * 2)
			UiAimFov.Position = UDim2.fromOffset(MouseLocation.X, MouseLocation.Y)
			UiAimFov.Visible = Config.Aimlock.UseFieldOfView and Config.Aimlock.DrawFieldOfView
		end

		-- snapline: single thin white line from the CENTER of the screen to the
		-- SA TARGET part you picked (Head/Torso/...), falling back to the middle.
		local snapOn = false
		local aimPartName = Config.Silent.TargetPart[1] or "Head"

		if SilentTarget and SilentTarget.Character then
			local aimPart = SilentTarget.Character:FindFirstChild(aimPartName)
				or SilentTarget.Character:FindFirstChild("HumanoidRootPart")
				or SilentTarget.Character:FindFirstChild("Head")

			if aimPart then
				local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)

				if Config.Silent.Snapline and onScreen then
					snapOn = true
					local camSize = Camera.ViewportSize
					local fromPt = Vector2.new(camSize.X / 2, camSize.Y / 2)
					local toPt = Vector2.new(pos.X, pos.Y)
					local delta = toPt - fromPt

					if UiSnapline then
						UiSnapline.BackgroundColor3 = Config.Silent.SnaplineColor
						UiSnapline.Position = UDim2.fromOffset((fromPt.X + toPt.X) / 2, (fromPt.Y + toPt.Y) / 2)
						UiSnapline.Size = UDim2.fromOffset(delta.Magnitude, Config.Silent.SnaplineThickness)
						UiSnapline.Rotation = math.deg(math.atan2(delta.Y, delta.X))
					end
				end
			end
		end

		if UiSnapline then
			UiSnapline.Visible = snapOn
		end
		if UiSnaplineOutline then
			UiSnaplineOutline.Visible = false
		end
	end

	if DrawingsAvailable then
		SilentFieldOfView.Visible = Config.Silent.UseFieldOfView and Config.Silent.DrawFieldOfView
		SilentFieldOfView.Radius = Config.Silent.Radius
		SilentFieldOfView.NumSides = Config.Silent.Sides
		SilentFieldOfView.Color = Config.Silent.FieldOfViewColor
		SilentFieldOfView.Position = MouseLocation

		-- ring only: thin WHITE 1px ring, no fill, no black outline (like the TBot POV)
		SilentFieldOfViewFill.Visible = false
		SilentFieldOfViewOutline.Visible = false

		-- AIMBOT (aimlock) FOV circle (Drawing mirror)
		AimbotFieldOfView.Visible = Config.Aimlock.UseFieldOfView and Config.Aimlock.DrawFieldOfView
		AimbotFieldOfView.Radius = Config.Aimlock.Radius
		AimbotFieldOfView.NumSides = Config.Aimlock.Sides
		AimbotFieldOfView.Color = Config.Aimlock.FieldOfViewColor
		AimbotFieldOfView.Position = MouseLocation
		AimbotFieldOfViewFill.Visible = false
		AimbotFieldOfViewOutline.Visible = false

		-- snapline (Drawing mirror): identical line to the GUI one - thin, white,
		-- from the center of the screen to the SA TARGET part you picked
		local snapOn = false
		local aimPartName = Config.Silent.TargetPart[1] or "Head"

		if SilentTarget and SilentTarget.Character then
			local aimPart = SilentTarget.Character:FindFirstChild(aimPartName)
				or SilentTarget.Character:FindFirstChild("HumanoidRootPart")
				or SilentTarget.Character:FindFirstChild("Head")

			if aimPart then
				local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)

				if Config.Silent.Snapline and onScreen then
					snapOn = true
					local camSize = Camera.ViewportSize
					local fromPt = Vector2.new(camSize.X / 2, camSize.Y / 2)
					local toPt = Vector2.new(pos.X, pos.Y)

					SilentSnapline.From = fromPt
					SilentSnapline.To = toPt
					SilentSnapline.Color = Config.Silent.SnaplineColor
					SilentSnapline.Thickness = Config.Silent.SnaplineThickness
				end
			end
		end

		SilentSnapline.Visible = snapOn
		SilentSnaplineOutline.Visible = false
	end
	end)
end))

-- unhook + remove drawings when the whole gui unloads
table.insert(restoreCallbacks, function()
	pcall(function()
		if __namecall then
			hookmetamethod(Workspace, "__namecall", __namecall)
		end
	end)

	pcall(function()
		RunService:UnbindFromRenderStep("Functions")
	end)

	if DrawingsAvailable then
		pcall(SilentSnapline.Remove, SilentSnapline)
		pcall(SilentSnaplineOutline.Remove, SilentSnaplineOutline)
		pcall(SilentFieldOfView.Remove, SilentFieldOfView)
		pcall(SilentFieldOfViewOutline.Remove, SilentFieldOfViewOutline)
		pcall(SilentFieldOfViewFill.Remove, SilentFieldOfViewFill)

		pcall(AimbotFieldOfView.Remove, AimbotFieldOfView)
		pcall(AimbotFieldOfViewOutline.Remove, AimbotFieldOfViewOutline)
		pcall(AimbotFieldOfViewFill.Remove, AimbotFieldOfViewFill)
	end

	pcall(function()
		if VisualGui then
			VisualGui:Destroy()
		end
	end)
end)

------------------------------------------------------------------
-- screen gui + window
------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ACECodeSniperUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483646
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

pcall(function()
	gui.OnTopOfCoreBlur = true
end)

for _, parent in ipairs(huiParents()) do
	pcall(function()
		gui.Parent = parent
	end)

	if gui.Parent then
		break
	end
end

genv.ACECodeSniperGui = gui

local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(1, 0)
window.Position = UDim2.new(1, -8, 0, 8)
window.Size = UDim2.fromOffset(WIN_W, WIN_H)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.ZIndex = 0
window.Parent = gui
corner(window, 14)
stroke(window, COLORS.White, 1, 0.58)

local bgImages = {
	{ Name = "NONE", Image = "", IsNone = true },
	{ Name = "1", Image = "rbxassetid://137692455767789" },
	{ Name = "2", Image = "rbxassetid://128081130356834" },
	{ Name = "3", Image = "rbxassetid://120480454937730" },
	{ Name = "4", Image = "rbxassetid://85127407374728" },
	{ Name = "5", Image = "rbxassetid://107291541054530" },
	{ Name = "6", Image = "rbxassetid://124230165619007" },
	{ Name = "7", Image = "rbxassetid://87766822871097" },
	{ Name = "8", Image = "rbxassetid://90280869222992" },
	{ Name = "9", Image = "rbxassetid://126860692354524" },
	{ Name = "10", Image = "rbxassetid://105131079571166" },
	{ Name = "11", Image = "rbxassetid://108751216016989" },
}

local BACKGROUND_INDEX = 2

local bgImage = Instance.new("ImageLabel")
bgImage.Name = "Background"
bgImage.Size = UDim2.fromScale(1, 1)
bgImage.BackgroundTransparency = 1
bgImage.ScaleType = Enum.ScaleType.Stretch
bgImage.ZIndex = 1
bgImage.Parent = window
corner(bgImage, 14)

local function applyBackground(index)
	BACKGROUND_INDEX = math.clamp(index, 1, #bgImages)
	local entry = bgImages[BACKGROUND_INDEX]
	bgImage.Image = entry.Image
	bgImage.Visible = not entry.IsNone
end

local shade = Instance.new("Frame")
shade.Name = "BackgroundShade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shade.BackgroundTransparency = 0.5
shade.BorderSizePixel = 0
shade.ZIndex = 2
shade.Parent = window
corner(shade, 13)

-- falling dots
do
	local layer = Instance.new("Frame")
	layer.Name = "ACEFallingDots"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ClipsDescendants = true
	layer.ZIndex = 90
	layer.Parent = window

	local rng = Random.new()
	local alive = true
	layer.Destroying:Connect(function()
		alive = false
	end)

	for _ = 1, 14 do
		task.spawn(function()
			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dot.BorderSizePixel = 0
			dot.Visible = false
			dot.ZIndex = 91
			dot.Parent = layer
			corner(dot, 1)
			task.wait(rng:NextNumber(0, 3))

			while alive and layer.Parent do
				local size = rng:NextInteger(2, 4)
				local startX = rng:NextNumber(0.03, 0.97)
				local endX = math.clamp(startX + rng:NextNumber(-0.15, 0.1), 0.02, 0.98)
				local duration = rng:NextNumber(5.8, 9.2)

				dot.Size = UDim2.fromOffset(size, size)
				dot.Position = UDim2.new(startX, 0, -0.1, -size)
				dot.BackgroundTransparency = rng:NextNumber(0.28, 0.58)
				dot.Visible = true

				local tween = TweenService:Create(
					dot,
					TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					{ Position = UDim2.new(endX, 0, 1.06, size), BackgroundTransparency = rng:NextNumber(0.48, 0.76) }
				)

				tween:Play()
				tween.Completed:Wait()
				dot.Visible = false
				task.wait(rng:NextNumber(0.12, 0.45))
			end

			if dot.Parent then
				dot:Destroy()
			end
		end)
	end
end

local uiScale = Instance.new("UIScale")
uiScale.Name = "InterfaceScale"
uiScale.Scale = 1
uiScale.Parent = window

local userScale = 1

local function fitWindow()
	local camera = workspace.CurrentCamera
	local fit = 1

	if camera then
		fit = math.min((camera.ViewportSize.X - 16) / WIN_W, (camera.ViewportSize.Y - 16) / WIN_H)
	end

	uiScale.Scale = math.max(0.35, math.min(1, fit)) * userScale
end

fitWindow()

pcall(function()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fitWindow)

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWindow)
	end
end)

------------------------------------------------------------------
-- header
------------------------------------------------------------------
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.Active = true
header.ZIndex = 3
header.Parent = window

label(header, "Title", "Bleh Hub", UDim2.fromOffset(155, 25), UDim2.fromOffset(16, 16), 15, COLORS.White, Enum.Font.GothamBold).ZIndex =
	4

local divider = Instance.new("Frame")
divider.Name = "TitleDivider"
divider.Size = UDim2.new(1, -34, 0, 1)
divider.Position = UDim2.fromOffset(17, 54)
divider.BackgroundColor3 = COLORS.White
divider.BackgroundTransparency = 0.72
divider.BorderSizePixel = 0
divider.ZIndex = 4
divider.Parent = header

------------------------------------------------------------------
-- pages
------------------------------------------------------------------
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 34)
tabBar.Position = UDim2.fromOffset(0, TAB_Y)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 6
tabBar.Parent = window

local mainPage = Instance.new("Frame")
mainPage.Name = "MainPage"
mainPage.Size = UDim2.new(1, 0, 1, -PAGE_Y)
mainPage.Position = UDim2.fromOffset(0, PAGE_Y)
mainPage.BackgroundTransparency = 1
mainPage.ZIndex = 2
mainPage.Parent = window

local movementPage = Instance.new("Frame")
movementPage.Name = "MovementPage"
movementPage.Size = mainPage.Size
movementPage.Position = mainPage.Position
movementPage.BackgroundTransparency = 1
movementPage.Visible = false
movementPage.ZIndex = 2
movementPage.Parent = window

local visualPage = Instance.new("Frame")
visualPage.Name = "VisualPage"
visualPage.Size = mainPage.Size
visualPage.Position = mainPage.Position
visualPage.BackgroundTransparency = 1
visualPage.Visible = false
visualPage.ZIndex = 2
visualPage.Parent = window

local settingsPage = Instance.new("Frame")
settingsPage.Name = "SettingsPage"
settingsPage.Size = mainPage.Size
settingsPage.Position = mainPage.Position
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.ZIndex = 2
settingsPage.Parent = window

local footer = label(
	window,
	"DiscordFooter",
	"discord.gg/nnkfvWdK42",
	UDim2.fromOffset(140, 19),
	UDim2.new(0.5, -70, 0, 414),
	10,
	COLORS.White,
	Enum.Font.GothamBold
)
footer.TextXAlignment = Enum.TextXAlignment.Center
footer.TextStrokeColor3 = COLORS.Window
footer.TextStrokeTransparency = 0.35
footer.ZIndex = 3

-- tab buttons
local tabGroup = Instance.new("Frame")
tabGroup.Name = "TabGroup"
tabGroup.Size = UDim2.new(1, -34, 0, 22)
tabGroup.Position = UDim2.new(0, 17, 0.5, -11)
tabGroup.BackgroundColor3 = COLORS.Log
tabGroup.BackgroundTransparency = 0.1
tabGroup.BorderSizePixel = 0
tabGroup.ZIndex = 6
tabGroup.Parent = tabBar
corner(tabGroup, 7)
stroke(tabGroup, COLORS.White, 1, 0.55)

local pages = {}
local activeTab = "MAIN"

local function makeTab(name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.2, 0, 1, 0)
	button.Position = UDim2.new(order, 0, 0, 0)
	button.BackgroundColor3 = Color3.fromRGB(30, 26, 30)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.TextSize = 10
	button.TextColor3 = COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 7
	button.Parent = tabGroup
	corner(button, 6)
	pressable(button)
	local buttonStroke = stroke(button, COLORS.White, 1, 1)
	return { Button = button, Outline = buttonStroke }
end

local mainTab = makeTab("MainTab", "MAIN", 0)
local movementTab = makeTab("MovementTab", "MOVEMENT", 0.2)
local visualTab = makeTab("VisualTab", "VISUAL", 0.4)
local settingsTab = makeTab("SettingsTab", "SETTINGS", 0.6)
pages.MAIN = { tab = mainTab, page = mainPage }
pages.MOVEMENT = { tab = movementTab, page = movementPage }
pages.VISUAL = { tab = visualTab, page = visualPage }
pages.SETTINGS = { tab = settingsTab, page = settingsPage }

local function selectTab(key)
	if activeTab == key then
		return
	end

	for name, entry in pairs(pages) do
		local active = name == key
		entry.tab.Button.TextColor3 = active and COLORS.White or COLORS.Text
		entry.tab.Button.BackgroundTransparency = active and 0.05 or 1
		entry.tab.Outline.Transparency = active and 0.55 or 1

		if not active then
			entry.page.Visible = false
		end
	end

	local entry = pages[key]

	if not entry then
		return
	end

	entry.page.Visible = true
	entry.page.Position = UDim2.fromOffset(0, PAGE_Y + 10)
	TweenService:Create(entry.page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, PAGE_Y),
	}):Play()
	activeTab = key
end

mainTab.Button.MouseButton1Click:Connect(function()
	selectTab("MAIN")
end)
movementTab.Button.MouseButton1Click:Connect(function()
	selectTab("MOVEMENT")
end)
visualTab.Button.MouseButton1Click:Connect(function()
	selectTab("VISUAL")
end)
settingsTab.Button.MouseButton1Click:Connect(function()
	selectTab("SETTINGS")
end)

-- initial tab styling
do
	local entry = pages.MAIN
	entry.tab.Button.TextColor3 = COLORS.White
	entry.tab.Button.BackgroundTransparency = 0.05
	entry.tab.Outline.Transparency = 0.55
end

------------------------------------------------------------------
-- MAIN page - triggerbot
------------------------------------------------------------------
do
	local LocalPlayer = Players.LocalPlayer

	local Trigger = {
		Enabled = false,
		WallCheck = true,
		TeamCheck = true,
		RapidFire = true,
		RapidSpeed = 150, -- shots per second while rapid fire is on (slider)
		FireRate = 0.12, -- delay in seconds between shots while rapid fire is off
		FOV = 60,
		ShowFOV = true, -- POV circle on / off
		AimAngle = 45, -- anti aim: degrees your body turns away from where you look
		TargetPart = "Head",
		AutoDeactivate = true,
		DeactivateDelay = 0.01,
	}

	local MAX_SHOTS_PER_FRAME = 6
	local lastFire = 0
	local currentTarget = nil

	-- fov circle, drawn on top of everything, centred on the screen
	local fovFrame = Instance.new("Frame")
	fovFrame.Name = "TriggerFOV"
	fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fovFrame.BackgroundTransparency = 1
	fovFrame.BorderSizePixel = 0
	fovFrame.Size = UDim2.fromOffset(Trigger.FOV * 2, Trigger.FOV * 2)
	fovFrame.ZIndex = 200
	fovFrame.Visible = false
	fovFrame.Parent = gui
	corner(fovFrame, 999)

	local fovStroke = stroke(fovFrame, COLORS.White, 1, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local function getAimPart(character)
		if Trigger.TargetPart == "Head" then
			return character:FindFirstChild("Head")
		end

		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("HumanoidRootPart")
	end

	local function canSee(camera, targetPart)
		if not Trigger.WallCheck or not targetPart then
			return Trigger.WallCheck == false
		end

		local origin = camera.CFrame.Position
		local direction = targetPart.Position - origin
		rayParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
		return Workspace:Raycast(origin, direction, rayParams) == nil
	end

	local function isEnemy(player)
		if not Trigger.TeamCheck then
			return true
		end

		-- same teammate check as silent aim (handles Alkedion StageTeamSide,
		-- MatchId/PvPTeam attributes, Neutral and Player.Team fallback)
		return not IsTeammate(player)
	end

	local function getTarget(camera)
		local center = camera.ViewportSize * 0.5
		local bestDist = math.huge
		local bestTarget = nil

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and isEnemy(player) then
				local character = player.Character

				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					local root = character:FindFirstChild("HumanoidRootPart")

					if humanoid and humanoid.Health > 0 and root then
						local part = getAimPart(character)

						if part then
							local screen, onScreen = camera:WorldToViewportPoint(part.Position)

							if onScreen and screen.Z > 0 then
								local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude

								if distance <= Trigger.FOV and distance < bestDist and canSee(camera, part) then
									bestDist = distance
									bestTarget = part
								end
							end
						end
					end
				end
			end
		end

		return bestTarget
	end

	local function fire()
		local character = LocalPlayer.Character
		local tool = character and character:FindFirstChildOfClass("Tool")

		if not tool then
			return
		end

		pcall(function()
			tool:Activate()
		end)

		if Trigger.AutoDeactivate then
			local delay = Trigger.DeactivateDelay

			if delay > 0 then
				task.delay(delay, function()
					if tool.Parent == LocalPlayer.Character then
						pcall(function()
							tool:Deactivate()
						end)
					end
				end)
			else
				RunService.Heartbeat:Once(function()
					if tool.Parent == LocalPlayer.Character then
						pcall(function()
							tool:Deactivate()
						end)
					end
				end)
			end
		end
	end

	-- status line (compact - small text so all statuses fit on screen)
	local statusDot = Instance.new("Frame")
	statusDot.Name = "Dot"
	statusDot.Size = UDim2.fromOffset(6, 6)
	statusDot.Position = UDim2.fromOffset(CONTENT_X + 1, 4)
	statusDot.BackgroundColor3 = COLORS.Dim
	statusDot.BorderSizePixel = 0
	statusDot.ZIndex = 5
	statusDot.Parent = mainPage
	corner(statusDot, 3)

	local statusText = label(
		mainPage,
		"State",
		"TRIGGERBOT OFF",
		UDim2.new(0, 70, 0, 12),
		UDim2.fromOffset(CONTENT_X + 11, 0),
		7,
		COLORS.Dim,
		Enum.Font.GothamBlack
	)
	statusText.ZIndex = 5

	-- aimbot status (top line, beside the triggerbot one)
	local aimStatusDot = Instance.new("Frame")
	aimStatusDot.Name = "AimDot"
	aimStatusDot.Size = UDim2.fromOffset(6, 6)
	aimStatusDot.Position = UDim2.fromOffset(CONTENT_X + 84, 4)
	aimStatusDot.BackgroundColor3 = COLORS.Dim
	aimStatusDot.BorderSizePixel = 0
	aimStatusDot.ZIndex = 5
	aimStatusDot.Parent = mainPage
	corner(aimStatusDot, 3)

	local aimStatusText = label(
		mainPage,
		"AimState",
		"AIMBOT OFF",
		UDim2.new(0, 54, 0, 12),
		UDim2.fromOffset(CONTENT_X + 94, 0),
		7,
		COLORS.Dim,
		Enum.Font.GothamBlack
	)
	aimStatusText.ZIndex = 5

	-- silent aim status (top line, beside the aimbot one)
	local saStatusDot = Instance.new("Frame")
	saStatusDot.Name = "SADot"
	saStatusDot.Size = UDim2.fromOffset(6, 6)
	saStatusDot.Position = UDim2.fromOffset(CONTENT_X + 150, 4)
	saStatusDot.BackgroundColor3 = COLORS.Dim
	saStatusDot.BorderSizePixel = 0
	saStatusDot.ZIndex = 5
	saStatusDot.Parent = mainPage
	corner(saStatusDot, 3)

	local saStatusText = label(
		mainPage,
		"SAState",
		"SILENT AIM OFF",
		UDim2.new(0, 80, 0, 12),
		UDim2.fromOffset(CONTENT_X + 160, 0),
		7,
		COLORS.Dim,
		Enum.Font.GothamBlack
	)
	saStatusText.ZIndex = 5

	local cardSwitch

	local function refreshStatus()
		local on = Trigger.Enabled
		statusText.Text = on and "TRIGGERBOT ON" or "TRIGGERBOT OFF"
		statusText.TextColor3 = on and COLORS.White or COLORS.Dim
		statusDot.BackgroundColor3 = on and COLORS.Green or COLORS.Dim
	end

	local function refreshSAStatus()
		local on = Config.Silent.Enabled
		saStatusText.Text = on and "SILENT AIM ON" or "SILENT AIM OFF"
		saStatusText.TextColor3 = on and COLORS.White or COLORS.Dim
		saStatusDot.BackgroundColor3 = on and COLORS.Green or COLORS.Dim
	end

	local function refreshAimStatus()
		local on = Config.Aimlock.Enabled
		aimStatusText.Text = on and "AIMBOT ON" or "AIMBOT OFF"
		aimStatusText.TextColor3 = on and COLORS.White or COLORS.Dim
		aimStatusDot.BackgroundColor3 = on and COLORS.Green or COLORS.Dim
	end

	local function setEnabled(value)
		value = value == true
		Trigger.Enabled = value

		if cardSwitch and cardSwitch.state ~= value then
			cardSwitch.Set(value, true)
		end

		refreshStatus()
	end

	-- header toggle removed - the card switch is the only master now
	refreshStatus()
	refreshSAStatus()
	refreshAimStatus()

	-- triggerbot card
	local card = Instance.new("Frame")
	card.Name = "TriggerbotCard"
	card.Size = UDim2.fromOffset(CONTENT_W, 288)
	card.Position = UDim2.fromOffset(CONTENT_X, 18)
	card.BackgroundColor3 = COLORS.Log
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.ZIndex = 3
	card.Parent = mainPage
	corner(card, 9)
	stroke(card, COLORS.White, 1, 0.86)

	local cardHeader = Instance.new("Frame")
	cardHeader.Name = "Header"
	cardHeader.Size = UDim2.new(1, 0, 0, 30)
	cardHeader.BackgroundTransparency = 1
	cardHeader.ZIndex = 4
	cardHeader.Parent = card

	-- sub-section switcher: TRIGGERBOT / SILENT AIM / AUTOKILL
	local tabBar = Instance.new("Frame")
	tabBar.Name = "SubTabs"
	tabBar.Size = UDim2.fromOffset(246, 22)
	tabBar.Position = UDim2.new(0, 13, 0.5, -11)
	tabBar.BackgroundColor3 = COLORS.Control
	tabBar.BorderSizePixel = 0
	tabBar.ZIndex = 5
	tabBar.Parent = cardHeader
	corner(tabBar, 7)

	local function tabButton(name, text, xOffset, tabWidth)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.fromOffset(tabWidth or 58, 18)
		button.Position = UDim2.fromOffset(xOffset, 2)
		button.BackgroundColor3 = COLORS.White
		button.BackgroundTransparency = 0.92
		button.AutoButtonColor = false
		button.Text = text
		button.TextSize = 7
		button.TextColor3 = COLORS.Text
		button.Font = Enum.Font.GothamBlack
		button.ZIndex = 6
		button.Parent = tabBar
		corner(button, 6)
		pcall(pressable, button)
		return button
	end

	local tbTabBtn = tabButton("TriggerbotTab", "TRIGGERBOT", 2)
	local aimTabBtn = tabButton("AimbotTab", "AIMBOT", 60)
	local saTabBtn = tabButton("SilentAimTab", "SILENT AIM", 118)
	local akTabBtn = tabButton("AutoKillTab", "AUTOKILL", 176)

	local cardRule = Instance.new("Frame")
	cardRule.Size = UDim2.new(1, -28, 0, 1)
	cardRule.Position = UDim2.new(0, 14, 0, 31)
	cardRule.BackgroundColor3 = COLORS.White
	cardRule.BackgroundTransparency = 0.86
	cardRule.BorderSizePixel = 0
	cardRule.ZIndex = 5
	cardRule.Parent = card

	local function newRowsFrame(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name
		frame.Size = UDim2.new(1, 0, 0, 252)
		frame.Position = UDim2.fromOffset(0, 34)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.ElasticBehavior = Enum.ElasticBehavior.Never
		frame.CanvasSize = UDim2.new()
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ScrollBarThickness = 3
		frame.ScrollBarImageColor3 = COLORS.Dim
		frame.ZIndex = 4
		frame.Parent = card

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame

		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 6)
		padding.Parent = frame

		return frame
	end

	local tbRows = newRowsFrame("Rows")
	local aimRows = newRowsFrame("AimbotRows")
	local saRows = newRowsFrame("SilentAimRows")
	local akRows = newRowsFrame("AutoKillRows")
	aimRows.Visible = false
	saRows.Visible = false
	akRows.Visible = false

	local rows = tbRows
	local order = 0

	local function switchRow(text, initial, onChange)
		order = order + 1
		local row = Instance.new("Frame")
		row.Name = "Row" .. text
		row.Size = UDim2.new(1, 0, 0, 27)
		row.BackgroundTransparency = 1
		row.LayoutOrder = order
		row.ZIndex = 5
		row.Parent = rows

		label(row, "Title", text, UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		return createSwitch(row, { state = initial, zIndex = 6, onChange = onChange })
	end

	local function sliderRow(text, minValue, maxValue, initial, onChange)
		order = order + 1

		local row = Instance.new("Frame")
		row.Name = "Slider" .. text
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundTransparency = 1
		row.LayoutOrder = order
		row.ZIndex = 5
		row.Parent = rows

		label(row, "Title", text, UDim2.new(0.5, -10, 0, 14), UDim2.fromOffset(14, 4), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		local valueLabel = label(
			row,
			"Value",
			tostring(initial),
			UDim2.new(0.5, -20, 0, 14),
			UDim2.new(0.5, 5, 0, 4),
			10,
			COLORS.White,
			Enum.Font.GothamBold
		)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 6

		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(1, -28, 0, 4)
		track.Position = UDim2.new(0, 14, 0, 24)
		track.BackgroundColor3 = COLORS.Control
		track.BorderSizePixel = 0
		track.ZIndex = 6
		track.Parent = row
		corner(track, 2)

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = COLORS.White
		fill.BorderSizePixel = 0
		fill.ZIndex = 7
		fill.Parent = track
		corner(fill, 2)

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		thumb.Size = UDim2.fromOffset(10, 10)
		thumb.BackgroundColor3 = COLORS.White
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 8
		thumb.Parent = track
		corner(thumb, 5)
		stroke(thumb, COLORS.Window, 1, 0.35)

		local current = initial

		local function apply(value, animate)
			current = value
			local ratio = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
			valueLabel.Text = tostring(value)

			if animate then
				TweenService:Create(fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(ratio, 0, 1, 0),
				}):Play()
				TweenService:Create(thumb, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(ratio, 0, 0.5, 0),
				}):Play()
			else
				fill.Size = UDim2.new(ratio, 0, 1, 0)
				thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
			end

			if onChange then
				onChange(value)
			end
		end

		apply(initial, false)

		local dragging = false

		local function moveTo(x)
			local absolute = track.AbsolutePosition.X
			local width = math.max(track.AbsoluteSize.X, 1)
			local ratio = math.clamp((x - absolute) / width, 0, 1)
			local value = math.floor(minValue + ratio * (maxValue - minValue) + 0.5)

			if value ~= current then
				apply(value, false)
			end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				moveTo(input.Position.X)
			end
		end)

		trackConnection(UserInputService.InputChanged:Connect(function(input)
			if
				dragging
				and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
			then
				moveTo(input.Position.X)
			end
		end))

		trackConnection(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		return {
			Get = function()
				return current
			end,
			Set = function(value)
				apply(value, false)
			end,
		}
	end

	-- anti aim state (engine wired at the bottom of this block)
	local aaEnabled = false

	cardSwitch = switchRow("ENABLED", Trigger.Enabled, function(value)
		setEnabled(value)
	end)

	switchRow("WALL CHECK", Trigger.WallCheck, function(value)
		Trigger.WallCheck = value
	end)

	switchRow("TEAM CHECK", Trigger.TeamCheck, function(value)
		Trigger.TeamCheck = value
	end)

	switchRow("RAPIDFIRE", Trigger.RapidFire, function(value)
		Trigger.RapidFire = value
	end)

	-- speed: shots per second while rapid fire is on
	sliderRow("RAPID SPEED", 10, 300, Trigger.RapidSpeed, function(value)
		Trigger.RapidSpeed = value
	end)

	-- POV circle on / off
	switchRow("POV", Trigger.ShowFOV, function(value)
		Trigger.ShowFOV = value
	end)

	sliderRow("FOV", 10, 300, Trigger.FOV, function(value)
		Trigger.FOV = value
	end)

	-- anti aim on / off
	switchRow("ANTI AIM", aaEnabled, function(value)
		aaEnabled = value
	end)

	-- how far the body turns: 0 = vanilla, 90 = sideways, 180 = fully backwards
	sliderRow("AIM ANGLE", 0, 180, Trigger.AimAngle, function(value)
		Trigger.AimAngle = value
	end)
-- =================================================
	-- SILENT AIM (engine installed above - these rows control it)
	-- =================================================
	rows = saRows
	order = 0
	local silentHeader = Instance.new("Frame")
	silentHeader.Name = "SilentAimHeader"
	silentHeader.Size = UDim2.new(1, 0, 0, 20)
	silentHeader.BackgroundTransparency = 1
	silentHeader.LayoutOrder = order
	silentHeader.ZIndex = 5
	silentHeader.Parent = rows

	local silentRule = Instance.new("Frame")
	silentRule.Size = UDim2.new(1, -28, 0, 1)
	silentRule.Position = UDim2.new(0, 14, 0.5, -1)
	silentRule.BackgroundColor3 = COLORS.White
	silentRule.BackgroundTransparency = 0.75
	silentRule.BorderSizePixel = 0
	silentRule.ZIndex = 6
	silentRule.Parent = silentHeader

	label(silentHeader, "Title", "SILENT AIM", UDim2.new(1, -30, 1, 0), UDim2.fromOffset(14, 0), 8, COLORS.White, Enum.Font.GothamBlack).ZIndex = 6

	switchRow("SA ENABLED", Config.Silent.Enabled, function(value)
		Config.Silent.Enabled = value
		Config.Silent.Targetting = value
		refreshSAStatus()
	end)

	switchRow("SA POV", Config.Silent.DrawFieldOfView, function(value)
		Config.Silent.UseFieldOfView = value
		Config.Silent.DrawFieldOfView = value
	end)

	switchRow("SA SNAPLINE", Config.Silent.Snapline, function(value)
		Config.Silent.Snapline = value
	end)

	switchRow("SA WALL CHECK", Config.Silent.WallCheck, function(value)
		Config.Silent.WallCheck = value
	end)

	switchRow("SA TEAM CHECK", Config.Silent.TeamCheck, function(value)
		Config.Silent.TeamCheck = value
		SilentTarget = nil
	end)

	sliderRow("SA FOV", 10, 500, Config.Silent.Radius, function(value)
		Config.Silent.Radius = value
	end)

	sliderRow("SA MAX DIST", 50, 3000, Config.Silent.MaxDistance, function(value)
		Config.Silent.MaxDistance = value
	end)

	sliderRow("SA HIT CHANCE", 1, 100, Config.Silent.HitChance, function(value)
		Config.Silent.HitChance = value
	end)

	-- SA TARGET - click to cycle the body part the bullets/snapline lock onto
	local BodyParts = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" }

	pcall(function()
		local _rig = "R15"
		local _char = Players.LocalPlayer and Players.LocalPlayer.Character

		if _char and _char:FindFirstChildOfClass("Humanoid") then
			_rig = _char:FindFirstChildOfClass("Humanoid").RigType.Name
		end

		if _rig == "R6" then
			BodyParts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" }
		else
			BodyParts = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg", "HumanoidRootPart" }
		end
	end)

	order = order + 1

	local partRow = Instance.new("Frame")
	partRow.Name = "RowSA Target"
	partRow.Size = UDim2.new(1, 0, 0, 27)
	partRow.BackgroundTransparency = 1
	partRow.LayoutOrder = order
	partRow.ZIndex = 5
	partRow.Parent = rows

	label(partRow, "Title", "SA TARGET", UDim2.new(1, -110, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

	local partIndex = table.find(BodyParts, Config.Silent.TargetPart[1]) or 1

	local partButton = Instance.new("TextButton")
	partButton.Name = "Picker"
	partButton.Size = UDim2.fromOffset(84, 20)
	partButton.Position = UDim2.new(1, -98, 0.5, -10)
	partButton.BackgroundColor3 = COLORS.Control
	partButton.TextColor3 = COLORS.White
	partButton.Text = BodyParts[partIndex]
	partButton.TextSize = 9
	partButton.Font = Enum.Font.GothamBold
	partButton.AutoButtonColor = false
	partButton.BorderSizePixel = 0
	partButton.ZIndex = 6
	partButton.Parent = partRow
	corner(partButton, 10)
	stroke(partButton, COLORS.White, 1, 0.7)

	local function setTargetPart(nextIndex)
		partIndex = ((nextIndex - 1) % #BodyParts) + 1
		local chosen = BodyParts[partIndex]
		table.clear(Config.Silent.TargetPart)
		table.insert(Config.Silent.TargetPart, chosen)
		partButton.Text = chosen
	end

	partButton.MouseButton1Click:Connect(function()
		setTargetPart(partIndex + 1)
	end)

	pcall(pressable, partButton)

	switchRow("SA BULLET PEN", Config.Silent.WallBang, function(value)
		Config.Silent.WallBang = value
	end)

	-- AIMBOT (aimlock) - Field Of View settings (ported from the provided script)
	rows = aimRows
	order = 0

	local aimHeader = Instance.new("Frame")
	aimHeader.Name = "AimbotHeader"
	aimHeader.Size = UDim2.new(1, 0, 0, 20)
	aimHeader.BackgroundTransparency = 1
	aimHeader.LayoutOrder = order
	aimHeader.ZIndex = 5
	aimHeader.Parent = rows

	local aimRule = Instance.new("Frame")
	aimRule.Size = UDim2.new(1, -28, 0, 1)
	aimRule.Position = UDim2.new(0, 14, 0.5, -1)
	aimRule.BackgroundColor3 = COLORS.White
	aimRule.BackgroundTransparency = 0.75
	aimRule.BorderSizePixel = 0
	aimRule.ZIndex = 6
	aimRule.Parent = aimHeader

	label(aimHeader, "Title", "AIMBOT", UDim2.new(1, -30, 1, 0), UDim2.fromOffset(14, 0), 8, COLORS.White, Enum.Font.GothamBlack).ZIndex = 6

	-- click-to-cycle picker row (Camera/Mouse, target part, ...)
	local function pickerRow(text, options, current, onPick)
		order = order + 1

		local row = Instance.new("Frame")
		row.Name = "Picker" .. text
		row.Size = UDim2.new(1, 0, 0, 27)
		row.BackgroundTransparency = 1
		row.LayoutOrder = order
		row.ZIndex = 5
		row.Parent = rows

		label(row, "Title", text, UDim2.new(1, -110, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		local index = table.find(options, current) or 1

		local button = Instance.new("TextButton")
		button.Name = "Picker"
		button.Size = UDim2.fromOffset(90, 20)
		button.Position = UDim2.new(1, -104, 0.5, -10)
		button.BackgroundColor3 = COLORS.Control
		button.TextColor3 = COLORS.White
		button.Text = options[index]
		button.TextSize = 9
		button.Font = Enum.Font.GothamBold
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.ZIndex = 6
		button.Parent = row
		corner(button, 10)
		stroke(button, COLORS.White, 1, 0.7)

		button.MouseButton1Click:Connect(function()
			index = (index % #options) + 1
			button.Text = options[index]
			onPick(options[index])
		end)

		pcall(pressable, button)

		return button
	end

	order = order + 1

	-- ENABLE (master) - ported from the aimlock's General > Enabled
	switchRow("ENABLE", Config.Aimlock.Enabled, function(value)
		Config.Aimlock.Enabled = value
		Config.Aimlock.Aiming = value

		if not value then
			AimbotTarget = nil
		end

		refreshAimStatus()
	end)

	-- AIMLOCK TYPE (Camera / Mouse) - click to cycle
	pickerRow("AIMLOCK TYPE", { "Camera", "Mouse" }, Config.Aimlock.Type, function(chosen)
		Config.Aimlock.Type = chosen
	end)

	-- TARGET PART (Head / UpperTorso / Torso / ...) - click to cycle
	pickerRow("TARGET PART", BodyParts, Config.Aimlock.TargetPart, function(chosen)
		Config.Aimlock.TargetPart = chosen
	end)

	-- TEAM CHECK
	switchRow("TEAM CHECK", Config.Aimlock.TeamCheck, function(value)
		Config.Aimlock.TeamCheck = value
	end)

	-- VISIBLE CHECK
	switchRow("VISIBLE CHECK", Config.Aimlock.WallCheck, function(value)
		Config.Aimlock.WallCheck = value
	end)

	-- MAX DISTANCE
	sliderRow("MAX DISTANCE", 0, 3000, Config.Aimlock.MaxDistance, function(value)
		Config.Aimlock.MaxDistance = value
	end)

	-- SMOOTHNESS (0 = instant snap, 100 = very smooth)
	sliderRow("SMOOTHNESS", 0, 100, math.floor((Config.Aimlock.Smoothness or 1) * 10), function(value)
		Config.Aimlock.Smoothness = value / 10
	end)

	-- Field Of View (ported from the aimlock: General Settings > Field Of View)
	switchRow("FOV", Config.Aimlock.UseFieldOfView, function(value)
		Config.Aimlock.UseFieldOfView = value
	end)

	switchRow("FOV CIRCLE", Config.Aimlock.DrawFieldOfView, function(value)
		Config.Aimlock.DrawFieldOfView = value
	end)

	sliderRow("FOV RADIUS", 0, 1000, Config.Aimlock.Radius, function(value)
		Config.Aimlock.Radius = value
	end)

	sliderRow("FOV SIDES", 3, 100, Config.Aimlock.Sides, function(value)
		Config.Aimlock.Sides = value
	end)

	-- sub-section switching (TRIGGERBOT / AIMBOT / SILENT AIM / AUTOKILL)
	local tabButtons = {
		TB = tbTabBtn,
		AIMBOT = aimTabBtn,
		SA = saTabBtn,
		AK = akTabBtn,
	}

	local function selectSubTab(name)
		tbRows.Visible = name == "TB"
		aimRows.Visible = name == "AIMBOT"
		saRows.Visible = name == "SA"
		akRows.Visible = name == "AK"

		for key, button in pairs(tabButtons) do
			local active = key == name
			button.BackgroundTransparency = active and 0.12 or 0.92
			button.TextColor3 = active and COLORS.White or COLORS.Text
		end
	end

	tbTabBtn.MouseButton1Click:Connect(function()
		selectSubTab("TB")
	end)

	aimTabBtn.MouseButton1Click:Connect(function()
		selectSubTab("AIMBOT")
	end)

	saTabBtn.MouseButton1Click:Connect(function()
		selectSubTab("SA")
	end)

	akTabBtn.MouseButton1Click:Connect(function()
		selectSubTab("AK")
	end)

	-- autokill panel: TARGET STRAFE (ported from the provided script)
	rows = akRows
	order = 0

	-- state
	local strafeMethods = { "Circular", "Random", "Sniper" }
	local strafeState = { Active = false, Loop = nil, Angle = 0, RandTimer = 0, RandOffset = Vector3.zero }
	local strafeRadius = 14
	local strafeSpeed = 40
	local strafeMethod = "Circular"
	local strafeStatus = nil

	local function getStrafeTarget()
		local origin = LocalPlayer.Character and FindFirstChild(LocalPlayer.Character, "HumanoidRootPart")
		if not origin then
			return nil
		end
		-- kapag naka-lock ang snapline (silent aim) sa isang kalaban,
		-- iyon din ang iikutan ng strafe
		if SilentTarget and SilentTarget ~= LocalPlayer then
			local sc = SilentTarget.Character
			local sh = sc and FindFirstChildOfClass(sc, "Humanoid")
			local sr = sc and FindFirstChild(sc, "HumanoidRootPart")
			if sh and sr and sh.Health > 0
				and not FindFirstChildOfClass(sc, "ForceField")
				and not IsTeammate(SilentTarget) then
				return SilentTarget
			end
		end
		local closest, closestDist = nil, math.huge
		for _, player in ipairs(GetPlayers(Players)) do
			if player == LocalPlayer then
				continue
			end
			local character = player.Character
			local humanoid = character and FindFirstChildOfClass(character, "Humanoid")
			local root = character and FindFirstChild(character, "HumanoidRootPart")
			if not humanoid or not root or humanoid.Health <= 0 then
				continue
			end
			if FindFirstChildOfClass(character, "ForceField") then
				continue
			end
			if IsTeammate(player) then
				continue
			end
			local dist = (root.Position - origin.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closest = player
			end
		end
		return closest
	end

	local function stopStrafe()
		strafeState.Active = false
		if strafeState.Loop then
			strafeState.Loop:Disconnect()
			strafeState.Loop = nil
		end
		local localRoot = LocalPlayer.Character and FindFirstChild(LocalPlayer.Character, "HumanoidRootPart")
		if localRoot then
			localRoot.AssemblyLinearVelocity = Vector3.zero
		end
	end

	local function startStrafe()
		stopStrafe()
		strafeState.Active = true
		strafeState.Loop = trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
			if not strafeState.Active then
				return
			end
			local targetPlayer = getStrafeTarget()
			local targetRoot = targetPlayer and targetPlayer.Character and FindFirstChild(targetPlayer.Character, "HumanoidRootPart")
			local localRoot = LocalPlayer.Character and FindFirstChild(LocalPlayer.Character, "HumanoidRootPart")
			if not targetRoot or not localRoot then
				strafeStatus.Text = "NO TARGET"
				strafeStatus.TextColor3 = COLORS.Red
				return
			end
			strafeStatus.Text = "ON"
			strafeStatus.TextColor3 = COLORS.Green
			local position = targetRoot.Position
			local n
			if strafeMethod == "Sniper" then
				strafeState.Angle = strafeState.Angle + math.rad(strafeSpeed) * deltaTime * 60
				local n2 = strafeRadius * 2
				n = position
					+ Vector3.new(math.cos(strafeState.Angle) * n2, strafeRadius * 4 + 40, math.sin(strafeState.Angle) * n2)
			elseif strafeMethod == "Random" then
				strafeState.RandTimer = strafeState.RandTimer - deltaTime
				if strafeState.RandTimer <= 0 or strafeState.RandOffset.Magnitude == 0 then
					strafeState.RandTimer = 0.12
					local n2 = math.random() * math.pi * 2
					local n3 = (math.random() - 0.5) * strafeRadius
					strafeState.RandOffset = Vector3.new(math.cos(n2) * strafeRadius, n3, math.sin(n2) * strafeRadius)
				end
				n = position + strafeState.RandOffset
			else
				strafeState.Angle = strafeState.Angle + math.rad(strafeSpeed) * deltaTime * 60
				n = position + Vector3.new(math.cos(strafeState.Angle) * strafeRadius, 0, math.sin(strafeState.Angle) * strafeRadius)
			end
			-- orbit the target but keep the character's own facing, so your
			-- view/aim isn't hijacked while snapline / silent aim is locked on
			localRoot.CFrame = CFrame.new(n) * localRoot.CFrame.Rotation
			localRoot.AssemblyLinearVelocity = Vector3.zero
		end))
	end

	local function toggleStrafe(value)
		if value then
			startStrafe()
			strafeStatus.Text = "ON"
			strafeStatus.TextColor3 = COLORS.Green
		else
			stopStrafe()
			strafeStatus.Text = "OFF"
			strafeStatus.TextColor3 = COLORS.Dim
		end
	end

	-- section header
	local akHeader = Instance.new("Frame")
	akHeader.Name = "AutoKillHeader"
	akHeader.Size = UDim2.new(1, 0, 0, 20)
	akHeader.BackgroundTransparency = 1
	akHeader.LayoutOrder = order
	akHeader.ZIndex = 5
	akHeader.Parent = rows

	local akRule = Instance.new("Frame")
	akRule.Size = UDim2.new(1, -28, 0, 1)
	akRule.Position = UDim2.new(0, 14, 0.5, -1)
	akRule.BackgroundColor3 = COLORS.White
	akRule.BackgroundTransparency = 0.75
	akRule.BorderSizePixel = 0
	akRule.ZIndex = 6
	akRule.Parent = akHeader

	label(akHeader, "Title", "TARGET STRAFE", UDim2.new(1, -30, 1, 0), UDim2.fromOffset(14, 0), 8, COLORS.White, Enum.Font.GothamBlack).ZIndex = 6

	strafeStatus = label(
		akHeader,
		"Status",
		"OFF",
		UDim2.new(1, -30, 1, 0),
		UDim2.fromOffset(0, 0),
		8,
		COLORS.Dim,
		Enum.Font.GothamBold
	)
	strafeStatus.TextXAlignment = Enum.TextXAlignment.Right
	strafeStatus.ZIndex = 6

	local strafeSwitch = switchRow("STRAFE [H]", false, toggleStrafe)

	-- method cycle (same picker style as SA TARGET)
	order = order + 1
	local methodRow = Instance.new("Frame")
	methodRow.Name = "RowStrafeMethod"
	methodRow.Size = UDim2.new(1, 0, 0, 27)
	methodRow.BackgroundTransparency = 1
	methodRow.LayoutOrder = order
	methodRow.ZIndex = 5
	methodRow.Parent = rows

	label(methodRow, "Title", "METHOD", UDim2.new(1, -110, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

	local methodIndex = 1
	local methodButton = Instance.new("TextButton")
	methodButton.Name = "Picker"
	methodButton.Size = UDim2.fromOffset(84, 20)
	methodButton.Position = UDim2.new(1, -98, 0.5, -10)
	methodButton.BackgroundColor3 = COLORS.Control
	methodButton.TextColor3 = COLORS.White
	methodButton.Text = strafeMethod
	methodButton.TextSize = 9
	methodButton.Font = Enum.Font.GothamBold
	methodButton.AutoButtonColor = false
	methodButton.BorderSizePixel = 0
	methodButton.ZIndex = 6
	methodButton.Parent = methodRow
	corner(methodButton, 10)
	stroke(methodButton, COLORS.White, 1, 0.7)
	pcall(pressable, methodButton)

	methodButton.MouseButton1Click:Connect(function()
		methodIndex = (methodIndex % #strafeMethods) + 1
		strafeMethod = strafeMethods[methodIndex]
		methodButton.Text = strafeMethod
	end)

	-- keybind row: click the button, then press any key to set it
	order = order + 1
	local keyRow = Instance.new("Frame")
	keyRow.Name = "RowStrafeKey"
	keyRow.Size = UDim2.new(1, 0, 0, 27)
	keyRow.BackgroundTransparency = 1
	keyRow.LayoutOrder = order
	keyRow.ZIndex = 5
	keyRow.Parent = rows

	label(keyRow, "Title", "KEYBIND", UDim2.new(1, -110, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

	local strafeKey = Enum.KeyCode.H
	local rebindingKey = false

	local keyButton = Instance.new("TextButton")
	keyButton.Name = "KeyButton"
	keyButton.Size = UDim2.fromOffset(64, 20)
	keyButton.Position = UDim2.new(1, -78, 0.5, -10)
	keyButton.BackgroundColor3 = COLORS.Control
	keyButton.TextColor3 = COLORS.White
	keyButton.Text = strafeKey.Name
	keyButton.TextSize = 9
	keyButton.Font = Enum.Font.GothamBold
	keyButton.AutoButtonColor = false
	keyButton.BorderSizePixel = 0
	keyButton.ZIndex = 6
	keyButton.Parent = keyRow
	corner(keyButton, 10)
	stroke(keyButton, COLORS.White, 1, 0.7)
	pcall(pressable, keyButton)

	local function setKeyLabel()
		keyButton.Text = rebindingKey and "..." or strafeKey.Name
		local card = strafeSwitch.Gui and strafeSwitch.Gui.Parent
		local switchLabel = card and card:FindFirstChild("Title")
		if switchLabel then
			switchLabel.Text = rebindingKey and "STRAFE (press any key)" or ("STRAFE [" .. strafeKey.Name .. "]")
		end
	end

	keyButton.MouseButton1Click:Connect(function()
		if rebindingKey then
			return
		end
		rebindingKey = true
		setKeyLabel()
	end)

	sliderRow("RADIUS", 4, 60, strafeRadius, function(value)
		strafeRadius = value
	end)

	sliderRow("SPEED", 1, 100, strafeSpeed, function(value)
		strafeSpeed = value
	end)

	-- keybind: chosen key toggles strafe on / off (click the KEYBIND button to rebind)
	trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if rebindingKey then
			if input.KeyCode == Enum.KeyCode.Escape then
				rebindingKey = false
				setKeyLabel()
				return
			end
			if
				input.KeyCode
				and input.KeyCode ~= Enum.KeyCode.Unknown
				and not UserInputService:GetFocusedTextBox()
			then
				strafeKey = input.KeyCode
				rebindingKey = false
				setKeyLabel()
			end
			return
		end

		if input.KeyCode ~= strafeKey then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		strafeSwitch.Toggle()
	end))

	selectSubTab("TB")

	-- engine
	trackConnection(RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera

		if not camera then
			return
		end

		if not Trigger.Enabled then
			fovFrame.Visible = false
			currentTarget = nil
			return
		end

		currentTarget = getTarget(camera)

		local viewport = camera.ViewportSize
		fovFrame.Position = UDim2.fromOffset(viewport.X * 0.5, viewport.Y * 0.5)
		fovFrame.Size = UDim2.fromOffset(Trigger.FOV * 2, Trigger.FOV * 2)
		fovFrame.Visible = Trigger.ShowFOV
		if currentTarget then
			fovStroke.Color = COLORS.White
		else
			fovStroke.Color = Color3.fromHSV((os.clock() * 0.6) % 1, 1, 1)
		end

		if currentTarget then
			local now = os.clock()
			local shots = 0

			if Trigger.RapidFire then
				-- slider speed = shots per second; several activations per frame
				local interval = 1 / math.max(1, Trigger.RapidSpeed)

				if now - lastFire >= interval then
					shots = math.clamp(math.floor((now - lastFire) / interval), 1, MAX_SHOTS_PER_FRAME)
					lastFire = now
				end
			elseif now - lastFire >= Trigger.FireRate then
				shots = 1
				lastFire = now
			end

			for _ = 1, shots do
				fire()
			end
		end
	end))

	-- anti aim: face away from where you look, with a slow wobble so the angle never sits still
	trackConnection(RunService.RenderStepped:Connect(function()
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not root or not humanoid then
			return
		end

		if not aaEnabled or Trigger.AimAngle <= 0 then
			if humanoid.AutoRotate == false then
				humanoid.AutoRotate = true
			end

			return
		end

		humanoid.AutoRotate = false

		local camera = Workspace.CurrentCamera

		if not camera then
			return
		end

		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)

		if flat.Magnitude < 0.05 then
			return
		end

		-- steady angle: face where you look, then twist by AIM ANGLE degrees
		local base = CFrame.lookAt(root.Position, root.Position + flat)
		root.CFrame = base * CFrame.Angles(0, math.rad(Trigger.AimAngle), 0)
	end))

	table.insert(restoreCallbacks, function()
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.AutoRotate = true
		end
	end)
end

------------------------------------------------------------------
-- MOVEMENT page (visual only - no logic attached)
------------------------------------------------------------------
do
	local dash = Instance.new("Frame")
	dash.Size = UDim2.fromOffset(10, 1)
	dash.Position = UDim2.fromOffset(17, 19)
	dash.BackgroundColor3 = COLORS.Dim
	dash.BorderSizePixel = 0
	dash.ZIndex = 3
	dash.Parent = movementPage

	label(movementPage, "MovementTitle", "MOVEMENT", UDim2.fromOffset(70, 24), UDim2.fromOffset(33, 8), 11, COLORS.White, Enum.Font.GothamBold).ZIndex =
		3

	local rule = Instance.new("Frame")
	rule.Size = UDim2.new(1, -126, 0, 1)
	rule.Position = UDim2.fromOffset(109, 19)
	rule.BackgroundColor3 = COLORS.Dim
	rule.BackgroundTransparency = 0.35
	rule.BorderSizePixel = 0
	rule.ZIndex = 3
	rule.Parent = movementPage

	local function featureRow(name, title, y)
		local row = Instance.new("Frame")
		row.Name = name .. "Row"
		row.Size = UDim2.new(1, -34, 0, 42)
		row.Position = UDim2.fromOffset(17, y)
		row.BackgroundColor3 = COLORS.Log
		row.BackgroundTransparency = 0.12
		row.BorderSizePixel = 0
		row.ZIndex = 3
		row.Parent = movementPage
		corner(row, 9)
		stroke(row, COLORS.White, 1, 0.8)

		local key = Instance.new("TextButton")
		key.Name = "Keybind"
		key.Size = UDim2.fromOffset(72, 24)
		key.Position = UDim2.fromOffset(9, 9)
		key.BackgroundColor3 = COLORS.Control
		key.BorderSizePixel = 0
		key.AutoButtonColor = false
		key.Text = "NONE"
		key.TextSize = 10
		key.TextColor3 = COLORS.White
		key.Font = Enum.Font.GothamBold
		key.ZIndex = 5
		key.Parent = row
		corner(key, 7)
		stroke(key, COLORS.White, 1, 0.72)
		pressable(key)

		label(row, "Title", title, UDim2.new(1, -153, 1, 0), UDim2.fromOffset(88, 0), 11, COLORS.White, Enum.Font.GothamMedium).ZIndex = 6

		createSwitch(row, { position = UDim2.new(1, -56, 0.5, -12), size = UDim2.fromOffset(47, 24), state = false, zIndex = 6 })

		key.MouseButton1Click:Connect(function()
			key.Text = key.Text == "NONE" and "..." or "NONE"
		end)
	end

	featureRow("speed", "Speed", 44)
	featureRow("jump", "Jump Power", 94)
	featureRow("noclip", "NoClip", 144)

	local note = label(
		movementPage,
		"Note",
		"visual only - nothing wired up",
		UDim2.new(1, -34, 0, 16),
		UDim2.fromOffset(17, 196),
		9,
		COLORS.Dim,
		Enum.Font.GothamBold
	)
	note.TextXAlignment = Enum.TextXAlignment.Center
	note.ZIndex = 4
-- =====================================================
	-- MOVEMENT FEATURES: walk speed (WalkSpeed/Velocity) + fly (Classic/CFrame/Superman)
	-- Uses the same row style as the triggerbot card rows
	-- =====================================================

	-- hide the old visual-only rows + note
	if movementPage then
		local function mvHideRow(name)
			local r = movementPage:FindFirstChild(name .. "Row")
			if r then r.Visible = false end
		end
		mvHideRow("speed")
		mvHideRow("jump")
		mvHideRow("noclip")

		local mvNote = movementPage:FindFirstChild("Note")
		if mvNote then mvNote.Visible = false end
	end

	getgenv().AntiCheatBypass = true

	local MOVE = {
		WalkSpeed = { Enabled = false, Type = "WalkSpeed", Types = { "WalkSpeed", "Velocity" }, Value = 16 },
		Fly = { Enabled = false, Type = "Classic", Types = { "Classic", "CFrame", "Superman" }, Value = 35 },
	}

	local MOVE_RunService = game:GetService("RunService")
	local MOVE_UIS = game:GetService("UserInputService")
	local MOVE_LocalPlayer = game:GetService("Players").LocalPlayer

	-- noclip state
	local MOVE_NoClip = { Enabled = false }
	local mv_noclipOffDone = true
	local movNoclipCache = {}
	local movNoclipChar = nil
	local movNoclipTick = 0

	local MOVE_NOCLIP_PARTS = {
		Head = true,
		HumanoidRootPart = true,
		Torso = true,
		UpperTorso = true,
		LowerTorso = true,
		["Left Arm"] = true,
		["Right Arm"] = true,
		["Left Leg"] = true,
		["Right Leg"] = true,
		LeftUpperArm = true,
		LeftLowerArm = true,
		RightUpperArm = true,
		RightLowerArm = true,
		LeftUpperLeg = true,
		LeftLowerLeg = true,
		RightUpperLeg = true,
		RightLowerLeg = true,
	}

	-- compact slider (same look as the triggerbot sliders)
	local function mvSlider(parent, minValue, maxValue, initial, onChange)
		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(1, -28, 0, 4)
		track.Position = UDim2.new(0, 14, 0, 24)
		track.BackgroundColor3 = COLORS.Control
		track.BorderSizePixel = 0
		track.ZIndex = 6
		track.Parent = parent
		corner(track, 2)

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = COLORS.White
		fill.BorderSizePixel = 0
		fill.ZIndex = 7
		fill.Parent = track
		corner(fill, 2)

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		thumb.Size = UDim2.fromOffset(10, 10)
		thumb.BackgroundColor3 = COLORS.White
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 8
		thumb.Parent = track
		corner(thumb, 5)
		stroke(thumb, COLORS.Window, 1, 0.35)

		local current = initial

		local function apply(value, animate)
			current = value
			local ratio = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
			if animate then
				TweenService:Create(fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(ratio, 0, 1, 0),
				}):Play()
				TweenService:Create(thumb, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(ratio, 0, 0.5, 0),
				}):Play()
			else
				fill.Size = UDim2.new(ratio, 0, 1, 0)
				thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
			end
			if onChange then onChange(value) end
		end

		apply(initial, false)

		local dragging = false

		local function moveTo(x)
			local absolute = track.AbsolutePosition.X
			local width = math.max(track.AbsoluteSize.X, 1)
			local ratio = math.clamp((x - absolute) / width, 0, 1)
			local value = math.floor(minValue + ratio * (maxValue - minValue) + 0.5)
			if value ~= current then
				apply(value, false)
			end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				moveTo(input.Position.X)
			end
		end)

		MOVE_UIS.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				moveTo(input.Position.X)
			end
		end)

		MOVE_UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	-- switch row (same as the triggerbot card rows)
	local function mvSwitchRow(parent, y, text, initial, onChange)
		local row = Instance.new("Frame")
		row.Name = "Row" .. text
		row.Size = UDim2.new(1, -34, 0, 27)
		row.Position = UDim2.fromOffset(17, y)
		row.BackgroundTransparency = 1
		row.ZIndex = 5
		row.Parent = parent

		label(row, "Title", text, UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		local sw = createSwitch(row, { state = initial, zIndex = 6, onChange = onChange })
		return { Row = row, Switch = sw }
	end

	-- picker row (same as the SA TARGET picker)
	local function mvPickerRow(parent, y, text, initial, options, onPick)
		local row = Instance.new("Frame")
		row.Name = "Row" .. text
		row.Size = UDim2.new(1, -34, 0, 27)
		row.Position = UDim2.fromOffset(17, y)
		row.BackgroundTransparency = 1
		row.ZIndex = 5
		row.Parent = parent

		label(row, "Title", text, UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		local current = initial

		local btn = Instance.new("TextButton")
		btn.Name = "Picker"
		btn.Size = UDim2.fromOffset(84, 20)
		btn.Position = UDim2.new(1, -98, 0.5, -10)
		btn.BackgroundColor3 = COLORS.Control
		btn.TextColor3 = COLORS.White
		btn.Text = tostring(current)
		btn.TextSize = 9
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = false
		btn.BorderSizePixel = 0
		btn.ZIndex = 6
		btn.Parent = row
		corner(btn, 10)
		stroke(btn, COLORS.White, 1, 0.7)
		pcall(pressable, btn)

		btn.MouseButton1Click:Connect(function()
			local idx = table.find(options, current) or 1
			current = options[(idx % #options) + 1]
			btn.Text = tostring(current)
			if onPick then onPick(current) end
		end)
	end

	-- slider row (same as the triggerbot sliders)
	local function mvSliderRow(parent, y, text, minValue, maxValue, initial, onChange)
		local row = Instance.new("Frame")
		row.Name = "Slider" .. text
		row.Size = UDim2.new(1, -34, 0, 36)
		row.Position = UDim2.fromOffset(17, y)
		row.BackgroundTransparency = 1
		row.ZIndex = 5
		row.Parent = parent

		label(row, "Title", text, UDim2.new(0.5, -10, 0, 14), UDim2.fromOffset(14, 4), 10, COLORS.Text, Enum.Font.GothamMedium).ZIndex = 6

		local valueLabel = label(row, "Value", tostring(initial), UDim2.new(0.5, -20, 0, 14), UDim2.new(0.5, 5, 0, 4), 10, COLORS.White, Enum.Font.GothamBold)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 6

		mvSlider(row, minValue, maxValue, initial, function(value)
			if onChange then onChange(value) end
			valueLabel.Text = tostring(value)
		end)
	end

	-- ============ WALK SPEED ============
	mvSwitchRow(movementPage, 40, "WALK SPEED", MOVE.WalkSpeed.Enabled, function(value)
		MOVE.WalkSpeed.Enabled = value
	end)

	mvPickerRow(movementPage, 76, "TYPE", MOVE.WalkSpeed.Type, MOVE.WalkSpeed.Types, function(value)
		MOVE.WalkSpeed.Type = value
	end)

	mvSliderRow(movementPage, 108, "SPEED", 1, 200, MOVE.WalkSpeed.Value, function(value)
		MOVE.WalkSpeed.Value = value
	end)

	-- ============ FLY ============
	mvSwitchRow(movementPage, 152, "FLY", MOVE.Fly.Enabled, function(value)
		MOVE.Fly.Enabled = value
	end)

	mvPickerRow(movementPage, 188, "TYPE", MOVE.Fly.Type, MOVE.Fly.Types, function(value)
		MOVE.Fly.Type = value
	end)

	mvSliderRow(movementPage, 220, "SPEED", 5, 200, MOVE.Fly.Value, function(value)
		MOVE.Fly.Value = value
	end)

	-- ============ NOCLIP ============
	mvSwitchRow(movementPage, 264, "NOCLIP", MOVE_NoClip.Enabled, function(value)
		MOVE_NoClip.Enabled = value
		mv_noclipOffDone = false
	end)

	-- =====================================================
	-- MOVEMENT LOGIC
	-- =====================================================

	local mv_flyStarted = false
	local mv_flyRoot = nil
	local mv_flyActiveType = nil
	local mv_registry = {}
	local mv_speedResetDone = false

	local function mv_clearRegistry()
		for _, item in ipairs(mv_registry) do
			local t = typeof(item)
			if t == "RBXScriptConnection" then
				pcall(item.Disconnect, item)
			elseif t == "Instance" then
				pcall(function() item:Destroy() end)
			elseif t == "function" then
				pcall(item)
			end
		end
		mv_registry = {}
	end

	local function mv_flightDir()
		return Vector3.new(
			(MOVE_UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (MOVE_UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
			(MOVE_UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (MOVE_UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
			(MOVE_UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (MOVE_UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
		)
	end

	local function mv_standUp(root)
		if root then
			local h = root:FindFirstChildOfClass("Humanoid")
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
		end
	end

	local function mv_stopFly()
		mv_clearRegistry()
		mv_standUp(mv_flyRoot)
		mv_flyStarted = false
		mv_flyRoot = nil
		mv_flyActiveType = nil
	end

	local function mv_startFly(root, hum)
		mv_stopFly()
		mv_flyRoot = root
		mv_flyActiveType = MOVE.Fly.Type

		if MOVE.Fly.Type == "Classic" then
			-- BodyGyro + BodyVelocity, freefall (keeps your tool armed)
			local gyro = Instance.new("BodyGyro")
			gyro.P = 9e4
			gyro.D = 1e3
			gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			local velo = Instance.new("BodyVelocity")
			velo.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			table.insert(mv_registry, gyro)
			table.insert(mv_registry, velo)
			table.insert(mv_registry, MOVE_RunService.Stepped:Connect(function()
				if not MOVE.Fly.Enabled or not root or not root.Parent then
					mv_stopFly()
					return
				end
				local camera = workspace.CurrentCamera
				local orientation = CFrame.new()
				if camera then
					orientation = CFrame.fromEulerAnglesXYZ(camera.CFrame:ToEulerAnglesXYZ())
				end
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
				gyro.CFrame = orientation
				velo.Velocity = orientation:PointToWorldSpace(mv_flightDir() * MOVE.Fly.Value)
				gyro.Parent = root
				velo.Parent = root
			end))

		elseif MOVE.Fly.Type == "CFrame" then
			-- move the root by CFrame every step, zero gravity via BodyVelocity
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bv.Velocity = Vector3.zero
			table.insert(mv_registry, bv)
			table.insert(mv_registry, MOVE_RunService.Stepped:Connect(function(_, delta_time)
				if not MOVE.Fly.Enabled or not root or not root.Parent then
					mv_stopFly()
					return
				end
				local camera = workspace.CurrentCamera
				local orientation = CFrame.new()
				if camera then
					orientation = CFrame.fromEulerAnglesXYZ(camera.CFrame:ToEulerAnglesXYZ())
				end
				local dir = mv_flightDir() * MOVE.Fly.Value * delta_time
				root.CFrame = CFrame.new(root.Position) * orientation * CFrame.new(dir)
				bv.Velocity = Vector3.zero
				bv.Parent = root
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
			end))
			table.insert(mv_registry, function()
				mv_standUp(root)
			end)

		elseif MOVE.Fly.Type == "Superman" then
			-- bobbing hover + camera WASD + flying pose animations
			local sup_originalGravity = game.Workspace.Gravity
			local sup_currentAnimTrack = nil

			local function sup_disableAnimate()
				local animate = MOVE_LocalPlayer.Character and MOVE_LocalPlayer.Character:FindFirstChild("Animate")
				if animate then animate.Disabled = true end
			end
			local function sup_enableAnimate()
				local animate = MOVE_LocalPlayer.Character and MOVE_LocalPlayer.Character:FindFirstChild("Animate")
				if animate then animate.Disabled = false end
			end
			local function sup_playAnimation(animId, startTime, spd)
				if sup_currentAnimTrack then
					pcall(function() sup_currentAnimTrack:Stop(0.1) end)
					sup_currentAnimTrack = nil
				end
				sup_disableAnimate()
				pcall(function()
					for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
						track:Stop()
					end
				end)
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. tostring(animId)
				sup_currentAnimTrack = hum:LoadAnimation(anim)
				sup_currentAnimTrack:Play()
				sup_currentAnimTrack.TimePosition = startTime
				sup_currentAnimTrack:AdjustSpeed(spd)
			end
			local function sup_stopAnimation()
				if sup_currentAnimTrack then
					pcall(function() sup_currentAnimTrack:Stop(0.1) end)
					sup_currentAnimTrack = nil
				end
				sup_enableAnimate()
				pcall(function()
					for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
						track:Stop()
					end
				end)
			end

			local sup_moveState = { forward = 0, backward = 0, left = 0, right = 0 }
			local sup_currentCF = nil
			local sup_currentRoll = 0
			local sup_curVelocity = Vector3.new(0, 0, 0)

			game.Workspace.Gravity = 0
			hum.PlatformStand = true
			sup_playAnimation(10714347256, 4, 0)

			local sup_gyro = Instance.new("BodyGyro")
			sup_gyro.Name = "SupFlyGyro"
			sup_gyro.P = 90000
			sup_gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			sup_gyro.CFrame = root.CFrame
			sup_gyro.Parent = root

			local sup_bv = Instance.new("BodyVelocity")
			sup_bv.Name = "SupFlyVelocity"
			sup_bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			sup_bv.Velocity = Vector3.new(0, 0.1, 0)
			sup_bv.Parent = root

			local sup_renderConn = MOVE_RunService.RenderStepped:Connect(function()
				if not MOVE.Fly.Enabled or not root or not root.Parent then
					mv_stopFly()
					return
				end
				local cam = workspace.CurrentCamera
				if not cam then return end
				local fwd = sup_moveState.forward - sup_moveState.backward
				local side = sup_moveState.right - sup_moveState.left

				local inputVec = (cam.CFrame.LookVector * fwd) + (cam.CFrame.RightVector * side)
				if fwd ~= 0 then
					inputVec = inputVec + Vector3.new(0, 0.2 * fwd, 0)
				end

				local desiredVelocity
				if inputVec.Magnitude > 0 then
					desiredVelocity = inputVec.Unit * MOVE.Fly.Value
				else
					local bobbing = math.sin(tick() * 1) * 0.5
					desiredVelocity = Vector3.new(0, bobbing, 0)
				end

				sup_curVelocity = sup_curVelocity:Lerp(desiredVelocity, 0.1)
				sup_bv.Velocity = sup_curVelocity
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)

				local desiredCF
				if fwd > 0 then
					desiredCF = cam.CFrame * CFrame.Angles(math.rad(-90), 0, math.rad(sup_currentRoll))
				else
					desiredCF = cam.CFrame * CFrame.Angles(math.rad(-45 * fwd), 0, math.rad(sup_currentRoll))
				end
				sup_currentCF = sup_currentCF and sup_currentCF:Lerp(desiredCF, 0.1) or desiredCF
				sup_gyro.CFrame = sup_currentCF
			end)

			local sup_inputBegan = MOVE_UIS.InputBegan:Connect(function(input, gp)
				if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				local key = input.KeyCode
				if key == Enum.KeyCode.W then
					sup_moveState.forward = 1
					sup_playAnimation(10714177846, 4.65, 0)
				elseif key == Enum.KeyCode.S then
					sup_moveState.backward = 1
					sup_playAnimation(10714347256, 4, 0)
				elseif key == Enum.KeyCode.A then
					sup_moveState.left = 1
					if sup_moveState.forward > 0 then sup_playAnimation(10714177846, 4.65, 0) end
				elseif key == Enum.KeyCode.D then
					sup_moveState.right = 1
					if sup_moveState.forward > 0 then sup_playAnimation(10714177846, 4.65, 0) end
				end
			end)

			local sup_inputEnded = MOVE_UIS.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				local key = input.KeyCode
				if key == Enum.KeyCode.W then
					sup_moveState.forward = 0
					sup_playAnimation(10714347256, 4, 0)
				elseif key == Enum.KeyCode.S then
					sup_moveState.backward = 0
					sup_playAnimation(10714347256, 4, 0)
				elseif key == Enum.KeyCode.A then
					sup_moveState.left = 0
					if sup_moveState.forward > 0 then sup_playAnimation(10714177846, 4.65, 0) end
				elseif key == Enum.KeyCode.D then
					sup_moveState.right = 0
					if sup_moveState.forward > 0 then sup_playAnimation(10714177846, 4.65, 0) end
				end
			end)

			table.insert(mv_registry, sup_renderConn)
			table.insert(mv_registry, sup_inputBegan)
			table.insert(mv_registry, sup_inputEnded)
			table.insert(mv_registry, sup_gyro)
			table.insert(mv_registry, sup_bv)
			table.insert(mv_registry, function()
				game.Workspace.Gravity = sup_originalGravity
				pcall(function() hum.PlatformStand = false end)
				sup_stopAnimation()
				sup_moveState = { forward = 0, backward = 0, left = 0, right = 0 }
				sup_currentCF = nil
				sup_curVelocity = Vector3.new(0, 0, 0)
				mv_standUp(root)
			end)
		end

		mv_flyStarted = true
	end

	MOVE_RunService:BindToRenderStep("MV_NOCLIP", 5, function()
		if MOVE_NoClip.Enabled then
			local c = MOVE_LocalPlayer.Character
			if c and c ~= movNoclipChar then
				movNoclipChar = c
				movNoclipCache = {}
				for _, v in ipairs(c:GetDescendants()) do
					if v:IsA("BasePart") and MOVE_NOCLIP_PARTS[v.Name] then
						table.insert(movNoclipCache, v)
					end
				end
			end
			movNoclipTick = movNoclipTick + 1
			if movNoclipTick % 2 ~= 0 then return end
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health ~= 0 then
				for _, v in ipairs(movNoclipCache) do
					if v and v.Parent then pcall(function() v.CanCollide = false end) end
				end
			end
		else
			if not mv_noclipOffDone then
				mv_noclipOffDone = true
				local c = MOVE_LocalPlayer.Character
				if c then
					for _, v in ipairs(c:GetDescendants()) do
						if v:IsA("BasePart") and MOVE_NOCLIP_PARTS[v.Name] and v.Parent then
							pcall(function() v.CanCollide = true end)
						end
					end
				end
			end
		end
	end)

	MOVE_RunService:BindToRenderStep("MV_WALK", 1050, function()
		local char = MOVE_LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		-- fly state machine (auto-restarts after respawn or type change)
		if MOVE.Fly.Enabled then
			if mv_flyStarted then
				if MOVE.Fly.Type ~= mv_flyActiveType then
					mv_startFly(root, hum)
				elseif root and root ~= mv_flyRoot and hum and hum.Health > 0 then
					mv_startFly(root, hum)
				end
			elseif root and hum and hum.Health > 0 then
				mv_startFly(root, hum)
			end
		else
			if mv_flyStarted then mv_stopFly() end
		end

		-- walk speed
		if MOVE.WalkSpeed.Enabled and not MOVE.Fly.Enabled then
			if hum and MOVE.WalkSpeed.Type == "WalkSpeed" then
				hum.WalkSpeed = MOVE.WalkSpeed.Value
			elseif root and MOVE.WalkSpeed.Type == "Velocity" then
				local dir = Vector3.zero
				local camera = workspace.CurrentCamera
				if camera then
					if MOVE_UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z) end
					if MOVE_UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z) end
					if MOVE_UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z) end
					if MOVE_UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z) end
				end
				if dir.Magnitude > 0 then
					root.AssemblyLinearVelocity = dir.Unit * MOVE.WalkSpeed.Value + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
				end
			end
			mv_speedResetDone = false
		else
			if not mv_speedResetDone then
				mv_speedResetDone = true
				local c = MOVE_LocalPlayer.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if h then pcall(function() h.WalkSpeed = 16 end) end
			end
		end
	end)
end

------------------------------------------------------------------
-- ESP skeleton (toggled from VISUAL) - screen space bones over players
------------------------------------------------------------------
local skeleton = {}

do
	-- bone pairs: R15 first, then R6 - pairs with a missing part are skipped
	local BONES = {
		{ "HumanoidRootPart", "LowerTorso" },
		{ "LowerTorso", "UpperTorso" },
		{ "UpperTorso", "Head" },
		{ "UpperTorso", "LeftUpperArm" },
		{ "LeftUpperArm", "LeftLowerArm" },
		{ "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" },
		{ "RightUpperArm", "RightLowerArm" },
		{ "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" },
		{ "LeftUpperLeg", "LeftLowerLeg" },
		{ "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" },
		{ "RightUpperLeg", "RightLowerLeg" },
		{ "RightLowerLeg", "RightFoot" },
		{ "HumanoidRootPart", "Torso" },
		{ "Torso", "Head" },
		{ "Torso", "Left Arm" },
		{ "Torso", "Right Arm" },
		{ "Torso", "Left Leg" },
		{ "Torso", "Right Leg" },
	}

	local BONE_COUNT = #BONES
	local BONE_THICKNESS = 2
	local me = Players.LocalPlayer

	local espGui = Instance.new("ScreenGui")
	espGui.Name = "ACECodeSniperSkeleton"
	espGui.ResetOnSpawn = false
	espGui.IgnoreGuiInset = true
	espGui.DisplayOrder = 2147483645
	espGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	espGui.Enabled = false

	pcall(function()
		espGui.OnTopOfCoreBlur = true
	end)

	for _, parent in ipairs(huiParents()) do
		pcall(function()
			espGui.Parent = parent
		end)

		if espGui.Parent then
			break
		end
	end

	local layer = Instance.new("Frame")
	layer.Name = "Bones"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ZIndex = 150
	layer.Parent = espGui

	local entries = {}
	local enabled = false
	local rainbow = false -- rainbow colouring (turn off for green/red wall detection)
	local RAINBOW_SPEED = 0.12 -- hue cycles per second
	local UPDATE_RATE = 1 / 30 -- skeleton redraws at 30 Hz instead of every frame
	local updateAccum = 0

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	-- reused so no table is allocated per raycast
	local filterList = { nil }

	local function clearEntries()
		for _, entry in pairs(entries) do
			entry.container:Destroy()
		end

		table.clear(entries)
	end

	-- bones are resolved ONCE per character instead of 21 FindFirstChild calls per frame
	local function resolveBones(character)
		local resolved = {}

		for _, bone in ipairs(BONES) do
			local partA = character:FindFirstChild(bone[1])
			local partB = character:FindFirstChild(bone[2])

			if partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
				resolved[#resolved + 1] = { partA, partB }
			end
		end

		return resolved
	end

	local function hideLine(record)
		if record.visible then
			record.visible = false
			record.frame.Visible = false
		end
	end

	local function buildEntry(player, character)
		local container = Instance.new("Frame")
		container.Name = "Skeleton" .. tostring(player.UserId)
		container.Size = UDim2.fromScale(1, 1)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.ZIndex = 151
		container.Parent = layer

		local lines = {}

		for index = 1, BONE_COUNT do
			local line = Instance.new("Frame")
			line.Name = "Bone" .. index
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundColor3 = COLORS.Green
			line.BorderSizePixel = 0
			line.ZIndex = 152
			line.Visible = false
			line.Parent = container
			corner(line, 1)

			-- last written values: untouched properties never trigger a layout pass
			lines[index] = {
				frame = line,
				visible = false,
				px = nil,
				py = nil,
				len = nil,
				rot = nil,
				color = nil,
			}
		end

		return { container = container, lines = lines, character = character, bones = resolveBones(character) }
	end

	local function update(dt)
		if not enabled then
			return
		end

		-- 30 Hz cap: half the work of a per-frame redraw, still smooth
		updateAccum = updateAccum + dt

		if updateAccum < UPDATE_RATE then
			return
		end

		updateAccum = 0

		local camera = Workspace.CurrentCamera

		if not camera then
			return
		end

		local origin = camera.CFrame.Position
		local viewport = camera.ViewportSize
		local viewX, viewY = viewport.X, viewport.Y
		local hue = (os.clock() * RAINBOW_SPEED) % 1
		local seen = {}

		-- filter list reused: no table allocation per raycast
		filterList[1] = me.Character
		rayParams.FilterDescendantsInstances = filterList

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= me then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					seen[player] = true

					local entry = entries[player]

					if not entry then
						entry = buildEntry(player, character)
						entries[player] = entry
					elseif entry.character ~= character then
						-- respawned: re-resolve the bone list (once, not per frame)
						entry.character = character
						entry.bones = resolveBones(character)
					end

					-- one projection for the whole player: everyone off screen is skipped entirely
					local rootScreen, rootOnScreen = camera:WorldToViewportPoint(root.Position)

					local onScreen = rootOnScreen
						and rootScreen.Z > 0
						and rootScreen.X > -140
						and rootScreen.X < viewX + 140
						and rootScreen.Y > -180
						and rootScreen.Y < viewY + 180

					if onScreen ~= entry.container.Visible then
						entry.container.Visible = onScreen
					end

					if onScreen then
						-- green = clear line of sight, red = behind a wall (skipped while rainbow is on)
						local sightColor

						if not rainbow then
							local hit = Workspace:Raycast(origin, root.Position - origin, rayParams)
							local visible = hit == nil or (hit.Instance and hit.Instance:IsDescendantOf(character))
							sightColor = visible and COLORS.Green or COLORS.Red
						end

						local bones = entry.bones
						local lines = entry.lines
						local boneTotal = #bones

						for index = 1, BONE_COUNT do
							local record = lines[index]

							if index > boneTotal then
								hideLine(record)
							else
								local pair = bones[index]
								local a, aOnScreen = camera:WorldToViewportPoint(pair[1].Position)
								local b, bOnScreen = camera:WorldToViewportPoint(pair[2].Position)

								if aOnScreen and bOnScreen then
									local dx = b.X - a.X
									local dy = b.Y - a.Y
									local length = math.sqrt(dx * dx + dy * dy)

									if length >= 1 then
										local px = (a.X + b.X) * 0.5
										local py = (a.Y + b.Y) * 0.5
										local rot = math.deg(math.atan2(dy, dx))
										local frame = record.frame

										-- only write what changed: every write is a layout pass
										if record.px ~= px or record.py ~= py then
											record.px = px
											record.py = py
											frame.Position = UDim2.fromOffset(px, py)
										end

										if record.len ~= length then
											record.len = length
											frame.Size = UDim2.fromOffset(length, BONE_THICKNESS)
										end

										if record.rot ~= rot then
											record.rot = rot
											frame.Rotation = rot
										end

										local color = sightColor or Color3.fromHSV((hue + index * 0.012) % 1, 0.7, 1)

										if record.color ~= color then
											record.color = color
											frame.BackgroundColor3 = color
										end

										if not record.visible then
											record.visible = true
											frame.Visible = true
										end
									else
										hideLine(record)
									end
								else
									hideLine(record)
								end
							end
						end
					end
				end
			end
		end

		for player, entry in pairs(entries) do
			if not seen[player] then
				entry.container:Destroy()
				entries[player] = nil
			end
		end
	end

	trackConnection(RunService.RenderStepped:Connect(update))

	function skeleton.Set(value)
		enabled = value == true
		espGui.Enabled = enabled

		if not enabled then
			clearEntries()
		end
	end

	function skeleton.Get()
		return enabled
	end

	function skeleton.SetRainbow(value)
		rainbow = value == true
	end

	function skeleton.GetRainbow()
		return rainbow
	end

	function skeleton.Destroy()
		enabled = false
		clearEntries()

		if espGui and espGui.Parent then
			espGui:Destroy()
		end
	end
end

------------------------------------------------------------------
-- ESP tracer - line from screen bottom to each player.
-- Rendered with BOTH a ScreenGui frame layer (every executor) AND a
-- Drawing line (executors that support it), same as the snapline visuals.
------------------------------------------------------------------
local tracer = {}

do
	local tracerSettings = {
		Enabled = false,
		RGB = Color3.fromRGB(255, 255, 255),
		Rainbow = false,
		Thickness = 1,
	}

	local me = Players.LocalPlayer
	local cameraObject = Workspace.CurrentCamera

	trackConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		cameraObject = Workspace.CurrentCamera
	end))

	local trGui = Instance.new("ScreenGui")
	trGui.Name = "ACECodeSniperTracer"
	trGui.ResetOnSpawn = false
	trGui.IgnoreGuiInset = true
	trGui.DisplayOrder = 2147483645
	trGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	trGui.Enabled = false

	pcall(function()
		trGui.OnTopOfCoreBlur = true
	end)

	for _, parent in ipairs(huiParents()) do
		pcall(function()
			trGui.Parent = parent
		end)

		if trGui.Parent then
			break
		end
	end

	local trLayer = Instance.new("Frame")
	trLayer.Name = "Tracers"
	trLayer.Size = UDim2.fromScale(1, 1)
	trLayer.BackgroundTransparency = 1
	trLayer.BorderSizePixel = 0
	trLayer.ZIndex = 150
	trLayer.Parent = trGui

	local entries = {} -- [player] = { frame, draw, visible, px, py, len, rot }
	local enabled = false
	local _trRainbowHue = 0

	local function newFrame(player)
		local line = Instance.new("Frame")
		line.Name = "Tracer" .. tostring(player.UserId)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = tracerSettings.RGB
		line.BorderSizePixel = 0
		line.ZIndex = 152
		line.Visible = false
		line.Parent = trLayer
		corner(line, 1)
		return line
	end

	local function newDrawing()
		if not DrawingsAvailable then
			return nil
		end

		local ok, result = pcall(Draw, "Line", { Visible = false, Color = tracerSettings.RGB, Thickness = tracerSettings.Thickness, ZIndex = 3 })
		return ok and result or nil
	end

	local function buildEntry(player)
		return {
			frame = newFrame(player),
			draw = newDrawing(),
			visible = false,
			px = nil,
			py = nil,
			len = nil,
			rot = nil,
		}
	end

	local function destroyEntry(entry)
		if entry.frame then
			pcall(function()
				entry.frame:Destroy()
			end)
		end

		if entry.draw then
			pcall(function()
				entry.draw:Remove()
			end)
		end
	end

	local function clearEntries()
		for _, entry in pairs(entries) do
			destroyEntry(entry)
		end

		table.clear(entries)
	end

	local function _rainbowColor(hue)
		return Color3.fromHSV(hue, 1, 1)
	end

	local function update(dt)
		_trRainbowHue = (_trRainbowHue + dt * 0.5) % 1

		if not enabled then
			return
		end

		local camera = cameraObject

		if not camera then
			return
		end

		local trRGB = tracerSettings.Rainbow and _rainbowColor(_trRainbowHue) or tracerSettings.RGB
		local trThick = tracerSettings.Thickness

		local vp = camera.ViewportSize
		local originX = vp.X * 0.5
		local originY = vp.Y
		local seen = {}

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= me then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")

				if hum and hum.Health > 0 and hrp then
					seen[player] = true

					local entry = entries[player]

					if not entry then
						entry = buildEntry(player)
						entries[player] = entry
					end

					local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

					-- pos.Z > 0 keeps the line from lingering on screen when the
					-- enemy is behind the camera (onScreen alone can stay true).
					if onScreen and pos.Z > 0 then
						local dx = pos.X - originX
						local dy = pos.Y - originY
						local length = math.sqrt(dx * dx + dy * dy)

						if length >= 1 then
							local frame = entry.frame
							local px = (originX + pos.X) * 0.5
							local py = (originY + pos.Y) * 0.5
							local rot = math.deg(math.atan2(dy, dx))

							if entry.px ~= px or entry.py ~= py then
								entry.px = px
								entry.py = py
								frame.Position = UDim2.fromOffset(px, py)
							end

							if entry.len ~= length then
								entry.len = length
								frame.Size = UDim2.fromOffset(length, math.max(trThick, 1))
							end

							if entry.rot ~= rot then
								entry.rot = rot
								frame.Rotation = rot
							end

							if frame.BackgroundColor3 ~= trRGB then
								frame.BackgroundColor3 = trRGB
							end

							if not entry.visible then
								entry.visible = true
								frame.Visible = true
							end

							if entry.draw then
								entry.draw.From = Vector2.new(originX, originY)
								entry.draw.To = Vector2.new(pos.X, pos.Y)
								entry.draw.Color = trRGB
								entry.draw.Thickness = trThick

								if not entry.draw.Visible then
									entry.draw.Visible = true
								end
							end
						else
							if entry.visible then
								entry.visible = false
								entry.frame.Visible = false
							end

							if entry.draw and entry.draw.Visible then
								entry.draw.Visible = false
							end
						end
					else
						if entry.visible then
							entry.visible = false
							entry.frame.Visible = false
						end

						if entry.draw and entry.draw.Visible then
							entry.draw.Visible = false
						end
					end
				end
			end
		end

		for player, entry in pairs(entries) do
			if not seen[player] then
				destroyEntry(entry)
				entries[player] = nil
			end
		end
	end

	trackConnection(RunService.RenderStepped:Connect(update))

	function tracer.Set(value)
		enabled = value == true
		trGui.Enabled = enabled

		if not enabled then
			clearEntries()
		end
	end

	function tracer.Get()
		return enabled
	end

	function tracer.SetRainbow(value)
		tracerSettings.Rainbow = value == true
	end

	function tracer.GetRainbow()
		return tracerSettings.Rainbow
	end

	function tracer.Destroy()
		enabled = false
		clearEntries()

		if trGui and trGui.Parent then
			trGui:Destroy()
		end
	end
end

------------------------------------------------------------------
-- VISUAL page - appearance
------------------------------------------------------------------
do
	-- ---- APPEARANCE auto-save (keeps your picks after rejoin) ----
	local apFile = "MyMain_Appearance.json"
	local apHttp = game:GetService("HttpService")

	local function apHasApi()
		return type(writefile) == "function" and type(readfile) == "function"
	end

	local apSaved = {}
	if apHasApi() then
		pcall(function()
			if type(isfile) ~= "function" or isfile(apFile) then
				local raw = readfile(apFile)
				if type(raw) == "string" and raw ~= "" then
					local decoded = apHttp:JSONDecode(raw)
					if type(decoded) == "table" then
						apSaved = decoded
					end
				end
			end
		end)
	end

	local function apSave()
		if not apHasApi() then
			return
		end
		pcall(function()
			writefile(apFile, apHttp:JSONEncode(apSaved))
		end)
	end

	if type(apSaved.background) == "number" then
		BACKGROUND_INDEX = math.clamp(math.floor(apSaved.background), 1, #bgImages)
	end

	local dash = Instance.new("Frame")
	dash.Size = UDim2.fromOffset(10, 1)
	dash.Position = UDim2.fromOffset(16, 19)
	dash.BackgroundColor3 = COLORS.Dim
	dash.BorderSizePixel = 0
	dash.ZIndex = 3
	dash.Parent = visualPage

	local title = label(
		visualPage,
		"AppearanceTitle",
		"APPEARANCE",
		UDim2.fromOffset(90, 24),
		UDim2.fromOffset(33, 8),
		11,
		COLORS.White,
		Enum.Font.GothamBold
	)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0.35
	title.ZIndex = 3

	local rule = Instance.new("Frame")
	rule.Size = UDim2.new(1, -140, 0, 1)
	rule.Position = UDim2.fromOffset(123, 19)
	rule.BackgroundColor3 = COLORS.Dim
	rule.BackgroundTransparency = 0.35
	rule.BorderSizePixel = 0
	rule.ZIndex = 3
	rule.Parent = visualPage

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "BackgroundOptions"
	scroller.Size = UDim2.new(1, -34, 0, 82)
	scroller.Position = UDim2.fromOffset(17, 38)
	scroller.BackgroundColor3 = COLORS.Log
	scroller.BackgroundTransparency = 0.3
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = COLORS.Dim
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroller.CanvasSize = UDim2.new()
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.ZIndex = 3
	scroller.Parent = visualPage
	corner(scroller, 9)
	stroke(scroller, COLORS.White, 1, 0.8)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroller

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 7)
	pad.PaddingRight = UDim.new(0, 7)
	pad.Parent = scroller

	local thumbs = {}

	local function refreshThumbs()
		for index, button in ipairs(thumbs) do
			local thumbStroke = button:FindFirstChildOfClass("UIStroke")

			if thumbStroke then
				thumbStroke.Color = index == BACKGROUND_INDEX and COLORS.White or COLORS.Dim
				thumbStroke.Transparency = index == BACKGROUND_INDEX and 0.1 or 0.76
				thumbStroke.Thickness = index == BACKGROUND_INDEX and 2 or 1
			end
		end
	end

	for index, entry in ipairs(bgImages) do
		local button = Instance.new("TextButton")
		button.Name = "Background" .. tostring(index)
		button.Size = UDim2.fromOffset(66, 40)
		button.BackgroundColor3 = COLORS.Control
		button.BackgroundTransparency = entry.IsNone and 0.35 or 0
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = ""
		button.LayoutOrder = index
		button.ZIndex = 4
		button.Parent = scroller
		corner(button, 8)
		stroke(button, COLORS.Dim, 1, 0.76)
		pressable(button)

		if entry.IsNone then
			label(button, "NoBg", "NO BG", UDim2.new(1, -16, 0, 14), UDim2.fromOffset(8, 17), 8, COLORS.White, Enum.Font.GothamBold).ZIndex =
				5
			label(button, "None", "NONE", UDim2.new(1, -12, 0, 14), UDim2.fromOffset(8, 34), 8, COLORS.Dim, Enum.Font.GothamBold).ZIndex = 5
		else
			local preview = Instance.new("ImageLabel")
			preview.Name = "Preview"
			preview.Size = UDim2.new(1, -4, 1, -6)
			preview.Position = UDim2.fromOffset(2, 2)
			preview.BackgroundColor3 = COLORS.Window
			preview.BorderSizePixel = 0
			preview.Image = entry.Image
			preview.ScaleType = Enum.ScaleType.Crop
			preview.ZIndex = 5
			preview.Parent = button
			corner(preview, 6)

			local number = label(
				button,
				"Number",
				entry.Name,
				UDim2.fromOffset(28, 16),
				UDim2.new(1, -25, 1, -17),
				8,
				COLORS.White,
				Enum.Font.GothamBold
			)
			number.TextXAlignment = Enum.TextXAlignment.Right
			number.TextStrokeColor3 = Color3.new(0, 0, 0)
			number.TextStrokeTransparency = 0.25
			number.ZIndex = 6
		end

		thumbs[index] = button

		button.MouseButton1Click:Connect(function()
			applyBackground(index)
			refreshThumbs()
			apSaved.background = index
			apSave()
		end)
	end

	refreshThumbs()

	-- gui scale
	local scaleCard = Instance.new("Frame")
	scaleCard.Name = "GuiScale"
	scaleCard.Size = UDim2.new(1, -34, 0, 42)
	scaleCard.Position = UDim2.fromOffset(17, 132)
	scaleCard.BackgroundColor3 = COLORS.Log
	scaleCard.BackgroundTransparency = 0.12
	scaleCard.BorderSizePixel = 0
	scaleCard.ZIndex = 3
	scaleCard.Parent = visualPage
	corner(scaleCard, 9)
	stroke(scaleCard, COLORS.White, 1, 0.8)

	local scaleTitle = label(scaleCard, "ScaleTitle", "GUI Scale", UDim2.fromOffset(120, 42), UDim2.fromOffset(12, 0), 11, COLORS.White, Enum.Font.GothamBold)
	scaleTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
	scaleTitle.TextStrokeTransparency = 0.35
	scaleTitle.ZIndex = 4

	local function scaleButton(name, text, xOffset, width)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.fromOffset(width, 24)
		button.Position = UDim2.new(1, xOffset, 0.5, -12)
		button.BackgroundColor3 = COLORS.White
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = text
		button.TextSize = 12
		button.TextColor3 = COLORS.Window
		button.Font = Enum.Font.GothamBold
		button.ZIndex = 4
		button.Parent = scaleCard
		corner(button, 12)
		pressable(button)
		return button
	end

	if type(apSaved.scale) == "number" then
		userScale = math.clamp(math.floor(apSaved.scale * 20 + 0.5) / 20, 0.5, 1.5)
		fitWindow()
	end

	local valueLabel = scaleButton("ScaleValue", string.format("%.2f", userScale), -92, 48)
	valueLabel.Active = false
	local minus = scaleButton("ScaleMinus", "-", -124, 30)
	local plus = scaleButton("ScalePlus", "+", -38, 30)

	local function setScale(value)
		userScale = math.clamp(math.floor(value * 20 + 0.5) / 20, 0.5, 1.5)
		valueLabel.Text = string.format("%.2f", userScale)
		fitWindow()
		apSaved.scale = userScale
		apSave()
	end

	minus.MouseButton1Click:Connect(function()
		setScale(userScale - 0.05)
	end)

	plus.MouseButton1Click:Connect(function()
		setScale(userScale + 0.05)
	end)

	-- visual options scroller (holds the toggle cards so the page can grow)
	local visualList = Instance.new("ScrollingFrame")
	visualList.Name = "VisualList"
	visualList.Size = UDim2.new(1, -34, 0, 162)
	visualList.Position = UDim2.fromOffset(17, 186)
	visualList.BackgroundTransparency = 1
	visualList.BorderSizePixel = 0
	visualList.ScrollBarThickness = 3
	visualList.ScrollBarImageColor3 = COLORS.Dim
	visualList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	visualList.CanvasSize = UDim2.new()
	visualList.ScrollingDirection = Enum.ScrollingDirection.Y
	visualList.ZIndex = 3
	visualList.Parent = visualPage

	local visualLayout = Instance.new("UIListLayout")
	visualLayout.FillDirection = Enum.FillDirection.Vertical
	visualLayout.SortOrder = Enum.SortOrder.LayoutOrder
	visualLayout.Padding = UDim.new(0, 8)
	visualLayout.Parent = visualList

	local visualPad = Instance.new("UIPadding")
	visualPad.PaddingTop = UDim.new(0, 2)
	visualPad.Parent = visualList

	-- falling snow
	local snowCard = Instance.new("Frame")
	snowCard.Name = "FallingSnow"
	snowCard.Size = UDim2.new(1, 0, 0, 34)
	snowCard.Position = UDim2.fromOffset(0, 0)
	snowCard.LayoutOrder = 1
	snowCard.BackgroundColor3 = COLORS.Log
	snowCard.BackgroundTransparency = 0.12
	snowCard.BorderSizePixel = 0
	snowCard.ZIndex = 3
	snowCard.Parent = visualList
	corner(snowCard, 9)
	stroke(snowCard, COLORS.White, 1, 0.8)

	label(snowCard, "Title", "Falling snow", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium).ZIndex = 4

	local fallingDots = window:FindFirstChild("ACEFallingDots")

	local snowOn = apSaved.snow == true

	if fallingDots then
		fallingDots.Visible = snowOn
	end

	createSwitch(snowCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = snowOn,
		zIndex = 4,
		onChange = function(enabled)
			if fallingDots then
				fallingDots.Visible = enabled
			end
			apSaved.snow = enabled
			apSave()
		end,
	})

	-- esp skeleton
	local espCard = Instance.new("Frame")
	espCard.Name = "EspSkeleton"
	espCard.Size = UDim2.new(1, 0, 0, 34)
	espCard.Position = UDim2.fromOffset(0, 0)
	espCard.LayoutOrder = 2
	espCard.BackgroundColor3 = COLORS.Log
	espCard.BackgroundTransparency = 0.12
	espCard.BorderSizePixel = 0
	espCard.ZIndex = 3
	espCard.Parent = visualList
	corner(espCard, 9)
	stroke(espCard, COLORS.White, 1, 0.8)

	local espTitle = label(espCard, "Title", "ESP Skeleton", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium)
	espTitle.ZIndex = 4

	local espOn = apSaved.espskeleton == true

	skeleton.Set(espOn)

	createSwitch(espCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = espOn,
		zIndex = 4,
		onChange = function(enabled)
			skeleton.Set(enabled)
			apSaved.espskeleton = enabled
			apSave()
		end,
	})

	-- rainbow esp (off = green/red wall colours)
	local rainbowCard = Instance.new("Frame")
	rainbowCard.Name = "RainbowEsp"
	rainbowCard.Size = UDim2.new(1, 0, 0, 34)
	rainbowCard.Position = UDim2.fromOffset(0, 0)
	rainbowCard.LayoutOrder = 3
	rainbowCard.BackgroundColor3 = COLORS.Log
	rainbowCard.BackgroundTransparency = 0.12
	rainbowCard.BorderSizePixel = 0
	rainbowCard.ZIndex = 3
	rainbowCard.Parent = visualList
	corner(rainbowCard, 9)
	stroke(rainbowCard, COLORS.White, 1, 0.8)

	local rainbowTitle = label(rainbowCard, "Title", "Rainbow ESP", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium)
	rainbowTitle.ZIndex = 4

	local rainbowOn = apSaved.rainbow == true

	skeleton.SetRainbow(rainbowOn)
	tracer.SetRainbow(rainbowOn)

	createSwitch(rainbowCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = rainbowOn,
		zIndex = 4,
		onChange = function(on)
			skeleton.SetRainbow(on)
			tracer.SetRainbow(on)
			apSaved.rainbow = on
			apSave()
		end,
	})

	-- esp tracer (line from the bottom of the screen to each player)
	local tracerCard = Instance.new("Frame")
	tracerCard.Name = "EspTracer"
	tracerCard.Size = UDim2.new(1, 0, 0, 34)
	tracerCard.Position = UDim2.fromOffset(0, 0)
	tracerCard.LayoutOrder = 4
	tracerCard.BackgroundColor3 = COLORS.Log
	tracerCard.BackgroundTransparency = 0.12
	tracerCard.BorderSizePixel = 0
	tracerCard.ZIndex = 3
	tracerCard.Parent = visualList
	corner(tracerCard, 9)
	stroke(tracerCard, COLORS.White, 1, 0.8)

	local tracerTitle = label(tracerCard, "Title", "ESP Tracer", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium)
	tracerTitle.ZIndex = 4

	local tracerOn = apSaved.tracer == true

	tracer.Set(tracerOn)

	createSwitch(tracerCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = tracerOn,
		zIndex = 4,
		onChange = function(enabled)
			tracer.Set(enabled)
			apSaved.tracer = enabled
			apSave()
		end,
	})

	-- self chams (LX_SelfChams outline + forcefield tint, from the provided script)
	local chamsCard = Instance.new("Frame")
	chamsCard.Name = "SelfChams"
	chamsCard.Size = UDim2.new(1, 0, 0, 34)
	chamsCard.BackgroundColor3 = COLORS.Log
	chamsCard.BackgroundTransparency = 0.12
	chamsCard.BorderSizePixel = 0
	chamsCard.LayoutOrder = 5
	chamsCard.ZIndex = 3
	chamsCard.Parent = visualList
	corner(chamsCard, 9)
	stroke(chamsCard, COLORS.White, 1, 0.8)

	local chamsTitle = label(chamsCard, "Title", "Self Chams", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium)
	chamsTitle.ZIndex = 4

	local chamsState = { Active = false, hl = nil, saved = nil, conn = nil, hb = nil }
	local chamsColor = Color3.fromRGB(90, 170, 255)
	local chamsTransparency = 0.72

	local function isChamsPart(part)
		if not part:IsA("BasePart") then
			return false
		end
		if part.Name == "HumanoidRootPart" then
			return false
		end
		if part.Parent and part.Parent:IsA("Accessory") then
			return false
		end
		return true
	end

	local function tintChamsPart(part)
		if not isChamsPart(part) then
			return
		end
		if chamsState.saved[part] == nil then
			chamsState.saved[part] = { part.Transparency, part.Color, part.Material, part.Reflectance }
		end
		pcall(function()
			part.Material = Enum.Material.ForceField
			part.Color = chamsColor
			part.Transparency = chamsTransparency
			part.Reflectance = 0
		end)
	end

	local function tintSelfChams()
		local character = LocalPlayer.Character
		if not character then
			return
		end
		for _, descendant in ipairs(character:GetDescendants()) do
			tintChamsPart(descendant)
		end
	end

	local function buildSelfChams()
		local character = LocalPlayer.Character
		if not character then
			return
		end
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant.Name == "rtx_highlight" then
				pcall(function()
					descendant:Destroy()
				end)
			end
		end
		tintSelfChams()
		if not chamsState.hl or chamsState.hl.Parent == nil then
			local highlight = Instance.new("Highlight")
			highlight.Name = "LX_SelfChams"
			pcall(function()
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			end)
			highlight.FillTransparency = 1
			highlight.OutlineColor = Color3.fromRGB(120, 200, 255)
			highlight.OutlineTransparency = 0.35
			highlight.Adornee = character
			highlight.Parent = character
			chamsState.hl = highlight
		elseif chamsState.hl.Adornee ~= character then
			chamsState.hl.Adornee = character
		end
	end

	local function restoreChams()
		if not chamsState.saved then
			return
		end
		for part, props in pairs(chamsState.saved) do
			if part and part.Parent then
				pcall(function()
					part.Transparency = props[1]
					part.Color = props[2]
					part.Material = props[3]
					part.Reflectance = props[4]
				end)
			end
		end
		chamsState.saved = nil
	end

	local function enableChams()
		chamsState.Active = true
		chamsState.saved = {}
		buildSelfChams()
		chamsState.conn = LocalPlayer.CharacterAdded:Connect(function()
			if chamsState.Active then
				task.wait(0.3)
				buildSelfChams()
			end
		end)
		chamsState.hb = RunService.Heartbeat:Connect(function()
			if chamsState.Active then
				tintSelfChams()
			end
		end)
	end

	local function disableChams()
		chamsState.Active = false
		if chamsState.hb then
			chamsState.hb:Disconnect()
			chamsState.hb = nil
		end
		if chamsState.conn then
			chamsState.conn:Disconnect()
			chamsState.conn = nil
		end
		if chamsState.hl then
			pcall(function()
				chamsState.hl:Destroy()
			end)
			chamsState.hl = nil
		end
		restoreChams()
	end

	local chamsOn = apSaved.chams == true

	createSwitch(chamsCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = chamsOn,
		zIndex = 4,
		onChange = function(enabled)
			if enabled then
				enableChams()
			else
				disableChams()
			end
			apSaved.chams = enabled
			apSave()
		end,
	})

	if chamsOn then
		enableChams()
	end

	table.insert(restoreCallbacks, function()
		disableChams()
	end)

	-- self aura (LX_SelfAura point light + sparkle particles, from the provided script)
	local auraCard = Instance.new("Frame")
	auraCard.Name = "SelfAura"
	auraCard.Size = UDim2.new(1, 0, 0, 34)
	auraCard.BackgroundColor3 = COLORS.Log
	auraCard.BackgroundTransparency = 0.12
	auraCard.BorderSizePixel = 0
	auraCard.LayoutOrder = 6
	auraCard.ZIndex = 3
	auraCard.Parent = visualList
	corner(auraCard, 9)
	stroke(auraCard, COLORS.White, 1, 0.8)

	local auraTitle = label(auraCard, "Title", "Self Aura", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 0), 11, COLORS.White, Enum.Font.GothamMedium)
	auraTitle.ZIndex = 4

	local auraState = { Active = false, conn = nil, hb = nil, parts = {} }
	-- same accent green as the source script's self aura (tbl.Acc2)
	local auraColor = Color3.fromRGB(0, 255, 95)

	local function clearAuraParts()
		for _, part in ipairs(auraState.parts) do
			pcall(function()
				part:Destroy()
			end)
		end
		auraState.parts = {}
	end

	local function buildAura()
		clearAuraParts()
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local pointLight = Instance.new("PointLight")
		pointLight.Name = "LX_SelfAura_Light"
		pointLight.Color = auraColor
		pointLight.Brightness = 3
		pointLight.Range = 16
		pointLight.Parent = root
		table.insert(auraState.parts, pointLight)
		local attachment = Instance.new("Attachment")
		attachment.Name = "LX_SelfAura_Att"
		attachment.Parent = root
		table.insert(auraState.parts, attachment)
		local particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Name = "LX_SelfAura_PE"
		particleEmitter.Color = ColorSequence.new(auraColor)
		particleEmitter.LightEmission = 1
		particleEmitter.LightInfluence = 0
		pcall(function()
			particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		end)
		particleEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		particleEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		particleEmitter.Lifetime = NumberRange.new(0.6, 1.1)
		particleEmitter.Rate = 70
		particleEmitter.Speed = NumberRange.new(4, 7)
		particleEmitter.SpreadAngle = Vector2.new(180, 180)
		particleEmitter.Acceleration = Vector3.new(0, 9, 0)
		particleEmitter.Parent = attachment
		table.insert(auraState.parts, particleEmitter)
	end

	local function enableAura()
		auraState.Active = true
		buildAura()
		auraState.conn = LocalPlayer.CharacterAdded:Connect(function()
			if auraState.Active then
				task.wait(0.3)
				buildAura()
			end
		end)
		auraState.hb = RunService.Heartbeat:Connect(function()
			if not auraState.Active then
				return
			end
			local light = auraState.parts[1]
			if light and light.Parent then
				light.Brightness = 2 + math.abs(math.sin(tick() * 3)) * 3
			end
		end)
	end

	local function disableAura()
		auraState.Active = false
		if auraState.hb then
			auraState.hb:Disconnect()
			auraState.hb = nil
		end
		if auraState.conn then
			auraState.conn:Disconnect()
			auraState.conn = nil
		end
		clearAuraParts()
	end

	local auraOn = apSaved.aura == true

	createSwitch(auraCard, {
		position = UDim2.new(1, -50, 0.5, -9),
		state = auraOn,
		zIndex = 4,
		onChange = function(enabled)
			if enabled then
				enableAura()
			else
				disableAura()
			end
			apSaved.aura = enabled
			apSave()
		end,
	})

	if auraOn then
		enableAura()
	end

	table.insert(restoreCallbacks, function()
		disableAura()
	end)
end

------------------------------------------------------------------
-- SETTINGS page - optimization
------------------------------------------------------------------
do
	local dash = Instance.new("Frame")
	dash.Size = UDim2.fromOffset(10, 1)
	dash.Position = UDim2.fromOffset(17, 19)
	dash.BackgroundColor3 = COLORS.Dim
	dash.BorderSizePixel = 0
	dash.ZIndex = 3
	dash.Parent = settingsPage

	local title = label(
		settingsPage,
		"OptimizationTitle",
		"OPTIMIZATION",
		UDim2.fromOffset(100, 24),
		UDim2.fromOffset(33, 8),
		11,
		COLORS.White,
		Enum.Font.GothamBold
	)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0.35
	title.ZIndex = 3

	local rule = Instance.new("Frame")
	rule.Size = UDim2.new(1, -152, 0, 1)
	rule.Position = UDim2.fromOffset(135, 19)
	rule.BackgroundColor3 = COLORS.Dim
	rule.BackgroundTransparency = 0.35
	rule.BorderSizePixel = 0
	rule.ZIndex = 3
	rule.Parent = settingsPage

	local optList = Instance.new("ScrollingFrame")
	optList.Name = "OptimizationOptions"
	optList.Size = UDim2.new(1, -34, 0, 190)
	optList.Position = UDim2.fromOffset(17, 38)
	optList.BackgroundTransparency = 1
	optList.BorderSizePixel = 0
	optList.ScrollBarThickness = 3
	optList.ScrollBarImageColor3 = COLORS.Dim
	optList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	optList.CanvasSize = UDim2.new()
	optList.ScrollingDirection = Enum.ScrollingDirection.Y
	optList.ZIndex = 3
	optList.Parent = settingsPage

	local optLayout = Instance.new("UIListLayout")
	optLayout.FillDirection = Enum.FillDirection.Vertical
	optLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optLayout.Padding = UDim.new(0, 5)
	optLayout.Parent = optList

	local optPad = Instance.new("UIPadding")
	optPad.PaddingTop = UDim.new(0, 5)
	optPad.PaddingBottom = UDim.new(0, 10)
	optPad.Parent = optList

	local optOrder = 0

	local function optRow(key, text, initial, onChange)
		optOrder = optOrder + 1
		local row = Instance.new("Frame")
		row.Name = "Row_" .. key
		row.Size = UDim2.new(1, -6, 0, 34)
		row.LayoutOrder = optOrder
		row.BackgroundColor3 = COLORS.Log
		row.BackgroundTransparency = 0.12
		row.BorderSizePixel = 0
		row.ZIndex = 6
		row.Parent = optList
		corner(row, 6)
		stroke(row, COLORS.White, 1, 0.84)

		label(row, "Title", text, UDim2.new(1, -58, 1, 0), UDim2.fromOffset(12, 0), 10, COLORS.White, Enum.Font.GothamMedium).ZIndex = 7

		return createSwitch(row, {
			position = UDim2.new(1, -48, 0.5, -9),
			state = initial,
			zIndex = 7,
			onChange = onChange,
		})
	end

	-- real optimization logic (reversible: turning it off restores your settings)
	local optSaved = {}

	local function optSave(key, getter)
		if optSaved[key] == nil then
			local ok, value = pcall(getter)
			if ok then optSaved[key] = value end
		end
	end

	local optLow, optMaster

	local function applyOpt()
		local lighting = game:GetService("Lighting")
		local sg = settings()
		local active = optMaster.state or optLow.state

		optSave("globalShadows", function() return lighting.GlobalShadows end)
		optSave("fogEnd", function() return lighting.FogEnd end)
		optSave("fogStart", function() return lighting.FogStart end)
		optSave("diffuse", function() return lighting.EnvironmentDiffuseScale end)
		optSave("specular", function() return lighting.EnvironmentSpecularScale end)
		optSave("quality", function() return sg.RenderingQualityLevel end)

		if active then
			pcall(function() lighting.GlobalShadows = false end)
			pcall(function() lighting.FogEnd = 9e9 end)
			pcall(function() lighting.FogStart = 9e9 end)
			pcall(function() sethiddenproperty(sg, "RenderingQualityLevel", 1) end)
			pcall(function() sg.RenderingQualityLevel = Enum.RenderingQualityLevel.Level01 end)
		else
			if optSaved.globalShadows ~= nil then pcall(function() lighting.GlobalShadows = optSaved.globalShadows end) end
			if optSaved.fogEnd ~= nil then pcall(function() lighting.FogEnd = optSaved.fogEnd end) end
			if optSaved.fogStart ~= nil then pcall(function() lighting.FogStart = optSaved.fogStart end) end
			if optSaved.quality ~= nil then
				pcall(function() sg.RenderingQualityLevel = optSaved.quality end)
				pcall(function() sethiddenproperty(sg, "RenderingQualityLevel", optSaved.quality and optSaved.quality.Value or 5) end)
			end
		end

		if optMaster.state then
			pcall(function() lighting.EnvironmentDiffuseScale = 0 end)
			pcall(function() lighting.EnvironmentSpecularScale = 0 end)
		else
			if optSaved.diffuse ~= nil then pcall(function() lighting.EnvironmentDiffuseScale = optSaved.diffuse end) end
			if optSaved.specular ~= nil then pcall(function() lighting.EnvironmentSpecularScale = optSaved.specular end) end
		end
	end

	optLow = optRow("lowGraphics", "Low graphics", false, function()
		applyOpt()
	end)

	optMaster = optRow("master", "Optimization", false, function(enabled)
		optLow:Set(enabled, true)
		applyOpt()
	end)

	local note = label(
		settingsPage,
		"Note",
		"applies instantly - turning it off restores your settings",
		UDim2.new(1, -34, 0, 16),
		UDim2.fromOffset(17, 238),
		9,
		COLORS.Dim,
		Enum.Font.GothamBold
	)
	note.TextXAlignment = Enum.TextXAlignment.Center
	note.ZIndex = 4
end

------------------------------------------------------------------
-- drag
------------------------------------------------------------------
do
	local dragging = false
	local grabPosition = nil
	local startPosition = nil

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			grabPosition = input.Position
			startPosition = window.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = input.Position - grabPosition
			window.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

-- keybind: K opens / closes the whole gui (the triggerbot keeps running)
trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode ~= Enum.KeyCode.K then
		return
	end

	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end

	gui.Enabled = not gui.Enabled
end))

-- open animation
do
	local target = uiScale.Scale
	uiScale.Scale = math.max(0.05, target * 0.6)
	TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
end

applyBackground(BACKGROUND_INDEX)

genv.ACECodeSniperUnload = function()
	for _, connection in ipairs(cleanupConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	pcall(skeleton.Destroy)

	for _, restore in ipairs(restoreCallbacks) do
		pcall(restore)
	end

	if gui and gui.Parent then
		gui:Destroy()
	end

	if genv.ACECodeSniperGui == gui then
		genv.ACECodeSniperGui = nil
	end

	genv.ACECodeSniperUnload = nil
end

-- ============================================================================
-- ============================= MISC PAGE (added) ============================
-- ============================================================================
-- New "MISC" tab + "Velocity Desync" feature (ported from the provided script:
-- spoof a huge random AssemblyLinearVelocity on Heartbeat, restore the real one
-- on RenderStepped, so enemy aim prediction misses).
-- ============================================================================
local miscPage = Instance.new("Frame")
miscPage.Name = "MiscPage"
miscPage.Size = mainPage.Size
miscPage.Position = mainPage.Position
miscPage.BackgroundTransparency = 1
miscPage.Visible = false
miscPage.ZIndex = 2
miscPage.Parent = window

local miscTab = makeTab("MiscTab", "MISC", 0.8)
pages.MISC = { tab = miscTab, page = miscPage }
miscTab.Button.MouseButton1Click:Connect(function()
	selectTab("MISC")
end)

-- scroller that holds the MISC cards
local miscList = Instance.new("ScrollingFrame")
miscList.Name = "MiscList"
miscList.Size = UDim2.new(1, -34, 1, -56)
miscList.Position = UDim2.fromOffset(17, 44)
miscList.BackgroundTransparency = 1
miscList.BorderSizePixel = 0
miscList.ScrollBarThickness = 3
miscList.ScrollBarImageColor3 = COLORS.Dim
miscList.AutomaticCanvasSize = Enum.AutomaticSize.Y
miscList.CanvasSize = UDim2.new()
miscList.ScrollingDirection = Enum.ScrollingDirection.Y
miscList.ZIndex = 3
miscList.Parent = miscPage

local miscLayout = Instance.new("UIListLayout")
miscLayout.FillDirection = Enum.FillDirection.Vertical
miscLayout.SortOrder = Enum.SortOrder.LayoutOrder
miscLayout.Padding = UDim.new(0, 8)
miscLayout.Parent = miscList

local miscPad = Instance.new("UIPadding")
miscPad.PaddingTop = UDim.new(0, 2)
miscPad.Parent = miscList

-- ------------------------- VELOCITY DESYNC card -----------------------------
local vdState = { Active = false, hb = nil, rs = nil, savedVel = nil }

local vdCard = Instance.new("Frame")
vdCard.Name = "VelocityDesync"
vdCard.Size = UDim2.new(1, 0, 0, 56)
vdCard.BackgroundColor3 = COLORS.Log
vdCard.BackgroundTransparency = 0.12
vdCard.BorderSizePixel = 0
vdCard.LayoutOrder = 1
vdCard.ZIndex = 3
vdCard.Parent = miscList
corner(vdCard, 9)
stroke(vdCard, COLORS.White, 1, 0.8)

local vdTitle = label(vdCard, "Title", "Velocity Desync", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 7), 11, COLORS.White, Enum.Font.GothamMedium)
vdTitle.ZIndex = 4

local vdDesc = label(vdCard, "Desc", "spoof velocity so enemy aim misses", UDim2.new(1, -88, 1, 0), UDim2.fromOffset(14, 29), 9, COLORS.Text, Enum.Font.Gotham)
vdDesc.ZIndex = 4
vdDesc.TextTruncate = Enum.TextTruncate.AtEnd

local function vdRootPart()
	local character = LocalPlayer.Character
	local humanoid = character and FindFirstChildOfClass(character, "Humanoid")
	return humanoid and humanoid.RootPart
end

local function disableVelocityDesync()
	if not vdState.Active then
		return
	end
	vdState.Active = false
	if vdState.hb then
		vdState.hb:Disconnect()
		vdState.hb = nil
	end
	if vdState.rs then
		vdState.rs:Disconnect()
		vdState.rs = nil
	end
	vdState.savedVel = nil
end

local function enableVelocityDesync()
	if vdState.Active then
		return
	end
	vdState.Active = true

	vdState.hb = RunService.Heartbeat:Connect(function()
		if not vdState.Active then
			return
		end
		-- huwag mag-spoof habang naka-lock ang snapline, para hindi maapektuhan ang aim
		if SilentTarget or vdState.savedVel then
			return
		end
		local root = vdRootPart()
		if not root then
			return
		end
		local function rand()
			return math.random(1, 2) == 1 and -16384 or 16384
		end
		vdState.savedVel = root.AssemblyLinearVelocity
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.new(rand(), rand(), rand())
		end)
	end)

	vdState.rs = RunService.RenderStepped:Connect(function()
		if vdState.savedVel then
			local root = vdRootPart()
			if root then
				pcall(function()
					root.AssemblyLinearVelocity = vdState.savedVel
				end)
			end
			vdState.savedVel = nil
		end
	end)
end

createSwitch(vdCard, {
	position = UDim2.new(1, -50, 0.5, -9),
	state = false,
	zIndex = 4,
	onChange = function(enabled)
		if enabled then
			enableVelocityDesync()
		else
			disableVelocityDesync()
		end
	end,
})

table.insert(restoreCallbacks, function()
	disableVelocityDesync()
end)

-- ------------------------ INVISIBLE DESYNC card ----------------------------
-- Ported from the provided script: velocity flick (random yaw flip + fake
-- velocity every Heartbeat, restored after one RenderStepped) + packet choke
-- (NetworkIsSleeping for a ping-window every ~15ms) = anti-aim / "invisible" desync.
local invN = 16384
local invState = { Active = false, Flick = nil, Choke = nil, Sleep1 = nil, Sleep2 = nil, Busy = false }

local invCard = Instance.new("Frame")
invCard.Name = "InvisibleDesync"
invCard.Size = UDim2.new(1, 0, 0, 56)
invCard.BackgroundColor3 = COLORS.Log
invCard.BackgroundTransparency = 0.12
invCard.BorderSizePixel = 0
invCard.LayoutOrder = 2
invCard.ZIndex = 3
invCard.Parent = miscList
corner(invCard, 9)
stroke(invCard, COLORS.White, 1, 0.8)

local invTitle = label(invCard, "Title", "Invisible Desync", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 7), 11, COLORS.White, Enum.Font.GothamMedium)
invTitle.ZIndex = 4

local invDesc = label(invCard, "Desc", "velocity flick + packet choke anti-aim", UDim2.new(1, -88, 1, 0), UDim2.fromOffset(14, 29), 9, COLORS.Text, Enum.Font.Gotham)
invDesc.ZIndex = 4
invDesc.TextTruncate = Enum.TextTruncate.AtEnd

local function invPing()
	local ok, result = pcall(function()
		return game:GetService("Stats").PerformanceStats.Ping:GetValue()
	end)
	return math.ceil(ok and result or 60) / 1000
end

local function invChoke()
	local root = vdRootPart()
	if root and sethiddenproperty then
		pcall(function()
			sethiddenproperty(root, "NetworkIsSleeping", true)
		end)
	end
end

local function invFlick()
	if invState.Busy then
		return
	end
	local root = vdRootPart()
	if not root then
		return
	end
	invState.Busy = true
	local realVel = root.AssemblyLinearVelocity
	local yaw = math.random(-180, 180)
	local fakeVel = Vector3.new(math.random(-invN, 16384), -math.random(0, 16384), math.random(-invN, 16384))
	pcall(function()
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(yaw), 0)
		root.AssemblyLinearVelocity = fakeVel
	end)
	RunService.RenderStepped:Wait()
	if (LocalPlayer.Character and vdRootPart()) == root then
		pcall(function()
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(-yaw), 0)
			root.AssemblyLinearVelocity = realVel
		end)
	end
	invState.Busy = false
end

local function disableInvisibleDesync()
	if not invState.Active then
		return
	end
	invState.Active = false
	if invState.Flick then
		invState.Flick:Disconnect()
		invState.Flick = nil
	end
	invState.Choke = nil
	local root = vdRootPart()
	if root and sethiddenproperty then
		pcall(function()
			sethiddenproperty(root, "NetworkIsSleeping", false)
		end)
	end
end

local function enableInvisibleDesync()
	if invState.Active then
		return
	end
	if not sethiddenproperty then
		return
	end
	if not vdRootPart() then
		return
	end
	invState.Active = true

	invState.Flick = RunService.Heartbeat:Connect(function()
		if invState.Active then
			invFlick()
		end
	end)

	invState.Choke = true

	task.spawn(function()
		while invState.Active do
			task.wait(0.015)
			if not invState.Active then
				break
			end
			invState.Sleep1 = RunService.Heartbeat:Connect(invChoke)
			invState.Sleep2 = RunService.RenderStepped:Connect(invChoke)
			task.wait(invPing())
			if invState.Sleep1 then
				invState.Sleep1:Disconnect()
				invState.Sleep1 = nil
			end
			if invState.Sleep2 then
				invState.Sleep2:Disconnect()
				invState.Sleep2 = nil
			end
		end
		if invState.Sleep1 then
			invState.Sleep1:Disconnect()
			invState.Sleep1 = nil
		end
		if invState.Sleep2 then
			invState.Sleep2:Disconnect()
			invState.Sleep2 = nil
		end
		local root = vdRootPart()
		if root and sethiddenproperty then
			pcall(function()
				sethiddenproperty(root, "NetworkIsSleeping", false)
			end)
		end
	end)
end

createSwitch(invCard, {
	position = UDim2.new(1, -50, 0.5, -9),
	state = false,
	zIndex = 4,
	onChange = function(enabled)
		if enabled then
			enableInvisibleDesync()
		else
			disableInvisibleDesync()
		end
	end,
})

table.insert(restoreCallbacks, function()
	disableInvisibleDesync()
end)

-- ----------------------------- FIRE SPEED card -----------------------------
-- Ported from the provided snippet: force a very high RateOfFire attribute on
-- every Tool (character + backpack) so weapons fire faster. Off by default;
-- disconnects the watchers when toggled off.
local fsState = { Active = false, Connections = {}, Originals = {}, Holding = false, Firing = nil }

local function fsRecordOriginal(tool)
	if fsState.Originals[tool] == nil then
		fsState.Originals[tool] = {
			RateOfFire = tool:GetAttribute("RateOfFire"),
			rateOfFire = tool:GetAttribute("rateOfFire"),
		}
	end
end

local function fsApplyToTool(tool)
	if not tool:IsA("Tool") then
		return
	end
	pcall(function()
		fsRecordOriginal(tool)
		tool:SetAttribute("RateOfFire", 100000)
		tool:SetAttribute("rateOfFire", 100000)
	end)
end

local function fsWatchContainer(container)
	if not container then
		return
	end
	for _, item in ipairs(container:GetChildren()) do
		fsApplyToTool(item)
	end
	local connection = container.ChildAdded:Connect(function(item)
		if fsState.Active then
			fsApplyToTool(item)
		end
	end)
	table.insert(fsState.Connections, connection)
end

local function fsClearConnections()
	for _, connection in ipairs(fsState.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(fsState.Connections)
end

local function fsWatchBackpack()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		fsWatchContainer(backpack)
		return
	end
	task.spawn(function()
		local waited = LocalPlayer:WaitForChild("Backpack", 5)
		if fsState.Active and waited then
			fsWatchContainer(waited)
		end
	end)
end

local function fsCurrentTool()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Tool")
end

-- fire one shot using the most universal method available: a real synthetic
-- mouse click first (works on most games), then tool Activate() as fallback
local function fsFireOnce(tool)
	if type(mouse1click) == "function" then
		pcall(mouse1click)
	elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
		pcall(function()
			mouse1press()
			mouse1release()
		end)
	elseif tool then
		pcall(function()
			tool:Activate()
		end)
		pcall(function()
			tool:Deactivate()
		end)
	end
end

-- while ENABLED and the mouse/touch is held, keep firing (auto-fire on hold)
local function fsEnsureFiring()
	if fsState.Firing or not fsState.Active or not fsState.Holding then
		return
	end
	fsState.Firing = task.spawn(function()
		while fsState.Active and fsState.Holding do
			fsFireOnce(fsCurrentTool())
			task.wait()
		end
		fsState.Firing = nil
	end)
end

local function fsRestoreTools()
	for tool, original in pairs(fsState.Originals) do
		pcall(function()
			if typeof(tool) == "Instance" and tool:IsA("Tool") and tool.Parent ~= nil then
				tool:SetAttribute("RateOfFire", original.RateOfFire)
				tool:SetAttribute("rateOfFire", original.rateOfFire)
			end
		end)
	end
	table.clear(fsState.Originals)
end

local function disableFireSpeed()
	if not fsState.Active then
		return
	end
	fsState.Active = false
	fsState.Holding = false
	fsClearConnections()
	fsRestoreTools()
end

local function enableFireSpeed()
	if fsState.Active then
		return
	end
	fsState.Active = true
	if LocalPlayer.Character then
		fsWatchContainer(LocalPlayer.Character)
	end
	fsWatchBackpack()

	-- if the button is already being held when toggled ON, start firing now
	local ok, down = pcall(function()
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	end)
	if ok and down then
		fsState.Holding = true
		fsEnsureFiring()
	end
end

-- keep watching after respawn while enabled
LocalPlayer.CharacterAdded:Connect(function(character)
	if not fsState.Active then
		return
	end
	fsClearConnections()
	task.spawn(function()
		task.wait(0.1)
		if not fsState.Active then
			return
		end
		fsWatchContainer(character)
		fsWatchBackpack()
	end)
end)

-- hold-to-fire input (left mouse / touch). Only acts while ENABLED.
trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not fsState.Active or gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fsState.Holding = true
		fsEnsureFiring()
	end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fsState.Holding = false
	end
end))

local fsCard = Instance.new("Frame")
fsCard.Name = "FireSpeed"
fsCard.Size = UDim2.new(1, 0, 0, 56)
fsCard.BackgroundColor3 = COLORS.Log
fsCard.BackgroundTransparency = 0.12
fsCard.BorderSizePixel = 0
fsCard.LayoutOrder = 3
fsCard.ZIndex = 3
fsCard.Parent = miscList
corner(fsCard, 9)
stroke(fsCard, COLORS.White, 1, 0.8)

local fsTitle = label(fsCard, "Title", "Fire Speed", UDim2.new(1, -80, 1, 0), UDim2.fromOffset(14, 7), 11, COLORS.White, Enum.Font.GothamMedium)
fsTitle.ZIndex = 4

local fsDesc = label(fsCard, "Desc", "fast fire + auto-fire on hold", UDim2.new(1, -88, 1, 0), UDim2.fromOffset(14, 29), 9, COLORS.Text, Enum.Font.Gotham)
fsDesc.ZIndex = 4
fsDesc.TextTruncate = Enum.TextTruncate.AtEnd

createSwitch(fsCard, {
	position = UDim2.new(1, -50, 0.5, -9),
	state = false,
	zIndex = 4,
	onChange = function(enabled)
		if enabled then
			enableFireSpeed()
		else
			disableFireSpeed()
		end
	end,
})

table.insert(restoreCallbacks, function()
	disableFireSpeed()
end)

-- ------------------------------ WHITELIST card -----------------------------
-- UI only. Uses the EXISTING silent-aim whitelist (library.whitelist + 
-- Config.Silent.Whitelisted) - the SA target picker already skips these names.
local wlCard = Instance.new("Frame")
wlCard.Name = "Whitelist"
wlCard.Size = UDim2.new(1, 0, 0, 80)
wlCard.BackgroundColor3 = COLORS.Log
wlCard.BackgroundTransparency = 0.12
wlCard.BorderSizePixel = 0
wlCard.LayoutOrder = 4
wlCard.ZIndex = 3
wlCard.Parent = miscList
corner(wlCard, 9)
stroke(wlCard, COLORS.White, 1, 0.8)

local wlTitle = label(wlCard, "Title", "Whitelist", UDim2.new(1, -60, 1, 0), UDim2.fromOffset(14, 6), 11, COLORS.White, Enum.Font.GothamMedium)
wlTitle.ZIndex = 4

local wlStatus = label(wlCard, "Status", "none whitelisted", UDim2.new(1, -60, 1, 0), UDim2.fromOffset(14, 27), 9, COLORS.Text, Enum.Font.Gotham)
wlStatus.ZIndex = 4
wlStatus.TextXAlignment = Enum.TextXAlignment.Left

local function wlIsListed(name)
	return table.find(library.whitelist, name) ~= nil
end

local function wlRefresh()
	if #library.whitelist == 0 then
		wlStatus.Text = "none whitelisted"
	else
		wlStatus.Text = "#" .. #library.whitelist .. ": " .. table.concat(library.whitelist, ", ")
	end
end

local wlListBtn = Instance.new("TextButton")
wlListBtn.Name = "ListButton"
wlListBtn.Size = UDim2.fromOffset(44, 20)
wlListBtn.Position = UDim2.new(1, -56, 0, 8)
wlListBtn.BackgroundColor3 = COLORS.Control
wlListBtn.TextColor3 = COLORS.White
wlListBtn.Text = "LIST"
wlListBtn.TextSize = 9
wlListBtn.Font = Enum.Font.GothamBold
wlListBtn.AutoButtonColor = false
wlListBtn.BorderSizePixel = 0
wlListBtn.ZIndex = 4
wlListBtn.Parent = wlCard
corner(wlListBtn, 10)
stroke(wlListBtn, COLORS.White, 1, 0.7)
pressable(wlListBtn)

-- player rows panel (shown when LIST is open)
local wlRows = Instance.new("Frame")
wlRows.Name = "PlayerList"
wlRows.Size = UDim2.new(1, 0, 0, 8)
wlRows.Position = UDim2.fromOffset(0, 52)
wlRows.BackgroundTransparency = 1
wlRows.ZIndex = 4
wlRows.Visible = false
wlRows.Parent = wlCard

-- active server players (alive, not self)
local wlPlayers = {}

local function wlRefreshPlayers()
	local fresh = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local c = p.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local r = c and c:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				table.insert(fresh, p.Name)
			end
		end
	end
	wlPlayers = fresh
end

local function wlAddName(name)
	if name and not wlIsListed(name) then
		table.insert(library.whitelist, name)
		if not table.find(Config.Silent.Whitelisted, name) then
			table.insert(Config.Silent.Whitelisted, name)
		end
	end
	wlRefresh()
end

local function wlRemoveName(name)
	if name then
		for i = #library.whitelist, 1, -1 do
			if library.whitelist[i] == name then
				table.remove(library.whitelist, i)
			end
		end
		for i = #Config.Silent.Whitelisted, 1, -1 do
			if Config.Silent.Whitelisted[i] == name then
				table.remove(Config.Silent.Whitelisted, i)
			end
		end
	end
	wlRefresh()
end

local function wlBuildRows()
	wlRefreshPlayers()
	for _, child in ipairs(wlRows:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for i, name in ipairs(wlPlayers) do
		local row = Instance.new("TextButton")
		row.Name = "Row" .. i
		row.Size = UDim2.new(1, -32, 0, 22)
		row.Position = UDim2.fromOffset(16, 6 + (i - 1) * 24)
		row.BackgroundColor3 = COLORS.Control
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.TextSize = 10
		row.Font = Enum.Font.GothamBold
		row.TextTruncate = Enum.TextTruncate.AtEnd
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = name
		row.ZIndex = 5
		row.Parent = wlRows
		corner(row, 8)
		pressable(row)
		local function refreshRow()
			local listed = wlIsListed(name)
			row.Text = (listed and "✓ " or "") .. name
			row.TextColor3 = listed and COLORS.Green or COLORS.White
		end
		row.MouseButton1Click:Connect(function()
			if wlIsListed(name) then
				wlRemoveName(name)
			else
				wlAddName(name)
			end
			refreshRow()
		end)
		refreshRow()
	end
	local h = #wlPlayers * 24 + 8
	wlRows.Size = UDim2.new(1, 0, 0, h)
	wlRows.Visible = true
	wlCard.Size = UDim2.new(1, 0, 0, #wlPlayers * 24 + 68)
end

local wlListOpen = false

wlListBtn.MouseButton1Click:Connect(function()
	wlListOpen = not wlListOpen
	if wlListOpen then
		wlBuildRows()
		wlListBtn.Text = "HIDE"
	else
		wlRows.Visible = false
		wlListBtn.Text = "LIST"
		wlCard.Size = UDim2.new(1, 0, 0, 80)
	end
end)

wlRefresh()
wlRefreshPlayers()

-- ------------------------ MOBILE: FPS + PING HUD ----------------------------
-- Small HUD at the top of the screen showing live FPS + ping (ms).
-- The bar ITSELF is tappable (mobile keybind): tap it to on/off the main GUI.
-- Enable the display via SETTINGS > MOBILE - FPS + PING, or press RIGHT SHIFT
-- (same as PC) to toggle the GUI. Nothing else is touched.
local perfHud = Instance.new("Frame")
perfHud.Name = "FpsPingHud"
perfHud.AnchorPoint = Vector2.new(0.5, 0)
perfHud.Position = UDim2.new(0.5, 0, 0, 8)
perfHud.Size = UDim2.fromOffset(170, 22)
perfHud.BackgroundColor3 = Color3.new(0, 0, 0)
perfHud.BackgroundTransparency = 0.45
perfHud.BorderSizePixel = 0
perfHud.ZIndex = 500
perfHud.Visible = false
perfHud.Parent = gui
corner(perfHud, 8)
stroke(perfHud, COLORS.White, 1, 0.5)

local perfText = label(perfHud, "Text", "FPS --  |  PING ---ms", UDim2.new(1, 0, 1, 0), UDim2.fromOffset(0, 0), 10, COLORS.White, Enum.Font.GothamBold)
perfText.ZIndex = 501

-- the FPS bar itself is the tap target (opens/closes the main GUI)
local perfTap = Instance.new("TextButton")
perfTap.Name = "FpsPingTap"
perfTap.Size = UDim2.new(1, 0, 1, 0)
perfTap.BackgroundTransparency = 1
perfTap.BorderSizePixel = 0
perfTap.Text = ""
perfTap.AutoButtonColor = false
perfTap.ZIndex = 502
perfTap.Parent = perfHud
pressable(perfTap)

perfTap.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
	perfUpdateHud()
end)

local perfStats = game:GetService("Stats").PerformanceStats
local perfFrames = 0
local perfCountTime = 0

local perfConn = RunService.RenderStepped:Connect(function(dt)
	if perfHud.Visible then
		perfFrames = perfFrames + 1
		perfCountTime = perfCountTime + dt
		if perfCountTime >= 0.5 then
			local fps = math.floor(perfFrames / perfCountTime)
			local ms = 0
			pcall(function()
				ms = math.floor(perfStats.Ping:GetValue())
			end)
			perfText.Text = "FPS " .. fps .. "  |  PING " .. ms .. "ms"
			perfFrames = 0
			perfCountTime = 0
		end
		-- compact: fit the bar exactly to the text
		perfHud.Size = UDim2.fromOffset(math.max(perfText.TextBounds.X + 20, 90), 22)
	end
end)

table.insert(restoreCallbacks, function()
	if perfConn then
		perfConn:Disconnect()
		perfConn = nil
	end
end)

local perfUserEnabled = false

local function perfUpdateHud()
	perfHud.Visible = perfUserEnabled or not window.Visible
end

local perfToggleKey = Enum.KeyCode.RightShift

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == perfToggleKey then
		window.Visible = not window.Visible
		perfUpdateHud()
	end
end))

perfUpdateHud()

-- SETTINGS page -> MOBILE section: FPS + PING switch
local perfDash = Instance.new("Frame")
perfDash.Size = UDim2.fromOffset(10, 1)
perfDash.Position = UDim2.fromOffset(17, 266)
perfDash.BackgroundColor3 = COLORS.Dim
perfDash.BorderSizePixel = 0
perfDash.ZIndex = 3
perfDash.Parent = settingsPage

local perfTitle = label(settingsPage, "MobileTitle", "MOBILE", UDim2.fromOffset(100, 24), UDim2.fromOffset(33, 259), 11, COLORS.White, Enum.Font.GothamBold)
perfTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
perfTitle.TextStrokeTransparency = 0.35
perfTitle.ZIndex = 3

local perfRule = Instance.new("Frame")
perfRule.Size = UDim2.new(1, -152, 0, 1)
perfRule.Position = UDim2.fromOffset(135, 266)
perfRule.BackgroundColor3 = COLORS.Dim
perfRule.BackgroundTransparency = 0.35
perfRule.BorderSizePixel = 0
perfRule.ZIndex = 3
perfRule.Parent = settingsPage

local mobBtn = Instance.new("TextButton")
mobBtn.Name = "MobileButton"
mobBtn.Size = UDim2.new(1, -34, 0, 42)
mobBtn.Position = UDim2.fromOffset(17, 282)
mobBtn.BackgroundColor3 = COLORS.Control
mobBtn.BackgroundTransparency = 0.15
mobBtn.BorderSizePixel = 0
mobBtn.TextColor3 = COLORS.White
mobBtn.Text = "MOBILE  -  FPS + PING"
mobBtn.TextSize = 11
mobBtn.Font = Enum.Font.GothamBold
mobBtn.AutoButtonColor = false
mobBtn.ZIndex = 7
mobBtn.Parent = settingsPage
corner(mobBtn, 6)
stroke(mobBtn, COLORS.White, 1, 0.7)
pressable(mobBtn)

mobBtn.MouseButton1Click:Connect(function()
	perfUserEnabled = not perfUserEnabled
	perfUpdateHud()
end)

local perfNote = label(settingsPage, "MobileNote", "tap FPS on top, or press RIGHT SHIFT, to on/off GUI", UDim2.new(1, -34, 0, 14), UDim2.fromOffset(17, 328), 9, COLORS.Dim, Enum.Font.GothamBold)
perfNote.TextXAlignment = Enum.TextXAlignment.Center
perfNote.ZIndex = 4
-- ============================================================================

