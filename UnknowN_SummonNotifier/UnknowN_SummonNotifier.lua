local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
_uc.summonnotifier = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

addon.mouseDownText = ''
addon.mouseDownTime = nil
addon.lastSayTime = nil
addon.lastSayText = nil

function addon:OnInitialize()
end

function addon:OnEnable()
    self:Print("Enabled!")
	
	self:RegisterEvent("CURSOR_UPDATE", function(event, ...)
		if InCombatLockdown() then
			return
		end
		
		addon.mouseDownText = ''
		if GameTooltipTextLeft1:GetText() then
			GameTooltipTextLeft1:SetText(GameTooltipTextLeft1:GetText() .. ' ')
		end
	end)
	
	WorldFrame:SetScript('OnMouseDown', function(self, button)
		if InCombatLockdown() then
			return
		end
		
		addon.mouseDownText = GameTooltipTextLeft1:GetText()
		addon.mouseDownTime = GetTime()
	end)
	
	WorldFrame:SetScript('OnMouseUp', function(self, button)
		if InCombatLockdown() then
			return
		end
		
		if GetNumGroupMembers() == 0 then
			return
		end
	
		if true then
			return
		end

		if addon.mouseDownTime and GetTime() - addon.mouseDownTime < 0.8 then
			if addon.mouseDownText == 'Summoning Portal' or addon.mouseDownText == 'Meeting Stone' then
				
				if UnitInRaid('target') or UnitInParty('target') then
					
					local castingStone = nil
					for i = 1, GetNumGroupMembers() do
						local name, rank, subgroup, level, class = GetRaidRosterInfo(i)
						if class == 'Warlock' and UnitChannelInfo(name) == 'Ritual of Summoning' then
							castingStone = true
							break
						end   
					end
						
					if not castingStone then
						addon:Say('Summoning ' .. _uc:fullUnitName('target') .. '.')
					else
						addon:Say('Portal clicked.')
					end
				else
					addon:Say('Stone clicked.')
				end
			elseif addon.mouseDownText == 'Meeting Stone Summoning Portal' then
				addon:Say('Portal clicked.')
			end
		end
		
		addon.mouseDownText = ''
	end)
end

function addon:OnDisable()
end

function addon:Say(text)
	if self.lastSayTime and GetTime() - self.lastSayTime < 2 and text == self.lastSayText then
		return
	end
	
	self.lastSayTime = GetTime()
	self.lastSayText = text
	
	if _uc.db.dbg then
		print(text)
	else
		SendChatMessage(text)
	end
end