local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
_uc.shadowedufhelper = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

addon.MAX_DAMAGE_TAKEN_COUNT = 5;
addon.raidFramesInfoAlreadyHidden = false;
addon.currentRosterInfo = nil;
addon.ProcessUnitAura = nil;
addon.OriginalUnitAura = UnitAura

function addon:OnInitialize()
end

function addon:OnEnable()
    self:Print("Enabled!")
	
	self:setupRaidFramesInfo()
	
	self:setupResurrectionDetection()
	
	self:setupAuraCooldownFilter()
	
	self:setupLatencyCastBar()
	
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:GROUP_ROSTER_UPDATE()
end

function addon:OnDisable()
end

function addon:setupRaidFramesInfo()
	self:ScheduleRepeatingTimer("RaidFramesInfoTimerFeedback", 0.5)
end

function addon:setupResurrectionDetection()
	ShadowUF.Tags.defaultTags["resurrection"] = [[
	function(unit, unitOwner, fontString)
		local hasRes, endTime, casterUnit, casterGUID = _uc.lib.LibResInfo:UnitHasIncomingRes(unit)

		local resultText = nil
		
		if hasRes then
			if casterUnit then
				resultText = 'R:' .. _uc:fullUnitName(casterUnit)
			else
				if hasRes ~= 'CASTING' then
					resultText = 'R'
				end
			end
		end
		
		return resultText
	end
	]]
	
	ShadowUF.Tags.defaultCategories["resurrection"] = "raid"
	ShadowUF.Tags.defaultEvents["resurrection"] = "RESURRECTION_INFO"
	ShadowUF.Tags.defaultNames["resurrection"] = "Resurrection Info"
	ShadowUF.Tags.defaultHelp["resurrection"] = "Returns the player resurrection info."
	ShadowUF.Tags.customEvents["RESURRECTION_INFO"] = {
		EnableTag = function(frame, fontString)
			_uc.lib.LibResInfo.RegisterAllCallbacks(addon, function(callback, targetUnit, targetGUID, casterUnit, casterGUID, endTime)
				self:updateResUnit(targetUnit)
			end)
			self.resTagsEnabled = true
		end,
		DisableTag = function(frame, fontString)
			_uc.lib.LibResInfo.UnregisterAllCallbacks(addon)
			self.resTagsEnabled = nil
		end
	}
end

function addon:setupLatencyCastBar()
	local hideLatency = function(frame)
		if frame and frame.castBar and frame.castBar.bar and frame.castBar.bar.latency then
			frame.castBar.bar.latency:Hide()
		end
	end

	self:RawHook(ShadowUF.modules.castBar, 'OnEnable', function(self, frame, ...)
		addon.hooks[ShadowUF.modules.castBar]['OnEnable'](self, frame, ...)
	
		if not frame or not frame.castBar or frame.unit ~= 'player' then
			return
		end

		frame.castBar.bar.latency = frame.castBar.bar:CreateTexture(nil, "ARTWORK")
		
		frame.castBar.bar:RegisterEvent('UNIT_SPELLCAST_SENT')
		frame.castBar.bar:SetScript('OnEvent', function(frm, event, unit, spell, ...)
			if event == 'UNIT_SPELLCAST_SENT' then
				frm.latency.spellcastSentTime = GetTime()
			end
		end)
		
		if not addon:IsHooked(frame.castBar.bar.name, 'SetAlpha') then
			addon:SecureHook(frame.castBar.bar.name, 'SetAlpha', function(self, alpha, ...)
				frame.castBar.bar.latency:SetAlpha(0.7)
			end)
			
			addon:SecureHook(frame.castBar.bar.name, 'Hide', function(self, ...)
				hideLatency(frame)
			end)
		end
	end)
	
	self:RawHook(ShadowUF.modules.castBar, 'OnDisable', function(self, frame, unit, ...)
		
		-- TODO: Workaround. check later if the Hide method already exists and delete this block.
		if frame.castBar.monitor and not frame.castBar.monitor.Hide then 
			frame.castBar.monitor.Hide = function(self, ...)
			end
		end
		
		addon.hooks[ShadowUF.modules.castBar]['OnDisable'](self, frame, unit, ...)
		
		hideLatency(frame)
	end)
	
	

	self:RawHook(ShadowUF.modules.castBar, 'OnLayoutApplied', function(self, frame, config, ...)
		addon.hooks[ShadowUF.modules.castBar]['OnLayoutApplied'](self, frame, config, ...)
	
		if frame and frame.castBar and frame.castBar.bar and frame.castBar.bar.latency then
			frame.castBar.bar.latency:SetParent(frame.highFrame)
			frame.castBar.bar.latency:ClearAllPoints()
			frame.castBar.bar.latency:SetWidth(frame.castBar:GetHeight())
			frame.castBar.bar.latency:SetHeight(frame.castBar:GetHeight())

			frame.castBar.bar.latency:SetTexture(ShadowUF.db.profile.castColors.interrupted.r, ShadowUF.db.profile.castColors.interrupted.g, ShadowUF.db.profile.castColors.interrupted.b, 0.7)

			frame.castBar.bar.latency:SetPoint("TOPRIGHT", frame.castBar.bar, "TOPRIGHT", 0, 0)

			frame.castBar.bar.latency:Hide()
		end
	end)
	
	self:RawHook(ShadowUF.modules.castBar, 'UpdateCast', function(self, frame, unit, channelled, spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, notInterruptible, ...)
		addon.hooks[ShadowUF.modules.castBar]['UpdateCast'](self, frame, unit, channelled, spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, notInterruptible, ...)

		local cast = frame.castBar.bar
		
		if cast.latency then
			cast.latency:ClearAllPoints()
			if( channelled ) then
				cast.latency:SetPoint("TOPLEFT", cast, "TOPLEFT", 0, 0)
			else
				cast.latency:SetPoint("TOPRIGHT", cast, "TOPRIGHT", -1, 0)
			end
			cast.latency:SetAlpha(0.7)

			local w = cast:GetWidth()
			local duration = cast.endSeconds
			
			if duration then
				if cast.latency.spellcastSentTime then
					local lag = (GetTime() - cast.latency.spellcastSentTime) * 1000
					local lw = min(((lag / 1000) * w) / duration,w)

					cast.latency:SetWidth(lw)
					cast.latency:Show()

					cast.latency.spellcastSentTime = nil
				end

			--[[
				local _, _, lag = GetNetStats()
				local lw = min(((lag / 1000) * w) / duration,w)

				cast.latency:SetWidth(lw)
				cast.latency:Show()
			]]--
			else
				cast.latency:Hide()
			end
		end
	end)
	
	self:RawHook(ShadowUF.modules.castBar, 'UpdateCurrentCast', function(self, frame, ...)
		addon.hooks[ShadowUF.modules.castBar]['UpdateCurrentCast'](self, frame, ...)

		hideLatency(frame)
	end)
end

function addon:setupAuraCooldownFilter()
	
	self:SecureHook('UnitAura', function(unit, index, filter)
		if not addon.ProcessUnitAuraFrame then
			return
		end
		
		local name, rank, texture, count, auraType, duration, endTime, caster, isRemovable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = addon.OriginalUnitAura(unit, index, filter)
		local cooldownsOnlymine = ShadowUF.db.profile.filters.blacklists.UNKNOWNCORE_ONLYMINE
		local cooldownsBlacklistSpellId = ShadowUF.db.profile.filters.blacklists.UNKNOWNCORE_BLACKLIST_SPELLID

		addon.ProcessUnitAuraFrame.auras.blacklist = {}
		if (cooldownsOnlymine and caster ~= 'player' and (cooldownsOnlymine[name] or cooldownsOnlymine[tostring(spellID)])) or (cooldownsBlacklistSpellId and cooldownsBlacklistSpellId[tostring(spellID)]) then
			addon.ProcessUnitAuraFrame.auras.blacklist.buffs = true
			addon.ProcessUnitAuraFrame.auras.blacklist.debuffs = true
			addon.ProcessUnitAuraFrame.auras.blacklist[name] = true 
		end
	end)

	self:RawHook(ShadowUF.modules.auras, 'Update', function(self, frame, ...)
		
		local cooldownsBlacklist = ShadowUF.db.profile.filters.blacklists.UNKNOWNCORE_COOLDOWNS
		local cooldownsAlert = ShadowUF.db.profile.filters.blacklists.UNKNOWNCORE_ALERT
		
		if _uc:tableLength(frame.auras.blacklist) == 0 then
			addon.ProcessUnitAuraFrame = frame
		end
		
		addon.hooks[ShadowUF.modules.auras]['Update'](self, frame, ...)

		if addon.ProcessUnitAuraFrame then
			addon.ProcessUnitAuraFrame = nil
			frame.auras.blacklist = {}
		end

		local processButton = function(button)

			if button:IsVisible() and button.unit and button.auraID then
				local name, rank, texture, count, auraType, duration, endTime, caster, isRemovable, shouldConsolidate, spellID = UnitAura(button.unit, button.auraID, button.filter)

				if cooldownsBlacklist and button.cooldown:IsVisible() then
					if caster ~= 'player' and (cooldownsBlacklist[name] or cooldownsBlacklist[tostring(spellID)]) then
						button.cooldown:Hide()
					end
				end
				
				if cooldownsAlert and button:IsVisible() then
					if (cooldownsAlert[name] or cooldownsAlert[tostring(spellID)]) then
						l = button
						
						local currentSize = button.border:GetSize()
						button.border:SetSize(currentSize + 10, currentSize + 10)
						
						button.cooldownAlertGreenColor = button.cooldownAlertGreenColor or false
						if button.cooldownAlertGreenColor == true then
							button.border:SetVertexColor(0, 1, 0, 1)
						else
							button.border:SetVertexColor(1, 0, 1, 1)
						end
						button.cooldownAlertGreenColor = not button.cooldownAlertGreenColor
					end
				end

				if not button.skinned then
					local libMasque = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
					if not libMasque then
						return
					end
					
					local group = libMasque:Group("ShadowedUF")
					if not group then
						return
					end
					
					button.border.oldSetVertexColor = button.border.SetVertexColor
					button.border.SetVertexColor = function(border, r, g, b, a)
						a = 1
						if r == .6 and g == .6 and b == .6 then
							a = 0
						end
						border:oldSetVertexColor(r, g, b, a)
					end
					
					
					local r, g, b = button.border:GetVertexColor()
					button.border:SetVertexColor(floor(r * 100 + 0.5) / 100, floor(g * 100 + 0.5) / 100, floor(b * 100 + 0.5) / 100)
					
					group:AddButton(button, {
						Icon = button.icon,
						Cooldown = button.cooldown,
						Border = button.border,
						Count = button.stack,
					})
					
					button:SetFrameLevel(frame.highFrame:GetFrameLevel() + 1)
					
					button.skinned = true
				end
			end
		end
	
		for k, v in pairs(frame.auras.buffs.buttons) do
			processButton(v)
		end 
	
		for k, v in pairs(frame.auras.debuffs.buttons) do
			processButton(v)
		end
	end)
end

function addon:updateResUnit(unit)
	if not unit or (not string.find(unit, 'raid') or string.find(unit, 'pet')) then
		return
	end
	
	local frame = ShadowUF.Units.unitFrames[unit]
	
	if not frame or not frame:IsVisible() then
		return
	end
	
	for k, v in pairs(frame.fontStrings) do
		v:UpdateTags()
	end
end

function addon:GROUP_ROSTER_UPDATE()
	self.currentRosterInfo = {
		groups = {},
		mostNearPerGroup = {},
		unitFrames = {}
	}
	
	for k, v in pairs(ShadowUF.Units.unitFrames) do
		if v.unitType == 'raid' then
			local name = _uc:fullUnitName(k)
			if name then
				self.currentRosterInfo.unitFrames[name] = {id = k, name = name, frame = v}
			end
		end
	end		
	
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		
		if self.resTagsEnabled then
			self:updateResUnit(name)
		end
		
		if name and self.currentRosterInfo.unitFrames[name] then
			self.currentRosterInfo.groups[subgroup] = self.currentRosterInfo.groups[subgroup] or {}
			self.currentRosterInfo.mostNearPerGroup[subgroup] = 0
			
			local player = {}
			player.name = name
			player.subgroup = subgroup
			player.id = self.currentRosterInfo.unitFrames[name].id
			player.frame = self.currentRosterInfo.unitFrames[name].frame
			player.pn = (5 * (subgroup - 1)) + 1 + _uc:tableLength(self.currentRosterInfo.groups[subgroup])
			player.count = 0
			player.damageTaken = 0
			player.counted = {}
			
			self.currentRosterInfo.groups[subgroup][player.name] = player
		end
	end
end

function addon:RaidFramesInfoTimerFeedback()

	if GetNumGroupMembers() > 1 then
		
		raidFramesInfoAlreadyHidden = false
		
		if not self.currentRosterInfo then
			_uc:log('RaidFramesInfoTimerFeedback: currentRosterInfo not found.')
			return
		end
		
		for k1, v1--[[Group]] in pairs(self.currentRosterInfo.groups) do
			self.currentRosterInfo.mostNearPerGroup[k1] = 0
			for k2, v2--[[Player]] in pairs(v1) do
				v2.damageTaken = 0
				v2.visible = UnitIsVisible(v2.id) and not UnitIsDeadOrGhost(v2.id)
				v2.count = 0
				v2.groupCount = 0
				v2.counted = {}
				v2.groupCounted = {}
				if v2.visible then
					v2.position = _uc:UnitPosition(v2.id)
					v2.hp = _uc:UnitHealth(v2.id, true)
				end
			end
		end

		local spec = _uc:getSpecNumber()

		local raidTargetData = {
			[2560] = {
				group = true,
				distance = 30,
			},
			[2570] = {
				group = function()
					return not _uc:talentSelected(7, 1)
				end,
				count = 5,
				distance = 30,
			},
		}

		if raidTargetData[spec] then
			for k1, v1--[[Group]] in pairs(self.currentRosterInfo.groups) do
				for k2, v2--[[Player]] in pairs(v1) do

					if _uc.db.dbg then
						v2.groupCount = math.random(1, 4)
					else
						if v2.visible then
							if (type(raidTargetData[spec].group) == 'function' and raidTargetData[spec].group() or raidTargetData[spec].group) then
								for k3, v3--[[Player]] in pairs(v1) do
									if v3.visible and k2 ~= k3 and _uc:tableIndexOfValue(v2.groupCounted, k3) == 0 then 
										table.insert(v2.groupCounted, k3)
										table.insert(v3.groupCounted, k2)
										
										local distance = _uc:distanceBetween(v2.position, v3.position)
										
										if distance > 0 and distance < raidTargetData[spec].distance then
											v2.groupCount = v2.groupCount + 1
											v3.groupCount = v3.groupCount + 1
										end
									end
								end
								if v2.groupCount > self.currentRosterInfo.mostNearPerGroup[k1] then
									self.currentRosterInfo.mostNearPerGroup[k1] = v2.groupCount
								end
							else
								for k3, v3--[[Group]] in pairs(self.currentRosterInfo.groups) do
									for k4, v4--[[Player]] in pairs(v3) do
										if v4.visible and k2 ~= k4 and _uc:tableIndexOfValue(v2.counted, k4) == 0 then
											table.insert(v2.counted, k4)
											table.insert(v4.counted, k2)

											local distance = _uc:distanceBetween(v2.position, v4.position)
										
											if distance > 0 and distance < raidTargetData[spec].distance then
												v2.count = v2.count + 1
												v4.count = v4.count + 1
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if Skada then
			for k1, v1--[[Window]] in pairs(Skada:GetWindows()) do
				if v1.selectedset == 'current' and v1.db.mode == 'Damage taken' then
			        
			        local damageTakenCount = 1
			        
					for k2, v2--[[SkadaItem]] in pairs(v1.dataset) do
						if damageTakenCount > self.MAX_DAMAGE_TAKEN_COUNT then
							break
						end
						for k3, v3--[[Group]] in pairs(self.currentRosterInfo.groups) do
							if damageTakenCount > self.MAX_DAMAGE_TAKEN_COUNT then
								break
							end
							for k4, v4--[[Player]] in pairs(v3) do
								if damageTakenCount > self.MAX_DAMAGE_TAKEN_COUNT then
									break
								end
								if v2.label == _uc:playerNameOnly(v4.name) then
									if v4.visible then
										v4.damageTaken = damageTakenCount
										damageTakenCount = damageTakenCount + 1
									else
										_uc:log('SkadaDamageTaken: Not Visible: ', v4.name)
									end
									break
								end
							end
						end
					end	

			        break
			    end
			end
		end

		for k1, v1 in pairs(self.currentRosterInfo.groups) do
			for k2, v2 in pairs(v1) do
				v2.frame = ShadowUF.Units.unitFrames[v2.id]

				if v2.frame and v2.frame.highlight then
					if not v2.frame.infoWrapper then
						v2.frame.infoWrapper = CreateFrame("Frame", nil, v2.frame)
						v2.frame.infoWrapper:SetFrameLevel(v2.frame.topFrameLevel)
						v2.frame.infoWrapper:SetAllPoints(v2.frame)
						v2.frame.infoWrapper:SetSize(1, 1)
						v2.frame.infoWrapper:Show()
						
						v2.frame.infoWrapper.proxBar = v2.frame.infoWrapper:CreateTexture(nil, "OVERLAY")
						v2.frame.infoWrapper.proxBar:SetBlendMode('ADD')
						v2.frame.infoWrapper.proxBar:SetTexture(_uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.STATUSBAR, _uc.DEFAULT_TEXTURE_NAME))
						v2.frame.infoWrapper.proxBar:SetHeight(6)
						v2.frame.infoWrapper.proxBar:SetTexCoord(v2.frame.highlight.top:GetTexCoord())
						v2.frame.infoWrapper.proxBar:SetHorizTile(v2.frame.highlight.top:GetHorizTile())
						v2.frame.infoWrapper.proxBar:SetPoint('LEFT', v2.frame.infoWrapper, 0, -4)
						v2.frame.infoWrapper.proxBar.owner = v2.frame
						
						v2.frame.infoWrapper.proxBar.SetValue = function(self, value)
							self:SetWidth(value)
						end
						v2.frame.infoWrapper.proxBar.GetValue = function(self)
							return self:GetWidth()
						end
						v2.frame.infoWrapper.proxBar.GetMinMaxValues = function(self)
							return 0, self.owner:GetWidth()
						end
						_uc.lib.LibSmoothStatusBar:SmoothBar(v2.frame.infoWrapper.proxBar)


						v2.frame.infoWrapper.damageTakenBar = v2.frame.infoWrapper:CreateTexture(nil, "OVERLAY")
						v2.frame.infoWrapper.damageTakenBar:SetBlendMode('ADD')
						v2.frame.infoWrapper.damageTakenBar:SetTexture(_uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.STATUSBAR, _uc.DEFAULT_TEXTURE_NAME))
						v2.frame.infoWrapper.damageTakenBar:SetTexCoord(v2.frame.highlight.top:GetTexCoord())
						v2.frame.infoWrapper.damageTakenBar:SetHorizTile(v2.frame.highlight.top:GetHorizTile())
						v2.frame.infoWrapper.damageTakenBar:SetPoint('TOPLEFT', v2.frame.infoWrapper, 0, 0)
						v2.frame.infoWrapper.damageTakenBar:SetPoint('BOTTOMLEFT', v2.frame.infoWrapper, 0, 0)
						v2.frame.infoWrapper.damageTakenBar.owner = v2.frame
						v2.frame.infoWrapper.damageTakenBar:SetWidth(5)
						v2.frame.infoWrapper.damageTakenBar:SetVertexColor(1, 0, 1, 1)
					end

					if v2.groupCount > 0 and (_uc.db.dbg or v2.groupCount == self.currentRosterInfo.mostNearPerGroup[k1]) then
						v2.frame.infoWrapper.proxBar:SetValue((v2.frame:GetWidth() / 5) * (v2.groupCount + 1))
						
						local multiplier = 0.2 * (v2.groupCount + 1)
						v2.frame.infoWrapper.proxBar:SetVertexColor(0.4, 0.4, 0.4, multiplier)

						v2.frame.infoWrapper.proxBar:Show()
					else
						if v2.frame.infoWrapper then
							v2.frame.infoWrapper.proxBar:Hide()
						end
					end

					if v2.damageTaken > 0 then
						v2.frame.infoWrapper.damageTakenBar:Show()
					else
						v2.frame.infoWrapper.damageTakenBar:Hide()
					end
				end	
			end
		end

		return
	end

	if raidFramesInfoAlreadyHidden then
		return
	else
		
		for i = 1, 40 do
			local frame = ShadowUF.Units.unitFrames['raid' .. i]
			if frame and frame.infoWrapper then
				frame.infoWrapper.proxBar:Hide()
				frame.infoWrapper.damageTakenBar:Hide()
			end
		end
		
		raidFramesInfoAlreadyHidden = true
	end
end
