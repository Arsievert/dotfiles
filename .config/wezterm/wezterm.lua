-- WezTerm configuration

local wezterm = require("wezterm")
local utils = require("utils")
local pane_tree = require("pane-tree")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("Berkeley Mono")
config.font_size = 16.0
config.allow_square_glyphs_to_overflow_width = "Always"

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Mouse / URLs
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Tab bar
config.enable_tab_bar = false

-- Emacs-style keybindings with C-x (process-aware)
-- When emacs is running: C-x passes through to emacs
-- Otherwise: C-x activates WezTerm key table
config.keys = {
    {
        key = "x",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
                if utils.is_emacs(pane) then
                    -- Pass C-x through to emacs
                    window:perform_action(wezterm.action.SendKey({ key = "x", mods = "CTRL" }), pane)
                else
                    -- Activate WezTerm's key table for window management
                    window:perform_action(
                        wezterm.action.ActivateKeyTable({ name = "ctrl_x", one_shot = true, timeout_milliseconds = 1000 }),
                        pane
                    )
                end
        end),
    },
}

-- Key table for C-x commands (only active when NOT in emacs)
config.key_tables = {
    ctrl_x = {
        { key = "o", action = wezterm.action.ActivatePaneDirection("Next") },
        { key = "2", action = wezterm.action_callback(pane_tree.wrap_split("vertical")) },
        { key = "3", action = wezterm.action_callback(pane_tree.wrap_split("horizontal")) },
        { key = "0", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
        { key = "1", action = wezterm.action.TogglePaneZoomState },
        { key = "b", action = wezterm.action.ShowTabNavigator },
        { key = "k", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
        { key = "f", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
        { key = "=", action = wezterm.action_callback(pane_tree.balance) },
    },
}

-- Window
config.window_padding = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2,
}

-- Gruvbox Dark Color Scheme
config.colors = {
    foreground = "#ebdbb2",
    background = "#282828",
    cursor_fg = "#282828",
    cursor_bg = "#ebdbb2",
    cursor_border = "#ebdbb2",
    selection_fg = "#ebdbb2",
    selection_bg = "#928374",

    -- Tab bar colors
    tab_bar = {
        background = "#282828",
        active_tab = {
            bg_color = "#8ec07c",
            fg_color = "#282828",
        },
        inactive_tab = {
            bg_color = "#3c3836",
            fg_color = "#ebdbb2",
        },
        inactive_tab_hover = {
            bg_color = "#504945",
            fg_color = "#ebdbb2",
        },
        new_tab = {
            bg_color = "#3c3836",
            fg_color = "#ebdbb2",
        },
        new_tab_hover = {
            bg_color = "#504945",
            fg_color = "#ebdbb2",
        },
    },

    -- Normal colors (0-7)
    ansi = {
        "#282828", -- black
        "#cc241d", -- red
        "#98971a", -- green
        "#d79921", -- yellow
        "#458588", -- blue
        "#b16286", -- magenta
        "#689d6a", -- cyan
        "#a89984", -- white
    },

    -- Bright colors (8-15)
    brights = {
        "#928374", -- bright black
        "#fb4934", -- bright red
        "#b8bb26", -- bright green
        "#fabd2f", -- bright yellow
        "#83a598", -- bright blue
        "#d3869b", -- bright magenta
        "#8ec07c", -- bright cyan
        "#ebdbb2", -- bright white
    },
}

pane_tree.install()

return config
