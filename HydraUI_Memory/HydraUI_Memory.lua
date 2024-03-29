if (not HydraUIGlobal) then
	return
end

local HydraUI, Language, Assets, Settings = HydraUIGlobal:get()

local select = select
local format = format
local tinsert = tinsert
local tremove = tremove
local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local IsAddOnLoaded = IsAddOnLoaded
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local InCombatLockdown = InCombatLockdown
local Label = Language["Memory"]

local Sorted = {}
local TablePool = {}

local Sort = function(a, b)
	return a[2] > b[2]
end

local GetMemory = function(kb)
	if (kb > 1024) then
		return format("%.2f", (kb / 1024)), "MB"
	else
		return format("%.0f", kb), "KB"
	end
end

local OnEnter = function(self)
	self:SetTooltip()

	local Name, Table
	local Memory = 0
	local TotalMemory = 0

	self:Update(61)

	for i = 1, GetNumAddOns() do
		if IsAddOnLoaded(i) then
			Name = select(2, GetAddOnInfo(i))
			Memory = GetAddOnMemoryUsage(i)
			Table = TablePool[1] and tremove(TablePool, 1) or {}

			Table[1] = Name
			Table[2] = Memory

			TotalMemory = TotalMemory + Memory

			tinsert(Sorted, Table)
		end
	end

	GameTooltip:AddDoubleLine(Language["Add-On Memory"], format("%s %s", GetMemory(TotalMemory)), 1, 1, 1)
	GameTooltip:AddLine(" ")

	table.sort(Sorted, Sort)

	local Max = #Sorted

	for i = 1, (Max > 30 and 30 or Max) do
		GameTooltip:AddDoubleLine(Sorted[i][1], format("%s %s", GetMemory(Sorted[i][2])), 1, 1, 1)
	end

	if (Max > 30) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(Language["%s more addons are not shown"], Max - 30))
	end

	for i = 1, Max do
		tinsert(TablePool, tremove(Sorted, 1))
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, elapsed)
	self.Elapsed = self.Elapsed + elapsed

	if (self.Elapsed > 60) then
		UpdateAddOnMemoryUsage()

		local TotalMemory = 0

		for i = 1, GetNumAddOns() do
			TotalMemory = TotalMemory + GetAddOnMemoryUsage(i)
		end

		local Value, Unit = GetMemory(TotalMemory)

		self.Text:SetFormattedText("|cff%s%.2f|r |cff%s%s|r", Settings["data-text-label-color"], Value, HydraUI.ValueColor, Unit)

		self.Elapsed = 0
	end
end

local OnMouseUp = function(self)
	if InCombatLockdown() then
		return ERR_NOT_IN_COMBAT
	end

	if IsModifierKeyDown() then
		collectgarbage()

		self:Update(61)

		GameTooltip:ClearLines()
		OnEnter(self)
	else
		if AddonList then
			ToggleFrame(AddonList)
		end
	end
end

local OnEvent = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		self:SetScript("OnUpdate", nil)
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:SetScript("OnUpdate", Update)
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", OnEvent)
	self:SetScript("OnUpdate", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

	self.Elapsed = 0

	self:Update(61)
end

local OnDisable = function(self)
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)

	self.Elapsed = 0

	self.Text:SetText("")
end

HydraUI:AddDataText(Label, OnEnable, OnDisable, Update)
HydraUI:NewPlugin("HydraUI_Memory")