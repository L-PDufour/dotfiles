local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Remove all GUI-specific settings for headless server
-- No front_end, font, or display configurations needed

-- Keep session management plugins
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- Unix domain for local multiplexer (recommended for same-machine usage)
config.unix_domains = {
	{
		name = "unix",
		socket_path = "/tmp/wezterm-mux-sock",
	},
}

-- Alternative: TCP domain for remote access
-- config.tcp_domains = {
--   {
--     name = "server",
--     host = "127.0.0.1",
--     port = 8080,
--   },
-- }

-- Default to multiplexer domain
config.default_domain = "unix"

-- Keep your key bindings (they work in multiplexer mode)
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

return config
