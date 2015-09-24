local addonName, addonTable = ...

local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
_uc = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)

addon.DEFAULT_FONT_NAME = "MyriadCondensedWeb"
addon.DEFAULT_TEXTURE_NAME = "Flat"

addon.lib = {
	AceAddon = LibStub("AceAddon-3.0"), 
	AceConfig = LibStub("AceConfig-3.0"),
	AceConfigCmd = LibStub("AceConfigCmd-3.0"),
	AceConfigDialog = LibStub("AceConfigDialog-3.0"),
	AceConfigRegistry = LibStub("AceConfigRegistry-3.0"),
	AceConsole = LibStub("AceConsole-3.0"),
	AceDB = LibStub("AceDB-3.0"),
	AceDBOptions = LibStub("AceDBOptions-3.0"),
	AceEvent = LibStub("AceEvent-3.0"),
	AceGUI = LibStub("AceGUI-3.0"), 
	AceGUISharedMediaWidgets = LibStub("AceGUISharedMediaWidgets-1.0"),
	AceHook = LibStub("AceHook-3.0"),
	AceTimer = LibStub("AceTimer-3.0"),  
	CallbackHandler = LibStub("CallbackHandler-1.0"),
	LibCandyBar = LibStub("LibCandyBar-3.0"),
	LibDataBroker = LibStub("LibDataBroker-1.1"),
	LibDBIcon = LibStub("LibDBIcon-1.0"),
	LibResInfo = LibStub("LibResInfo-1.0"),
	LibSharedMedia = LibStub("LibSharedMedia-3.0"),
	LibSmoothStatusBar = LibStub("LibSmoothStatusBar-1.0"),
	--LibStub
}

addon.emptyTable = {};
addon.auras = {};
addon.callbacks = {};
addon.metatables = {};
addon.loggedOnce = false;
addon.glyphList = {};
addon.menu = nil;
addon.iconDataBroker = nil;
addon.dbController = nil;
addon.db = nil;
addon.externalMenuItems = {};
addon.menuItems = nil;
addon.dbDefaults = {
	profile = {
		dbg = nil,
		autoDisenchant = {},
		muteAuctionAlert = nil,
		minimap = {
			hide = false,
			minimapPos = 134,
		},
	},
};
addon.slashOptions = nil;

function addon:OnInitialize()
	_uc.lib.LibSharedMedia:Register(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME, [[Interface\AddOns\UnknowN_Core\Fonts\MyriadCondensedWeb.ttf]])
	_uc.lib.LibSharedMedia:Register(_uc.lib.LibSharedMedia.MediaType.STATUSBAR, _uc.DEFAULT_TEXTURE_NAME, [[Interface\AddOns\UnknowN_Core\Textures\Flat.tga]])
	_uc.lib.LibSharedMedia:Register(_uc.lib.LibSharedMedia.MediaType.STATUSBAR, 'Ruben', [[Interface\AddOns\UnknowN_Core\Textures\Ruben.tga]])
end

function addon:OnEnable()
    self:Print("Enabled!")

    self.dbController = _uc.lib.AceDB:New('UnknowNCoreDB', self.dbDefaults, true)
	self.db = self.dbController.profile

	self.slashOptions = {
		type= "group",
		args = {
			menu = {
				type = "execute",
				name = 'menu',
				desc = 'Show menu',
				func = function() addon:OpenMenu() end
			},
		},
	}
 
	_uc.lib.AceConfig:RegisterOptionsTable(addonName, self.slashOptions)

	local handleChatCommand = function(input)
		if not input then
			_uc.lib.AceConfigDialog:Open(addonName)
		else
			_uc.lib.AceConfigCmd.HandleCommand(addon, "uc", addonName, input)
		end
	end

	self:RegisterChatCommand('uc', handleChatCommand)
	self:RegisterChatCommand('unknowncore', handleChatCommand)

	self.iconDataBroker = _uc.lib.LibDataBroker:NewDataObject(addonTitle, {
		type = "data source",
		label = addonTitle,
		text = addonTitle,
		icon = "Interface\\Icons\\INV_Scroll_07",
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(addonTitle)
			tooltip:AddLine(' ')
			tooltip:AddLine('Click to toggle window')
			tooltip:AddLine('Right-click to open menu')
		end,
		OnClick = function(frame, button)
			if button == "LeftButton" then
				
			elseif button == "RightButton" then
				addon:OpenMenu()
			end
		end
	})

	_uc.lib.LibDBIcon:Register(addonName, self.iconDataBroker, self.db.minimap)
	if not self.db.minimap.hide then
		_uc.lib.LibDBIcon:Show(addonName)
	end

	addon:setupMenuItems()
end

function addon:OnDisable()
end

function addon:setupMenuItems()
	self.menuItems = {
		{
			text = addonTitle,
			isTitle = 1,
		},
		{
			disabled = 1,
		},
		{
			condition = function() return GetCVar('Sound_EnableAllSound') ~= '0' end,
			[1] = {
				text = 'Mute Sound',
				func = function() SetCVar('Sound_EnableAllSound', 0) end,
			},
			[0] = {
				text = 'Unmute Sound',
				func = function() SetCVar('Sound_EnableAllSound', 1) end,
			},
		},
		{
			condition = function() return IsAddOnLoaded('Volumizer') end,
			[1] = {
				text = 'Toggle Volumizer',
				func = function() SlashCmdList['Volumizer']('') end,
			},
		},
		{
			disabled = 1,
		},
		{
			table = function() return addon.externalMenuItems end,
		},
		{
			disabled = 1,
		},
		{
			condition = function() return not _uc.db.dbg end,
			[1] = {
				text = 'Enable Debugging',
				func = function() _uc.db.dbg = 1 end,
			},
			[0] = {
				text = 'Disable Debugging',
				func = function() _uc.db.dbg = nil end,
			},
		},
		{
			condition = function() return _uc.db.minimap.hide end,
			[1] = {
				text = 'Show Minimap Icon (After Reload UI)',
				func = function() _uc.db.minimap.hide = false end,
			},
			[0] = {
				text = 'Hide Minimap Icon (After Reload UI)',
				func = function() _uc.db.minimap.hide = true end,
			},
		},
		{
			text = CLOSE,
			func = function() CloseDropDownMenus() end,
		},
	}
end

function addon:OpenMenu()
	if not self.menu then
		self.menu = CreateFrame("Frame", "UnknowNCoreMenu")
	
		self.menu.displayMode = "MENU"
		
		_uc.callbacks.processMenuLevel = _uc.callbacks.processMenuLevel or function(menuTable, depth, level)
			if depth > 1 then
				for k, v in pairs(menuTable) do
					if type(v.table) == 'function' then
						_uc.callbacks.processMenuLevel(v.table(), depth, level)
					elseif v.value == UIDROPDOWNMENU_MENU_VALUE and v.childrens then
						_uc.callbacks.processMenuLevel(v.childrens, depth - 1, level)
					end
				end
			else
				local info = {}
				for k, v in pairs(menuTable) do
					if type(v.table) == 'function' then
						_uc.callbacks.processMenuLevel(v.table(), depth, level)
					else
						wipe(info)

						info.notCheckable = 1

						if v.value and v.childrens then
							info.hasArrow = 1
						end

						if v.condition then
							if v.condition() then
								if v[1] then
									for k2, v2 in pairs(v[1]) do
										info[k2] = v2
									end
								else
									wipe(info)
								end
							else
								if v[0] then
									for k2, v2 in pairs(v[0]) do
										info[k2] = v2
									end
								else
									wipe(info)
								end
							end
						end

						for k2, v2 in pairs(v) do
						
							if addon:tableIndexOfValue({'childrens', 1, 0, 'condition'}, k2) == 0 then
								info[k2] = v2
							end
						end

						if _uc:tableLength(info) > 0 then
							UIDropDownMenu_AddButton(info, level)
						end
					end
				end
			end
		end

		self.menu.initialize = function(self, level)
			_uc.callbacks.processMenuLevel(addon.menuItems, level, level)
		end
	end

	local x, y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, self.menu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function addon:isMop()
	return select(4, GetBuildInfo()) < 60000
end

function addon:isWod()
	return select(4, GetBuildInfo()) >= 60000
end

function addon:UnitHealth(unit, object)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	if maxHp == 0 then
		maxHp = 1
	end
	if currentHp == 0 then
		currentHp = 1
	end
 
 	local pct = currentHp / maxHp
 	local dif = maxHp - currentHp

	if object then
		return {pct = pct, dif = dif}
	end
	return pct, dif
end

function addon:UnitPosition(unit)
	local x, y = UnitPosition(unit)
	return {x = x, y = y}
end

function addon:distanceBetween(unit1, unit2)
    local x1, y1, x2, y2
    if type(unit1) == 'string' and type(unit2) == 'string' then
    	x1, y1 = UnitPosition(unit1)
    	x2, y2 = UnitPosition(unit2)
	else
		x1, y1, x2, y2 = unit1.x, unit1.y, unit2.x, unit2.y
	end
    return sqrt(((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))
end

function addon:pickupFlyout(name)
    local i = 1
    while true do
        local skillType, spellId = GetSpellBookItemInfo(i,BOOKTYPE_SPELL)
        if skillType == nil then
            break
        end
        
        if skillType == 'FLYOUT' and GetFlyoutInfo(spellId) == name then
            PickupSpellBookItem(i, BOOKTYPE_SPELL)
            break
        end
        i = i + 1
    end
end

function addon:limitText(text, length)
	if not text or not length then
		return ''
	end
	
	if string.len(text) > length then
		text = string.sub(text, 1, length - 3) .. '...'
	end
	
	return text
end

function addon:copyTable(tbl)
	if type(tbl) ~= 'table' then 
		return tbl 
	end
	local mt = getmetatable(tbl)
	local result = {}
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			v = self:copyTable(v)
		end
		result[k] = v
	end
	setmetatable(result, mt)
	return result
end

function addon:mergeTable(t1, t2)
    for k, v in pairs(t2) do
		if type(v) == 'table' then
			if not t1[k] then
				t1[k] = {}
			end
			self:mergeTable(t1[k], v)
		else
			t1[k] = v
		end
	end
end


function addon:log(...)
	if CopyChatFrame and CopyChatFrame:IsVisible() then
		if not self.loggedOnce then
			CopyChatFrameEditBox:SetText("")
			self.loggedOnce = true
		end	
	else
		self.loggedOnce = false
		return
	end

	local args = {...}
	local text = ''
	
	local k, v = next(args)
	if type(v) == 'table' then
		local k2, v2 = next(args, k)
		text = self:tablePrint(v, nil, type(v2) == 'number' and v2 or nil)
	end
	
	if text == '' then
		text = self:implode(args, ', ')
	end
	
	CopyChatFrameEditBox:SetText(CopyChatFrameEditBox:GetText() .. "\n" .. text)
end

function addon:print(...)
    if not self.db.dbg then
        return
    end
    self:log('|cffff6060'.. addonTitle ..' Debug: |cffffffff', ...)
end

function addon:playerNameOnly(name)
	return string.split('-', name)
end

function addon:fullUnitName(unit)
	if not unit then
		return
	end
	local name, server = UnitName(unit)
	if name and server and server ~= "" then
		name = string.format("%s-%s", name, server)
	end
	return name
end

function addon:getPoint(frame)
	if not self.metatables.getPointResultMetaTable then
		self.metatables.getPointResultMetaTable = {
			point = '',
			relativeFrame = nil,
			relativePoint = '',
			x = 0,
			y = 0,
			frame = nil,
			save = function(self)
				if self.frame and self.frame.SetPoint then
					self.frame:SetPoint(self.point, self.relativeFrame, self.relativePoint, self.x, self.y)    
				end
			end,
			format = function(self)
				return self:prettyFormat():gsub('___', '\031')
			end,
			prettyFormat = function(self)
				local relativeFrameName = (self.relativeFrame and self.relativeFrame.GetName) and self.relativeFrame:GetName() or self.relativeFrame 
				return string.format('%s___%s___%s___%d___%d', self.point, relativeFrameName, self.relativePoint, addon:round(self.x), addon:round(self.y))
			end
		}
		self.metatables.getPointResultMetaTable.__index = self.metatables.getPointResultMetaTable
	end
	
    local result = setmetatable({}, self.metatables.getPointResultMetaTable)
	
	local point, relativeFrame, relativePoint, x, y = '', nil, '', 0, 0
	
	if type(frame) == 'string' then
		point, relativeFrame, relativePoint, x, y = string.split('\031', frame)
    else
		if frame and frame.GetPoint then
			point, relativeFrame, relativePoint, x, y = frame:GetPoint()
		end			
	end
	
	result.point = point
	result.relativeFrame = relativeFrame
	result.relativePoint = relativePoint
	result.x = x
	result.y = y
	result.frame = frame
	
    return result
end

function addon:round(number, decimalPlaces)
	if decimalPlaces and decimalPlaces > 0 then
		local mult = 10 ^ decimalPlaces
		return floor(number * mult + 0.5) / mult
	end
	return floor(number + 0.5)
end

function addon:shuffleBags()
	PickupContainerItem(0, 1);
	PickupContainerItem(1, 1);
	PickupContainerItem(2, 1);
	PickupContainerItem(3, 1);
	PickupContainerItem(4, 1);
	PickupContainerItem(4, 2);
	if CursorHasItem() then
		PickupContainerItem(0, 1);
	end
end

function addon:getItemInfoFromLink(itemLink)
	local result = {
		name = '',
		link = '',
		id = 0,
		str = '',
	};
	
	if not itemLink then
		return result;
	end
	local itemString = string.match(itemLink, "item[%-?%d:]+");
	if not itemString then
		return result;
	end
	local linkType, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId = strsplit(":", itemString);
	local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(itemId);
	
	return { 
			name = sName or '',
			link = sLink or '',
			id = tonumber(itemId) or 0,
			str = itemString or ''
		};
end

function addon:getItemInfoFromSlot(bag, slot)
	return self:getItemInfoFromLink(GetContainerItemLink(bag, slot));
end

function addon:getSpecNumber()
	local spec = GetSpecialization()
	if not spec then 
	    return 0
	end
	return GetSpecializationInfo(spec)
end

function addon:talentIndex(row, col)
	return ((row - 1) * 3) + col
end

function addon:talentSelected(row, col, info)
	local talentName, talentSelected = '', false
	info = info or {}

	if self:isWod() then
		local spellId, name, texture, selected = GetTalentInfo(row, col, GetActiveSpecGroup())
		talentName = name
		talentSelected = selected
	else
		local name, texture, tier, column, selected = GetTalentInfo(self:talentIndex(row, col))
		talentName = name
		talentSelected = selected
	end

	
	info.talentName = talentName or ''
	
	return talentSelected
end

function addon:glyphSelected(glyphItemName, socket, info)
	local socketStart = 1
	local socketEnd = 6
	info = info or {}

	if(socket or 0) > 0 then
		socketStart = socket
		socketEnd = socket
	end

	local selected = false
	
	for i = socketStart, socketEnd do
		local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon, glyphID = GetGlyphSocketInfo(i)

		if glyphSpellID then
			local name = GetSpellInfo(glyphSpellID)
			
			if name == glyphItemName then
				selected = true
				break
			end
		end
	end
 
	if not self.glyphList then
		self.glyphList = {}
		for i = 1, GetNumGlyphs() do
			local name, glyphType, isKnown, icon, castSpell, link = GetGlyphInfo(i)
			
			if link then
				local _, _, glyphName = string.find(link, "%[(.*)%]")
				self.glyphList[glyphName] = {icon = icon, spell = name}
			end
		end
	end

	return selected
end

function addon:tableIndexOfValue(tbl, value)
    for k, v in pairs(tbl or self.emptyTable) do
        if value == v then
            return k
        end
    end
	return 0
end

function addon:tableLength(tbl)
    local result = 0
    
    if type(tbl) == 'table' then
		for k, v in pairs(tbl) do
			result = result + 1
		end
	end
	
    return result
end

function addon:implode(tbl, glue)
    if type(tbl) ~= 'table' then
        return ''
    end
    
    local result = ''
    for k, v in pairs(tbl) do
        if result ~= '' then
            result = result .. glue    
        end
        
        result = result .. tostring(v)
    end
    return result
end

function addon:tableIsEmpty(tbl) 
    return not next(tbl or self.emptyTable)
end

function addon:tablePrint(tbl, linePrint, maxDepth, name, indent)
    local cart = ''    
    local autoref = {}
    local printStr
	
	local depth = 1
	maxDepth = maxDepth or 1
	
	if tbl == nil then
		return
	end
	
	self.callbacks.basicSerialize = self.callbacks.basicSerialize or function(obj)
		local so = tostring(obj)
        if type(obj) == "function" then
            if debug then
                local info = debug.getinfo(obj, "S")
                if info.what == "C" then
                    return string.format("%q", so .. ", C function")
                else 
                    return string.format("%q", so .. ", defined in (" .. info.linedefined .. "-" .. info.lastlinedefined .. ")" .. info.source)
                end
            else
                return string.format("%q", so .. ", hidden function")
            end
        elseif type(obj) == "number" or type(obj) == "boolean" then
            return so
		else
            return string.format("%q", so)
        end
    end
    
	local processTablePrint = nil
    processTablePrint = function(value, name, indent, saved, field)
        indent = indent or ""
        saved = saved or {}
        field = field or name
		
		local currentName = indent .. field
        
        if type(value) ~= "table" then
            printStr = currentName .. " = " .. addon.callbacks.basicSerialize(value) .. ";" 
            if linePrint then
                print(printStr)
            end
            cart = cart .. printStr .. '\n'
        else
            if saved[value] then
                printStr = currentName .. " = {}; -- " .. saved[value] .. " (self reference)"
                if linePrint then
                    print(printStr)
                end
                cart = cart .. printStr .. '\n'
                
				table.insert(autoref, name .. " = " .. saved[value] .. ";")
            else
                saved[value] = name
                if addon:tableIsEmpty(value) then
                    printStr = currentName .. " = {};"
                    if linePrint then
                        print(printStr)
                    end
                    cart = cart .. printStr .. '\n'
                else
					local getName = ''
					if type(value) == 'string' then
						getName = value
					else
						getName = value.GetName and value:GetName() or ''
					end
					
                    printStr = currentName .. '(' .. tostring(value) .. (getName ~= '' and (' - ' .. getName) or '') .. ')' .. " = {"
                    if linePrint then
                        print(printStr)
                    end
                    cart = cart .. printStr .. '\n'
					if depth <= maxDepth then
						depth = depth + 1
						for k, v in pairs(value) do
							k = addon.callbacks.basicSerialize(k)
							local fname = string.format("%s[%s]", name, k)
							field = string.format("[%s]", k)
							processTablePrint(v, fname, indent .. "   ", saved, field)
						end
						depth = depth - 1
					end
					
					printStr = indent .. "};"
                    if linePrint then
                        print(printStr)
                    end
                    cart = cart .. printStr .. '\n'
                end
            end
        end
    end
    
    name = name or "__unnamed__"
    if type(tbl) ~= "table" then
        printStr = name .. " = " .. self.callbacks.basicSerialize(tbl)
        if linePrint then
            print(printStr)
            return
        else
            return printStr
        end
    end
    
	processTablePrint(tbl, name, indent)
	
	local autorefTemp = ''
	
	for k, v in pairs(autoref) do
		if linePrint then
			print(v)
		else
			autorefTemp = autorefTemp .. v
		end
	end
	
    printStr = cart .. autorefTemp
    if not linePrint then
        return printStr
    end
end

function addon:GetDarkmoonDays()
	weekday, month, day, year = CalendarGetDate();
	result = {}
	start = day - weekday + 8;
	while start > 7 do
		start = 
		start - 7;
	end
	
	for i = start, start + 7 do
		table.insert(result, i)
	end
	
	return result;
end

function addon:IsDarkmoon()
	
	days = self:GetDarkmoonDays()
	weekday, month, day, year = CalendarGetDate()
	if day >= days[1] and day <= days[#days] then 
		hour, minute = GetGameTime()
		
		if day == days[#days] and hour >= 6 then 
			return false
		end
		return true
	end
	return false
end 