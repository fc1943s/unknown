local addonName, addonTable = ...

local addon = _uc.lib.AceAddon:NewAddon(addonName, "AceConsole-3.0")
_uc.summonnotifier = addon

local _, addonTitle, addonNotes, addonEnabled, addonLoadable, addonReason, addonSecurity = GetAddOnInfo(addonName)


function addon:OnInitialize()
	local MSQ = LibStub("Masque", true)
	if not MSQ then return end

	MSQ:AddSkin("ElvUI",{
		Author = "Stew UnknowN",
		Version = "5.4.0",
		Shape = "Square",
		Masque_Version = 40300,
		Backdrop = {
			Width = 34,
			Height = 34,
			Color = {1, 1, 1, 1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Backdrop]],
		},
		Icon = {
			Width = 34,
			Height = 34,
			TexCoords = {0.09,0.90,0.09,0.90}, -- Keeps the icon from showing its "silvery" edges.
		},
		Flash = {
			Width = 29,
			Height = 29,
			Color = {1, 0, 0, 1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Overlay]],
		},
		Cooldown = {
			Width = 34,
			Height = 34,
		},
		Pushed = {
			Width = 34,
			Height = 34,
			Color = {1, 1, 1, 1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Overlay]],
		},
		Normal = {
			Width = 36,
			Static = true,
			Height = 36,
			Color = {0, 0, 0, 1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Normal]],
		},
		Disabled = {
			Hide = true,
		},
		Checked = {
			Width = 35,
			Height = 35,
			BlendMode = "BLEND",
			Color = {1,1,1,1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Border]],
		},
		Border = {
			Width = 35,
			Height = 35,
			BlendMode = "ADD",
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Border]],
		},
		Gloss = {
			Width = 34,
			Height = 34,
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Gloss]],
		},
		AutoCastable = {
			Width = 34,
			Height = 34,
			Texture = [[Interface\Buttons\UI-AutoCastableOverlay]],
		},
		Highlight = {
			Width = 34,
			Height = 34,
			BlendMode = "ADD",
			Color = {1, 1, 1, 1},
			Texture = [[Interface\AddOns\UnknowN_MasqueSkinElvUI\Textures\Highlight]],
		},
		Name = {
			Width = 33,
			Height = 10,
			Color = {3, 3, 3, 0.6},
			Font = _uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME),
			OffsetY = 3,
		},
		Count = {
			Width = 40,
			Height = 10,
			OffsetX = -1,
			Font = _uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME),
			OffsetY = 3,
		},
		HotKey = {
			Width = 40,
			Height = 10,
			OffsetX = -4,
			FontSize = 6,
			Font = _uc.lib.LibSharedMedia:Fetch(_uc.lib.LibSharedMedia.MediaType.FONT, _uc.DEFAULT_FONT_NAME),
			OffsetY = -5,
		},
		Duration = {
			Width = 40,
			Height = 10,
			OffsetY = -2,
		},
		AutoCast = {
			Width = 36,
			Height = 36,
			OffsetX = 1,
			OffsetY = -1,
		},
	}, true)
end

function addon:OnEnable()
    self:Print("Enabled!")
end

function addon:OnDisable()
end