if (not vUIGlobal) then
	return
end

local vUI, GUI, Language, Media, Settings = vUIGlobal:get()

local select = select
local format = format
local tinsert = tinsert
local tremove = tremove
local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local IsAddOnLoaded = IsAddOnLoaded
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
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
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	local Name, Table
	local Memory = collectgarbage("count")
	
	UpdateAddOnMemoryUsage()
	
	GameTooltip:AddDoubleLine(Language["Lua Memory"], format("%s %s", GetMemory(Memory)), 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Add-On Memory"], format("%s %s", GetMemory(self.MemoryValue)), 1, 1, 1)
	GameTooltip:AddLine(" ")
	
	-- Get addon information and put it into the sorting table
	for i = 1, GetNumAddOns() do
		if IsAddOnLoaded(i) then
			Name = select(2, GetAddOnInfo(i))
			Memory = GetAddOnMemoryUsage(i)
			Table = TablePool[1] and tremove(TablePool, 1) or {}
			
			Table[1] = Name
			Table[2] = Memory
			
			tinsert(Sorted, Table)
		end
	end
	
	-- Sort information
	table.sort(Sorted, Sort)
	
	local Max = #Sorted
	
	-- Show up to 30 entries
	for i = 1, (Max > 30 and 30 or Max) do
		GameTooltip:AddDoubleLine(Sorted[i][1], format("%s %s", GetMemory(Sorted[i][2])), 1, 1, 1)
	end
	
	-- If we exceeded the limit, tell the user how many were omitted
	if (Max > 30) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(Language["%s more addons are not shown"], Max - 30))
	end
	
	-- Clear the sorting table for next use
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
		
		self.Text:SetFormattedText("|cff%s%.2f|r |cff%s%s|r", Settings["data-text-label-color"], Value, Settings["data-text-value-color"], Unit)
		
		self.Elapsed = 0
		self.MemoryValue = TotalMemory
	end
end

local OnMouseUp = function(self)
	collectgarbage()
	
	self:Update(61)
	
	GameTooltip:Hide()
	OnEnter(self)
end

local OnEnable = function(self)
	self:SetScript("OnUpdate", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)
	
	self.Elapsed = 0
	self.MemoryValue = 0
	
	self:Update(61)
end

local OnDisable = function(self)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)
	
	self.Elapsed = 0
	
	self.Text:SetText("")
end

vUI:AddDataText(Label, OnEnable, OnDisable, Update)
vUI:NewPlugin("vUI_MemoryDataText")