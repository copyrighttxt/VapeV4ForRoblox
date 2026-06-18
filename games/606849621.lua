local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert') end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function() return game:HttpGet('https://raw.githubusercontent.com/copyrighttxt/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true) end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local tweenService = cloneref(game:GetService('TweenService'))
local teamsService = cloneref(game:GetService('Teams'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local httpService = cloneref(game:GetService('HttpService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local vm = loadstring(downloadFile('newvape/libraries/vm.lua'), 'vm')()

local jb = {}
local InfNitro = {Enabled = false}
local LazerGodmode = {Enabled = false}

local function getVehicle(ent)
	if ent.Player then
		for _, car in collectionService:GetTagged('Vehicle') do
			for _, seat in car:GetChildren() do
				if (seat.Name == 'Seat' or seat.Name == 'Passenger') then
					seat = seat:FindFirstChild('PlayerName')
					if seat and seat.Value == ent.Player.Name then
						return car
					end
				end
			end
		end
	end
end

local function isArrested(name)
	for i, v in jb.CircleAction.Specs do
		if v.Name == 'Arrest' and v.PlayerName == name then
			return not v.ShouldArrest
		end
	end
	return false
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isIllegal(ent)
	if ent.Player and ent.Player.Team == teamsService.Prisoner then
		local items = ent.Player:FindFirstChild('CurrentInventory')
		items = items and items.Value
		if items then
			for i, v in items:GetChildren() do
				if v.Name ~= 'MansionInvite' then
					return true
				end
			end
		end

		return ent.Illegal
	end
	return true
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			},
			{
				Connect = function()
					return hum:GetPropertyChangedSignal('Sit'):Connect(function()
						if getVehicle(ent) then
							ent.Illegal = true
						end
					end)
				end
			}
		}
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then return ent:TeamCheck() end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		if lplr.Team == teamsService.Police then
			return ent.Player.Team ~= teamsService.Police
		else
			return ent.Player.Team == teamsService.Police
		end
		return true
	end
end)
entitylib.start()

run(function()
	local function dumpRemotes(scripts, renamed)
		local returned = {}

		for _, scr in scripts do
			local deserializedcode = vm.luau_deserialize(getscriptbytecode(scr))

			for _, proto in deserializedcode.protoList do
				local stack, top, code = {}, -1, proto.code
				for i, inst in code do
					if inst.opcode == 4 then -- LOADN
						stack[inst.A] = inst.D
					elseif inst.opcode == 5 then -- LOADK
						stack[inst.A] = inst.K
					elseif inst.opcode == 6 then -- MOVE
						stack[inst.A] = stack[inst.B]
					elseif inst.opcode == 12 then -- GETIMPORT
						local count, import = inst.KC, getrenv()[inst.K0]

						if count == 1 then
							stack[inst.A] = import
						elseif count == 2 then
							stack[inst.A] = import[inst.K1]
						elseif count == 3 then
							stack[inst.A] = import[inst.K1][inst.K2]
						end
					elseif inst.opcode == 20 then -- NAMECALL
						local A, B, kv = inst.A, inst.B, inst.K
						stack[A + 1] = stack[B]

						local callInst = code[i + 2]
						local callA, callB, callC = callInst.A, callInst.B, callInst.C
						local params = if callB == 0 then top - callA else callB - 1
						if kv == 'sub' or kv == 'reverse' then
							local arg1, arg2, arg3 = table.unpack(stack, callA + 1, callA + params)
							if kv == 'reverse' and not arg1 then arg1 = 'a' end

							local ret_list = table.pack(string[kv](arg1, arg2, arg3))
							local ret_num = ret_list.n - 1
							if callC == 0 then
								top = callA + ret_num - 1
							else
								ret_num = callC - 1
							end

							table.move(ret_list, 1, ret_num, callA, stack)
						elseif kv == 'FireServer' then
							local name, val = proto.debugname == '(??)' and scr.Name or proto.debugname, stack[callA + 2]
							if name == val then table.insert(returned, val) continue end
							if returned[name] then
								for i = 1, 10 do
									if not returned[name..i] then name ..= i break end
								end
							end

							returned[name] = val
						end
					elseif inst.opcode == 49 then -- CONCAT
						local s = ""
						for i = inst.B, inst.C do
							if type(stack[i]) ~= 'string' then continue end
							s ..= stack[i]
						end
						stack[inst.A] = s
					end
				end
			end
		end

		for i, v in table.clone(returned) do
			if renamed[i] then
				returned[i] = nil
				returned[renamed[i]] = v
			end
		end

		return returned
	end

	local function getCash()
		for i, v in debug.getupvalue(jb.TeamChooseController.Init, 2) do
			if type(v) == 'function' then
				for _, const in debug.getconstants(v) do
					if tostring(const):find('PlusCash') then
						return v, i
					end
				end
			end
		end
	end

	local function toMoney(num)
		local one, two, three = string.match(tostring(num), '^([^%d]*%d)(%d*)(.-)$')
		return one .. (two:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. three)..'$'
	end

	jb = {
		BulletEmitter = require(replicatedStorage.Game.ItemSystem.BulletEmitter),
		CircleAction = require(replicatedStorage.Module.UI).CircleAction,
		CargoController = require(replicatedStorage.Game.Robbery.RobberyPassengerTrain),
		FallingController = require(replicatedStorage.Game.Falling),
		GunController = require(replicatedStorage.Game.Item.Gun),
		HotbarItemSystem = require(replicatedStorage.Hotbar.HotbarItemSystem),
		InventoryItemSystem = require(replicatedStorage.Inventory.InventoryItemSystem),
		ItemSystemController = require(replicatedStorage.Game.ItemSystem.ItemSystem),
		PlayerUtils = require(replicatedStorage.Game.PlayerUtils),
		RagdollController = require(replicatedStorage.Module.AlexRagdoll),
		TaserController = require(replicatedStorage.Game.Item.Taser),
		TeamChooseController = require(replicatedStorage.TeamSelect.TeamChooseUI),
		VehicleController = require(replicatedStorage.Vehicle.VehicleUtils)
	}

	if not jb.VehicleController.toggleLocalLocked or not jb.VehicleController.NitroShopVisible then
		repeat task.wait() until (jb.VehicleController.toggleLocalLocked and jb.VehicleController.NitroShopVisible) or vape.Loaded == nil
		if vape.Loaded == nil then return end
	end
	local remotetable = debug.getupvalue(jb.VehicleController.toggleLocalLocked, 2)
	local fireserver, hook = remotetable.FireServer

	remotes = dumpRemotes({
		replicatedStorage.Game.TrainSystem.LocomotiveFront,
		replicatedStorage.Game.ItemSystem.ItemSystem,
		replicatedStorage.Game.CashBuyUI,
		replicatedStorage.Game.Item.Taser,
		replicatedStorage.Game.Item.Gun,
		replicatedStorage.Game.Falling,
		lplr.PlayerScripts.LocalScript
	}, {
		Action = 'Pickup',
		Action3 = 'StartRob',
		Action2 = 'EndRob',
		AttemptArrest = 'Arrest',
		attemptPunch = 'Punch',
		AttemptVehicleEject = 'Eject',
		AttemptVehicleEnter = 'GetIn',
		BroadcastInputBegan = 'InputBegan',
		BroadcastInputEnded = 'InputEnded',
		CalculateDelta = 'UseNitro',
		Draw = 'TaseReplicate',
		Gun = 'PopTires',
		LocalScript2 = 'LookAngle',
		LocalScript = 'SelfDamage',
		onPressed = 'FlipVehicle',
		OnJump = 'GetOut',
		OnJump1 = 'GetOut',
		UpdateMousePosition = 'AimPosition'
	})

	local function fireHook(self, id, ...)
		local rem
		for i, v in remotes do
			if v == id then
				rem = i
			end
		end

		if InfNitro.Enabled and rem == 'UseNitro' then return end
		if LazerGodmode.Enabled and rem == 'SelfDamage' then return end
		if rem ~= 'LookAngle' and rem ~= 'AimPosition' then
			local called = getfenv(3)
			called = called and called.script
			if called and (not rem) then print(id, 'called with', called:GetFullName()) end
			print(id, rem or id, ...)
		end

		return hook(self, id, ...)
	end

	hook = hookfunction(fireserver, function(self, id, ...)
		return fireHook(self, id, ...)
	end)

	function jb:FireServer(id, ...)
		if not remotes[id] then
			notif('Vape', 'Failed to find remote ('..id..')', 10, 'alert')
			return
		end
		return hook(remotetable, remotes[id], ...)
	end

	local arrests = sessioninfo:AddItem('Arrested')
	local moneymade = sessioninfo:AddItem('Money Made', 0, toMoney, true)
	local bounty = sessioninfo:AddItem('Bounty List', '', function()
		local text, tab = '', workspace.MostWanted:FindFirstChild('Board', true)
		tab = tab and tab:GetChildren() or {}

		for i, v in tab do
			if v:IsA('Frame') then
				local plrname = v:FindFirstChild('PlayerName', true)
				local bounty = v:FindFirstChild('Bounty', true)
				if plrname and bounty then
					text = text..'\n'..(plrname.Text..': '..bounty.Text:gsub(' Bounty', ''))
				end
			end
		end

		return text
	end, false)

	local cashfunc, cashhook = getCash()
	if cashfunc then
		cashhook = hookfunction(cashfunc, function(amount, text, ...)
			moneymade:Increment(amount)
			if text == 'Arrest' then
				arrests:Increment()
			end
			return cashhook(amount, text, ...)
		end)
	end

	vape:Clean(function()
		table.clear(remotes)
		table.clear(jb)
		hookfunction(fireserver, hook)
		hookfunction(cashfunc, cashhook)
		--restorefunction(fireserver)
		--restorefunction(cashfunc)
	end)
end)

for _, v in {'Reach', 'TriggerBot', 'Disabler', 'AntiFall', 'HitBoxes', 'Killaura', 'MurderMystery'} do
	vape:Remove(v)
end
run(function()
	local ForceHeadshot
	
	ForceHeadshot = vape.Categories.Combat:CreateModule({
		Name = 'ForceHeadshot',
		Function = function(callback)
			if callback then
				local hook
				hook = hookfunction(jb.GunController.BulletEmitterOnLocalHitPlayer, function(...)
					local shotData = select(15, ...)
					shotData.isHeadshot = true
					return hook(...)
				end)
			else
				restorefunction(jb.GunController.BulletEmitterOnLocalHitPlayer)
			end
		end,
		Tooltip = 'Modifies bullets to always do headshot damage.'
	})
end)
	
run(function()
	local SilentAim
	local Target
	local Mode
	local Range
	local HitChance
	local HeadshotChance
	local CircleColor
	local CircleTransparency
	local CircleFilled
	local CircleObject
	local Instant
	local Hooked
	local ProjectileRaycast = RaycastParams.new()
	ProjectileRaycast.RespectCanCollide = true
	
	SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			if CircleObject then
				CircleObject.Visible = callback and Mode.Value == 'Mouse'
			end
	
			if callback then
				Hooked = jb.GunController.TransformLocalMousePosition
				jb.GunController.TransformLocalMousePosition = function(self, pos)
					local ent = entitylib['Entity'..Mode.Value]({
						Range = Range.Value,
						Wallcheck = Target.Walls.Enabled and (obj or true) or nil,
						Part = 'RootPart',
						Origin = entitylib.isAlive and entitylib.character.RootPart.Position or nil,
						Players = Target.Players.Enabled,
						NPCs = Target.NPCs.Enabled
					})
	
					if ent then
						local item = jb.ItemSystemController:GetLocalEquipped()
						if item and ((self.Tip.CFrame.Position - ent.RootPart.Position).Magnitude / (item.Config.BulletSpeed or 1000)) < item.BulletEmitter.LifeSpan then
							ProjectileRaycast.FilterDescendantsInstances = {gameCamera, ent.Character, workspace.Vehicles}
							ProjectileRaycast.CollisionGroup = ent.RootPart.CollisionGroup
							local calc = prediction.SolveTrajectory(self.Tip.CFrame.Position, item.Config.BulletSpeed or 1000, math.abs(item.BulletEmitter.GravityVector.Y), ent.RootPart.Position, Instant.Enabled and Vector3.zero or ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
							if calc then
								targetinfo.Targets[ent] = tick() + 1
								return calc
							end
						end
					end
	
					return pos
				end
	
				repeat
					if CircleObject then
						CircleObject.Position = inputService:GetMouseLocation()
					end
	
					if Instant.Enabled then
						local item = jb.ItemSystemController:GetLocalEquipped()
						if item and item.BulletEmitter then
							rawset(item.BulletEmitter, 'LastUpdate', tick() - (item.BulletEmitter.LifeSpan - 0.1))
						end
					end
	
					task.wait()
				until not SilentAim.Enabled
			else
				jb.GunController.TransformLocalMousePosition = Hooked
			end
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Target = SilentAim:CreateTargets({Players = true})
	Mode = SilentAim:CreateDropdown({
		Name = 'Mode',
		List = {'Mouse', 'Position'},
		Function = function(val)
			if CircleObject then
				CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
			end
		end,
		Tooltip = 'Mouse - Checks for entities near the mouses position\nPosition - Checks for entities near the local character'
	})
	Range = SilentAim:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 1000,
		Default = 150,
		Function = function(val)
			if CircleObject then
				CircleObject.Radius = val
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	SilentAim:CreateToggle({
		Name = 'Range Circle',
		Function = function(callback)
			if callback then
				CircleObject = Drawing.new('Circle')
				CircleObject.Filled = CircleFilled.Enabled
				CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
				CircleObject.Position = vape.gui.AbsoluteSize / 2
				CircleObject.Radius = Range.Value
				CircleObject.NumSides = 100
				CircleObject.Transparency = 1 - CircleTransparency.Value
				CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
			else
				pcall(function()
					CircleObject.Visible = false
					CircleObject:Remove()
				end)
			end
			CircleColor.Object.Visible = callback
			CircleTransparency.Object.Visible = callback
			CircleFilled.Object.Visible = callback
		end
	})
	CircleColor = SilentAim:CreateColorSlider({
		Name = 'Circle Color',
		Function = function(hue, sat, val)
			if CircleObject then
				CircleObject.Color = Color3.fromHSV(hue, sat, val)
			end
		end,
		Darker = true,
		Visible = false
	})
	CircleTransparency = SilentAim:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.5,
		Function = function(val)
			if CircleObject then
				CircleObject.Transparency = 1 - val
			end
		end,
		Darker = true,
		Visible = false
	})
	CircleFilled = SilentAim:CreateToggle({
		Name = 'Circle Filled',
		Function = function(callback)
			if CircleObject then
				CircleObject.Filled = callback
			end
		end,
		Darker = true,
		Visible = false
	})
	Instant = SilentAim:CreateToggle({Name = 'Hitscan Bullets'})
end)
	
run(function()
	local AutoArrest
	
	AutoArrest = vape.Categories.Blatant:CreateModule({
		Name = 'AutoArrest',
		Function = function(callback)
			if callback then
				repeat
					local item = jb.ItemSystemController:GetLocalEquipped()
					if item and item.__ClassName == 'Handcuffs' then
						local localPosition = entitylib.character.Humanoid.HumanoidUnloadServerPosition.Value
						local plrs = entitylib.AllPosition({
							Players = true,
							Part = 'RootPart',
							Range = 50
						})
	
						for _, ent in plrs do
							if not AutoArrest.Enabled then break end
							if ent.Player and isIllegal(ent) then
								local vehicle = ent.Humanoid.Sit and getVehicle(ent) or nil
								if vehicle then
									jb:FireServer('Eject', vehicle)
								elseif not isArrested(ent.Player.Name) and (localPosition - ent.RootPart.Position).Magnitude < 18.4 then
									jb:FireServer('Arrest', ent.Player.Name)
									task.wait(0.6)
								end
							end
						end
					end
	
					task.wait(0.016)
				until not AutoArrest.Enabled
			end
		end,
		Tooltip = 'Automatically uses handcuffs on nearby entities'
	})
end)
	
run(function()
	local AutoPop
	local Range
	local TeamCheck
	
	local function getEntitiesInVehicle(car)
		local entities = {}
	
		for _, seat in car:GetChildren() do
			if (seat.Name == 'Seat' or seat.Name == 'Passenger') then
				seat = seat:FindFirstChild('PlayerName')
				if seat then
					for _, ent in entitylib.List do
						if ent.Player and ent.Player.Name == seat.Value then
							table.insert(entities, ent)
						end
					end
				end
			end
		end
	
		return entities
	end
	
	local function getVehiclesNear()
		local allowed = {}
	
		if entitylib.isAlive then
			local localPosition = entitylib.character.HumanoidRootPart.Position
			for _, car in collectionService:GetTagged('Vehicle') do
				if car.PrimaryPart and (car.PrimaryPart.Position - localPosition).Magnitude <= Range.Value then
					local entities = getEntitiesInVehicle(car)
					local check = #entities > 0
					if TeamCheck.Enabled then
						for _, ent in entities do
							if not ent.Targetable then
								check = false
								break
							end
						end
					end
	
					if check then
						table.insert(allowed, car)
					end
				end
			end
		end
	
		return allowed
	end
	
	AutoPop = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPop',
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						local item = jb.ItemSystemController:GetLocalEquipped()
						if item and item.BulletEmitter and item.Model then
							for _, car in getVehiclesNear() do
								if not (AutoPop.Enabled and item.Model) then break end
								jb:FireServer('PopTires', car, item.Model.Name)
								task.wait(0.1)
							end
						end
	
						task.wait(0.016)
					until not AutoPop.Enabled
				end)
			end
		end,
		Tooltip = 'Automatically pops vehicles tires around you'
	})
	Range = AutoPop:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 600,
		Default = 600
	})
	TeamCheck = AutoPop:CreateToggle({Name = 'Team Check'})
end)
	
run(function()
	local AutoPunch
	
	AutoPunch = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPunch',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive then
						jb:FireServer('Punch')
					end
	
					task.wait(0.3)
				until not AutoPunch.Enabled
			end
		end,
		Tooltip = 'Always punches people infront of you'
	})
end)
	
run(function()
	local AutoTaze
	local HandCheck
	
	AutoTaze = vape.Categories.Blatant:CreateModule({
		Name = 'AutoTaze',
		Function = function(callback)
			if callback then
				repeat
					local item = jb.ItemSystemController:GetLocalEquipped()
					item = item and item.__ClassName == 'Taser' or nil
					if not HandCheck.Enabled or item then
						local ent = entitylib.EntityPosition({
							Players = true,
							Part = 'RootPart',
							Range = 50
						})
	
						if ent and isIllegal(ent) and not isArrested(ent.Player.Name) then
							if item then
								jb:FireServer('TaseReplicate', ent.Head.Position)
							end
							jb:FireServer('Tase', ent.Humanoid, ent.Head, ent.Head.Position)
							task.wait(10)
						end
					end
	
					task.wait(0.016)
				until not AutoTaze.Enabled
			end
		end,
		Tooltip = 'Immobilizes entities around you'
	})
	HandCheck = AutoTaze:CreateToggle({Name = 'Hand Check'})
end)
	
run(function()
	LazerGodmode = vape.Categories.Blatant:CreateModule({Name = 'LazerGodmode'})
end)
	
run(function()
	vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			debug.setconstant(debug.getupvalue(jb.FallingController.Init, 20), 9, callback and 'Archivable' or 'Sit')
		end,
		Tooltip = 'Disables ragdoll handling & fall damage'
	})
end)
	
run(function()
	local nitrotable = debug.getupvalue(jb.VehicleController.NitroShopVisible, 1)
	local oldnitro
	
	InfNitro = vape.Categories.Utility:CreateModule({
		Name = 'InfiniteNitro',
		Function = function(callback)
			if callback then
				oldnitro = nitrotable.Nitro
				jb.VehicleController.updateSpdBarRatio(1)
	
				repeat
					nitrotable.Nitro = 250
					task.wait(0.1)
				until not InfNitro.Enabled
			else
				nitrotable.Nitro = oldnitro
				jb.VehicleController.updateSpdBarRatio(oldnitro / 250)
			end
		end,
		Tooltip = 'Infinite boost for the local car'
	})
end)
	
run(function()
	vape.Categories.Utility:CreateModule({
		Name = 'InstantAction',
		Function = function(callback)
			debug.setconstant(jb.CircleAction.Press, 3, callback and 'Timeda' or 'Timed')
		end,
		Tooltip = 'Allows you to instantly complete ProximityPrompt actions'
	})
end)

run(function()
	local BountyTracker
	local MinBounty
	local gui
	local listFrame
	local emptyLabel
	local entryPool = {}
	local rowHeight = 28
	local rowPadding = 3
	local panelW = 240

	local function findBountyData()
		for _, v in game:GetDescendants() do
			if v:IsA('StringValue') and v.Name == 'BountyData' then
				return v
			end
		end
	end

	local function formatBounty(num)
		local s = tostring(math.floor(num))
		local r = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
		if r:sub(1, 1) == ',' then r = r:sub(2) end
		return '$' .. r
	end

	local function getBounties()
		local val = findBountyData()
		if not val then return {} end
		local suc, data = pcall(function() return httpService:JSONDecode(val.Value) end)
		if not suc or type(data) ~= 'table' then return {} end
		local out = {}
		for _, e in ipairs(data) do
			if (e.Bounty or 0) > (MinBounty and MinBounty.Value or 2000) then
				table.insert(out, e)
			end
		end
		table.sort(out, function(a, b) return (a.Bounty or 0) > (b.Bounty or 0) end)
		return out
	end

	local function renderBounties()
		if not gui then return end
		for _, row in entryPool do row.Visible = false end
		local entries = getBounties()
		if #entries == 0 then
			emptyLabel.Text = 'No bounties over ' .. formatBounty(MinBounty and MinBounty.Value or 2000)
			emptyLabel.Visible = true
			return
		end
		emptyLabel.Visible = false
		for i, entry in ipairs(entries) do
			local row = entryPool[i]
			if not row then
				row = Instance.new('Frame')
				row.BackgroundTransparency = 1
				row.Size = UDim2.new(1, 0, 0, rowHeight)
				row.LayoutOrder = i

				local sep = Instance.new('Frame', row)
				sep.Size = UDim2.new(1, 0, 0, 1)
				sep.Position = UDim2.new(0, 0, 1, -1)
				sep.BackgroundColor3 = Color3.new(1, 1, 1)
				sep.BackgroundTransparency = 0.9
				sep.BorderSizePixel = 0

				local av = Instance.new('ImageLabel', row)
				av.Name = 'Avatar'
				av.Size = UDim2.fromOffset(20, 20)
				av.Position = UDim2.fromOffset(0, (rowHeight - 20) / 2)
				av.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				av.BackgroundTransparency = 0.3
				av.Image = ''
				av.ScaleType = Enum.ScaleType.Crop
				Instance.new('UICorner', av).CornerRadius = UDim.new(0, 3)

				local lbl = Instance.new('TextLabel', row)
				lbl.Name = 'Lbl'
				lbl.Size = UDim2.new(1, -28, 1, 0)
				lbl.Position = UDim2.fromOffset(26, 0)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextStrokeColor3 = Color3.new()
				lbl.TextStrokeTransparency = 0.8

				row.Parent = listFrame
				entryPool[i] = row
			end
			row.Visible = true
			row.LayoutOrder = i
			row.Lbl.Text = (entry.Name or '?') .. '  -  ' .. formatBounty(entry.Bounty or 0)

			local uid = entry.UserId
			if not uid then
				local plr = playersService:FindFirstChild(entry.Name or '')
				uid = plr and plr.UserId or nil
			end
			if uid then
				local av = row.Avatar
				task.spawn(function()
					local ok, url = pcall(function()
						return playersService:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
					end)
					if ok and url and url ~= '' and av and av.Parent then
						av.Image = url
					end
				end)
			end
		end
	end

	local function buildGui()
		gui = Instance.new('ScreenGui')
		gui.Name = 'VapeBountyTracker'
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = lplr.PlayerGui

		local panel = Instance.new('Frame', gui)
		panel.Name = 'Panel'
		panel.Size = UDim2.fromOffset(panelW, 32)
		panel.Position = UDim2.fromScale(0.05, 0.2)
		panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		panel.BackgroundTransparency = 0.15
		panel.BorderSizePixel = 0
		panel.Active = true
		panel.Draggable = true
		panel.AutomaticSize = Enum.AutomaticSize.Y
		Instance.new('UICorner', panel).CornerRadius = UDim.new(0, 6)
		local stroke = Instance.new('UIStroke', panel)
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.88

		local header = Instance.new('Frame', panel)
		header.Size = UDim2.new(1, 0, 0, 22)
		header.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		header.BackgroundTransparency = 0.1
		header.BorderSizePixel = 0
		Instance.new('UICorner', header).CornerRadius = UDim.new(0, 6)
		local hCover = Instance.new('Frame', header)
		hCover.Size = UDim2.new(1, 0, 0.5, 0)
		hCover.Position = UDim2.fromScale(0, 0.5)
		hCover.BackgroundColor3 = header.BackgroundColor3
		hCover.BackgroundTransparency = header.BackgroundTransparency
		hCover.BorderSizePixel = 0
		local hLbl = Instance.new('TextLabel', header)
		hLbl.Size = UDim2.new(1, -8, 1, 0)
		hLbl.Position = UDim2.fromOffset(8, 0)
		hLbl.BackgroundTransparency = 1
		hLbl.TextColor3 = Color3.new(1, 1, 1)
		hLbl.Font = Enum.Font.GothamBold
		hLbl.TextSize = 11
		hLbl.TextXAlignment = Enum.TextXAlignment.Left
		hLbl.Text = 'BOUNTY TRACKER'

		local padding = Instance.new('UIPadding', panel)
		padding.PaddingBottom = UDim.new(0, 6)

		listFrame = Instance.new('Frame', panel)
		listFrame.Name = 'List'
		listFrame.Position = UDim2.fromOffset(8, 26)
		listFrame.Size = UDim2.new(1, -16, 0, 0)
		listFrame.BackgroundTransparency = 1
		listFrame.AutomaticSize = Enum.AutomaticSize.Y
		local layout = Instance.new('UIListLayout', listFrame)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, rowPadding)

		emptyLabel = Instance.new('TextLabel', listFrame)
		emptyLabel.Size = UDim2.new(1, 0, 0, rowHeight)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 11
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		emptyLabel.Text = 'No bounties over $2,000'
		emptyLabel.Visible = false
		emptyLabel.LayoutOrder = 0
	end

	BountyTracker = vape.Categories.Render:CreateModule({
		Name = 'BountyTracker',
		Function = function(callback)
			if callback then
				if not gui then buildGui() end
				gui.Enabled = true
				repeat
					renderBounties()
					task.wait(5)
				until not BountyTracker.Enabled
				gui.Enabled = false
				for _, row in entryPool do row.Visible = false end
				emptyLabel.Visible = false
			end
		end,
		Tooltip = 'Shows wanted players above a bounty threshold'
	})

	MinBounty = BountyTracker:CreateSlider({
		Name = 'Min Bounty',
		Min = 0,
		Max = 100000,
		Default = 2000,
		Suffix = function(val) return '  (' .. formatBounty(val) .. ')' end
	})

	vape:Clean(function()
		if gui then gui:Destroy() end
		gui, listFrame, emptyLabel = nil, nil, nil
		table.clear(entryPool)
	end)
end)
