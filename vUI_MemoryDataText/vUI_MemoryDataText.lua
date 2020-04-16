local AddOn = ...
local vUI, GUI, Language, Media, Settings = vUIGlobal:get()

local MemoryDT = vUI:NewPlugin(AddOn)

local format = format
local tinsert = tinsert
local tremove = tremove
local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local IsAddOnLoaded = IsAddOnLoaded
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local Label = Language["Memory"]

local Sorted = {}
local TablePool = {}

local GetTable = function()
	local Table
	
	if TablePool[1] then
		Table = tremove(TablePool, 1)
	else
		Table = {}
	end
	
	return Table
end

local Sort = function(a, b)
	return a[2] > b[2]
end

local OnEnter = function(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	local Name
	local Table
	local Memory = 0
	
	GameTooltip:AddLine(Label)
	GameTooltip:AddLine(" ")
	
	-- Get addon information and put it into the sorting table
	for i = 1, GetNumAddOns() do
		if IsAddOnLoaded(i) then
			Name = select(2, GetAddOnInfo(i))
			Memory = GetAddOnMemoryUsage(i)
			Table = GetTable()
			
			Table[1] = Name
			Table[2] = Memory
			
			tinsert(Sorted, Table)
		end
	end
	
	-- Sort information
	table.sort(Sorted, Sort)
	
	-- Show up to 30 entries
	for i = 1, (#Sorted > 30 and 30 or #Sorted) do
		if (Sorted[i][2] > 999) then
			Memory = ((Sorted[i][2] / 1024) * 10) / 10
			
			GameTooltip:AddDoubleLine(Sorted[i][1], format("%.2f mb", Memory), 1, 1, 1)
		else
			Memory = (Sorted[i][2] * 10) / 10
			
			GameTooltip:AddDoubleLine(Sorted[i][1], format("%.0f kb", Memory), 1, 1, 1)
		end
	end
	
	-- If we exceeded the limit, tell the user how many were omitted
	if (#Sorted > 30) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(Language["%s more addons are not shown"], #Sorted - 30))
	end
	
	-- Clear the sorting table for next use
	for i = 1, #Sorted do
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
		
		local Memory = 0
		
		for i = 1, GetNumAddOns() do
			Memory = Memory + GetAddOnMemoryUsage(i)
		end
		
		if (Memory > 999) then
			Memory = ((Memory / 1024) * 10) / 10
			
			self.Text:SetFormattedText("|cff%s%.2f|r |cff%smb|r", Settings["data-text-label-color"], Memory, Settings["data-text-value-color"])
		else
			Memory = (Memory * 10) / 10
			
			self.Text:SetFormattedText("|cff%s%.2f|r |cff%skb|r", Settings["data-text-label-color"], Memory, Settings["data-text-value-color"])
		end
		
		self.Elapsed = 0
	end
end

local OnEnable = function(self)
	self:SetScript("OnUpdate", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	
	self.Elapsed = 0
	
	self:Update(61)
end

local OnDisable = function(self)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	
	self.Elapsed = 0
	
	self.Text:SetText("")
end

vUI:AddDataText(Label, OnEnable, OnDisable, Update)