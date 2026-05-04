local wezterm = require("wezterm")

local M = {}

function M.is_emacs(pane)
    local process = pane:get_foreground_process_name()
    if process then
        return process:find("emacs") ~= nil or process:find("ssh") ~= nil
    end
    return false
end

return M
