local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0", "AceHook-3.0")
_uc.unknownui = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

addon.profileChanged = false;
addon.autoMoversTimer = nil;
addon.framesConfig = nil;
addon.zoneReminderSettings = nil;
addon.actionBarSettings = nil;
addon.zoneReminderNote = '';
addon.lastCheckedZone = nil;
addon.zoneReminderDataBroker = nil;
addon.customBossModsSettings = nil;
addon.customBossModsBarCount = nil;
addon.creatingBigWigsBar = nil;

--[[
"HeadSlot"
"NeckSlot"
"ShoulderSlot"
"BackSlot"
"ChestSlot"
"ShirtSlot"
"TabardSlot"
"WristSlot"
"HandsSlot"
"WaistSlot"
"LegsSlot"
"FeetSlot"
"Finger0Slot"
"Finger1Slot"
"Trinket0Slot"
"Trinket1Slot"
"MainHandSlot"
"SecondaryHandSlot"

3 - dot
4 - self dispel
q - T.AUNT, group spam
e - big heal
c - moving
r - aoe
cr - aoe
ce - hot
cse - pet
se - heal
' - execute
sq - escape
ca - self heal
csd - intrrupt/silnce
sd - interrupt/stun
z - slow/cc/interrupt/stun
b - self cd
sc - raid cd
av - second self cd
ar - aoe
ac - second escape
csg - help ally
t - large cd
ae - apply target
cg - second large long cd
cst - another CD
g = 30s+ cd
csa - root
css - external
af - speed
5 - target dispel
s1 - buff
s2 - buff
s3 - buff
s4 - buff
cs1 - stance
cs2 - stance
cs3 - stance
cs4 - stance

1
2
c1
c4
c3
c2
cq
csp
ct - spam
cv
cb
cs
sv
asp
sb
sg

]]

addon.specInfo = {
    -- MAGE MA
    [62] = { 'INT' }--[[ Arcane ]],
    [63] = { 'INT' }--[[ Fire ]],
    [64] = { 'INT' }--[[ Frost ]],
    -- PALADIN PA
    [65] = { 'INT', 'SPI', 'MELEE' }--[[ Holy ]],
    [66] = { 'STR', 'STA' }--[[ Protection ]],
    [70] = { 'STR' }--[[ Retribution ]],
    -- WARRIOR WA
    [71] = { 'STR' }--[[ Arms ]],
    [72] = { 'STR' }--[[ Fury ]],
    [73] = { 'STR', 'STA' }--[[ Protection ]],
    -- DRUID DR
    [102] = { 'INT' }--[[Balance],]
	[103] = {'AGI'} --[[Feral]],
    [104] = { 'AGI', 'STA' }--[[ Guardian ]],
    [105] = { 'INT', 'SPI' }--[[ Restoration ]],
    -- DEATHKNIGHT DK
    [250] = { 'STR', 'STA' }--[[ Blood ]],
    [251] = { 'STR' }--[[ Frost ]],
    [252] = { 'STR' }--[[ Unholy ]],
    -- HUNTER HU
    [253] = { 'AGI' }--[[ Beast Mastery ]],
    [254] = { 'AGI' }--[[ Marksmanship ]],
    [255] = { 'AGI' }--[[ Survival ]],
    -- PRIEST PR
    [256] = { 'INT', 'SPI' }--[[ Discipline ]],
    [257] = { 'INT', 'SPI' }--[[ Holy ]],
    [258] = { 'INT' }--[[ Shadow ]],
    -- ROGUE RO
    [259] = { 'AGI' }--[[ Assassination ]],
    [260] = { 'AGI' }--[[ Combat ]],
    [261] = { 'AGI' }--[[ Subtlety ]],
    -- SHAMAN SH
    [262] = { 'INT' }--[[ Elemental ]],
    [263] = { 'AGI' }--[[ Enhancement ]],
    [264] = { 'INT', 'SPI' }--[[ Restoration ]],
    -- WARLOCK WL
    [265] = { 'INT' }--[[ Affliction ]],
    [266] = { 'INT' }--[[ Demonology ]],
    [267] = { 'INT' }--[[ Destruction ]],
    -- MONK MO
    [268] = { 'AGI', 'STA' }--[[ Brewmaster ]],
    [269] = { 'AGI' }--[[ Windwalker ]],
    [270] = { 'INT', 'SPI', 'MELEE' }--[[ Mistweaver ]],
};

function addon:OnInitialize()
end

function addon:OnEnable()
    self:Print("Enabled!")

    self:setupVolumeControl()

    self:setupRepeatingTimers()

    self:setupCustomBossMods()

    self:setupObjectivesHide()

    self:setupZoneReminder()

    self:setupQuestSchedule()

    self:setupAutoMovers()

    self:setupBars()

    self:setupCustomMenu()

    self:setupAutoSheat()
end

function addon:OnDisable()
end

function addon:setupAutoSheat()
    if StayUnsheathed then
        self:ScheduleRepeatingTimer( function()
            ToggleSheath()
            StayUnsheathed:TimerFeedback()
        end , 30)
    end
end

function addon:setupCustomMenu()
    table.insert(_uc.externalMenuItems, {
        text = addonTitle,
        value = addonName,
        childrens =
        {
            {
                text = 'Apply Action Bar Settings',
                func = function() addon:applyActionBarSettings() end,
            },
            {
                text = 'Clear Action Bars',
                func = function() for i = 1, 120 do PickupAction(i) ClearCursor() end end,
            },
            {
                text = 'Fix Default Profiles',
                func = function()
                    local dbList = { ElvDB, ElvPrivateDB, Bartender4DB, MogItWishlist }

                    for k, v in pairs(dbList) do
                        if v and v.profiles.Default then
                            for k2, v2 in pairs(v.profileKeys) do
                                v.profileKeys[k2] = 'Default';
                            end

                            for k2, v2 in pairs(v.profiles) do
                                if k2 ~= 'Default' then
                                    v.profiles[k2] = nil;
                                end
                            end
                        end
                    end

                    if TinyXStats then
                        TinyXStats.db.char.FrameHide = true
                        TinyXStats.db.char.Style.labels = true
                        TinyXStats.db.char.Style.showRecords = false
                        TinyXStats.db.char.RecordMsg = false
                    end

                    if HealerManaWatchSaved then
                        HealerManaWatchSaved["Layout"] = "v"
                        HealerManaWatchSaved["points"] = {
                            "TOPLEFT",-- [1]
                            nil,-- [2]
                            "TOPLEFT",-- [3]
                            1737.36779785156,-- [4]
                            - 189.56364440918,-- [5]
                        }
                    end
                end,
            },
            {
                text = 'Reposition Skada Windows',
                func = function()
                    local save = function(group)
                        group.win.db.background.height = _uc:round(group:GetHeight())
                        group.win.db.barwidth = _uc:round(group:GetWidth())
                        LibStub("LibWindow-1.1").SavePosition(group)
                    end

                    local group = _G['SkadaBarWindowSkadaHealing']
                    if group then
                        group:SetPoint('BOTTOMLEFT', 0, 243)
                        group:SetWidth(225)
                        group:SetHeight(117)
                        save(group)
                    end

                    local group = _G['SkadaBarWindowSkadaDamage']
                    if group then
                        group:SetPoint('BOTTOMLEFT', SkadaBarWindowSkadaHealing, 'TOPLEFT', 0, 18)
                        group:SetWidth(225)
                        group:SetHeight(130)
                        save(group)
                    end

                    local group = _G['SkadaBarWindowSkadaDamageTaken']
                    if group then
                        group:SetPoint('BOTTOMLEFT', SkadaBarWindowSkadaDamage, 'TOPLEFT', 0, 18)
                        group:SetWidth(225)
                        group:SetHeight(84)
                        save(group)
                    end

                    local group = _G['SkadaBarWindowSkadaDispels']
                    if group then
                        group:SetPoint('BOTTOMLEFT', SkadaBarWindowSkadaDamageTaken, 'TOPLEFT', 0, 18)
                        group:SetWidth(225)
                        group:SetHeight(69)
                        save(group)
                    end

                    local group = _G['SkadaBarWindowSkadaThreat']
                    if group then
                        group:SetPoint('BOTTOMLEFT', SkadaBarWindowSkadaDispels, 'TOPLEFT', 0, 18)
                        group:SetWidth(225)
                        group:SetHeight(69)
                        save(group)
                    end
                end,
            },
        },
    } )
end

function addon:setupVolumeControl()
    self:ScheduleTimer( function()
        if not InCombatLockdown() then
            SetCVar('Sound_SFXVolume', 0.05)
        end
    end , 1)
end

function addon:setupRepeatingTimers()
    self:ScheduleRepeatingTimer( function()
        if not InCombatLockdown() and WeakAuras then
            WeakAuras.HandleEvent(WeakAuras.frames['WeakAuras Main Frame'], 'UNKNOWNCORE_WA_EVENT_ZONE_REMINDER')
        end
    end , 10)

    self:ScheduleRepeatingTimer( function()
        if WeakAuras then
            WeakAuras.HandleEvent(WeakAuras.frames['WeakAuras Main Frame'], 'UNKNOWNCORE_WA_EVENT_1')
        end
    end , 0.7)

    self:ScheduleRepeatingTimer( function()
        if WeakAuras then
            WeakAuras.HandleEvent(WeakAuras.frames['WeakAuras Main Frame'], 'UNKNOWNCORE_WA_EVENT_5')
        end

        if CopyChatFrame and not CopyChatFrame.resized then
            CopyChatFrame:SetHeight(400)
            CopyChatFrame.resized = true
        end

        if not InCombatLockdown() then
            SetCVar('nameplateShowEnemies', 1)
            SetCVar('nameplateShowFriends', 0)
        end
    end , 5)
end

function addon:setupCustomBossMods()
    self.customBossModsSettings = {
        default =
        {
            -- ['Bar'] = function(self, key, length, text, icon, alertCountdown)

            -- end,
        },
        ['Gruul the Dragonkiller'] =
        {
            alerts = { 'Ground Slam' },
            hooks =
            {
                ['OnEngage'] = function(self)
                    self.growCount = 0
                end,
                ['Grow'] = function(self, args)
                    if self.growCount then
                        self.growCount = self.growCount + 1
                        if self.growCount == 1 then
                            addon:BigWigsBar(62618, 12, '#### BARRIER ####')
                            addon:BigWigsBar(34433, 20, '<alert>#### CD ####', true)
                            addon:BigWigsBar(62618, 30, '<alert>#### LONG BARRIER ####')
                        end
                    end
                end,
            },
        },
        ['High King Maulgar'] =
        {
            alerts = { },
            hooks =
            {
                ['OnEngage'] = function(self)
                    self.smashCount = 0
                end,
                ['Smash'] = function(self, args)
                    if self.smashCount then
                        self.smashCount = self.smashCount + 1
                        if self.smashCount == 2 then
                            addon:BigWigsBar(62618, 12, '<alert>#### BARRIER ####')
                        end
                    end
                end,
            },
        },
        ['Magtheridon'] =
        {
            alerts = { 'Blast Nova x2' },
            hooks =
            {
                ['UNIT_HEALTH_FREQUENT'] = function(self, unit)
                    if self:MobId(UnitGUID(unit)) == 17257 then
                        local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
                        if hp > 30 and hp < 37 then
                            addon:BigWigsBar(62618, 12, '<alert>#### BARRIER ####')
                        end
                    end
                end,
            },
        },
        ["Garrosh Hellscream"] =
        {
            alerts = { },
            hooks =
            {
                ['OnEngage'] = function(self)
                    self.desecrateCount = 0
                    self.empoweredWhirlingCount = 0
                end,
                ['Desecrate'] = function(self, args)
                    if self.desecrateCount then
                        self.desecrateCount = self.desecrateCount + 1
                        if self.desecrateCount == 1 then
                            addon:BigWigsBar(62618, 40, '<alert>##### BARRIER #####')
                        end
                    end
                end,
                ['UNIT_SPELLCAST_SUCCEEDED'] = function(self, unitId, spellName, _, _, spellId)
                    if spellId == 145647 and self.empoweredWhirlingCount == 0 then
                        self.empoweredWhirlingCount = 1

                        addon:BigWigsBar(62618, 12, '<alert>#### BARRIER ####')
                    end
                end,
            },
        },
    }

    if not BigWigs then
        self:RegisterEvent('ADDON_LOADED', function(event, addonName, ...)
            if string.find(addonName, 'BigWigs') then
                self:hookBossMods()
            end
        end )
    else
        self:hookBossMods()
    end
end

function addon:setupObjectivesHide()
    self:RegisterEvent('PLAYER_REGEN_ENABLED', function(event, ...)
        if WatchFrame and WatchFrame.collapsed then
            WatchFrame_CollapseExpandButton_OnClick()
        end
    end )

    self:RegisterEvent('PLAYER_REGEN_DISABLED', function(event, ...)
        local name, type, difficulty = GetInstanceInfo()

        if WatchFrame and not WatchFrame.collapsed and _uc:tableIndexOfValue( { 3, 4, 5, 6, 7, 9, 14 }, difficulty) > 0 then
            WatchFrame_CollapseExpandButton_OnClick()
        end
    end )
end

function addon:setupZoneReminder()
    addon.zoneReminderDataBroker = _uc.lib.LibDataBroker:NewDataObject('Zone Reminder', {
        type = "data source",
        label = 'Zone Reminder',
        text = "Zone Reminder",
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(self.zoneReminderNote)
        end,
        OnClick = function(frame, button)
        end
    } )

    self.zoneReminderSettings = {
        default =
        {
            default =
            {
                -- #############################################
                [ { 250, 251, 252 }] =
                {
                    glyphs =
                    {
                        [1] = 'Glyph of Path of Frost',
                        [2] = 'Glyph of Blood Boil',
                        [4] = 'Glyph of Raise Ally',
                    },
                    talents =
                    {
                        [1] = 1,
                        [2] = 3,
                        [3] = 1,
                        [4] = 3,
                        [5] = 1,
                        [6] = 1,
                        [7] = 1,
                    },
                },
                [ { 251, 252 }] =
                {
                    glyphs =
                    {
                        [3] = 'Glyph of Army of the Dead',
                        [5] = 'Glyph of Tranquil Grip',
                        [6] = 'Glyph of Anti-Magic Shell',
                    },
                    talents =
                    {
                    },
                },
                [ { 250 }] =
                {
                    glyphs =
                    {
                        [3] = 'Glyph of Foul Menagerie',
                        [5] = 'Glyph of Horn of Winter',
                        [6] = 'Glyph of Vampiric Blood',
                    },
                    talents =
                    {
                    },
                },
                [ { 251 }] =
                {
                    glyphs =
                    {
                    },
                    talents =
                    {
                    },
                },
                [ { 252 }] =
                {
                    glyphs =
                    {
                    },
                    talents =
                    {
                    },
                },
                -- #############################################
                [ { 256, 257, 258 }] =
                {
                    glyphs =
                    {
                        [1] = 'Glyph of the Sha',
                    },
                    talents =
                    {
                        [1] = 3,
                        [2] = 2,
                        [3] = 3,
                        [4] = 1,
                    }
                },
                [ { 256 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Holy Fire',
                        [3] = 'Glyph of Borrowed Time',
                        [4] = 'Glyph of Weakened Soul',
                        [5] = 'Glyph of Angels',
                        [6] = 'Glyph of Penance',
                    },
                    talents =
                    {
                        [5] = 2,
                        [6] = 1,
                        [7] = 1,
                    },
                },
                [ { 257 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Circle of Healing',
                        [3] = 'Glyph of the Val\'kyr',
                        [4] = 'Glyph of Deep Wells',
                        [5] = 'Glyph of Angels',
                        [6] = 'Glyph of Renew',
                    },
                    talents =
                    {
                        [5] = 2,
                        [6] = 1,
                        [7] = 2,
                    },
                },
                [ { 258 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Dispersion',
                        [3] = 'Glyph of Dark Archangel',
                        [4] = 'Glyph of Mind Flay',
                        [5] = 'Glyph of Shadow',
                        [6] = 'Glyph of Inner Fire',
                    },
                    talents =
                    {
                        [5] = 1,
                        [6] = 3,
                        [7] = 1,
                    },
                },
                -- #############################################
                [ { 262, 263, 264 }] =
                {
                    glyphs =
                    {
                        [1] = 'Glyph of Spirit Wolf',
                        [3] = 'Glyph of Ghostly Speed',
                    },
                    talents =
                    {
                        [1] = 3,
                        [2] = 3,
                        [3] = 3,
                        [4] = 1,
                        [5] = 2,
                        [6] = 2,
                        [7] = 1,
                    },
                },
                [ { 262, 264 }] =
                {
                    glyphs =
                    {
                        [6] = 'Glyph of Spiritwalker\'s Grace',
                    },
                    talents =
                    {
                    },
                },
                [ { 262 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Shocks',
                        [4] = 'Glyph of Unstable Earth',
                        [5] = 'Glyph of Thunderstorm',
                    },
                    talents =
                    {
                    },
                },
                [ { 263 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Frost Shock',
                        [4] = 'Glyph of Lava Spread',
                        [5] = 'Glyph of Spirit Raptors',
                        [6] = 'Glyph of Fire Nova',
                    },
                    talents =
                    {
                    },
                },
                [ { 264 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Totemic Recall',
                        [4] = 'Glyph of Purify Spirit',
                        [5] = 'Glyph of Deluge',
                    },
                    talents =
                    {
                    },
                },
                -- #############################################
                [ { 268, 269, 270 }] =
                {
                    glyphs =
                    {
                        [1] = 'Glyph of Jab',
                        [3] = 'Glyph of Spirit Roll',
                        [5] = 'Glyph of Water Roll',
                    },
                    talents =
                    {
                        [1] = 2,
                        [2] = 3,
                        [4] = 3,
                        [5] = 3,
                        [7] = 3,
                    },
                },
                [ { 268 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Keg Smash',
                        [4] = 'Glyph of Breath of Fire',
                        [6] = 'Glyph of Fortifying Brew',
                    },
                    talents =
                    {
                        [3] = 2,
                        [6] = 2,
                    },
                },
                [ { 269 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Zen Meditation',
                        [4] = 'Glyph of Flying Fists',
                        [6] = 'Glyph of Touch of Karma',
                    },
                    talents =
                    {
                        [3] = 3,
                        [6] = 2,
                    },
                },
                [ { 270 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Renewing Mist',
                        [4] = 'Glyph of Surging Mist',
                        [6] = 'Glyph of Soothing Mist',
                    },
                    talents =
                    {
                        [3] = 1,
                        [6] = 1,
                    },
                },
                -- #############################################
            },
        },
        ['Proving Grounds'] =
        {
            default =
            {
                [ { 256 }] =
                {
                    glyphs =
                    {
                        [2] = 'Glyph of Purify',
                        [6] = 'Glyph of Smite',
                    },
                    talents =
                    {
                        [4] = 1,
                    },
                },
            },
        },
        ['Highmaul'] =
        {
            default =
            {
                default =
                {
                    disableAddons =
                    {
                        'AddonUsage',
                        'Stubby',
                        'Broker: Garrison',
                    },
                },
            },
            ['The Coliseum'] =
            {
                -- Kargath
                [ { 256, 257 }] =
                {
                    talents =
                    {
                        [6] = 1,
                    },
                },
            },
            ['Market District'] =
            {
                -- Tectus
                [ { 256, 257 }] =
                {
                    talents =
                    {
                    },
                },
            },
            ['Gorian Strand'] =
            {
                -- Brackenspore
                [ { 256, 257 }] =
                {
                    talents =
                    {
                    },
                },
            },
            ['The Underbelly'] =
            {
                -- Butcher
                [ { 256, 257 }] =
                {
                    talents =
                    {
                        [6] = 1,
                    },
                },
            },
            ['The Gorthenon'] =
            {
                -- Twin Ogron
                [ { 256, 257 }] =
                {
                    talents =
                    {
                    },
                },
            },
            ['Chamber of Nullification'] =
            {
                -- Ko'ragh
                [ { 256, 257 }] =
                {
                    talents =
                    {
                        [6] = 1,
                    },
                },
                [ { 268, 269, 270 }] =
                {
                    talents =
                    {
                        [5] = 3,
                    },
                },
            },

        },
    }

    for k, v in pairs(self.zoneReminderSettings) do
        for k2, v2 in pairs(v) do
            local newBlocks = { }
            for k3, v3 in pairs(v2) do
                if type(k3) == 'table' then
                    for k4, v4 in pairs(k3) do
                        if not newBlocks[v4] then
                            newBlocks[v4] = { }
                        end
                        _uc:mergeTable(newBlocks[v4], v3)
                    end

                    v2[k3] = nil
                end
            end
            for k3, v3 in pairs(newBlocks) do
                v2[k3] = v3
            end
        end
    end

    self:RegisterEvent("PLAYER_ALIVE", function(event, ...)
        self.customBossModsBarCount = nil
    end )

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, ...)
        self:updateZoneReminder()
    end )

    self:RegisterEvent("ZONE_CHANGED", function(event, ...)
        self:updateZoneReminder()
    end )

    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", function(event, ...)
        self:updateZoneReminder()
    end )

    self:RegisterEvent("ZONE_CHANGED_INDOORS", function(event, ...)
        self:updateZoneReminder()
    end )

    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function(event, ...)
        self:updateZoneReminder()
    end )

    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(event, ...)
        self.lastCheckedZone = nil
        self:updateZoneReminder()
    end )

    self:RegisterEvent("EQUIPMENT_SETS_CHANGED", function(event, ...)
        self.lastCheckedZone = nil
        self:updateZoneReminder()
    end )

    self:RegisterEvent("PLAYER_TALENT_UPDATE", function(event, ...)
        self.lastCheckedZone = nil
        self:updateZoneReminder()
    end )

end

function addon:setupBars()
    self.actionBarSettings = {
        -- !!1
        [001] =
        {
            { specs = { 62, 63, 64 }, spell = 'Frostfire Bolt' },
            { specs = { 65, 66, 70 }, spell = 'Crusader Strike' },
            { specs = { 71, 72, 73 }, spell = 'Heroic Strike' },
            { specs = { 102, 103, 104, 105 }, spell = 'Wrath' },
            { specs = { 250, 251, 252 }, spell = '<macro>BloodTap' },
            { specs = { 253, 254, 255 }, spell = 'Arcane Shot' },
            { specs = { 256, 257, 258 }, spell = '<macro>Smite' },
            { specs = { 259, 260, 261 }, spell = 'Sinister Strike' },
            { specs = { 262, 263, 264 }, spell = 'Lightning Bolt' },
            { specs = { 265, 266, 267 }, spell = 'Shadow Bolt' },
            { specs = { 268, 269, 270 }, spell = 'Jab' },
        },
        -- !!2
        [002] =
        {
            { specs = { 62, 63, 64 }, spell = 'Fire Blast' },
            { specs = { 65, 66, 70 }, spell = 'Judgment' },
            { specs = { 71, 72 }, spell = 'Whirlwind' },
            { specs = { 73 }, spell = 'Shield Slam' },
            { specs = { 102, 103, 104, 105 }, spell = 'Thrash' },
            { specs = { 250, 251, 252 }, spell = 'Blood Boil' },
            { specs = { 256 }, spell = 'Penance' },
            { specs = { 257 }, spell = 'Holy Word: Chastise' },
            { specs = { 258 }, spell = 'Mind Blast' },
            { specs = { 259, 261 }, spell = 'Rupture' },
            { specs = { 260 }, spell = 'Revealing Strike' },
            { specs = { 262 }, spell = 'Earthquake' },
            { specs = { 263 }, spell = 'Fire Nova' },
            { specs = { 264 }, spell = 'Chain Heal' },
            { specs = { 265 }, spell = 'Haunt' },
            { specs = { 266 }, spell = 'Soul Fire' },
            { specs = { 267 }, spell = 'Chaos Bolt' },
            { specs = { 268, 269, 270 }, spell = 'Blackout Kick' },
        },
        -- !!3
        [003] =
        {
            { specs = { 62, 63, 64 }, spell = 'Cone of Cold' },
            { specs = { 65 }, spell = '<macro>HolyShock' },
            { specs = { 66, 70 }, spell = 'Hammer of the Righteous' },
            { specs = { 71 }, spell = 'Rend' },
            { specs = { 72 }, spell = 'Wild Strike' },
            { specs = { 73 }, spell = 'Devastate' },
            { specs = { 102, 103, 104, 105 }, spell = 'Mangle' },
            { specs = { 251 }, spell = 'Howling Blast' },
            { specs = { 252 }, spell = 'Scourge Strike' },
            { specs = { 253 }, spell = 'Kill Command' },
            { specs = { 254 }, spell = 'Chimaera Shot' },
            { specs = { 255 }, spell = 'Explosive Shot' },
            { specs = { 256, 257, 258 }, spell = 'Shadow Word: Pain' },
            { specs = { 259 }, spell = 'Mutilate' },
            { specs = { 260 }, spell = 'Blade Flurry' },
            { specs = { 261 }, spell = 'Backstab' },
            { specs = { 262, 263, 264 }, spell = 'Flame Shock' },
            { specs = { 265, 266, 267 }, spell = 'Corruption' },
            { specs = { 268 }, spell = 'Breath of Fire' },
            { specs = { 269, 270 }, spell = 'Rising Sun Kick' },
        },
        -- !!4
        [004] =
        {
            { specs = { 62 }, spell = 'Arcane Missiles' },
            { specs = { 63 }, spell = 'Fireball' },
            { specs = { 64 }, spell = 'Frostbolt' },
            { specs = { 65, 66, 70 }, spell = '<macro>SacredShield' },
            { specs = { 71, 73 }, spell = 'Thunder Clap' },
            { specs = { 72 }, spell = 'Raging Blow' },
            { specs = { 102, 103, 104 }, spell = 'Remove Corruption' },
            { specs = { 105 }, spell = 'Nature\'s Cure' },
            { specs = { 250, 251, 252 }, spell = 'Death Strike' },
            { specs = { 253, 254, 255 }, spell = 'Steady Shot' },
            { specs = { 256 }, spell = '<macro>ClarityOfWill' },
            { specs = { 257 }, spell = 'Binding Heal' },
            { specs = { 258 }, spell = 'Vampiric Touch' },
            { specs = { 259, 260, 261 }, spell = 'Eviscerate' },
            { specs = { 262, 263, 264 }, spell = 'Cleanse Spirit' },
            { specs = { 265 }, spell = 'Unstable Affliction' },
            { specs = { 266 }, spell = 'Hellfire' },
            { specs = { 267 }, spell = 'Conflagrate' },
            { specs = { 268, 269, 270 }, spell = 'Spinning Crane Kick' },
        },
        -- !!5
        [005] =
        {
            { specs = { 62, 63, 64 }, spell = 'Remove Curse' },
            { specs = { 65, 66, 70 }, spell = 'Cleanse' },
            { specs = { 102, 103, 104, 105 }, spell = 'Soothe' },
            { specs = { 253, 254, 255 }, spell = 'Tranquilizing Shot' },
            { specs = { 256, 257 }, spell = 'Purify' },
            { specs = { 259, 260, 261 }, spell = 'Shiv' },
            { specs = { 262, 263, 264 }, spell = 'Purge' },
            { specs = { 265, 266 }, spell = 'Drain Life' },
            { specs = { 268, 269, 270 }, spell = 'Detox' },
        },
        -- !!Q
        [006] =
        {
            { specs = { 65, 66, 70 }, spell = 'Reckoning' },
            { specs = { 71, 72, 73 }, spell = 'Taunt' },
            { specs = { 102, 103, 104, 105 }, spell = 'Growl' },
            { specs = { 250 }, spell = 'Dark Command' },
            { specs = { 253, 254, 255 }, spell = 'Distracting Shot' },
            { specs = { 256, 257, 258 }, spell = 'Power Word: Shield' },
            { specs = { 259, 260, 261 }, spell = 'Ambush' },
            { specs = { 264 }, spell = 'Earth Shield' },
            { specs = { 268, 269, 270 }, spell = 'Provoke' },
        },
        -- !!E
        [007] =
        {
            { specs = { 62 }, spell = 'Evocation' },
            { specs = { 65 }, spell = 'Holy Light' },
            { specs = { 66 }, spell = 'Holy Wrath' },
            { specs = { 71, 72, 73 }, spell = 'Charge' },
            { specs = { 102, 103, 104, 105 }, spell = 'Healing Touch' },
            { specs = { 250, 251, 252 }, spell = 'Death Coil' },
            { specs = { 256, 257 }, spell = 'Heal' },
            { specs = { 259, 260, 261 }, spell = 'Slice and Dice' },
            { specs = { 262 }, spell = 'Earth Shock' },
            { specs = { 263 }, spell = 'Lava Lash' },
            { specs = { 264 }, spell = 'Healing Wave' },
            { specs = { 265, 266, 267 }, spell = 'Fear' },
            { specs = { 268, 269, 270 }, spell = 'Roll' },
        },
        -- !!C
        [008] =
        {
            { specs = { 62 }, spell = 'Arcane Explosion' },
            { specs = { 63 }, spell = 'Scorch' },
            { specs = { 65 }, spell = 'Beacon of Light' },
            { specs = { 70 }, spell = 'Exorcism' },
            { specs = { 102, 105 }, spell = 'Wild Mushroom' },
            { specs = { 103 }, spell = 'Rip' },
            { specs = { 250 }, spell = 'Rune Tap' },
            { specs = { 251 }, spell = 'Obliterate' },
            { specs = { 252 }, spell = 'Festering Strike' },
            { specs = { 256 }, spell = 'Holy Nova' },
            { specs = { 262 }, spell = 'Unleash Flame' },
            { specs = { 263 }, spell = 'Unleash Elements' },
            { specs = { 264 }, spell = 'Unleash Life' },
            { specs = { 268 }, spell = 'Purifying Brew' },
            { specs = { 269 }, spell = 'Storm, Earth, and Fire' },
            { specs = { 270 }, spell = 'Soothing Mist' },
        },
        -- !!V
        [009] = '<item>109076',
        -- Goblin Glider Kit
        -- !!R
        [010] =
        {
            { specs = { 63 }, spell = 'Flamestrike' },
            { specs = { 64 }, spell = 'Blizzard' },
            { specs = { 65, 66, 70 }, spell = '<macro>LightsHammer' },
            { specs = { 71, 72, 73 }, spell = 'Heroic Leap' },
            { specs = { 102, 103, 104, 105 }, spell = 'Hurricane' },
            { specs = { 250, 251, 252 }, spell = 'Death and Decay' },
            { specs = { 253, 254, 255 }, spell = 'Explosive Trap' },
            { specs = { 256 }, spell = 'Power Word: Barrier' },
            { specs = { 259, 260, 261 }, spell = 'Distract' },
            { specs = { 262, 263, 264 }, spell = 'Healing Rain' },
            { specs = { 265, 266, 267 }, spell = 'Demonic Gateway' },
            { specs = { 268 }, spell = 'Dizzying Haze' },
        },
        -- !!B
        [011] =
        {
            { specs = { 62, 63, 64 }, spell = 'Ice Block' },
            { specs = { 65, 66, 70 }, spell = 'Divine Shield' },
            { specs = { 71, 72 }, spell = 'Die by the Sword' },
            { specs = { 73 }, spell = 'Shield Wall' },
            { specs = { 102, 104, 105 }, spell = 'Barkskin' },
            { specs = { 250, 251, 252 }, spell = 'Icebound Fortitude' },
            { specs = { 253, 254, 255 }, spell = 'Deterrence' },
            { specs = { 258 }, spell = 'Dispersion' },
            { specs = { 259, 260, 261 }, spell = 'Evasion' },
            { specs = { 262, 263, 264 }, spell = '<macro>ShamanTier1' },
            { specs = { 265, 266, 267 }, spell = 'Unending Resolve' },
            { specs = { 268, 269, 270 }, spell = 'Fortifying Brew' },
        },
        -- !!G
        [012] =
        {
            { specs = { 62, 63, 64 }, spell = 'Slow Fall' },
            { specs = { 102, 103, 104, 105 }, spell = 'Frenzied Regeneration' },
            { specs = { 250 }, spell = 'Bone Shield' },
            { specs = { 252 }, spell = 'Dark Transformation' },
            { specs = { 253, 254, 255 }, spell = 'Freezing Trap' },
            { specs = { 256, 257, 258 }, spell = 'Levitate' },
            { specs = { 259, 260, 261 }, spell = 'Blind' },
            { specs = { 262, 263, 264 }, spell = 'Water Walking' },
            { specs = { 268, 269, 270 }, spell = 'Transcendence: Transfer' },
        },

        -- ############################################# 2
        -- !!S1
        [013] =
        {
            { specs = { 62, 63, 64 }, spell = 'Arcane Brilliance' },
            { specs = { 65, 66, 70 }, spell = 'Blessing of Kings' },
            { specs = { 71, 72, 73 }, spell = 'Battle Shout' },
            { specs = { 102, 103, 104, 105 }, spell = 'Mark of the Wild' },
            { specs = { 250, 251, 252 }, spell = 'Horn of Winter' },
            { specs = { 253, 254, 255 }, spell = 'Call Pet 1' },
            { specs = { 256, 257, 258 }, spell = 'Power Word: Fortitude' },
            { specs = { 259, 260, 261 }, spell = 'Deadly Poison' },
            { specs = { 262, 263, 264 }, spell = 'Lightning Shield' },
            { specs = { 265, 266, 267 }, spell = 'Dark Intent' },
            { specs = { 268, 269 }, spell = 'Legacy of the White Tiger' },
            { specs = { 270 }, spell = 'Legacy of the Emperor' },
        },
        -- !!S2
        [014] =
        {
            { specs = { 65, 66, 70 }, spell = 'Blessing of Might' },
            { specs = { 71, 72, 73 }, spell = 'Commanding Shout' },
            { specs = { 250, 251, 252 }, spell = 'Path of Frost' },
            { specs = { 253, 254, 255 }, spell = 'Call Pet 2' },
            { specs = { 256, 257, 258 }, spell = 'Fear Ward' },
            { specs = { 259, 260, 261 }, spell = 'Wound Poison' },
            { specs = { 265, 266, 267 }, spell = 'Unending Breath' },
        },
        -- !!S3
        [015] =
        {
            { specs = { 65, 66, 70 }, spell = 'Righteous Fury' },
            { specs = { 250, 251, 252 }, spell = 'Runeforging' },
            { specs = { 253, 254, 255 }, spell = 'Call Pet 3' },
            { specs = { 259, 260, 261 }, spell = 'Crippling Poison' },
            { specs = { 262, 263, 264 }, spell = 'Astral Recall' },
            { specs = { 265, 266, 267 }, spell = 'Summon Infernal' },
        },
        -- !!S4
        [016] =
        {
            { specs = { 102, 103, 104, 105 }, spell = 'Teleport: Moonglade' },
            { specs = { 250, 251, 252 }, spell = 'Death Gate' },
            { specs = { 253, 254, 255 }, spell = 'Call Pet 4' },
            { specs = { 262, 263, 264 }, spell = 'Far Sight' },
            { specs = { 265, 266, 267 }, spell = 'Summon Doomguard' },
            { specs = { 268, 269, 270 }, spell = 'Zen Pilgrimage' },
        },
        -- !!'
        [017] =
        {
            { specs = { 63 }, spell = 'Pyroblast' },
            { specs = { 64 }, spell = 'Frozen Orb' },
            { specs = { 65, 66, 70 }, spell = 'Hammer of Wrath' },
            { specs = { 71, 72, 73 }, spell = 'Execute' },
            { specs = { 102 }, spell = 'Starsurge' },
            { specs = { 103 }, spell = 'Savage Roar' },
            { specs = { 104 }, spell = 'Maul' },
            { specs = { 105 }, spell = 'Swiftmend' },
            { specs = { 250, 251, 252 }, spell = 'Soul Reaper' },
            { specs = { 253, 254 }, spell = 'Kill Shot' },
            { specs = { 258 }, spell = 'Shadow Word: Death' },
            { specs = { 259, 260, 261 }, spell = 'Crimson Tempest' },
            { specs = { 265, 266 }, spell = 'Health Funnel' },
            { specs = { 267 }, spell = 'Shadowburn' },
            { specs = { 268, 269, 270 }, spell = 'Touch of Death' },
        },
        -- !!SQ
        [018] =
        {
            { specs = { 62, 63, 64 }, spell = 'Invisibility' },
            { specs = { 65, 66, 70 }, spell = 'Hand of Freedom' },
            { specs = { 71, 72, 73 }, spell = 'Berserker Rage' },
            { specs = { 250, 251, 252 }, spell = '<macro>Lichborne' },
            { specs = { 253, 254, 255 }, spell = 'Master\'s Call' },
            { specs = { 256, 257, 258 }, spell = 'Fade' },
            { specs = { 259, 260, 261 }, spell = 'Vanish' },
            { specs = { 262, 263, 264 }, spell = 'Tremor Totem' },
            { specs = { 268, 269, 270 }, spell = 'Nimble Brew' },
        },
        -- !!SE
        [019] =
        {
            { specs = { 65, 66, 70 }, spell = 'Flash of Light' },
            { specs = { 102 }, spell = 'Astral Communion' },
            { specs = { 103 }, spell = 'Tiger\'s Fury' },
            { specs = { 104 }, spell = 'Savage Defense' },
            { specs = { 105 }, spell = 'Regrowth' },
            { specs = { 250, 251, 252 }, spell = '<macro>DkTier5' },
            { specs = { 256, 257, 258 }, spell = '<macro>FlashHeal' },
            { specs = { 259, 260, 261 }, spell = 'Recuperate' },
            { specs = { 262, 263, 264 }, spell = 'Healing Surge' },
            { specs = { 265, 266 }, spell = 'Life Tap' },
            { specs = { 267 }, spell = 'Ember Tap' },
            { specs = { 268, 269, 270 }, spell = 'Surging Mist' },
        },
        -- !!SC
        [020] =
        {
            { specs = { 62, 63, 64 }, spell = 'Amplify Magic' },
            { specs = { 65 }, spell = 'Devotion Aura' },
            { specs = { 71, 72 }, spell = 'Rallying Cry' },
            { specs = { 73 }, spell = 'Demoralizing Shout' },
            { specs = { 105 }, spell = 'Tranquility' },
            { specs = { 250, 251, 252 }, spell = 'Army of the Dead' },
            { specs = { 257 }, spell = 'Divine Hymn' },
            { specs = { 258 }, spell = 'Vampiric Embrace' },
            { specs = { 259, 260, 261 }, spell = 'Smoke Bomb' },
            { specs = { 264 }, spell = 'Healing Tide Totem' },
            { specs = { 270 }, spell = 'Revival' },
        },
        -- !!CSV
        [021] = '<macro>TankCd2',
        -- !!CR
        [022] =
        {
            { specs = { 66 }, spell = 'Consecration' },
            { specs = { 250, 251, 252 }, spell = '<macro>AntiMagicZone' },
            { specs = { 253, 254, 255 }, spell = 'Flare' },
            { specs = { 256, 257, 258 }, spell = 'Mass Dispel' },
            { specs = { 259, 260, 261 }, spell = 'Kidney Shot' },
            { specs = { 262, 263, 264 }, spell = '<macro>TotemicProjectio' },
            { specs = { 265 }, spell = 'Soulburn' },
            { specs = { 267 }, spell = 'Rain of Fire' },
            { specs = { 268 }, spell = 'Summon Black Ox Statue' },
            { specs = { 270 }, spell = 'Summon Jade Serpent Statue' },
        },
        -- !!SB
        [023] =
        {
            { specs = { 62, 63, 64 }, spell = '<flyout>Teleport' },
            { specs = { 73 }, spell = 'Mocking Banner' },
            { specs = { 250, 251, 252 }, spell = 'Control Undead' },
            { specs = { 253, 254, 255 }, spell = 'Eagle Eye' },
            { specs = { 256, 257, 258 }, spell = 'Mind Vision' },
            { specs = { 262, 263, 264 }, spell = 'Fire Elemental Totem' },
            { specs = { 265, 266, 267 }, spell = 'Banish' },
        },
        -- !!SG
        [024] =
        {
            { specs = { 62, 63, 64 }, spell = '<flyout>Portal' },
            { specs = { 65, 66, 70 }, spell = 'Turn Evil' },
            { specs = { 250, 251, 252 }, spell = 'Dark Simulacrum' },
            { specs = { 253, 254, 255 }, spell = 'Call Pet 5' },
            { specs = { 256, 257, 258 }, spell = 'Shackle Undead' },
            { specs = { 259, 260, 261 }, spell = 'Cheap Shot' },
            { specs = { 262, 263, 264 }, spell = 'Earth Elemental Totem' },
            { specs = { 265, 266, 267 }, spell = 'Enslave Demon' },
            { specs = { 268, 269, 270 }, spell = 'Transcendence' },
        },

        -- ############################################# 3
        -- !!C1
        [025] =
        {
            { specs = { 65, 66, 70 }, spell = '<macro>HandOfPurity' },
            { specs = { 71, 72, 73 }, spell = 'Pummel' },
            { specs = { 250, 251, 252 }, spell = 'Death Grip' },
            { specs = { 256, 257 }, spell = '<macro>HolyFire' },
            { specs = { 262, 263, 264 }, spell = 'Healing Stream Totem' },
            { specs = { 269 }, spell = 'Touch of Karma' },
            { specs = { 270 }, spell = 'Enveloping Mist' },
        },
        -- !!C2
        [026] =
        {
            { specs = { 65, 66, 70 }, spell = '<macro>PaladinTier6' },
            { specs = { 102, 103, 104, 105 }, spell = 'Ferocious Bite' },
            { specs = { 250, 251, 252 }, spell = 'Plague Strike' },
            { specs = { 256, 257, 258 }, spell = 'Mind Sear' },
            { specs = { 259, 260, 261 }, spell = 'Garrote' },
            { specs = { 262, 263, 264 }, spell = 'Chain Lightning' },
            { specs = { 265 }, spell = 'Seed of Corruption' },
            { specs = { 266 }, spell = 'Summon Felguard' },
            { specs = { 267 }, spell = 'Flames of Xoroth' },
            { specs = { 268, 269, 270 }, spell = '<macro>MonkTier2' },
        },
        -- !!C3
        [027] =
        {
            { specs = { 65 }, spell = 'Light of Dawn' },
            { specs = { 66 }, spell = 'Shield of the Righteous' },
            { specs = { 70 }, spell = 'Templar\'s Verdict' },
            { specs = { 71 }, spell = 'Sweeping Strikes' },
            { specs = { 72 }, spell = 'Piercing Howl' },
            { specs = { 73 }, spell = 'Shield Block' },
            { specs = { 102, 103, 104, 105 }, spell = 'Shred' },
            { specs = { 250, 251, 252 }, spell = 'Icy Touch' },
            { specs = { 253, 254, 255 }, spell = 'Multi-Shot' },
            { specs = { 256 }, spell = 'Archangel' },
            { specs = { 257 }, spell = 'Circle of Healing' },
            { specs = { 258 }, spell = 'Devouring Plague' },
            { specs = { 262, 263, 264 }, spell = 'Primal Strike' },
            { specs = { 265 }, spell = 'Agony' },
            { specs = { 266 }, spell = 'Demonic Leap' },
            { specs = { 267 }, spell = 'Havoc' },
            { specs = { 268, 269, 270 }, spell = 'Tiger Palm' },
        },
        -- !!C4
        [028] =
        {
            { specs = { 65 }, spell = 'Holy Radiance' },
            { specs = { 66 }, spell = 'Avenger\'s Shield' },
            { specs = { 70 }, spell = 'Divine Storm' },
            { specs = { 71 }, spell = 'Colossus Smash' },
            { specs = { 73 }, spell = 'Revenge' },
            { specs = { 102 }, spell = 'Starfire' },
            { specs = { 103 }, spell = 'Swipe' },
            { specs = { 104 }, spell = 'Lacerate' },
            { specs = { 105 }, spell = 'Wild Growth' },
            { specs = { 250, 251, 252 }, spell = 'Outbreak' },
            { specs = { 253 }, spell = 'Focus Fire' },
            { specs = { 255 }, spell = 'Black Arrow' },
            { specs = { 256 }, spell = '<macro>SpiritShell' },
            { specs = { 257 }, spell = 'Lightwell' },
            { specs = { 258 }, spell = 'Mind Spike' },
            { specs = { 259, 261 }, spell = 'Fan of Knives' },
            { specs = { 260 }, spell = 'Killing Spree' },
            { specs = { 262, 263, 264 }, spell = '<macro>ElementalBlast' },
            { specs = { 265 }, spell = 'Soul Swap' },
            { specs = { 266 }, spell = 'Hand of Gul\'dan' },
            { specs = { 267 }, spell = 'Fire and Brimstone' },
            { specs = { 268 }, spell = 'Keg Smash' },
            { specs = { 269 }, spell = 'Fists of Fury' },
            { specs = { 270 }, spell = 'Uplift' },
        },
        -- !!S'
        [029] =
        {
            { specs = { 65, 66, 70 }, spell = 'Redemption' },
            { specs = { 102, 103, 104, 105 }, spell = 'Revive' },
            { specs = { 253, 254, 255 }, spell = 'Revive Pet' },
            { specs = { 256, 257, 258 }, spell = 'Resurrection' },
            { specs = { 262, 263, 264 }, spell = 'Ancestral Spirit' },
            { specs = { 268, 269, 270 }, spell = 'Resuscitate' },
        },
        -- !!CQ
        [030] =
        {
            { specs = { 62 }, spell = 'Presence of Mind' },
            { specs = { 63 }, spell = 'Combustion' },
            { specs = { 65 }, spell = '<macro>PaladinTier7' },
            { specs = { 66, 70 }, spell = '<macro>Seraphim' },
            { specs = { 71, 72, 73 }, spell = 'Shield Barrier' },
            { specs = { 102 }, spell = 'Solar Beam' },
            { specs = { 103 }, spell = 'Maim' },
            { specs = { 105 }, spell = 'Genesis' },
            { specs = { 250, 251, 252 }, spell = '<macro>GorefiendsGrasp' },
            { specs = { 256, 257, 258 }, spell = '<macro>PriestTier6' },
            { specs = { 262, 263, 264 }, spell = 'Searing Totem' },
            { specs = { 268 }, spell = 'Elusive Brew' },
            { specs = { 269 }, spell = 'Tigereye Brew' },
            { specs = { 270 }, spell = 'Mana Tea' },
        },
        -- !!CE
        [031] =
        {
            { specs = { 65, 66, 70 }, spell = 'Word of Glory' },
            { specs = { 102, 103, 104, 105 }, spell = 'Rejuvenation' },
            { specs = { 257 }, spell = 'Renew' },
            { specs = { 262 }, spell = 'Thunderstorm' },
            { specs = { 263 }, spell = 'Magma Totem' },
            { specs = { 264 }, spell = 'Riptide' },
            { specs = { 270 }, spell = 'Renewing Mist' },
        },
        -- !!CC
        [032] = '<macro>Slot6',
        -- !!AV
        [033] =
        {
            { specs = { 65, 66, 70 }, spell = 'Divine Protection' },
            { specs = { 103, 104 }, spell = 'Survival Instincts' },
            { specs = { 250, 251, 252 }, spell = 'Anti-Magic Shell' },
            { specs = { 256, 257, 258 }, spell = '<macro>DesperatePrayer' },
            { specs = { 259, 260, 261 }, spell = 'Cloak of Shadows' },
            { specs = { 262, 263 }, spell = 'Shamanistic Rage' },
            { specs = { 268, 269, 270 }, spell = '<macro>MonkTier5' },
        },
        -- !!AR
        [034] =
        {
            { specs = { 253, 254, 255 }, spell = 'Ice Trap' },
            { specs = { 261 }, spell = 'Premeditation' },
        },
        -- !!CB
        [035] =
        {
            { specs = { 62 }, spell = 'Slow' },
            { specs = { 64 }, spell = 'Deep Freeze' },
            { specs = { 66 }, spell = 'Hand of Salvation' },
            { specs = { 71, 72, 73 }, spell = 'Spell Reflection' },
            { specs = { 250, 251, 252 }, spell = '<macro>DesecratedGround' },
            { specs = { 262, 263, 264 }, spell = '<macro>ShamanTier7' },
            { specs = { 265, 266, 267 }, spell = 'Create Soulwell' },
            { specs = { 268, 269, 270 }, spell = '<macro>ChiBrew' },
        },
        -- !!CG
        [036] =
        {
            { specs = { 62, 63, 64 }, spell = 'Conjure Refreshment Table' },
            { specs = { 65, 66, 70 }, spell = '<macro>HolyAvenger' },
            { specs = { 250, 251, 252 }, spell = 'Empower Rune Weapon' },
            { specs = { 253, 254, 255 }, spell = 'Beast Lore' },
            { specs = { 259, 260, 261 }, spell = 'Feint' },
            { specs = { 262, 263, 264 }, spell = '<macro>CallOfTheElement' },
            { specs = { 265, 266, 267 }, spell = 'Demonic Circle: Summon' },
            { specs = { 270 }, spell = 'Detonate Chi' },
        },

        -- ############################################# 4
        -- !!CS1
        [037] =
        {
            { specs = { 65, 66, 70 }, spell = 'Seal of Insight' },
            { specs = { 71, 72, 73 }, spell = 'Battle Stance' },
            { specs = { 102, 103, 104, 105 }, spell = 'Cat Form' },
            { specs = { 250, 251, 252 }, spell = 'Blood Presence' },
            { specs = { 253, 254, 255 }, spell = 'Trap Launcher' },
            { specs = { 257 }, spell = 'Chakra: Sanctuary' },
            { specs = { 258 }, spell = 'Shadowform' },
            { specs = { 259, 260, 261 }, spell = 'Stealth' },
            { specs = { 262, 263, 264 }, spell = 'Ghost Wolf' },
            { specs = { 266 }, spell = 'Metamorphosis' },
            { specs = { 268, 269, 270 }, spell = 'Stance of the Fierce Tiger' },
        },
        -- !!CS2
        [038] =
        {
            { specs = { 66, 70 }, spell = 'Seal of Righteousness' },
            { specs = { 71, 72, 73 }, spell = 'Defensive Stance' },
            { specs = { 102, 103, 104, 105 }, spell = 'Bear Form' },
            { specs = { 250, 251, 252 }, spell = 'Unholy Presence' },
            { specs = { 253, 254, 255 }, spell = 'Aspect of the Cheetah' },
            { specs = { 257 }, spell = 'Chakra: Serenity' },
            { specs = { 265, 266, 267 }, spell = 'Summon Imp' },
            { specs = { 270 }, spell = 'Stance of the Wise Serpent' },
        },
        -- !!CS3
        [039] =
        {
            { specs = { 70 }, spell = 'Seal of Justice' },
            { specs = { 102, 103, 104, 105 }, spell = 'Travel Form' },
            { specs = { 250, 251, 252 }, spell = 'Frost Presence' },
            { specs = { 253, 254, 255 }, spell = 'Aspect of the Pack' },
            { specs = { 257 }, spell = 'Chakra: Chastise' },
            { specs = { 265, 266, 267 }, spell = 'Summon Felhunter' },
        },
        -- !!CS4
        [040] =
        {
            { specs = { 65, 66, 70 }, spell = 'Seal of Command' },
            { specs = { 102 }, spell = 'Moonkin Form' },
            { specs = { 253, 254, 255 }, spell = 'Aspect of the Fox' },
            { specs = { 265, 266, 267 }, spell = 'Summon Succubus' },
        },
        -- !!Z
        [041] =
        {
            { specs = { 62, 63, 64 }, spell = 'Blink' },
            { specs = { 65, 66, 70 }, spell = '<macro>PaladinTier2' },
            { specs = { 71, 72, 73 }, spell = 'Hamstring' },
            { specs = { 250, 251, 252 }, spell = '<macro>RemorselessWinte' },
            { specs = { 253, 254, 255 }, spell = 'Concussive Shot' },
            { specs = { 256, 257, 258 }, spell = '<macro>PsychicScream' },
            { specs = { 259, 260, 261 }, spell = 'Shroud of Concealment' },
            { specs = { 262, 263, 264 }, spell = 'Capacitor Totem' },
            { specs = { 265, 266, 267 }, spell = 'Eye of Kilrogg' },
            { specs = { 268, 269, 270 }, spell = '<macro>MonkTier4' },
        },
        -- !!CSQ
        [042] = '<macro>Slot13',
        -- !!CSE
        [043] =
        {
            { specs = { 64 }, spell = 'Summon Water Elemental' },
            { specs = { 71, 72, 73 }, spell = 'Intervene' },
            { specs = { 103, 104 }, spell = 'Skull Bash' },
            { specs = { 252 }, spell = 'Raise Dead' },
            { specs = { 256, 257, 258 }, spell = 'Shadowfiend' },
            { specs = { 259, 260, 261 }, spell = 'Sap' },
            { specs = { 263 }, spell = 'Feral Spirit' },
            { specs = { 264 }, spell = 'Spirit Link Totem' },
            { specs = { 268, 269, 270 }, spell = '<macro>InvokeXuen' },
        },
        -- !!AC
        [044] =
        {
            { specs = { 70 }, spell = 'Emancipate' },
            { specs = { 253, 254, 255 }, spell = 'Camouflage' },
            { specs = { 256, 257, 258 }, spell = '<macro>SpectralGuise' },
            { specs = { 262, 263, 264 }, spell = '<macro>WindwalkTotem' },
            { specs = { 268, 269 }, spell = 'Zen Meditation' },
        },
        -- !!X
        [045] =
        {
            { classes = { 'MAGE', 'PRIEST', 'WARLOCK' }, spell = 'Shoot' },
            { classes = { 'PALADIN', 'WARRIOR', 'DRUID', 'DEATHKNIGHT', 'HUNTER', 'ROGUE', 'SHAMAN', 'MONK' }, spell = 'Auto Attack' }
        },
        -- !!ACR
        [046] = '<macro>TankCd1',
        -- !!AB
        [047] = '<macro>StopPet',
        -- !!CSG
        [048] =
        {
            { specs = { 62, 63, 64 }, spell = 'Conjure Refreshment' },
            { specs = { 65, 66, 70 }, spell = 'Hand of Protection' },
            { specs = { 71, 72, 73 }, spell = 'Victory Rush' },
            { specs = { 102, 103, 104, 105 }, spell = 'Stampeding Roar' },
            { specs = { 253, 254, 255 }, spell = 'Feed Pet' },
            { specs = { 256, 257, 258 }, spell = 'Leap of Faith' },
            { specs = { 259, 260, 261 }, spell = 'Preparation' },
            { specs = { 265, 266, 267 }, spell = 'Demonic Circle: Teleport' },
        },

        -- ############################################# 5
        -- !!T
        [049] =
        {
            { specs = { 62 }, spell = 'Arcane Power' },
            { specs = { 64 }, spell = 'Icy Veins' },
            { specs = { 65, 70 }, spell = 'Avenging Wrath' },
            { specs = { 66 }, spell = 'Ardent Defender' },
            { specs = { 71, 72 }, spell = 'Recklessness' },
            { specs = { 73 }, spell = 'Last Stand' },
            { specs = { 102 }, spell = 'Celestial Alignment' },
            { specs = { 103, 104 }, spell = 'Berserk' },
            { specs = { 105 }, spell = 'Nature\'s Swiftness' },
            { specs = { 250 }, spell = 'Dancing Rune Weapon' },
            { specs = { 251 }, spell = 'Pillar of Frost' },
            { specs = { 252 }, spell = 'Summon Gargoyle' },
            { specs = { 253 }, spell = 'Bestial Wrath' },
            { specs = { 254 }, spell = 'Rapid Fire' },
            { specs = { 256, 257, 258 }, spell = '<macro>PowerInfusion' },
            { specs = { 259 }, spell = 'Vendetta' },
            { specs = { 260 }, spell = 'Adrenaline Rush' },
            { specs = { 261 }, spell = 'Shadow Dance' },
            { specs = { 262, 263, 264 }, spell = 'Ascendance' },
            { specs = { 265, 266, 267 }, spell = 'Dark Soul' },
            { specs = { 268 }, spell = 'Guard' },
            { specs = { 269 }, spell = 'Energizing Brew' },
            { specs = { 270 }, spell = 'Thunder Focus Tea' },
        },
        -- !!CSp
        [050] =
        {
            { specs = { 250, 251, 252 }, spell = '<macro>PlagueLeech' },
            { specs = { 253, 254, 255 }, spell = 'Dismiss Pet' },
            { specs = { 256, 257 }, spell = '<macro>PrayerOfHealing' },
            { specs = { 262, 263, 264 }, spell = 'Totemic Recall' },
        },
        -- !!AF1
        [051] = '<macro>MainMount',
        -- !!AF2
        [052] = '<macro>Yak',
        -- !!SA
        [053] =
        {
            { races = { 'Blood Elf' }, spell = 'Arcane Torrent' },
            { races = { 'Troll' }, spell = 'Berserking' },
            { races = { 'Draenei' }, spell = 'Gift of the Naaru' },
        },
        -- !!CA
        [054] =
        {
            { specs = { 62, 63, 64 }, spell = 'Spellsteal' },
            { specs = { 102 }, spell = 'Starfall' },
            { specs = { 103, 104 }, spell = 'Faerie Fire' },
            { specs = { 105 }, spell = 'Lifebloom' },
            { specs = { 253, 254, 255 }, spell = 'Disengage' },
            { specs = { 256, 257, 258 }, spell = '<macro>PrayerOfMending' },
            { specs = { 262, 263, 264 }, spell = 'Frost Shock' },
            { specs = { 268, 269, 270 }, spell = 'Expel Harm' },
        },
        -- !!CSA
        [055] =
        {
            { specs = { 62, 63, 64 }, spell = 'Frost Nova' },
            { specs = { 71, 72, 73 }, spell = 'Intimidating Shout' },
            { specs = { 102, 103, 104, 105 }, spell = 'Entangling Roots' },
            { specs = { 250, 251, 252 }, spell = 'Chains of Ice' },
            { specs = { 253, 254, 255 }, spell = 'Feign Death' },
            { specs = { 256, 257, 258 }, spell = '<macro>VoidTendrils' },
            { specs = { 262, 263, 264 }, spell = 'Earthbind Totem' },
            { specs = { 269 }, spell = 'Disable' },
        },
        -- !!SS
        [056] = '<macro>Slot10',
        -- !!CS
        [057] = { { specs = { 265, 266, 267 }, spell = 'Ritual of Summoning' }, },
        -- !!CSS
        [058] =
        {
            { specs = { 65, 66, 70 }, spell = 'Hand of Sacrifice' },
            { specs = { 105 }, spell = 'Ironbark' },
            { specs = { 253, 254, 255 }, spell = 'Misdirection' },
            { specs = { 256 }, spell = '<macro>PainSuppression' },
            { specs = { 257 }, spell = 'Guardian Spirit' },
            { specs = { 259, 260, 261 }, spell = 'Tricks of the Trade' },
            { specs = { 270 }, spell = 'Life Cocoon' },
        },
        -- !!AF
        [059] =
        {
            { specs = { 65, 66, 70 }, spell = '<macro>SpeedOfLight' },
            { specs = { 102, 103, 104, 105 }, spell = 'Dash' },
            { specs = { 250, 251, 252 }, spell = '<macro>DeathsAdvance' },
            { specs = { 256, 257, 258 }, spell = '<macro>AngelicFeather' },
            { specs = { 259, 260, 261 }, spell = 'Sprint' },
            { specs = { 262, 264 }, spell = 'Spiritwalker\'s Grace' },
            { specs = { 263 }, spell = 'Spirit Walk' },
            { specs = { 268, 269, 270 }, spell = '<macro>TigersLust' },
        },
        -- !!AG
        [060] =
        {
            { cats = { 'STR' }, spell = '<item>109219' },-- Draenic Strength Potion
            { cats = { 'AGI' }, spell = '<item>109217' },-- Draenic Agility Potion
            { cats = { 'INT' }, spell = '<item>109218' },
        },
        -- Draenic Intellect Potion

        -- ############################################# 6
        -- !!CST
        [061] =
        {
            { specs = { 66 }, spell = 'Guardian of Ancient Kings' },
            { specs = { 250 }, spell = 'Vampiric Blood' },
            { specs = { 262, 263, 264 }, spell = '<macro>ShamanTier4' },
            { specs = { 265, 266, 267 }, spell = 'Command Demon' },
            { specs = { 268, 269 }, spell = '<macro>MonkTier7' },
            { specs = { 270 }, spell = '<macro>BreathOfTheSerpe' },
        },
        -- !!CSSp
        [062] = '<macro>Slot14',
        -- !!CS'
        [063] =
        {
            { specs = { 102, 103, 104, 105 }, spell = 'Rebirth' },
            { specs = { 250, 251, 252 }, spell = 'Raise Ally' },
            { specs = { 265, 266, 267 }, spell = 'Soulstone' },
        },
        -- !!CV
        [064] =
        {
            { specs = { 250, 251, 252 }, spell = '<macro>UnholyBlight' },
            { specs = { 256, 257 }, spell = '<macro>SavingGrace' },
            { specs = { 259, 260, 261 }, spell = 'Pick Pocket' },
            { specs = { 262, 263, 264 }, spell = '<macro>AncestralGuidanc' },
            { specs = { 265, 266, 267 }, spell = 'Summon Voidwalker' },
            { specs = { 269 }, spell = 'Flying Serpent Kick' },
        },
        -- !!SV
        [065] =
        {
            { specs = { 62, 63, 64 }, spell = 'Time Warp' },
            { specs = { 65, 66, 70 }, spell = 'Lay on Hands' },
            { specs = { 102, 103, 104, 105 }, spell = 'Prowl' },
            { specs = { 250, 251, 252 }, spell = '<macro>BreathOfSindrago' },
            { specs = { 259, 260, 261 }, spell = 'Pick Lock' },
            { specs = { 262, 263, 264 }, faction = 'Alliance', spell = 'Heroism' },
            { specs = { 262, 263, 264 }, faction = 'Horde', spell = 'Bloodlust' },
            { specs = { 265, 266, 267 }, spell = 'Soulshatter' },
        },
        -- !!AE
        [066] = { { specs = { 262, 263, 264 }, spell = '<macro>ElementalChannel' }, },
        -- !!CT
        [067] =
        {
            { specs = { 65 }, spell = 'Denounce' },
            { specs = { 71, 72, 73 }, spell = 'Heroic Throw' },
            { specs = { 258 }, spell = '<macro>VoidEntropy' },
            { specs = { 259, 260, 261 }, spell = 'Throw' },
            { specs = { 268, 269, 270 }, spell = 'Crackling Jade Lightning' },
        },
        -- !!ACSSp
        [068] = '<macro>CancelBop',

        -- !!F2
        [069] = '<item>115009',
        -- Improved Iron Trap

        -- !!F3
        [070] = 'Garrison Ability',

        [071] =
        {
            { professions = { 'Enchanting' }, spell = 'Enchanting' },
            { professions = { 'Alchemy' }, spell = 'Alchemy' },
        },

        [072] =
        {
            { professions = { 'Engineering' }, spell = 'Engineering' },
            { professions = { 'Tailoring' }, spell = 'Tailoring' },
            { professions = { 'Inscription' }, spell = 'Inscription' },
        },

        -- ############################################# 7
        -- !!CSW
        [073] = '<item>109223',
        -- Healing Tonic
        -- !!ASp
        [074] =
        {
            { specs = { 253, 254, 255 }, spell = 'Tame Beast' },
            { specs = { 256, 257, 258 }, spell = '<macro>DominateMind' },
            { specs = { 262, 263, 264 }, spell = 'Grounding Totem' },
            { specs = { 265, 266, 267 }, spell = 'Create Healthstone' },
        },

        [075] =
        {
            { cats = { 'INT' }, spell = '<item>109155' },-- Greater Draenic Intellect Flask
            { cats = { 'STR' }, spell = '<item>109156' },-- Greater Draenic Strength Flask
            { cats = { 'AGI' }, spell = '<item>109153' },
        },
        -- Greater Draenic Agility Flask

        [076] =
        {
            { cats = { 'STA' }, spell = '<item>109160' },-- Greater Draenic Stamina Flask
            { cats = { 'SPI' }, spell = '<item>109222' },
        },
        -- Draenic Mana Potion

        [077] =
        {
            { cats = { 'STA' }, spell = '<item>109220' },-- Draenic Armor Potion
            { cats = { 'SPI' }, spell = '<item>109221' },
        },
        -- Draenic Channeled Mana Potion

        [078] =
        {
            { cats = { 'INT' }, spell = '<item>118632' },-- Focus Augment Rune
            { cats = { 'STR' }, spell = '<item>118631' },-- Stout Augment Rune
            { cats = { 'AGI' }, spell = '<item>118630' },
        },
        -- Hyper Augment Rune

        [079] = '',

        [080] = '',

        [081] = '',

        [082] = '',

        [083] = '',

        [084] = '<item>116268',
        -- Draenic Invisibility Potion

        -- ############################################# 8
        -- !!SD
        [085] =
        {
            { specs = { 62, 63, 64 }, spell = 'Polymorph' },
            { specs = { 65, 66, 70 }, spell = 'Hammer of Justice' },
            { specs = { 102, 103, 104, 105 }, spell = 'Cyclone' },
            { specs = { 250, 251, 252 }, spell = 'Strangulate' },
            { specs = { 258 }, spell = 'Psychic Horror' },
            { specs = { 259, 260, 261 }, spell = 'Gouge' },
            { specs = { 262, 263, 264 }, spell = 'Hex' },
            { specs = { 268, 269, 270 }, spell = 'Paralysis' },
        },
        -- !!CSD
        [086] =
        {
            { specs = { 62, 63, 64 }, spell = 'Counterspell' },
            { specs = { 65, 66, 70 }, spell = 'Rebuke' },
            { specs = { 102, 103, 104, 105 }, spell = 'Moonfire' },
            { specs = { 250, 251, 252 }, spell = 'Mind Freeze' },
            { specs = { 253, 254, 255 }, spell = 'Counter Shot' },
            { specs = { 256, 258 }, spell = 'Silence' },
            { specs = { 259, 260, 261 }, spell = 'Kick' },
            { specs = { 262, 263, 264 }, spell = 'Wind Shear' },
            { specs = { 268, 269, 270 }, spell = 'Spear Hand Strike' },
        },

        -- !!C5
        [087] = { { specs = { 256, 257, 258 }, spell = 'Dispel Magic' }, },

        [088] = '',

        [089] = '',

        [090] = '',

        [091] = '',

        [092] = '',

        [093] = '',

        [094] = '',

        [095] = '<item>113509',
        -- Conjured Mana Fritter

        [096] = { { cats = { 'INT' }, spell = '<item>117452' }, },
        -- Gorgrond Mineral Water

        -- ############################################# 9

        [097] = '<item>6948',
        -- Hearthstone

        [098] = '<item>44934',
        -- Loop of the Kirin Tor

        [099] = '<item>65274',
        -- Cloak of Coordination

        [100] = '<item>64402',
        -- Battle Standard of Coordination

        [101] = '<item>118662',
        -- Bladespire Relic

        [102] = '<macro>BlazingWings',
        -- Blazing Wings

        [103] = '<item>110560',
        -- Garrison Hearthstone

        [104] = '',

        [105] = '',

        [106] = { { warning = false, spell = '<flyout>Challenger\'s Path' } },

        [107] = 'Mobile Banking',

        [108] = 'Mass Resurrection',

        -- ############################################# 10

        [109] = 'Revive Battle Pets',

        [110] = '<item>86143',
        -- Battle Pet Bandage

        [111] = 'Fishing',

        [112] =
        {
            { professions = { 'Enchanting' }, spell = 'Disenchant' },
            { professions = { 'Inscription' }, spell = 'Milling' },
        },

        [113] = 'Survey',

        [114] = 'Archaeology',

        [115] = 'Cooking Fire',

        [116] = 'Cooking',

        [117] = 'First Aid',

        [118] = '<macro>AutoButtons',

        [119] = '<macro>TargetsMouseover',

        [120] = '<macro>MountSpecial',
    }

end

function addon:setupQuestSchedule()
    _uc.auras.questSchedule = _uc.auras.questSchedule or {
        {
            name = 'Darkmoon Pet',
            id = 32175,
            condition = function()
                return _uc:IsDarkmoon()
            end
        },
        {
            name = 'Warforged Seals',
            id = 33133,
            condition = function()
                localized_label, amount, icon_file_name = GetCurrencyInfo(738);
                if amount > 0 and UnitLevel('player') == 90 then
                    return true;
                end
                return false;
            end
        },
        {
            name = 'Cooking Bell',
            id = 31337,
            condition = function()
                return GetItemCount(86425, true) > 0;
            end
        },
    }
end

function addon:setupAutoMovers()

    self.autoMoversTimer = self:ScheduleRepeatingTimer( function()
        if not InCombatLockdown() then
            self.framesConfig = self.framesConfig or {
                {
                    unit = 'raid',
                    frame = SUFHeadermaintank,
                    test = function(self)
                        local highestSubgroup = 0
                        for i = 1, GetNumGroupMembers() do
                            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
                            if subgroup > highestSubgroup and subgroup <= ShadowUF.db.profile.units.raid.groupsPerRow then
                                highestSubgroup = subgroup
                            end
                        end
                        return highestSubgroup
                    end
                },
                {
                    unit = 'boss',
                    frame = SUFHeaderboss,
                    test = function(self)
                        local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
                        return difficultyID > 0 and 1 or 0
                    end
                },
                {
                    unit = 'maintank',
                    frame = SUFHeadermaintank,
                    test = function(self)
                        local _, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()

                        if instanceType == 'pvp' then
                            for i = 1, 40 do
                                local role = UnitGroupRolesAssigned('raid' .. i)
                                if role == 'TANK' then
                                    return 1
                                end
                            end
                        else
                            for i = 1, GetNumGroupMembers() do
                                local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, partyRole = GetRaidRosterInfo(i)
                                if string.upper(role or '') == 'MAINTANK' or string.upper(partyRole or '') == 'TANK' then
                                    return 1
                                end
                            end
                        end

                        return 0
                    end
                },
                {
                    unit = 'arena',
                    frame = SUFHeaderarena,
                    test = function(self)
                        return IsActiveBattlefieldArena() and 1 or 0
                    end
                },
            }

            local changeAmount = ShadowUF.db.profile.units.raid.width / 2

            local focusPoint = _uc:getPoint(SUFUnitfocus)
            local ttPoint = _uc:getPoint(SUFUnittargettarget)

            local oldFocusPointX = _uc:round(focusPoint.x, 1)

            focusPoint.x = 0
            ttPoint.x = 0

            if not self.profileChanged and ShadowUF.Units.headerFrames.raidParent then
                -- ShadowUF.Units:ProfileChanged()
                self.profileChanged = true
            end

            local currentOffset = 0

            for k, v in pairs(self.framesConfig) do
                local testResult = v:test()

                v.framePoint = _uc:getPoint(v.frame)

                if testResult > 0 then
                    focusPoint.x = focusPoint.x -(changeAmount * testResult)
                    ttPoint.x = ttPoint.x +(changeAmount * testResult)

                    v.framePoint.x = currentOffset
                    currentOffset = currentOffset +(changeAmount * testResult * 2)
                else
                    v.framePoint.x = 0
                end
            end

            if oldFocusPointX ~= _uc:round(focusPoint.x, 1) then
                local fixScale = function(unit, insert)
                    if ShadowUF.db.profile.positions[unit].anchorTo == "UIParent" then
                        local newScale = ShadowUF.db.profile.units[unit].scale * UIParent:GetScale()
                        if insert then
                            ShadowUF.db.profile.positions[unit].x = ShadowUF.db.profile.positions[unit].x * newScale
                        else
                            ShadowUF.db.profile.positions[unit].x = ShadowUF.db.profile.positions[unit].x / newScale
                        end
                    end
                end

                for k, v in pairs(self.framesConfig) do
                    v.framePoint:save()
                    ShadowUF.db.profile.positions[v.unit].x = v.framePoint.x
                    fixScale(v.unit, true)
                end

                focusPoint:save()
                ttPoint:save()

                ShadowUF.db.profile.positions['focus'].x = focusPoint.x
                fixScale('focus', true)
                ShadowUF.db.profile.positions['targettarget'].x = ttPoint.x
                fixScale('targettarget', true)

                _uc.lib.AceConfigRegistry:NotifyChange("ShadowedUF")

                -- ShadowUF.Units:ProfileChanged()
            end
        end
    end , 3)
end

function addon:applyActionBarSettings()
    if InCombatLockdown() then
        return
    end

    local spec = GetSpecialization()
    if not spec then
        return
    end

    for k, v in pairs(self.actionBarSettings) do
        ClearCursor()

        local spellType = ''
        local spellName = ''
        local warning = true

        if type(v) == 'string' then
            spellName = v
        elseif type(v) == 'table' then
            for k2, v2 in pairs(v) do
                spellName = v2.spell

                if v2.warning == false then
                    warning = false
                end

                if v2.classes and _uc:tableIndexOfValue(v2.classes, select(2, UnitClass('player'))) == 0 then
                    spellName = ''
                end

                if v2.specs and _uc:tableIndexOfValue(v2.specs, GetSpecializationInfo(spec)) == 0 then
                    spellName = ''
                end

                if v2.cats then
                    local found = false
                    for k3, v3 in pairs(self.specInfo[GetSpecializationInfo(spec)]) do
                        if _uc:tableIndexOfValue(v2.cats, v3) > 0 then
                            found = true
                            break
                        end
                    end
                    if not found then
                        spellName = ''
                    end
                end

                if v2.races and _uc:tableIndexOfValue(v2.races, UnitRace('player')) == 0 then
                    spellName = ''
                end

                if v2.faction and v2.faction ~= UnitFactionGroup('player') then
                    spellName = ''
                end

                if v2.professions then
                    local found = false
                    for i = 1, 15 do
                        local info = GetSpellTabInfo(i)

                        if _uc:tableIndexOfValue(v2.professions, info) > 0 then
                            found = true
                            break
                        end
                    end
                    if not found then
                        spellName = ''
                    end
                end

                if spellName ~= '' and(v2.mop == true or v2.mop == false) then
                    local mop = _uc:isMop()

                    if (v2.mop == true and not mop) or(v2.mop == false and mop) then
                        spellName = ''
                    end
                end

                if spellName ~= '' then
                    break
                end
            end
        end

        if spellName ~= '' then
            if string.find(spellName, '<') == 1 then
                spellType, spellName = string.split('>', string.sub(spellName, 2))
            else
                spellType = 'spell'
            end
        end

        if spellName ~= '' then
            if spellType ~= '' then
                if spellType == 'flyout' then
                    _uc:pickupFlyout(spellName)
                elseif spellType == 'spell' then
                    PickupSpellBookItem(spellName)
                elseif spellType == 'item' then
                    PickupItem(spellName)
                elseif spellType == 'macro' then
                    PickupMacro(spellName)
                end

                if GetCursorInfo() == spellType then
                    PlaceAction(k)
                else
                    PickupAction(k)
                    if warning then
                        print('Action not found.', k, spellType, spellName)
                    end
                end
            end
        else
            PickupAction(k)
        end

        ClearCursor()
    end
end

function addon:hookBossFunc(boss, funcName)
    if boss[funcName] and not self:IsHooked(boss, funcName) then
        self:SecureHook(boss, funcName, function(self, ...)
            local bossHooks = addon.customBossModsSettings[self.moduleName]
            local defaultHooks = addon.customBossModsSettings.default

            if defaultHooks then
                local hookFunc = defaultHooks[funcName]
                if hookFunc then
                    hookFunc(self, ...)
                end
            end

            if bossHooks then
                local hookFunc = bossHooks.hooks[funcName]
                if hookFunc then
                    hookFunc(self, ...)
                end
            end
        end )
    end
end

function addon:BigWigsBar(key, time, text, isApprox, icon)
    if not icon and type(key) == 'number' then
        icon = select(3, GetSpellInfo(key))
    end
    BigWigs:GetModule('Plugins').modules.Bars:BigWigs_StartBar('BigWigs_StartBar', BigWigs, key, text, time, icon, isApprox)
end

function addon:hookBossMods()
    if not BigWigs then
        return
    end

    if not self:IsHooked(BigWigs, 'NewBoss') then
        self:SecureHook(BigWigs, 'NewBoss', function(self, module, zoneId, ...)
            addon:hookBossMods()
        end )
    end

    local barsPlugin = BigWigs:GetModule('Plugins').modules.Bars
    if barsPlugin then
        if not self:IsHooked(barsPlugin, 'BigWigs_StartBar') then
            self:RawHook(barsPlugin, 'BigWigs_StartBar', function(self, _, module, key, text, time, icon, isApprox, ...)

                local originalText = text
                local tag = ''
                if text ~= '' then
                    if string.find(text, '<') == 1 then
                        tag, text = string.split('>', string.sub(text, 2))
                    end
                end

                addon.creatingBigWigsBar = 1

                if not addon.customBossModsBarCount then
                    addon.customBossModsBarCount = { }
                end

                local barCount = nil

                if text == "" then
                    addon.customBossModsBarCount['InvCount'] = addon.customBossModsBarCount['InvCount'] or { }

                    if not addon.customBossModsBarCount['InvCount'][icon] then
                        addon.customBossModsBarCount['InvCount']['Count'] =(addon.customBossModsBarCount['InvCount']['Count'] or 0) + 1
                        addon.customBossModsBarCount['InvCount'][icon] = addon.customBossModsBarCount['InvCount']['Count']
                    end

                    text = "inv" .. addon.customBossModsBarCount['InvCount'][icon]
                    barCount =(addon.customBossModsBarCount[icon] or 0) + 1
                    addon.customBossModsBarCount[icon] = barCount
                else
                    barCount =(addon.customBossModsBarCount[text] or 0) + 1
                    addon.customBossModsBarCount[text] = barCount
                end

                text = text .. ' x' .. barCount

                addon.hooks[barsPlugin]['BigWigs_StartBar'](self, test, module, key, text, time, icon, isApprox, ...)

                if addon.creatingBigWigsBar and addon.creatingBigWigsBar ~= 1 then
                    local bar = addon.creatingBigWigsBar
                    bar.tag = tag
                    bar.originalText = originalText

                    if BigWigs:GetModule('Plugins').modules['Super Emphasize']:IsSuperEmphasized(bar:Get("bigwigs:module"), bar:Get("bigwigs:option")) then
                        bar.superEmphasize = true
                    end

                    local customSettings = addon.customBossModsSettings[module.moduleName]
                    if customSettings then
                        if _uc:tableLength(customSettings.alerts) > 0 then
                            if (_uc:tableIndexOfValue(customSettings.alerts, originalText) > 0) or(_uc:tableIndexOfValue(customSettings.alerts, text) > 0) then
                                bar.tag = 'alert'
                            end
                        end
                    end

                    -- if text == 'Blast x2' then
                    -- bar.tag = 'alert'
                    -- end

                    if barsPlugin.db.profile.emphasize and time < barsPlugin.db.profile.emphasizeTime then
                        barsPlugin:EmphasizeBar(bar)
                    end
                end

                addon.creatingBigWigsBar = nil
            end )

            local bossBlockPlugin = BigWigs:GetModule('Plugins').modules.BossBlock
            if bossBlockPlugin then
                if not self:IsHooked(bossBlockPlugin, 'BigWigs_OnBossEngage') then
                    self:RawHook(bossBlockPlugin, 'BigWigs_OnBossEngage', function(self, ...)

                        addon.customBossModsBarCount = nil

                        addon.hooks[bossBlockPlugin]['BigWigs_OnBossEngage'](self, ...)
                    end )
                end
            end

            if not self:IsHooked(_uc.lib.LibCandyBar.barPrototype, 'SetDuration') then
                self:SecureHook(_uc.lib.LibCandyBar.barPrototype, 'SetDuration', function(self, duration, isApprox)

                    if addon.creatingBigWigsBar == 1 then
                        addon.creatingBigWigsBar = self
                    end
                end )
            end

            if not self:IsHooked(barsPlugin, 'EmphasizeBar') then
                self:SecureHook(barsPlugin, 'EmphasizeBar', function(self, bar, ...)
                    if bar.superEmphasize then
                        bar:SetColor(0.7, 0.7, 0.7, 1)
                    end

                    if bar.tag == 'alert' then
                        bar:SetColor(0, 0, 0, 1)

                        if bar.remaining > 5 then
                            for i = bar.remaining - 5, bar.remaining - 2 do
                                for j = 1, 5 do
                                    _uc.unknownui:ScheduleTimer( function()
                                        if not InCombatLockdown() then
                                            return
                                        end
                                        PlaySoundFile("Interface\\AddOns\\BigWigs\\Sounds\\Alert.ogg", "Master")
                                    end , i +(0.2 *(j - 1)))
                                end
                            end
                        end
                    end

                    bar.superEmphasize = nil
                    bar.tag = nil
                end )
            end
        end
    end

    local bossesModule = BigWigs:GetModule('Bosses')
    if bossesModule then

        for k, v in pairs(self.customBossModsSettings) do
            if k ~= 'default' then
                local boss = bossesModule.modules[k]
                if boss then
                    if self.customBossModsSettings.default then
                        for k2, v2 in pairs(self.customBossModsSettings.default) do
                            self:hookBossFunc(boss, k2)
                        end
                    end
                    for k2, v2 in pairs(v.hooks) do
                        self:hookBossFunc(boss, k2)
                    end
                end
            end
        end
    end
end

function addon:updateZoneReminder()
    if InCombatLockdown() then
        return
    end

    local zone = GetZoneText()
    local subZone = GetSubZoneText()

    local id = _uc:getSpecNumber()

    local zoneId =(zone or '') ..(subZone or '') .. id

    if id == 0 or not zone then
        return
    end

    if not self.lastCheckedZone then
        self.lastCheckedZone = zoneId
    else
        if zoneId == self.lastCheckedZone then
            return
        end
        self.lastCheckedZone = zoneId
    end

    self.zoneReminderNote = ''

    _uc.callbacks.mergeReminderTable = _uc.callbacks.mergeReminderTable or function(t1, t2)
        local note = t1 and t1.note or ''
        _uc:mergeTable(t1, t2)
        if note ~= '' and(t2 and t2.note or '') ~= '' then
            t1.note = note .. "\n" .. t2.note
        end
    end

    local mergedTable = { }
    if self.zoneReminderSettings.default and self.zoneReminderSettings.default.default then
        if self.zoneReminderSettings.default.default.default then
            _uc.callbacks.mergeReminderTable(mergedTable, self.zoneReminderSettings.default.default.default)
        end

        if self.zoneReminderSettings.default.default[id] then
            _uc.callbacks.mergeReminderTable(mergedTable, self.zoneReminderSettings.default.default[id])
        end
    end

    local zoneInfo = self.zoneReminderSettings[zone]
    if zoneInfo then
        if zoneInfo.default then
            if zoneInfo.default.default then
                _uc.callbacks.mergeReminderTable(mergedTable, zoneInfo.default.default)
            end

            if zoneInfo.default[id] then
                _uc.callbacks.mergeReminderTable(mergedTable, zoneInfo.default[id])
            end
        end

        if subZone then
            local subZoneInfo = zoneInfo[subZone]

            if subZoneInfo then
                if subZoneInfo.default then
                    _uc.callbacks.mergeReminderTable(mergedTable, subZoneInfo.default)
                end

                if subZoneInfo[id] then
                    _uc.callbacks.mergeReminderTable(mergedTable, subZoneInfo[id])
                end
            end
        end
    end

    _uc.callbacks.appendNote = _uc.callbacks.appendNote or function(text)
        if self.zoneReminderNote ~= '' then
            self.zoneReminderNote = self.zoneReminderNote .. "\n"
        end

        self.zoneReminderNote = self.zoneReminderNote .. text
    end

    if not _uc:tableIsEmpty(mergedTable.disableAddons) then
        local wrong = { }
        for k, v in pairs(mergedTable.disableAddons) do
            if IsAddOnLoaded(v) then
                table.insert(wrong, v)
            end
        end

        if not _uc:tableIsEmpty(wrong) then
            _uc.callbacks.appendNote("Addons To Disable: " .. _uc:implode(wrong, ', '))
        end
    end

    if not _uc:tableIsEmpty(mergedTable.enableAddons) then
        local wrong = { }
        for k, v in pairs(mergedTable.enableAddons) do
            if not IsAddOnLoaded(v) then
                table.insert(wrong, v)
            end
        end

        if not _uc:tableIsEmpty(wrong) then
            _uc.callbacks.appendNote("Addons To Enable: " .. _uc:implode(wrong, ', '))
        end
    end

    if mergedTable.note then
        _uc.callbacks.appendNote("Note: " .. mergedTable.note)
    end

    if mergedTable.glyphs then
        for k, v in pairs(mergedTable.glyphs) do
            if not _uc:glyphSelected(v, k) then
                _uc.callbacks.appendNote("Glyph: " .. v .. " (Socket " .. k .. ")")
            end
        end
    end

    if mergedTable.talents then
        for k, v in pairs(mergedTable.talents) do
            local talentInfo = { talentName = '' }
            if not _uc:talentSelected(k, v, talentInfo) then
                _uc.callbacks.appendNote("Talent: " .. talentInfo.talentName)
            end
        end
    end

    if mergedTable.set then
        local _, _, equipped = GetEquipmentSetInfoByName(mergedTable.set)
        if not equipped then
            _uc.callbacks.appendNote("Set: " .. mergedTable.set)
        end
    end

    if mergedTable.items then
        for k, v in pairs(mergedTable.items) do
            local itemId = GetInventoryItemID('player', GetInventorySlotInfo(k))

            local neededItemName = type(v) == 'table' and v.name or v
            local neededItemLevel = type(v) == 'table' and v.itemLevel or nil
            local found = false

            if itemId then
                local itemName, itemLink, itemRarity, itemLevel = GetItemInfo(itemId)
                if itemName == neededItemName and(not neededItemLevel or itemLevel == neededItemLevel) then
                    found = true
                end
            end
            if not found then
                _uc.callbacks.appendNote("Item: " .. neededItemName .. '. Slot: ' .. k .. '.' ..(neededItemLevel and(' Item Level: ' .. neededItemLevel) or ''))
            end
        end
    end

    self:ScheduleTimer( function()
        if not InCombatLockdown() and WeakAuras then
            WeakAuras.HandleEvent(WeakAuras.frames['WeakAuras Main Frame'], 'UNKNOWNCORE_WA_EVENT_ZONE_REMINDER')
            WeakAuras.ScanAll()
        end
    end , 0.5)
end







-----------------------


SB = SB or CreateFrame("Button", "SB", nil, "SecureActionButtonTemplate")
SB:SetAttribute("type", "click")
SB:SetAttribute("clickbutton", nil)

function CSBCreate(schemas)
    if InCombatLockdown() then
        return
    end

    local button = nil

    for k, v in pairs(schemas) do
        if button then
            break
        end
        local valid = true;

        local buttons = v[1];
        local hiddenRequired = v[2];
        local visibleRequired = v[3];

        for k2, v2 in pairs(hiddenRequired) do
            if v2:IsVisible() then
                valid = false
                break;
            end
        end

        if valid then
            for k2, v2 in pairs(visibleRequired) do
                if not v2:IsVisible() then
                    valid = false
                    break;
                end
            end
        end

        if valid then
            for k2, v2 in pairs(buttons) do
                if v2:IsVisible() then
                    button = v2
                    break
                end
            end
        end
    end

    SB:SetAttribute("clickbutton", button)
end
	
function CSB()
    if InCombatLockdown() then
        return
    end
    CSBCreate(
    {
        {
            { AuctioneerPostPromptYes, AucAdvancedBuyPromptYes, AutoDEPromptYes },
            { LootFrameCloseButton },
            { }
        },
        {
            { PostalOpenAllButton },
            { },
            { MailItem3Button }
        }
    }
    )
end


local function tstttt()








    local x =




    function()

        RareReminderAuraList = RareReminderAuraList or {
            ['Frostfire Ridge'] =
            {
                ['Leveling'] =
                {
                    [34470] = { 22.2, 66.4, 'Pale Fishmonger' },
                    [34129] = { 26.6, 55.6, 'Coldstomp the Griever' },
                    [34497] = { 27.4, 50.0, 'Breathless' },
                    [34865] = { 38.6, 63.0, 'Grutush the Pillager' },
                    [34843] = { 41.2, 68.2, 'Chillfang' },
                    [34825] = { 51.8, 64.8, 'Gruuk' },
                    [34839] = { 47.0, 55.2, 'Gurun' },
                    [33014] = { 41.6, 49.0, 'Cindermaw' },
                    [34133] = { 26.8, 31.6, 'The Beater' },
                    [33938] = { 36.8, 34.0, 'Primalist Mur\'og' },
                    [32941] = { 33.8, 23.2, 'Canyon Icemother' },
                    [34559] = { 40.6, 27.8, 'Yaga the Scarred' },
                    [32918] = { 54.6, 22.2, 'Giant-Slayer Kul' },
                    [33843] = { 66.4, 31.4, 'Broodmother Reeg\'ak' },
                    [33504] = { 71.4, 46.8, 'Firefury Giant' },
                    [34132] = { 76.4, 63.4, 'Scout Goreseeker' },
                    [34477] = { 67.4, 78.2, 'Cyclonic Fury' },
                },
                ['Max Level'] =
                {
                    [37388] = { 38.0, 14.2, 'Gorivax' },
                    [37383] = { 38.2, 16.0, 'Son of Goramal' },
                    [37386] = { 48.8, 24.2, 'Jabberjaw' },
                    [37382] = { 68.8, 19.4, 'Hoarfrost' },
                    [37378] = { 72.4, 24.2, 'Valkor' },
                    [34361] = { 72.2, 33.0, 'The Bone Crawler' },
                    [37379] = { 70.6, 39.0, 'Vrok the Ancient' },
                    [37402] = { 85.0, 48.0, 'Ogom the Mangler' },
                    [37404] = { 87.0, 46.4, 'Kaga the Ironbender' },
                    [37401] = { 86.6, 48.8, 'Ragore Driftstalker' },
                    [37556] = { 85.0, 52.2, 'Jaluk the Pacifist' },
                    [37525] = { 88.6, 57.4, 'Ak\'ox the Slaughterer' },
                },
            },
            ['Gorgrond'] =
            {
                ['Leveling'] =
                {
                    [36656] = { 44.6, 92.2, 'Sunclaw' },
                    [36600] = { 37.6, 81.4, 'Riptar' },
                    [35335] = { 40.0, 79.0, 'Bashiok' },
                    [35910] = { 38.2, 66.2, 'Stomper Kreego' },
                    [36394] = { 40.4, 60.8, 'Sulfurious' },
                    [36391] = { 41.8, 45.4, 'Gelgor of the Blue Flame' },
                    [36204] = { 46.2, 50.8, 'Glut' },
                    [36178] = { 50.6, 53.2, 'Mandrakor' },
                    [37413] = { 52.8, 53.6, 'Gnarljaw' },
                    [36794] = { 64.4, 61.6, 'Sylldross' },
                    [36387] = { 57.6, 68.2, 'Fossilwood the Petrified' },
                    [36837] = { 55.2, 71.2, 'Stompalupagus' },
                    [35908] = { 52.2, 70.2, 'Hive Queen Skrikka' },
                    [34726] = { 53.4, 78.2, 'Mother Araneae' },
                },
                ['Max Level'] =
                {
                    [37368] = { 46.0, 33.6, 'Blademaster Ro\gor' },
                    [37367] = { 47.6, 30.6, 'Inventor Blammo' },
                    [37363] = { 49.0, 33.8, 'Maniacal Madgard' },
                    [37362] = { 48.2, 21.0, 'Defector Dazgo' },
                    [37366] = { 50.0, 23.8, 'Durp the Hated' },
                    [35503] = { 53.4, 44.6, 'Char the Burning' },
                    [37377] = { 55.0, 46.6, 'Hunter Balra' },
                    [37370] = { 57.6, 35.8, 'Depthroot' },
                    [37371] = { 58.6, 41.2, 'Alkali' },
                    [37375] = { 59.6, 43.0, 'Grove Warden Yal' },
                    [37374] = { 70.8, 34.0, 'Swift Onyx Flayer' },
                    [37373] = { 72.8, 35.8, 'Firestarter Grash' },
                },
            },
            ['Talador'] =
            {
                ['Leveling'] =
                {
                    [34142] = { 68.2, 15.8, 'Dr. Gloom' },
                    [34859] = { 86.4, 30.6, 'Nolosh' },
                    [34205] = { 69.8, 31.8, 'Wandering Vindicator' },
                    [34135] = { 53.8, 25.8, 'Yazheera the Incinerator' },
                    [34185] = { 64.6, 45.4, 'Hammertooth' },
                    [34196] = { 59.4, 59.6, 'Rakahn' },
                    [34929] = { 67.4, 80.6, 'Gennadian' },
                    [34498] = { 66.8, 85.4, 'Klikixx' },
                    [34668] = { 53.8, 91.0, 'Talonpriest Zorkra' },
                    [34208] = { 49.0, 92.0, 'Lo\'mark Jawcrusher' },
                    [35018] = { 50.6, 84.6, 'Felbark' },
                    [35219] = { 56.6, 63.6, 'Kharazos the Triumphant' },
                    [34165] = { 37.6, 70.4, 'Cro Fleshrender' },
                    [34189] = { 33.2, 64.0, 'Glimmerwing' },
                    [34221] = { 34.2, 57.0, 'Echo of Murmur' },
                },
                ['Max Level'] =
                {
                    [37350] = { 36.8, 41.0, 'Vigilant Paarthos' },
                    [37348] = { 37.2, 37.6, 'Kurlosh Doomfang' },
                    [37340] = { 47.6, 39.0, 'Gugtol' },
                    [37338] = { 46.6, 35.2, 'Avatar of Socrethar' },
                    [37341] = { 47.6, 33.0, 'Felfire Consort' },
                    [37343] = { 38.0, 14.6, 'Xothear the Destroyer' },
                    [37349] = { 39.0, 49.6, 'Matron of Sin' },
                    [37346] = { 33.8, 37.8, 'Lady Demlash' },
                },
            },
            ['Spires of Arak'] =
            {
                ['Leveling'] =
                {
                    [36306] = { 56.6, 94.6, 'Jiasska the Sporegorger' },
                    [36396] = { 54.6, 89.0, 'Mutafen' },
                    [36291] = { 58.4, 84.2, 'Betsi Boombasket' },
                    [36254] = { 57.4, 74.0, 'Tesska the Broken' },
                    [36283] = { 64.4, 65.6, 'Blightglow' },
                    [36278] = { 54.6, 63.2, 'Talonbreaker' },
                    [36472] = { 52.8, 55.6, 'Swarmleaf' },
                    [36129] = { 36.4, 52.4, 'Nas Dunberlin' },
                    [36276] = { 68.8, 49.0, 'Sangrikass' },
                    [36268] = { 62.8, 37.6, 'Kalos the Bloodbathed' },
                    [36279] = { 59.4, 37.4, 'Poisonmaster Bortusk' },
                    [36478] = { 52.0, 35.6, 'Shadowbark' },
                    [36267] = { 46.4, 28.6, 'Durkath Steelmaw' },
                    [36470] = { 38.4, 27.8, 'Rotcap' },
                    [36943] = { 25.2, 24.2, 'Gaze' },
                    [36265] = { 33.4, 22.0, 'Stonespite' },
                    [35599] = { 46.8, 23.0, 'Bladedancer Aeryx' },
                    [36887] = { 59.2, 15.0, 'Hermit Palefur' },
                },
            },
            ['Nagrand'] =
            {
                ['Leveling'] =
                {
                    [35875] = { 43.6, 49.4, 'Ophiis' },
                    [35920] = { 65.0, 39.0, 'Turaaka' },
                    [35877] = { 70.6, 29.4, 'Windcaller Korast' },
                    [35923] = { 80.6, 30.4, 'Hunter Blacktooth' },
                    [35893] = { 69.8, 41.4, 'Flinthide' },
                    [35714] = { 66.8, 51.2, 'Greatfeather' },
                    [35717] = { 66.6, 56.6, 'Gnarlhoof the Rapid' },
                    [35931] = { 54.8, 61.2, 'Scout Pokhar' },
                    [35943] = { 61.8, 69.0, 'Outrider Duretha' },
                    [35865] = { 47.6, 70.8, 'Netherspawn' },
                    [34727] = { 34.6, 77.0, 'Captain Ironbeard' },
                    [35900] = { 58.0, 84.0, 'Ruklaa' },
                    [35712] = { 73.6, 57.8, 'Redclaw the Feral' },
                    [36128] = { 75.6, 65.0, 'Soulfang' },
                    [35932] = { 81.2, 60.0, 'Malroc Stonesunder' },
                    [35784] = { 86.4, 72.6, 'Grizzlemaw' },
                    [35623] = { 89.0, 41.2, 'Explorer Nozzand' },
                    [35923] = { 80.6, 30.4, 'Hunter Blacktooth' },
                },
                ['Max Level'] =
                {
                    [37400] = { 43.0, 36.4, 'Brutag Grimblade' },
                    [37399] = { 46.0, 36.0, 'Karosh Blackwind' },
                    [37395] = { 38.6, 22.4, 'Durg Spinecrushder' },
                    [36229] = { 45.8, 15.2, 'Mr Pinchy' },
                    [37398] = { 58.2, 12.0, 'Krud the Eviscerator' },
                },
            },


        }

        return RareReminderAuraText or ''
    end





    --[[






['Orgrimmar'] = {
            ['Leveling'] = {
                [36656] = {52.0, 55.0, 'Far 1'},
                [37218] = {52.0, 55.0, 'Already Completed'},
            },
            ['Max Level'] = {
                [37368] = {69.0, 41.0, 'Far 2'},
                [37218] = {52.0, 55.0, 'Already Completed'},
            },
        },




_uc:tablePrint(GetQuestsCompleted(), 1)




local txt = '';
for k, v in pairs(GetQuestsCompleted()) do
    if txt ~= '' then
        txt = txt .. ','
    else
        txt = txt .. 'local alreadyDone = {'
    end
    txt = txt .. k
end
txt = txt .. '}'
_uc:log(txt)






local alreadyDone = {34582,34583,34584,34461,34586,34587,34402,33815,33847,34375,39,34378,34379,37187,34453,34364,34765,34585,33868,25265}
for k, v in pairs(GetQuestsCompleted()) do
    local found = false
    for k2, v2 in pairs(alreadyDone) do
        if k == v2 then
            found = true
            break
        end
    end
    if not found then
        print('NEW QUEST', k)
    end
end



            ['Treasure'] = {
            	[34476] = {57.1, 52.1},
            },


]]





    local q =


    function()
        if not RareReminderAuraToggleButton then
            RareReminderAuraToggleButton = CreateFrame("BUTTON", "RareReminderAuraToggleButton")
            SetBindingClick("CTRL-F7", RareReminderAuraToggleButton:GetName())
            RareReminderAuraToggleButton:SetScript("OnClick", function(self, button, down)
                if RareReminderAuraToggleButtonActive then
                    RareReminderAuraToggleButtonActive = nil
                else
                    RareReminderAuraToggleButtonActive = 1
                end
            end )
            RareReminderAuraToggleButton:RegisterForClicks("AnyUp")

            local AceTimer = LibStub('AceTimer-3.0', true)
            if AceTimer then
                AceTimer:ScheduleRepeatingTimer( function()
                    if InCombatLockdown() then
                        return
                    end
                    local rareReminderActiveKeys = nil
                    local currentZoneList = nil

                    if RareReminderAuraList then
                        local auraText = ''
                        local zoneText = GetZoneText()

                        currentZoneList = RareReminderAuraList[zoneText]

                        if currentZoneList and RareReminderAuraToggleButtonActive then
                            for k, v --[[ LevelInfo ]] in pairs(currentZoneList) do
                                if k == 'Leveling' or(k == 'Max Level' and UnitLevel('player') == 100) then
                                    rareReminderActiveKeys = rareReminderActiveKeys or { }
                                    table.insert(rareReminderActiveKeys, k)
                                    auraText = auraText .. '\n- ' .. zoneText .. ' ' .. k .. ':\n\n'
                                    for k2, v2 --[[ MobInfo ]] in pairs(v) do
                                        v2[4] = nil
                                        if not IsQuestFlaggedCompleted(k2) then
                                            auraText = auraText .. v2[3] .. '\n'
                                            v2[4] = true
                                        end
                                    end

                                end
                            end

                        end
                        RareReminderAuraText = auraText
                    end

                    if TomTom then
                        if RareReminderAuraToggleButtonActive then
                            RareReminderBlockTomTom = nil
                        end

                        local mapId, mapFloor = nil, nil
                        if not RareReminderBlockTomTom then
                            mapId, mapFloor = TomTom:GetCurrentPlayerPosition()

                            for k, v --[[ Map ]] in pairs(TomTom.waypoints) do
                                for k2, v2 --[[ Waypoint ]] in pairs(v) do
                                    if v2.rareReminderWaypoint then
                                        v2.rareReminderClear = true
                                        if k == mapId and rareReminderActiveKeys then
                                            for k3, v3 --[[ ActiveKey ]] in pairs(rareReminderActiveKeys) do
                                                for k4, v4 --[[ MobInfo ]] in pairs(currentZoneList[v3]) do
                                                    if v2.rareReminderWaypoint == k4 and v4[4] then
                                                        v4[4] = k2
                                                        v2.rareReminderClear = nil
                                                    end
                                                end
                                            end
                                        end
                                        if v2.rareReminderClear then
                                            TomTom:RemoveWaypoint(v2)
                                        end
                                    end
                                end
                            end
                            if not RareReminderAuraToggleButtonActive then
                                RareReminderBlockTomTom = true
                            end
                        end

                        if rareReminderActiveKeys then
                            for k, v --[[ ActiveKey ]] in pairs(rareReminderActiveKeys) do
                                for k2, v2 --[[ MobInfo ]] in pairs(currentZoneList[v]) do
                                    if v2[4] then
                                        if type(v2[4]) == 'boolean' then
                                            TomTom:AddMFWaypoint(mapId, mapFloor, v2[1] / 100, v2[2] / 100, {
                                                title = v2[3],
                                                rareReminderWaypoint = true,
                                            } )
                                        end
                                    end
                                end
                            end

                            local closest = TomTom:GetClosestWaypoint()
                            if closest and closest.rareReminderWaypoint and RareReminderLastClosest ~= closest then
                                RareReminderLastClosest = closest
                                TomTom:SetClosestWaypoint()
                            end
                        end
                    end
                end , 2)
            end
        end

        return RareReminderAuraToggleButtonActive
    end










end