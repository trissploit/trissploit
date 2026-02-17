local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(clonefunction) == "function" then
    -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {}
do
    local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "AccentGradient" }
    ThemeManager.Folder = "ObsidianLibSettings"
    -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

    ThemeManager.Library = nil
    ThemeManager.AppliedToTab = false
    ThemeManager.BuiltInThemes = {
        ["Default"] = {
            1,
            { FontColor = "ffffff", MainColor = "0e0e0e", AccentColor = "ffffff", BackgroundColor = "111111", OutlineColor = "2f2f2f", AccentGradientStart = "ffffff", AccentGradientEnd = "868686", FontFace = "Code" },
        },
        ["BBot"] = {
            2,
            { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414", AccentGradientStart = "9e68c3", AccentGradientEnd = "5e2883" },
        },
        ["Fatality"] = {
            3,
            { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d", AccentGradientStart = "e52774", AccentGradientEnd = "a50034" },
        },
        ["Jester"] = {
            4,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737", AccentGradientStart = "fb6487", AccentGradientEnd = "bb2447" },
        },
        ["Mint"] = {
            5,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737", AccentGradientStart = "5dd4a8", AccentGradientEnd = "1d9468" },
        },
        ["Tokyo Night"] = {
            6,
            { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232", AccentGradientStart = "8779d3", AccentGradientEnd = "473993" },
        },
        ["Ubuntu"] = {
            7,
            { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919", AccentGradientStart = "ff783e", AccentGradientEnd = "c23800" },
        },
        ["Quartz"] = {
            8,
            { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f", AccentGradientStart = "628ea7", AccentGradientEnd = "224e67" },
        },
        ["Nord"] = {
            9,
            { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a", AccentGradientStart = "a8e0f0", AccentGradientEnd = "68a0b0" },
        },
        ["Dracula"] = {
            10,
            { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4", AccentGradientStart = "ff99e6", AccentGradientEnd = "df59a6" },
        },
        ["Monokai"] = {
            11,
            { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e", AccentGradientStart = "ff4692", AccentGradientEnd = "d90652" },
        },
        ["Gruvbox"] = {
            12,
            { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945", AccentGradientStart = "ff6954", AccentGradientEnd = "db2914" },
        },
        ["Solarized"] = {
            13,
            { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75", AccentGradientStart = "eb6b36", AccentGradientEnd = "ab2b00" },
        },
        ["Catppuccin"] = {
            14,
            { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268", AccentGradientStart = "ffe2ff", AccentGradientEnd = "d5a2c7" },
        },
        ["One Dark"] = {
            15,
            { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370", AccentGradientStart = "e698fd", AccentGradientEnd = "a658bd" },
        },
        ["Cyberpunk"] = {
            16,
            { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e", AccentGradientStart = "40ffbf", AccentGradientEnd = "00df7f" },
        },
        ["Oceanic Next"] = {
            17,
            { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46", AccentGradientStart = "86b9ec", AccentGradientEnd = "4679ac" },
        },
        ["Material"] = {
            18,
            { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242", AccentGradientStart = "a2caff", AccentGradientEnd = "628adf" },
        }
    }

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    --// Folders \\--
    function ThemeManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        paths[#paths + 1] = self.Folder .. "/themes"

        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then
                continue
            end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then
            return
        end
        self:BuildFolderTree()

        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    --// Apply, Update theme \\--
    function ThemeManager:ApplyTheme(theme)
        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]

        if not data then
            return
        end

        local scheme = data[2]
        for idx, val in pairs(customThemeData or scheme) do
            if idx == "VideoLink" then
                continue
            elseif idx == "FontFace" then
                self.Library:SetFont(Enum.Font[val])

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end

            elseif idx == "AccentGradient" then
                -- accept either a serialized gradient (table of stops) or a single color string
                if type(val) == "table" then
                    local stopsSrc = val.Stops or val
                    local parsed = {}
                    for _, s in ipairs(stopsSrc) do
                        local pos = math.clamp(tonumber((s and s.pos) or 0) or 0, 0, 1)
                        local color = s and s.color
                        if typeof(color) == "string" then
                            pcall(function() color = Color3.fromHex(color:gsub("#", "")) end)
                        end
                        if typeof(color) ~= "Color3" then
                            color = Color3.fromRGB(255, 255, 255)
                        end
                        local transp = math.clamp(tonumber((s and s.transparency) or 0) or 0, 0, 1)
                        table.insert(parsed, { pos = pos, color = color, transparency = transp })
                    end

                    table.sort(parsed, function(a, b) return a.pos < b.pos end)
                    if parsed[1].pos > 0 then table.insert(parsed, 1, { pos = 0, color = parsed[1].color, transparency = parsed[1].transparency }) end
                    if parsed[#parsed].pos < 1 then table.insert(parsed, { pos = 1, color = parsed[#parsed].color, transparency = parsed[#parsed].transparency }) end
                -- keep legacy start/end in sync for components still using them
                if parsed[1] and parsed[#parsed] then
                    self.Library.Scheme.AccentGradientStart = parsed[1].color
                    self.Library.Scheme.AccentGradientEnd = parsed[#parsed].color
                end

                    if self.Library.Options["AccentGradient"] then
                        local opt = self.Library.Options["AccentGradient"]
                        if type(opt.SetGradientStops) == "function" then
                            opt:SetGradientStops(parsed)
                        end
                        if type(opt.SetValueRGB) == "function" and parsed[1] then
                            opt:SetValueRGB(parsed[1].color, parsed[1].transparency or 0)
                        end
                    end

                elseif typeof(val) == "string" or typeof(val) == "Color3" then
                    local c = typeof(val) == "string" and Color3.fromHex(val) or val
                    self.Library.Scheme.AccentGradient = { Stops = { { pos = 0, color = c, transparency = 0 }, { pos = 1, color = c, transparency = 0 } } }

                    if self.Library.Options["AccentGradient"] then
                        local opt = self.Library.Options["AccentGradient"]
                        if type(opt.SetGradientStops) == "function" then
                            opt:SetGradientStops(self.Library.Scheme.AccentGradient.Stops)
                        end
                        if type(opt.SetValueRGB) == "function" then
                            opt:SetValueRGB(c, 0)
                        end
                    end
                end

            else
                self.Library.Scheme[idx] = Color3.fromHex(val)

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValueRGB(Color3.fromHex(val))
                end
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        for i, field in ThemeFields do
            if not (self.Library and self.Library.Options) then break end

            if field == "AccentGradient" then
                local opt = self.Library.Options["AccentGradient"]
                if opt and type(opt.GetGradientStops) == "function" then
                    local stops = opt:GetGradientStops()
                    self.Library.Scheme.AccentGradient = { Stops = stops }
                if stops[1] and stops[#stops] then
                    self.Library.Scheme.AccentGradientStart = stops[1].color
                    self.Library.Scheme.AccentGradientEnd = stops[#stops].color
                end
                else
                    -- fallback to a 2-stop gradient when picker API isn't available
                    if self.Library.Options["AccentGradient"] then
                        local v = self.Library.Options["AccentGradient"].Value
                        local col = (typeof(v) == "Color3") and v or (type(v) == "string" and Color3.fromHex(v) or self.Library.Scheme.AccentColor)
                        self.Library.Scheme.AccentGradient = { Stops = { { pos = 0, color = col, transparency = 0 }, { pos = 1, color = col, transparency = 0 } } }
                    end
                end
            else
                if self.Library.Options and self.Library.Options[field] then
                    self.Library.Scheme[field] = self.Library.Options[field].Value
                end
            end
        end

        self.Library:UpdateColorsUsingRegistry()
    end

    --// Get, Load, Save, Delete, Refresh \\--
    function ThemeManager:GetCustomTheme(file)
        local path = self.Folder .. "/themes/" .. file .. ".json"
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)

        if not success then
            return nil
        end

        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme = "Default"
        local content = isfile(self.Folder .. "/themes/default.txt") and readfile(self.Folder .. "/themes/default.txt")

        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        if isDefault then
            self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:SaveDefault(theme)
        writefile(self.Folder .. "/themes/default.txt", theme)
    end

    function ThemeManager:SetDefaultTheme(theme)
        assert(self.Library, "Must set ThemeManager.Library first!")
        assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

        local FinalTheme = {}
        local LibraryScheme = {}
        for _, field in ThemeFields do
            if field == "AccentGradient" then
                -- accept explicit serialized gradient (table) or fall back to start/end values
                if type(theme[field]) == "table" then
                    local stops = theme[field].Stops or theme[field]
                    local parsed = {}
                    for _, s in ipairs(stops) do
                        local pos = math.clamp(tonumber((s and s.pos) or 0) or 0, 0, 1)
                        local col = s and s.color
                        if typeof(col) == "string" then
                            pcall(function() col = Color3.fromHex(col:gsub("#", "")) end)
                        end
                        if typeof(col) ~= "Color3" then
                            col = Color3.fromRGB(255,255,255)
                        end
                        local transp = math.clamp(tonumber((s and s.transparency) or 0) or 0, 0, 1)
                        table.insert(parsed, { pos = pos, color = col, transparency = transp })
                    end

                    table.sort(parsed, function(a,b) return a.pos < b.pos end)
                    if parsed[1].pos > 0 then table.insert(parsed, 1, { pos = 0, color = parsed[1].color, transparency = parsed[1].transparency }) end
                    if parsed[#parsed].pos < 1 then table.insert(parsed, { pos = 1, color = parsed[#parsed].color, transparency = parsed[#parsed].transparency }) end

                    FinalTheme[field] = { Stops = {} }
                    for _, s in ipairs(parsed) do
                        table.insert(FinalTheme[field].Stops, { pos = s.pos, color = "#" .. s.color:ToHex(), transparency = s.transparency })
                    end

                    LibraryScheme.AccentGradient = { Stops = parsed }

                elseif typeof(theme["AccentGradientStart"]) == "string" or typeof(theme["AccentGradientStart"]) == "Color3" then
                    local s = typeof(theme["AccentGradientStart"]) == "string" and Color3.fromHex(theme["AccentGradientStart"]) or theme["AccentGradientStart"]
                    local e = typeof(theme["AccentGradientEnd"]) == "string" and Color3.fromHex(theme["AccentGradientEnd"]) or theme["AccentGradientEnd"]
                    FinalTheme["AccentGradientStart"] = "#" .. (s and s:ToHex() or "ffffff")
                    FinalTheme["AccentGradientEnd"] = "#" .. (e and e:ToHex() or "ffffff")
                    LibraryScheme.AccentGradient = { Stops = { { pos = 0, color = s or Color3.new(1,1,1), transparency = 0 }, { pos = 1, color = e or Color3.new(1,1,1), transparency = 0 } } }
                else
                    FinalTheme[field] = ThemeManager.BuiltInThemes["Default"][2][field]
                    -- default fallback uses built-in start/end
                    local sHex = ThemeManager.BuiltInThemes["Default"][2]["AccentGradientStart"]
                    local eHex = ThemeManager.BuiltInThemes["Default"][2]["AccentGradientEnd"]
                    local s = sHex and Color3.fromHex(sHex) or Color3.new(1,1,1)
                    local e = eHex and Color3.fromHex(eHex) or Color3.new(1,1,1)
                    LibraryScheme.AccentGradient = { Stops = { { pos = 0, color = s, transparency = 0 }, { pos = 1, color = e, transparency = 0 } } }
                end

            else
                if typeof(theme[field]) == "Color3" then
                    FinalTheme[field] = "#" .. theme[field]:ToHex()
                    LibraryScheme[field] = theme[field]

                elseif typeof(theme[field]) == "string" then
                    FinalTheme[field] = if theme[field]:sub(1, 1) == "#" then theme[field] else ("#" .. theme[field])
                    LibraryScheme[field] = Color3.fromHex(theme[field])

                else
                    FinalTheme[field] = ThemeManager.BuiltInThemes["Default"][2][field]
                    LibraryScheme[field] = Color3.fromHex(ThemeManager.BuiltInThemes["Default"][2][field])
                end
            end
        end

        if typeof(theme["FontFace"]) == "EnumItem" then
            FinalTheme["FontFace"] = theme["FontFace"].Name
            LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])

        elseif typeof(theme["FontFace"]) == "string" then
            FinalTheme["FontFace"] = theme["FontFace"]
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])

        else
            FinalTheme["FontFace"] = "Code"
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font.Code)
        end

        for _, field in { "Red", "Dark", "White" } do
            LibraryScheme[field] = self.Library.Scheme[field]
        end

        self.Library.Scheme = LibraryScheme
        self.BuiltInThemes["Default"] = { 1, FinalTheme }

        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(" ", "") == "" then
            self.Library:Notify("Invalid file name for theme (empty)", 3)
            return
        end

        local theme = {}
        for _, field in ThemeFields do
            if field == "AccentGradient" then
                local opt = self.Library.Options["AccentGradient"]
                if opt and type(opt.GetGradientStops) == "function" then
                    local stops = opt:GetGradientStops()
                    local ser = {}
                    for _, s in ipairs(stops) do
                        table.insert(ser, { pos = math.clamp(tonumber(s.pos) or 0, 0, 1), color = "#" .. (s.color and s.color:ToHex() or "ffffff"), transparency = math.clamp(tonumber(s.transparency) or 0, 0, 1) })
                    end
                    -- normalize saved stops: sort + ensure endpoints at 0 and 1
                    table.sort(ser, function(a, b) return a.pos < b.pos end)
                    if ser[1].pos > 0 then table.insert(ser, 1, { pos = 0, color = ser[1].color, transparency = ser[1].transparency }) end
                    if ser[#ser].pos < 1 then table.insert(ser, { pos = 1, color = ser[#ser].color, transparency = ser[#ser].transparency }) end
                    theme["AccentGradient"] = { Stops = ser }
                else
                    theme[field] = tostring(self.Library.Options[field].Value:ToHex())
                end
            else
                theme[field] = tostring(self.Library.Options[field].Value:ToHex())
            end
        end
        theme["FontFace"] = self.Library.Options["FontFace"].Value

        writefile(self.Folder .. "/themes/" .. file .. ".json", HttpService:JSONEncode(theme))
    end

    function ThemeManager:Delete(name)
        if not name then
            return false, "no config file is selected"
        end

        local file = self.Folder .. "/themes/" .. name .. ".json"
        if not isfile(file) then
            return false, "invalid file"
        end

        local success = pcall(delfile, file)
        if not success then
            return false, "delete file error"
        end

        return true
    end

    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. "/themes")

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                -- i hate this but it has to be done ...

                local pos = file:find(".json", 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= "/" and char ~= "\\" and char ~= "" do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == "/" or char == "\\" then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    --// GUI \\--
    function ThemeManager:CreateThemeManager(groupbox)
        groupbox
            :AddLabel("Background color")
            :AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
        groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
        groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
        groupbox
            :AddLabel("Outline color")
            :AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
        groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
        groupbox
            :AddLabel("Accent gradient")
            :AddColorPicker("AccentGradient", { Default = ((self.Library.Scheme and self.Library.Scheme.AccentGradient and self.Library.Scheme.AccentGradient.Stops and self.Library.Scheme.AccentGradient.Stops[1] and self.Library.Scheme.AccentGradient.Stops[1].color) or self.Library.Scheme.AccentColor), Gradient = true })
        -- if the library already has a stored multi-stop gradient, populate the picker with it
        if self.Library.Scheme and type(self.Library.Scheme.AccentGradient) == "table" and self.Library.Scheme.AccentGradient.Stops then
            local opt = self.Library.Options and self.Library.Options["AccentGradient"]
            if opt and type(opt.SetGradientStops) == "function" then
                opt:SetGradientStops(self.Library.Scheme.AccentGradient.Stops)
                -- also set the visible color to the first stop (fallback for picker default)
                if self.Library.Scheme.AccentGradient.Stops[1] and type(opt.SetValueRGB) == "function" then
                    local s = self.Library.Scheme.AccentGradient.Stops[1]
                    opt:SetValueRGB(s.color, s.transparency or 0)
                end
            end
        end
        groupbox:AddDropdown("FontFace", {
            Text = "Font Face",
            Default = "Code",
            Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans" },
        })

        -- Watermark controls
        groupbox:AddDivider()
        groupbox:AddToggle("Watermark", { Text = "Watermark", Default = self.Library.Watermark or false, Callback = function(v)
            self.Library:ToggleWatermark(v)
            self.Library.Watermark = v
            if getgenv then
                getgenv().watermark = v
            end
        end })
        groupbox:AddDropdown("WatermarkFields", { Text = "Watermark Settings", Values = { "Name", "FPS", "Ping", "Executor" }, Multi = true, Default = { "Name", "FPS", "Ping" }, Callback = function(v)
            local fields = { Name = false, FPS = false, Ping = false, Executor = false }
            if typeof(v) == "table" then
                for key, val in pairs(v) do
                    if typeof(key) == "string" then
                        fields[key] = true
                    elseif typeof(val) == "string" then
                        fields[val] = true
                    end
                end
            end
            if typeof(self.Library.SetWatermarkFields) == "function" then
                self.Library:SetWatermarkFields(fields)
            end
        end })

        local ThemesArray = {}
        for Name, Theme in pairs(self.BuiltInThemes) do
            table.insert(ThemesArray, Name)
        end

        table.sort(ThemesArray, function(a, b)
            return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
        end)

        groupbox:AddDivider()

        groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })
        groupbox:AddButton("Set as default", function()
            self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
            self.Library:Notify(
                string.format("Set default theme to %q", self.Library.Options.ThemeManager_ThemeList.Value)
            )
        end)

        self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
        end)

        groupbox:AddDivider()

        groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
        groupbox:AddButton("Create theme", function()
            local name = self.Library.Options.ThemeManager_CustomThemeName.Value

            if name:gsub(" ", "") == "" then
                self.Library:Notify("Invalid theme name (empty)", 2)
                return
            end

            self:SaveCustomTheme(name)

            self.Library:Notify(string.format("Created theme %q", name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        groupbox:AddDivider()

        groupbox:AddDropdown(
            "ThemeManager_CustomThemeList",
            { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
        )
        groupbox:AddButton("Load theme", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            self:ApplyTheme(name)
            self.Library:Notify(string.format("Loaded theme %q", name))
        end)
        groupbox:AddButton("Overwrite theme", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            self:SaveCustomTheme(name)
            self.Library:Notify(string.format("Overwrote config %q", name))
        end)
        groupbox:AddButton("Delete theme", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify("Failed to delete theme: " .. err)
                return
            end

            self.Library:Notify(string.format("Deleted theme %q", name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton("Refresh list", function()
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton("Set as default", function()
            if
                self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil
                and self.Library.Options.ThemeManager_CustomThemeList.Value ~= ""
            then
                self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                self.Library:Notify(
                    string.format("Set default theme to %q", self.Library.Options.ThemeManager_CustomThemeList.Value)
                )
            end
        end)
        groupbox:AddButton("Reset default", function()
            local success = pcall(delfile, self.Folder .. "/themes/default.txt")
            if not success then
                self.Library:Notify("Failed to reset default: delete file error")
                return
            end

            self.Library:Notify("Set default theme to nothing")
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        self:LoadDefault()
        self.AppliedToTab = true

        local function UpdateTheme()
            self:ThemeUpdate()
        end

        self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
        self.Library.Options.MainColor:OnChanged(UpdateTheme)
        self.Library.Options.AccentColor:OnChanged(UpdateTheme)
        self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
        self.Library.Options.FontColor:OnChanged(UpdateTheme)
        -- Update when gradient picker changes
        if self.Library.Options.AccentGradient then
            self.Library.Options.AccentGradient:OnChanged(function(Value)
                if type(Value) == "table" and Value.Stops then
                    self.Library.Scheme.AccentGradient = { Stops = Value.Stops }
                    if Value.Stops[1] and Value.Stops[#Value.Stops] then
                        self.Library.Scheme.AccentGradientStart = Value.Stops[1].color
                        self.Library.Scheme.AccentGradientEnd = Value.Stops[#Value.Stops].color
                    end
                elseif typeof(Value) == "Color3" then
                    local c = Value
                    self.Library.Scheme.AccentGradient = { Stops = { { pos = 0, color = c, transparency = 0 }, { pos = 1, color = c, transparency = 0 } } }
                    self.Library.Scheme.AccentGradientStart = c
                    self.Library.Scheme.AccentGradientEnd = c
                end
                self.Library:UpdateColorsUsingRegistry()
            end)
        end
        self.Library.Options.FontFace:OnChanged(function(Value)
            self.Library:SetFont(Enum.Font[Value])
            self.Library:UpdateColorsUsingRegistry()
        end)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        return tab:AddLeftGroupbox("Themes", "paintbrush")
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set ThemeManager.Library first!")
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
