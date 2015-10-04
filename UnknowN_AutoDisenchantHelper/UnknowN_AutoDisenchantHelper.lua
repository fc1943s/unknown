local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0")
_uc.autodisenchanthelper = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

addon.visibleBarCount = 0
addon.visibleBarList = { }
addon.playWarning = nil
addon.postalHooked = false

function addon:OnInitialize()
end

function addon:OnEnable()
    self:Print("Enabled!")

    -- Searches through table to get disenchanted items
    self:RawHook(BeanCounter.API, 'getBidReason', function(itemLink, quantity)
        local _reason, _time, _bid, _player = self.hooks[BeanCounter.API]['getBidReason'](itemLink, quantity);

        if itemLink and _uc.db.autoDisenchant[_uc:getItemInfoFromLink(itemLink).id] then
            _reason = 'Disenchant'
            _time = 1410729783
        end

        return _reason, _time, _bid, _player
    end )

    self:ScheduleRepeatingTimer( function()
        if InCombatLockdown() then
            addon.playWarning = nil
            return
        end

        if not addon.postalHooked and Postal then
            self:SecureHook(Postal, 'Print', function(self, text, ...)
                if string.find(text, 'Not taking more') then
                    addon.playWarning = 2
                end
            end )
            addon.postalHooked = true
        end

        if not addon.playWarning or(addon.playWarning == 1 and(not AuctionFrame or not AuctionFrame:IsShown())) then
            addon.playWarning = nil
            return
        end

        if not _uc.db.muteAuctionAlert then
            PlaySoundFile("Interface\\AddOns\\BigWigs\\Sounds\\Alert.ogg", "Master")
        end

        if addon.playWarning == 2 then
            addon.playWarning = nil
        end
    end , 2)

    self:SecureHook(AucAdvanced.API, 'ProgressBars', function(name, value, show, text, options, ...)
        if show then
            if not self.visibleBarList[name] then
                addon.playWarning = nil
                addon.visibleBarCount = addon.visibleBarCount + 1
                addon.visibleBarList[name] = true
            end
        else
            if addon.visibleBarList[name] then
                addon.visibleBarCount = addon.visibleBarCount - 1
                addon.visibleBarList[name] = nil

                if addon.visibleBarCount == 0 then
                    addon.playWarning = 1
                end
            end
        end
        _uc:log(name, value, show, text, options, ...)
    end )

    self:HookScript(GameTooltip, 'OnTooltipSetItem', function(tt)
        local item, link = tt:GetItem()
        local itemInfo = _uc:getItemInfoFromLink(link)

        if _uc.db.autoDisenchant[itemInfo.id] then
            tt:AddLine(" ")
            tt:AddLine("|cFFFF00FF# Auto Disenchant|r")
            tt:AddLine(" ")
        end
    end )

    -- Item click event
    self:Hook("ContainerFrameItemButton_OnModifiedClick", function(...)
        if InCombatLockdown() then
            return
        end

        if IsAltKeyDown() and(not IsControlKeyDown()) and IsShiftKeyDown() then
            local bag, slot =(...):GetParent():GetID(),(...):GetID();
            local itemInfo = _uc:getItemInfoFromSlot(bag, slot);

            if _uc.db.autoDisenchant[itemInfo.id] then
                _uc.db.autoDisenchant[itemInfo.id] = nil;
                print('Removing: ' .. itemInfo.link)
            else
                _uc.db.autoDisenchant[itemInfo.id] = true;
                print('Adding: ' .. itemInfo.link)
            end
        end
    end )

    table.insert(_uc.externalMenuItems, {
        text = addonTitle,
        value = addonName,
        childrens =
        {
            {
                condition = function() return _uc.db.muteAuctionAlert end,
                [1] =
                {
                    text = 'Unmute Alert',
                    func = function() _uc.db.muteAuctionAlert = nil end,
                },
                [0] =
                {
                    text = 'Mute Alert',
                    func = function() _uc.db.muteAuctionAlert = 1 end,
                },
            },
        },
    } )
end

function addon:OnDisable()
end