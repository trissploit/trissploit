-- Minimal UI extracted from tsstrafeui (settings-only)

-- Services
local SoundService = game:GetService("SoundService")

-- Remote library loading
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(function()
	if readfile and isfile and isfile("library/library.lua") then
		return loadstring(readfile("library/library.lua"))()
	else
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/library.lua"))()
	end
end)
if not success or not Library then error("Failed to load Obsidian Library: " .. tostring(Library)) return end
Library.ForceCheckbox = true
local success2, ThemeManager = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/thememanager.lua"))() end)
if not success2 then ThemeManager = nil end

local success3, SaveManager = pcall(function() return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)
if not success3 then SaveManager = nil end

-- Window (compact)
local Window = Library:CreateWindow({
	Title = "tris.rocks",
	Footer = {"tris.rocks", "example", "v0.0-example"}, -- Array for cycling footers
	FooterCycleInterval = 3, -- Change footer every 3 seconds
	FooterFadeDuration = 0.5, -- 0.5 second fade transition
	Icon = "rbxassetid://85419017315177",
	CornerRadius = 0,
	Size = UDim2.fromOffset(520, 380),
	NotifySide = "Right",
	ShowCustomCursor = true,
	Compact = true
})

-- Options and Toggles
local Options = Library.Options
local Toggles = Library.Toggles

-- Tabs
local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Key = Window:AddKeyTab("Key System"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings")
}

-- Left Groupbox
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

-- Tabboxes example
--[[
local TabBox = Tabs.Main:AddLeftTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")
]]

-- Toggle with color pickers
LeftGroupBox:AddToggle("MyToggle", {
	Text = "This is a toggle",
	DisabledTooltip = "I am disabled!",
	Default = true,
	Disabled = false,
	Visible = true,
	Risky = false,
	Callback = function(Value)
		print("[cb] MyToggle changed to:", Value)
	end,
})
	:AddColorPicker("ColorPicker1", {
		Default = Color3.new(1, 0, 0),
		Title = "Some color1",
		Transparency = 0,
		Callback = function(Value)
			print("[cb] Color changed!", Value)
		end,
	})
	:AddColorPicker("ColorPicker2", {
		Default = Color3.new(0, 1, 0),
		Title = "Gradient example",
		Gradient = true,
		Transparency = true,
		Callback = function(Value)
			if type(Value) == "table" and Value.Stops then
				for i, s in ipairs(Value.Stops) do
					print(string.format("[cb] Stop %d: pos=%.3f color=%s transp=%.3f", i, tonumber(s.pos) or 0, tostring(s.color), tonumber(s.transparency) or 0))
				end
			else
				print("[cb] Color changed!", Value)
			end
		end,
	})

Toggles.MyToggle:OnChanged(function()
	print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

-- Checkbox
LeftGroupBox:AddToggle("MyCheckbox", {
	Text = "This is a checkbox",
	DisabledTooltip = "I am disabled!",
	Default = true,
	Disabled = false,
	Visible = true,
	Risky = false,
	Callback = function(Value)
		print("[cb] MyCheckbox changed to:", Value)
	end,
})

Toggles.MyCheckbox:OnChanged(function()
	print("MyCheckbox changed to:", Toggles.MyCheckbox.Value)
end)

-- Buttons
local MyButton = LeftGroupBox:AddButton({
	Text = "Button",
	Func = function()
		Library:Notify({
			Title = "Button",
			Description = "You clicked the main button!",
			Time = 4,
			IconName = "bell",
		})
	end,
	DoubleClick = false,
	Tooltip = "This is the main button",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
	Risky = false,
})

local MyButton2 = MyButton:AddButton({
	Text = "Sub button",
	Func = function()
		Library:Notify({
			Title = "Warning",
			Description = "This is a warning from the sub button.",
			Time = 6,
			Type = "warning",
			IconName = "alert-triangle",
		})
	end,
	DoubleClick = true,
	Tooltip = "This is the sub button",
	DisabledTooltip = "I am disabled!",
})

local MyDisabledButton = LeftGroupBox:AddButton({
	Text = "Disabled Button",
	Func = function()
		print("You somehow clicked a disabled button!")
	end,
	DoubleClick = false,
	Tooltip = "This is a disabled button",
	DisabledTooltip = "I am disabled!",
	Disabled = true,
})

local UnloadExampleButton = LeftGroupBox:AddButton({
	Text = "Unload",
	Func = function()
		Library:Unload()
	end,
	DoubleClick = false,
	Tooltip = "Unload the UI",
})

-- Labels
LeftGroupBox:AddLabel("This is a label")
LeftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)
LeftGroupBox:AddLabel("This is a label exposed to Labels", true, "TestLabel")
LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label made with table options and an index",
	DoesWrap = true,
})
LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label that doesn't wrap it's own text",
	DoesWrap = false,
})

-- Divider
LeftGroupBox:AddDivider()

-- Sliders
LeftGroupBox:AddSlider("MySlider", {
	Text = "This is my slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		print("[cb] MySlider was changed! New value:", Value)
	end,
	Tooltip = "I am a slider!",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
})

Options.MySlider:OnChanged(function()
	print("MySlider was changed! New value:", Options.MySlider.Value)
end)

LeftGroupBox:AddSlider("MySlider2", {
	Text = "This is my custom display slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 0,
	Compact = false,
	FormatDisplayValue = function(slider, value)
		if value == slider.Max then return 'Everything' end
		if value == slider.Min then return 'Nothing' end
		return tostring(value)
	end,
	Callback = function(Value)
		print("[cb] MySlider2 was changed! New value:", Value)
	end,
	Tooltip = "I am a custom display slider!",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
})

-- Textbox
LeftGroupBox:AddInput("MyTextbox", {
	Default = "My textbox!",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Text = "This is a textbox",
	Tooltip = "This is a tooltip",
	Placeholder = "Placeholder text",
	Callback = function(Value)
		print("[cb] Text updated. New text:", Value)
	end,
})

Options.MyTextbox:OnChanged(function()
	print("Text updated. New text:", Options.MyTextbox.Value)
end)

-- Right side - Dropdowns
local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = false,
	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

Options.MyDropdown:OnChanged(function()
	print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

DropdownGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "This", "is", "a", "searchable", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A searchable dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = true,
	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyDisplayFormattedDropdown", {
	Values = { "This", "is", "a", "formatted", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A display formatted dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	FormatDisplayValue = function(Value)
		if Value == "formatted" then
			return "display formatted"
		end
		return Value
	end,
	Searchable = false,
	Callback = function(Value)
		print("[cb] Display formatted dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

-- Multi dropdown
DropdownGroupBox:AddDropdown("MyMultiDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = true,
	Text = "A multi dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Multi dropdown got changed:")
		for key, value in next, Options.MyMultiDropdown.Value do
			print(key, value)
		end
	end,
})

Options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A disabled dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Callback = function(Value)
		print("[cb] Disabled dropdown got changed. New value:", Value)
	end,
	Disabled = true,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyDisabledValueDropdown", {
	Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" },
	DisabledValues = { "disabled" },
	Default = 1,
	Multi = false,
	Text = "A dropdown with disabled value",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Callback = function(Value)
		print("[cb] Dropdown with disabled value got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyVeryLongDropdown", {
	Values = {
		"This",
		"is",
		"a",
		"very",
		"long",
		"dropdown",
		"with",
		"a",
		"lot",
		"of",
		"values",
		"but",
		"you",
		"can",
		"see",
		"more",
		"than",
		"8",
		"values",
	},
	Default = 1,
	Multi = false,
	MaxVisibleDropdownItems = 12,
	Text = "A very long dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = false,
	Callback = function(Value)
		print("[cb] Very long dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyPlayerDropdown", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Text = "A player dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Player dropdown got changed:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", {
	SpecialType = "Team",
	Text = "A team dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Team dropdown got changed:", Value)
	end,
})

-- Color picker on label
LeftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0),
	Title = "Some color",
	Transparency = 0,
	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end,
})

Options.ColorPicker:OnChanged(function()
	print("Color changed!", Options.ColorPicker.Value)
	print("Transparency changed!", Options.ColorPicker.Transparency)
end)

-- Keybind
LeftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
	Default = "MB2",
	SyncToggleState = false,
	Mode = "Toggle",
	Text = "Auto lockpick safes",
	NoUI = false,
	Callback = function(Value)
		print("[cb] Keybind clicked!", Value)
	end,
	ChangedCallback = function(NewKey, NewModifiers)
		print("[cb] Keybind changed!", NewKey, table.unpack(NewModifiers or {}))
	end,
})

Options.KeyPicker:OnClick(function()
	print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
	print("Keybind changed!", Options.KeyPicker.Value, table.unpack(Options.KeyPicker.Modifiers or {}))
end)

task.spawn(function()
	while task.wait(1) do
		local state = Options.KeyPicker:GetState()
		if state then
			print("KeyPicker is being held down")
		end
		if Library.Unloaded then
			break
		end
	end
end)

-- Press keybind
local KeybindNumber = 0
LeftGroupBox:AddLabel("Press Keybind"):AddKeyPicker("KeyPicker2", {
	Default = "X",
	Mode = "Press",
	WaitForCallback = false,
	Text = "Increase Number",
	Callback = function()
		KeybindNumber = KeybindNumber + 1
		print("[cb] Keybind clicked! Number increased to:", KeybindNumber)
	end
})

-- Long text label
local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel(
	"This label spans multiple lines! We're gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!",
	true
)

-- Tabbox on right
local TabBox = Tabs.Main:AddRightTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

-- Unload callback
Library:OnUnload(function()
	print("Unloaded!")
end)

-- Key Tab
Tabs.Key:AddLabel({
	Text = "Key: Banana",
	DoesWrap = true,
	Size = 16,
})

Tabs.Key:AddKeyBox(function(ReceivedKey)
	local Success = ReceivedKey == "Banana"
	print("Expected Key: Banana - Received Key:", ReceivedKey, "| Success:", Success)
		Library:Notify({
			Title = "Expected Key: Banana",
			Description = "Received Key: " .. ReceivedKey .. "\nSuccess: " .. tostring(Success),
			Time = 4,
			IconName = Success and "check-circle" or "x-circle",
		})
end)

-- Draggable Label
Library:AddDraggableLabel("This is a Draggable Label")

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "UI Scale",
	Callback = function(Value)
		local scale = tonumber(Value:match("(%d+)%%")) / 100
		Library:SetDPIScale(scale)
	end,
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "End",
	NoUI = true,
	Text = "Menu keybind"
})

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Theme & Save setup
if ThemeManager then pcall(function()
	ThemeManager:SetLibrary(Library)
	ThemeManager:SetFolder("MyScriptHub")
	ThemeManager:ApplyToTab(Tabs["UI Settings"])
end) end

if SaveManager then pcall(function()
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
	SaveManager:SetFolder("MyScriptHub/specific-game")
	SaveManager:SetSubFolder("specific-place")
	SaveManager:BuildConfigSection(Tabs["UI Settings"])
	SaveManager:LoadAutoloadConfig()
end) end
