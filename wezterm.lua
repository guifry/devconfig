local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local sessions = wezterm.plugin.require("https://github.com/abidibo/wezterm-sessions")

config.leader = { key = "]", mods = "CTRL", timeout_milliseconds = 1000 }

config.unix_domains = { { name = "unix" } }
config.default_gui_startup_args = { "connect", "unix" }

config.keys = {
  { key = '"', mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "%", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

  { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "&", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
  { key = "{", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },

  { key = "w", mods = "LEADER", action = act.ShowTabNavigator },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },

  { key = "0", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "1", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(4) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(5) },
  { key = "6", mods = "LEADER", action = act.ActivateTab(6) },
  { key = "7", mods = "LEADER", action = act.ActivateTab(7) },
  { key = "8", mods = "LEADER", action = act.ActivateTab(8) },
  { key = "9", mods = "LEADER", action = act.ActivateTab(9) },

  { key = ",", mods = "LEADER", action = act.PromptInputLine({
    description = "Tab name:",
    action = wezterm.action_callback(function(window, pane, line)
      if line then window:active_tab():set_title(line) end
    end),
  }) },

  { key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
  { key = "$", mods = "LEADER", action = act.PromptInputLine({
    description = "Workspace name:",
    action = wezterm.action_callback(function(window, pane, line)
      if line then wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line) end
    end),
  }) },
  { key = "a", mods = "LEADER", action = act.AttachDomain("unix") },
  { key = "d", mods = "LEADER", action = act.DetachDomain({ DomainName = "unix" }) },

  { key = "S", mods = "LEADER|SHIFT", action = act({ EmitEvent = "save_session" }) },
  { key = "R", mods = "LEADER|SHIFT", action = act({ EmitEvent = "restore_session" }) },
  { key = "O", mods = "LEADER|SHIFT", action = act({ EmitEvent = "load_session" }) },
}

config.color_scheme = "GruvboxDark"
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.scrollback_lines = 10000

return config
