local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
_uc.priesthelper = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

local barTypes = {
    RAPTURE = 1,
    GRACE = 2
}

local spellIds = {
    FLASH_HEAL = 2061,
    GREATER_HEAL = 2060,
    HEAL = 2050,
    PENANCE = 47750,
    GRACE = 77613,
    RAPTURE = 47755
}

addon.bars = {
    rapture = nil,
    grace =
    {

    }
};

function addon:OnInitialize()
    local localizedClass, englishClass, classIndex = UnitClass("player")

    if englishClass ~= 'PRIEST' then
        return
    end
end

function addon:OnEnable()
    self:Print("Enabled!")

    self:setupBars()

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function addon:OnDisable()
end

function addon:destroyBar(bar)
    bar:Stop(true)

    self:Unhook(bar, 'Stop')

    if bar.barType == barTypes.RAPTURE then
        self.bars.rapture = nil
    else
        self.bars.grace[bar.playerName] = nil
    end
end

function addon:startBar(bar)
    if bar.barType == barTypes.RAPTURE then
        bar:SetDuration(12)
    elseif bar.barType == barTypes.GRACE then
        bar:SetDuration(15)
    end

    local r, g, b, a = bar.candyBarBar:GetStatusBarColor()
    bar.candyBarBar:SetStatusBarColor(r, g, b, 1)

    bar:Start()
end

function addon:createBar(barType, playerName)
    local bar = _uc.lib.LibCandyBar:New(_uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.STATUSBAR, _uc.DEFAULT_TEXTURE_NAME), 300, 20)

    bar.barType = barType
    bar.playerName = playerName

    if bar.barType == barTypes.RAPTURE then
        bar:SetLabel('Rapture')
        bar:SetIcon(select(3, GetSpellInfo(spellIds.RAPTURE)))
    elseif playerName ~= nil and bar.barType == barTypes.GRACE then
        bar:SetLabel('Grace - ' .. playerName)
        bar:SetIcon(select(3, GetSpellInfo(spellIds.GRACE)))
    end

    bar.candyBarLabel:SetFont(_uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME), 11)
    bar.candyBarDuration:SetFont(_uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME), 11)

    bar:SetWidth(250)
    bar:SetHeight(20)
    bar:SetScale(1)
    bar:SetFill(false)
    bar.candyBarLabel:SetJustifyH('LEFT')
    bar.candyBarBar:SetStatusBarColor(1, 0, 0, 0)
    bar.candyBarBackground:SetVertexColor(0, 0, 0, 0.2)

    self:RawHook(bar, 'Stop', 'onBarStop', true)

    bar.running = true
    bar:SetTimeVisibility(bar.showTime)
    bar.candyBarDuration:SetFormattedText('Ready')
    bar.running = false

    bar:Show()

    return bar
end

function addon:realignBars()

    local function realignBar(bar, barNum)
        bar:SetPoint("CENTER", UIParent, "CENTER", 0,(-210 -(barNum * 20)) +(barNum * 1))
    end

    local barNum = 0

    if self.bars.rapture ~= nil then
        realignBar(self.bars.rapture, barNum)
        barNum = barNum + 1
    end

    for k, v in pairs(self.bars.grace) do
        realignBar(v, barNum)
        barNum = barNum + 1
    end
end

function addon:setupBars()

    if not _uc.db.dbg then
        if GetNumGroupMembers() <= 1 then
            if self.bars.rapture ~= nil then
                self:destroyBar(self.bars.rapture)
            end

            for k, v in pairs(self.bars.grace) do
                self:destroyBar(v)
            end
            return
        end
    end

    if GetSpellInfo(GetSpellInfo(spellIds.RAPTURE)) then
        self.bars.rapture = self.bars.rapture or self:createBar(barTypes.RAPTURE)
    else
        if self.bars.rapture ~= nil then
            self:destroyBar(self.bars.rapture)
        end
    end

    if GetSpellInfo(GetSpellInfo(spellIds.GRACE)) then

        local raidMemberNames = { }

        if _uc.db.dbg then
            table.insert(raidMemberNames,(UnitName("player")))

            if not self.bars.grace[UnitName("player")] then
                self.bars.grace[UnitName("player")] = self:createBar(barTypes.GRACE, UnitName("player"))
            end
        end

        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)

            if not name then
                _uc:print(GetRaidRosterInfo(i))
            end

            if UnitGroupRolesAssigned('raid' .. i) == 'TANK' or(i <= 5 and UnitGroupRolesAssigned('party' .. i) == 'TANK') then

                table.insert(raidMemberNames, name)

                if self.bars and not self.bars.grace[name] then
                    self.bars.grace[name] = self:createBar(barTypes.GRACE, name)
                end
            end


        end

        for k, v in pairs(self.bars.grace) do
            if _uc:tableIndexOfValue(raidMemberNames, k) == 0 then
                self:destroyBar(v)
            end
        end
    else
        for k, v in pairs(self.bars.grace) do
            self:destroyBar(v)
        end
    end

    self:realignBars()
end

function addon:onBarStop(bar, force)
    if force then
        self.hooks[bar]['Stop'](bar)
    else
        bar:SetScript('OnUpdate', nil)
        bar.candyBarDuration:SetFormattedText('Ready')

        local r, g, b, a = bar.candyBarBar:GetStatusBarColor()
        bar.candyBarBar:SetStatusBarColor(r, g, b, 0)

        if bar.barType == barTypes.GRACE then
            bar:SetLabel('Grace - ' .. bar.playerName)
        end
    end
end

function addon:chatCommand(input)
    if not input or input:trim() == "" then
        -- open config
    else
        _uc.lib.AceConfigCmd.HandleCommand(PB, "pb", "PriestBooster", input)
    end
end

--

function addon:PLAYER_ENTERING_WORLD()
    _uc:print('PLAYER_ENTERING_WORLD')
    self:setupBars()
end

function addon:GROUP_ROSTER_UPDATE()
    _uc:print('GROUP_ROSTER_UPDATE')
    self:setupBars()
end

function addon:ACTIVE_TALENT_GROUP_CHANGED()
    _uc:print('ACTIVE_TALENT_GROUP_CHANGED')
    self:setupBars()
end

function addon:SPELL_ENERGIZE(timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, powerType)
    if destName == UnitName("player") and sourceName == UnitName("player") and spellId == spellIds.RAPTURE then
        self:startBar(self.bars.rapture)
    end
end

--[[function addon:SPELL_AURA_APPLIED(timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType)
	if sourceName == UnitName("player") and spellId == spellIds.GRACE and self.bars.grace[destName] then
		self:startBar(self.bars.grace[destName])
	end
end

function addon:SPELL_AURA_APPLIED_DOSE(timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceName == UnitName("player") and spellId == spellIds.GRACE and self.bars.grace[destName] then
		_uc:print('DOSE: ' .. amount)
		self:startBar(self.bars.grace[destName])
	end
end
]]--
function addon:SPELL_HEAL(timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overhealing, absorbed, critical)
    if sourceName == UnitName("player") and self.bars.grace[destName] and _uc:tableIndexOfValue( { spellIds.FLASH_HEAL, spellIds.GREATER_HEAL, spellIds.HEAL, spellIds.PENANCE }, spellId) > 0 then
        name, rank, icon, count, dispelType, duration, expires, caster = UnitAura(UnitName(destName), GetSpellInfo(spellIds.GRACE), '', 'PLAYER')
        if caster == 'player' then
            count = count + 1
            if count > 3 then
                count = 3
            end
        else
            count = 1
        end
        self:startBar(self.bars.grace[destName])
        self.bars.grace[destName]:SetLabel('Grace - ' .. destName .. ' (' .. count .. ')')
    end
end

function addon:COMBAT_LOG_EVENT_UNFILTERED(_, timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    local func = self[event]

    local spellId, spellName, spellSchool = ...


    if sourceName ~= UnitName("player") and destName ~= UnitName("player") then
        return
    end

    _uc:print(timeStamp, event, sourceName, destName, spellId, spellName)

    if (func) then
        func(self, timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    end
end