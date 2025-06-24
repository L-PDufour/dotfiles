local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Performance optimizations for Wayland
config.enable_wayland = true
config.front_end = "WebGpu" -- Use GPU acceleration
config.webgpu_power_preference = "HighPerformance"

-- Reduce compositor overhead
config.window_background_opacity = 0.98 -- Remove transparency for better performance
-- Or if you need transparency, use a higher value like 0.98

-- Font optimizations
config.font = wezterm.font("FiraCode NerdFont", { weight = "Medium" })
config.font_size = 16.0
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" } -- Optimize ligatures
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"

-- Tab bar optimizations
config.use_fancy_tab_bar = false -- Simpler rendering
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- Reduce animation overhead
config.animation_fps = 60
config.max_fps = 60

-- Load plugins (consider caching these locally)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- SSH Configuration
config.ssh_domains = wezterm.default_ssh_domains()
for _, dom in ipairs(config.ssh_domains) do
	dom.assume_shell = "Posix"
end

-- Basic Configuration
config.color_scheme = "Catppuccin Frappe"
config.enable_tab_bar = true
config.unix_domains = {
	{
		name = "server",
		socket_path = "/tmp/wezterm-mux-sock",
		-- For remote servers, use:
		-- proxy_command = {"ssh", "your-server", "wezterm", "cli", "proxy"},
	},
}

-- Key binding to connect to server multiplexer

-- Key Bindings (keeping your existing ones)
config.keys = {
	-- Workspace Switcher Plugin
	{
		key = "s",
		mods = "ALT",
		action = workspace_switcher.switch_workspace(),
	},
	{
		key = "t",
		mods = "ALT",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},

	-- Session Management
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	},
	{
		key = "W",
		mods = "ALT|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.load_state(resurrect.workspace_state.get_workspace_state(), {
				relative = true,
				restore_text = true,
				on_pane_restore = resurrect.tab_state.default_on_pane_restore,
			})
		end),
	},
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "d",
		mods = "ALT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "D",
		mods = "ALT|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "h",
		mods = "ALT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "ALT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "ALT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "ALT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},

	-- Copy/Paste
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CopyTo("Clipboard"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- Plugin Configuration
workspace_switcher.apply_to_config(config, {
	workspace_formatter = function(label)
		return wezterm.format({
			{ Attribute = { Italic = true } },
			{ Foreground = { Color = "#fab387" } },
			{ Text = "󱂬 " .. label },
		})
	end,
})

-- Optimized Event Handlers
wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	return tab.tab_title and #tab.tab_title > 0 and tab.tab_title or tab.active_pane.title
end)

return config
