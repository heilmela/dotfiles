local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 16

-- ENABLE tab bar for status line
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false

config.colors = {
	foreground = "#CBE0F0",
	background = "#011423",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },

	-- Status bar colors
	tab_bar = {
		background = "#011423",
	},
}

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 10
config.status_update_interval = 2000

-- Replace the get_system_info function with this:
local function get_system_info()
	local success, stdout = wezterm.run_child_process({
		"sh",
		"-c",
		[[
			cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')
			mem=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages active:\s+(\d+)/ and printf("%.0f", $1 * $size / 1073741824);')
			top_proc=$(ps -Ao comm,%cpu -r | head -2 | tail -1 | awk '{print $1}' | xargs basename | cut -c1-15)
			top_cpu=$(ps -Ao %cpu -r | head -2 | tail -1 | awk '{printf "%.0f", $1}')

			echo "󰻠 ${cpu}% | 󰍛 ${mem}GB | 󰔟 ${top_proc} ${top_cpu}%"
		]],
	})

	if success then
		return stdout:gsub("\n", "")
	else
		return "󰀨 N/A"
	end
end

-- And update the status bar formatting:
wezterm.on("update-status", function(window, pane)
	local stat = get_system_info()
	local time = wezterm.strftime("󰥔 %H:%M")
	local date = wezterm.strftime("%a %d %b")

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#44FFB1" } },
		{ Text = " " .. stat .. " " },
		{ Foreground = { Color = "#666666" } },
		{ Text = "│" },
		{ Foreground = { Color = "#FFE073" } },
		{ Text = " " .. date .. " " },
		{ Foreground = { Color = "#0FC5ED" } },
		{ Text = time .. " " },
	}))
end)

config.keys = {
	{
		key = "LeftArrow",
		mods = "OPT",
		action = act.SendKey({ key = "b", mods = "ALT" }),
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = act.SendKey({ key = "f", mods = "ALT" }),
	},
	{
		key = "LeftArrow",
		mods = "CMD",
		action = act.SendKey({ key = "a", mods = "CTRL" }),
	},
	{
		key = "RightArrow",
		mods = "CMD",
		action = act.SendKey({ key = "e", mods = "CTRL" }),
	},
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("PrimarySelection"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.Nop,
	},
}

local ok, local_config = pcall(require, "wezterm_local")
if ok then
	local_config.apply(config, wezterm)
end

return config
