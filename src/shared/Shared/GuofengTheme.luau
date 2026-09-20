--!strict
-- src/shared/GuofengTheme.luau
-- Xianxia RPG Design System (Dark Jade, Imperial Gold & Luminous Cyan)
-- Exactly modeled on the authentic Xianxia RPG development roadmap art style.

local TweenService = game:GetService("TweenService")

local GuofengTheme = {}

-- ============================================================================
-- 1. AUTHENTIC XIANXIA COLOR PALETTE
-- ============================================================================
GuofengTheme.Colors = {
	-- Deep Obsidian Jade Backgrounds (Roadmap Slate)
	DarkJadeBg       = Color3.fromRGB(10, 22, 19),   -- Deepest forest jade shadow
	DarkJadeCard     = Color3.fromRGB(15, 34, 29),   -- Main column / window slate
	DarkJadeElevated = Color3.fromRGB(22, 48, 41),   -- Raised modal card
	DarkJadeHeader   = Color3.fromRGB(18, 40, 35),   -- Category banner slate

	-- Imperial Gold & Bronze Filigree (Prominent Frame & Title Trim)
	GoldBorder       = Color3.fromRGB(214, 178, 68),  -- Classic Xianxia gold frame line
	GoldBorderDim    = Color3.fromRGB(142, 116, 44),  -- Subtle secondary border
	GoldLight        = Color3.fromRGB(250, 226, 140), -- Shimmering title highlight
	GoldDark         = Color3.fromRGB(164, 126, 36),  -- Burnished bronze edge
	CopperCoin       = Color3.fromRGB(212, 142, 62),  -- Ancient spirit coin
	GoldAmber        = Color3.fromRGB(228, 176, 48),  -- Warm amber warning tone

	-- Luminous Cyan Spiritual Qi (The Glowing Energy Stream & Orbs)
	CyanGlow         = Color3.fromRGB(66, 216, 186),  -- Vibrant spiritual Qi stream
	CyanBright       = Color3.fromRGB(132, 248, 228), -- Core node aura
	CyanDark         = Color3.fromRGB(32, 102, 88),   -- Deep energy trail
	CyanMist         = Color3.fromRGB(180, 246, 236), -- Translucent vapor

	-- Ivory & Ancient Parchment Sub-Cards (Technique Scrolls / Cards)
	ParchmentLight   = Color3.fromRGB(244, 240, 230), -- Technique card rice paper
	ParchmentBase    = Color3.fromRGB(235, 228, 214), -- Aged manuscript
	ParchmentDark    = Color3.fromRGB(218, 206, 186), -- Rolled scroll dowel tone

	-- Calligraphy Ink & Typography
	InkDark          = Color3.fromRGB(28, 24, 22),    -- Traditional brushed black ink
	InkMedium        = Color3.fromRGB(54, 46, 42),    -- Muted ink wash
	TextWhite        = Color3.fromRGB(244, 252, 248), -- High-contrast heading text
	TextMuted        = Color3.fromRGB(168, 196, 186), -- Secondary description text
	TextGold         = Color3.fromRGB(248, 224, 136), -- Milestone / Realm text

	-- Cinnabar & Vitality Crimson
	Cinnabar         = Color3.fromRGB(186, 46, 36),   -- Traditional red seal
	CinnabarHover    = Color3.fromRGB(214, 62, 50),
	Crimson          = Color3.fromRGB(184, 40, 46),   -- Vitality HP bar
	CrimsonDark      = Color3.fromRGB(112, 22, 26),

	-- Rarity Tones matching the Roadmap Nodes
	RarityCommon     = Color3.fromRGB(130, 150, 145), -- Cloud Stag / Common
	RarityUncommon   = Color3.fromRGB(66, 216, 186),  -- Cyan Qi Spirit
	RarityRare       = Color3.fromRGB(214, 178, 68),  -- Imperial Gold
	RarityEpic       = Color3.fromRGB(158, 88, 218),  -- Purple Thunder
	RarityLegendary  = Color3.fromRGB(255, 140, 40),  -- True Samadhi Fire
}

GuofengTheme.Fonts = {
	Title  = Enum.Font.GothamBlack,
	Header = Enum.Font.GothamBold,
	Body   = Enum.Font.GothamMedium,
	Script = Enum.Font.SourceSansBold,
}

-- ============================================================================
-- 2. FACTORY HELPERS MATCHING THE ROADMAP DESIGN
-- ============================================================================

--- Creates the signature Xianxia RPG Panel (Deep Jade slate + Double Gold border + Notched corner brackets)
function GuofengTheme.createXianxiaPanel(parent: Instance, size: UDim2, position: UDim2, title: string?, subtitle: string?): Frame
	local panel = Instance.new("Frame")
	panel.Name = "XianxiaPanel"
	panel.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
	panel.Size = size
	panel.Position = position
	panel.BorderSizePixel = 0
	panel.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	-- Outer Gold Rim
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = GuofengTheme.Colors.GoldBorder
	outerStroke.Thickness = 2.0
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outerStroke.Parent = panel

	-- Inner Delicate Green-Gold Trim Frame
	local innerTrim = Instance.new("Frame")
	innerTrim.Name = "InnerTrim"
	innerTrim.BackgroundTransparency = 1
	innerTrim.Position = UDim2.new(0, 5, 0, 5)
	innerTrim.Size = UDim2.new(1, -10, 1, -10)
	innerTrim.BorderSizePixel = 0
	innerTrim.Parent = panel

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 5)
	innerCorner.Parent = innerTrim

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = GuofengTheme.Colors.CyanGlow
	innerStroke.Thickness = 1.0
	innerStroke.Transparency = 0.65
	innerStroke.Parent = innerTrim

	-- Header Banner (Deep Jade Header Ribbon with Gold Border)
	if title and #title > 0 then
		local headerBanner = Instance.new("Frame")
		headerBanner.Name = "HeaderBanner"
		headerBanner.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
		headerBanner.Size = UDim2.new(1, -24, 0, subtitle and 46 or 38)
		headerBanner.Position = UDim2.new(0, 12, 0, 10)
		headerBanner.BorderSizePixel = 0
		headerBanner.Parent = panel

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = headerBanner

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = GuofengTheme.Colors.GoldBorderDim
		bStroke.Thickness = 1.2
		bStroke.Parent = headerBanner

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleText"
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 24)
		titleLabel.Position = UDim2.new(0, 0, 0, 2)
		titleLabel.Font = GuofengTheme.Fonts.Title
		titleLabel.Text = title
		titleLabel.TextColor3 = GuofengTheme.Colors.GoldLight
		titleLabel.TextSize = 15
		titleLabel.Parent = headerBanner

		if subtitle and #subtitle > 0 then
			local subLabel = Instance.new("TextLabel")
			subLabel.Name = "SubtitleText"
			subLabel.BackgroundTransparency = 1
			subLabel.Size = UDim2.new(1, 0, 0, 16)
			subLabel.Position = UDim2.new(0, 0, 0, 24)
			subLabel.Font = GuofengTheme.Fonts.Body
			subLabel.Text = subtitle
			subLabel.TextColor3 = GuofengTheme.Colors.CyanGlow
			subLabel.TextSize = 10
			subLabel.Parent = headerBanner
		end
	end

	return panel
end

--- Creates a Circular Luminous Cyan Technique Orb (The glowing nodes along the energy stream in the image)
function GuofengTheme.createGlowingCyanOrb(parent: Instance, sizePx: number, position: UDim2, keybind: string?): Frame
	local orb = Instance.new("Frame")
	orb.Name = "GlowingCyanOrb"
	orb.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
	orb.Size = UDim2.new(0, sizePx, 0, sizePx)
	orb.Position = position
	orb.BorderSizePixel = 0
	orb.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- Perfect Circle
	corner.Parent = orb

	-- Outer Glowing Cyan Aura Ring
	local outerGlow = Instance.new("UIStroke")
	outerGlow.Color = GuofengTheme.Colors.CyanGlow
	outerGlow.Thickness = 2.5
	outerGlow.Parent = orb

	-- Inner Gold Ring
	local innerRing = Instance.new("Frame")
	innerRing.Name = "InnerRing"
	innerRing.BackgroundTransparency = 1
	innerRing.Size = UDim2.new(1, -8, 1, -8)
	innerRing.Position = UDim2.new(0, 4, 0, 4)
	innerRing.BorderSizePixel = 0
	innerRing.Parent = orb

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = innerRing

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = GuofengTheme.Colors.GoldBorder
	innerStroke.Thickness = 1.0
	innerStroke.Transparency = 0.2
	innerStroke.Parent = innerRing

	-- Keybind badge on bottom-right
	if keybind and #keybind > 0 then
		local badge = Instance.new("Frame")
		badge.Name = "KeybindBadge"
		badge.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
		badge.Size = UDim2.new(0, 18, 0, 18)
		badge.Position = UDim2.new(1, -12, 1, -12)
		badge.BorderSizePixel = 0
		badge.ZIndex = 5
		badge.Parent = orb

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(1, 0)
		bCorner.Parent = badge

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = GuofengTheme.Colors.GoldBorder
		bStroke.Thickness = 1
		bStroke.Parent = badge

		local bLabel = Instance.new("TextLabel")
		bLabel.BackgroundTransparency = 1
		bLabel.Size = UDim2.new(1, 0, 1, 0)
		bLabel.Font = GuofengTheme.Fonts.Header
		bLabel.Text = keybind
		bLabel.TextColor3 = GuofengTheme.Colors.GoldLight
		bLabel.TextSize = 10
		bLabel.ZIndex = 6
		bLabel.Parent = badge
	end

	return orb
end

--- Creates a Dark Jade Sub-Card with Gold Border (unified dark theme for items/skills)
function GuofengTheme.createParchmentCard(parent: Instance, size: UDim2, position: UDim2): Frame
	local card = Instance.new("Frame")
	card.Name = "DarkJadeCard"
	card.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
	card.Size = size
	card.Position = position
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = GuofengTheme.Colors.GoldBorderDim
	stroke.Thickness = 1.2
	stroke.Parent = card

	return card
end

--- Maps item rarity to a themed accent color
function GuofengTheme.getRarityColor(rarity: string): Color3
	if rarity == "Common" then
		return GuofengTheme.Colors.RarityCommon
	elseif rarity == "Uncommon" then
		return GuofengTheme.Colors.RarityUncommon
	elseif rarity == "Rare" then
		return GuofengTheme.Colors.RarityRare
	elseif rarity == "Epic" then
		return GuofengTheme.Colors.RarityEpic
	elseif rarity == "Legendary" then
		return GuofengTheme.Colors.RarityLegendary
	end
	return GuofengTheme.Colors.TextMuted
end

--- Creates a Luminous Cyan Qi Progress Bar with Gold Border
function GuofengTheme.createXianxiaProgressBar(parent: Instance, size: UDim2, position: UDim2, barColor: Color3, labelText: string?): (Frame, Frame, TextLabel)
	local container = Instance.new("Frame")
	container.Name = "BarContainer"
	container.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
	container.Size = size
	container.Position = position
	container.BorderSizePixel = 0
	container.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = GuofengTheme.Colors.GoldBorderDim
	stroke.Thickness = 1.2
	stroke.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = barColor
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BorderSizePixel = 0
	fill.Parent = container

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = fill

	-- Cyan/Gold energy shimmer gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 235, 225)),
	})
	gradient.Rotation = 90
	gradient.Parent = fill

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = GuofengTheme.Fonts.Header
	text.Text = labelText or ""
	text.TextColor3 = GuofengTheme.Colors.TextWhite
	text.TextSize = 11
	text.ZIndex = 3
	text.Parent = container

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = GuofengTheme.Colors.DarkJadeBg
	textStroke.Thickness = 1.2
	textStroke.Parent = text

	return container, fill, text
end

--- Creates an Imperial Gold / Cinnabar Action Button with fine gold framing
function GuofengTheme.createXianxiaActionButton(parent: Instance, text: string, size: UDim2, position: UDim2, isCinnabar: boolean?): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "XianxiaActionBtn"
	btn.BackgroundColor3 = isCinnabar and GuofengTheme.Colors.Cinnabar or GuofengTheme.Colors.DarkJadeElevated
	btn.Size = size
	btn.Position = position
	btn.BorderSizePixel = 0
	btn.Font = GuofengTheme.Fonts.Title
	btn.Text = text
	btn.TextColor3 = GuofengTheme.Colors.GoldLight
	btn.TextSize = 14
	btn.AutoButtonColor = false
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = GuofengTheme.Colors.GoldBorder
	stroke.Thickness = 1.5
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = isCinnabar and GuofengTheme.Colors.CinnabarHover or GuofengTheme.Colors.CyanDark }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.18), { Color = GuofengTheme.Colors.CyanBright, Thickness = 2 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = isCinnabar and GuofengTheme.Colors.Cinnabar or GuofengTheme.Colors.DarkJadeElevated }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.18), { Color = GuofengTheme.Colors.GoldBorder, Thickness = 1.5 }):Play()
	end)

	return btn
end

--- Creates the Taiji Yin-Yang Spiritual Vortex with a Glowing Cyan Bagua boundary
function GuofengTheme.createTaijiVortex(parent: Instance, sizePx: number, position: UDim2): Frame
	local container = Instance.new("Frame")
	container.Name = "TaijiVortex"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(0, sizePx, 0, sizePx)
	container.Position = position
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Parent = parent

	-- Outer Glowing Cyan & Gold Aura Ring
	local outerRing = Instance.new("Frame")
	outerRing.Name = "OuterRing"
	outerRing.BackgroundTransparency = 1
	outerRing.Size = UDim2.new(1, 16, 1, 16)
	outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
	outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
	outerRing.Parent = container

	local oCorner = Instance.new("UICorner")
	oCorner.CornerRadius = UDim.new(1, 0)
	oCorner.Parent = outerRing

	local oStroke = Instance.new("UIStroke")
	oStroke.Color = GuofengTheme.Colors.CyanGlow
	oStroke.Thickness = 2.5
	oStroke.Parent = outerRing

	-- Spinning core disk
	local core = Instance.new("Frame")
	core.Name = "SpinCore"
	core.BackgroundColor3 = GuofengTheme.Colors.ParchmentLight
	core.Size = UDim2.new(1, 0, 1, 0)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.new(0.5, 0, 0.5, 0)
	core.BorderSizePixel = 0
	core.ClipsDescendants = true
	core.Parent = container

	local coreCorner = Instance.new("UICorner")
	coreCorner.CornerRadius = UDim.new(1, 0)
	coreCorner.Parent = core

	-- Dark Yin Half (right semicircle - Deep Obsidian Jade)
	local yinHalf = Instance.new("Frame")
	yinHalf.Name = "YinHalf"
	yinHalf.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
	yinHalf.Size = UDim2.new(0.5, 0, 1, 0)
	yinHalf.Position = UDim2.new(0.5, 0, 0, 0)
	yinHalf.BorderSizePixel = 0
	yinHalf.Parent = core

	-- Top White Yang Circle
	local topCircle = Instance.new("Frame")
	topCircle.Name = "TopYangCircle"
	topCircle.BackgroundColor3 = GuofengTheme.Colors.ParchmentLight
	topCircle.Size = UDim2.new(0.5, 0, 0.5, 0)
	topCircle.Position = UDim2.new(0.25, 0, 0, 0)
	topCircle.BorderSizePixel = 0
	topCircle.Parent = core

	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(1, 0)
	tcCorner.Parent = topCircle

	-- Dark Yin Eye inside Top White Circle
	local yinEye = Instance.new("Frame")
	yinEye.Name = "YinEye"
	yinEye.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
	yinEye.Size = UDim2.new(0.3, 0, 0.3, 0)
	yinEye.AnchorPoint = Vector2.new(0.5, 0.5)
	yinEye.Position = UDim2.new(0.5, 0, 0.5, 0)
	yinEye.BorderSizePixel = 0
	yinEye.Parent = topCircle

	local yeCorner = Instance.new("UICorner")
	yeCorner.CornerRadius = UDim.new(1, 0)
	yeCorner.Parent = yinEye

	-- Bottom Black Yin Circle
	local botCircle = Instance.new("Frame")
	botCircle.Name = "BotYinCircle"
	botCircle.BackgroundColor3 = GuofengTheme.Colors.DarkJadeBg
	botCircle.Size = UDim2.new(0.5, 0, 0.5, 0)
	botCircle.Position = UDim2.new(0.25, 0, 0.5, 0)
	botCircle.BorderSizePixel = 0
	botCircle.Parent = core

	local bcCorner = Instance.new("UICorner")
	bcCorner.CornerRadius = UDim.new(1, 0)
	bcCorner.Parent = botCircle

	-- White Yang Eye inside Bottom Black Circle
	local yangEye = Instance.new("Frame")
	yangEye.Name = "YangEye"
	yangEye.BackgroundColor3 = GuofengTheme.Colors.ParchmentLight
	yangEye.Size = UDim2.new(0.3, 0, 0.3, 0)
	yangEye.AnchorPoint = Vector2.new(0.5, 0.5)
	yangEye.Position = UDim2.new(0.5, 0, 0.5, 0)
	yangEye.BorderSizePixel = 0
	yangEye.Parent = botCircle

	local ygeCorner = Instance.new("UICorner")
	ygeCorner.CornerRadius = UDim.new(1, 0)
	ygeCorner.Parent = yangEye

	-- Gentle spiritual rotation
	task.spawn(function()
		local rot = 0
		while container and container.Parent do
			rot = (rot + 0.35) % 360
			core.Rotation = rot
			task.wait(0.03)
		end
	end)

	return container
end

return GuofengTheme
