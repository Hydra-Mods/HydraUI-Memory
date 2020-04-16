local AddOn = ...
local vUI, GUI, Language, Media, Settings = vUIGlobal:get()

local MemoryDT = vUI:NewPlugin(AddOn)
local DT = vUI:GetModule("DataText")

local format = format
local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local IsAddOnLoaded = IsAddOnLoaded
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local Label = Language["Memory"]

local OnEnter = function(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	
	local Name
	local Memory = 0
	
	GameTooltip:AddLine(Label)
	GameTooltip:AddLine(" ")
	
	for i = 1, GetNumAddOns() do
		if IsAddOnLoaded(i) then
			Name = select(2, GetAddOnInfo(i))
			Memory =  GetAddOnMemoryUsage(i)
			
			if (Memory > 999) then
				Memory = ((Memory / 1024) * 10) / 10
				
				GameTooltip:AddDoubleLine(Name, format("%.2f mb", Memory), 1, 1, 1)
			else
				Memory = (Memory * 10) / 10
				
				GameTooltip:AddDoubleLine(Name, format("%.0f kb", Memory), 1, 1, 1)
			end
		end
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

DT:SetType(Label, OnEnable, OnDisable, Update)