local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Auto-detect environment
local is_gui = wezterm.target_triple:find("windows") or os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")
local hostname = wezterm.hostname() or "unknown"
local is_remote_server = hostname:find("server") or os.getenv("SSH_CONNECTION")

-- GUI-specific settings (only apply when running with GUI)
if is_gui then
	config.enable_wayland = true
	config.front_end = "WebGpu"
	config.webgpu_power_preference = "HighPerformance"
	config.window_background_opacity = 0.98
	config.font = wezterm.font("FiraCode NerdFont", { weight = "Medium" })
	config.font_size = 16.0
	config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
	config.freetype_load_target = "Normal"
	config.freetype_render_target = "Normal"
	config.use_fancy_tab_bar = false
	config.hide_tab_bar_if_only_one_tab = true
	config.tab_bar_at_bottom = false
	config.enable_tab_bar = true
	config.animation_fps = 60
	config.max_fps = 60
	config.color_scheme = "Catppuccin Frappe"
end

-- Load plugins (works in both GUI and headless)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- Universal settings
config.allow_win32_input_mode = false
config.term = "wezterm"
config.enable_csi_u_key_encoding = true
config.enable_kitty_keyboard = true

-- Unified domain configuration (same on both machines)
config.unix_domains = {
	{
		name = "unix",
		socket_path = "/tmp/wezterm-unix-" .. (os.getenv("USER") or "user"),
	},
}

-- SSH domains (configured on both machines for cross-connection)
config.ssh_domains = {
	{
		name = "desktop",
		remote_address = "192.168.50.100", -- Adjust to your desktop IP
		username = "desktop",
		assume_shell = "Posix",
		remote_wezterm_path = "/home/desktop/.nix-profile/bin/wezterm",
		multiplexing = "WezTerm",
	},
	{
		name = "server",
		remote_address = "192.168.50.101",
		username = "server",
		assume_shell = "Posix",
		remote_wezterm_path = "/home/server/.nix-profile/bin/wezterm",
		multiplexing = "WezTerm",
	},
}

-- Auto-detect default domain
if is_remote_server then
	config.default_domain = "local" -- Use local unix domain on server
else
	config.default_domain = is_gui and "local" or "local"
end

-- Unified key bindings (same on both machines)
config.keys = {
	-- Smart workspace switcher
	{
		key = "s",
		mods = "ALT",
		action = workspace_switcher.switch_workspace(),
	},

	-- Connect to desktop (works from both machines)
	{
		key = "1",
		mods = "ALT",
		action = wezterm.action_callback(function(window, pane)
			if is_remote_server then
				-- From server, connect to desktop
				window:perform_action(
					wezterm.action.SwitchToWorkspace({
						name = "desktop",
						spawn = { domain = { DomainName = "desktop" } },
					}),
					pane
				)
			else
				-- On desktop, switch to local workspace
				window:perform_action(wezterm.action.SwitchToWorkspace({ name = "local" }), pane)
			end
		end),
	},

	-- Connect to server (works from both machines)
	{
		key = "2",
		mods = "ALT",
		action = wezterm.action_callback(function(window, pane)
			if is_remote_server then
				-- On server, switch to local workspace
				window:perform_action(wezterm.action.SwitchToWorkspace({ name = "local" }), pane)
			else
				-- From desktop, connect to server
				window:perform_action(
					wezterm.action.SwitchToWorkspace({
						name = "server",
						spawn = { domain = { DomainName = "server" } },
					}),
					pane
				)
			end
		end),
	},

	-- Fuzzy launcher
	{
		key = "t",
		mods = "ALT",
		action = wezterm.action.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES|DOMAINS",
			title = "Workspaces & Domains",
		}),
	},

	-- Session save/restore (works everywhere)
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			local domain = pane:get_domain_name()
			local workspace = win:active_workspace()
			local state = resurrect.workspace_state.get_workspace_state()
			resurrect.save_state(state, {
				workspace_name = hostname .. "_" .. domain .. "_" .. workspace,
			})
		end),
	},
	{
		key = "W",
		mods = "ALT|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_load(win, pane, function(id, label)
				return label:find("^" .. hostname .. "_") ~= nil
			end)
		end),
	},

	-- Pane/tab management (universal)
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

	-- Navigation (universal)
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

	-- Copy/Paste (works in both GUI and terminal)
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- Plugin configuration (universal)
workspace_switcher.apply_to_config(config, {
	workspace_formatter = function(label)
		local domain_indicator = ""
		if is_remote_server then
			domain_indicator = "🖥️ "
		else
			domain_indicator = "💻 "
		end

		return wezterm.format({
			{ Attribute = { Italic = true } },
			{ Foreground = { Color = "#fab387" } },
			{ Text = domain_indicator .. "󱂬 " .. label },
		})
	end,
})

-- Universal event handlers
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local domain = tab.active_pane.domain_name
	local title = tab.tab_title and #tab.tab_title > 0 and tab.tab_title or tab.active_pane.title

	-- Add machine/domain indicators
	local prefix = ""
	if domain == "desktop" then
		prefix = "💻 "
	elseif domain == "server" then
		prefix = "🖥️ "
	elseif is_remote_server then
		prefix = "🖥️ "
	else
		prefix = "💻 "
	end

	return prefix .. title
end)

-- GUI-specific startup (only when GUI available)
if is_gui then
	wezterm.on("gui-startup", function(cmd)
		local _, _, window = wezterm.mux.spawn_window(cmd or {})
		window:gui_window():maximize()
	end)
end

-- Debug info (helpful for troubleshooting)
wezterm.log_info("WezTerm Config Loaded:")
wezterm.log_info("  Hostname: " .. hostname)
wezterm.log_info("  Is GUI: " .. tostring(is_gui))
wezterm.log_info("  Is Remote Server: " .. tostring(is_remote_server))
wezterm.log_info("  Default Domain: " .. config.default_domain)

return config
