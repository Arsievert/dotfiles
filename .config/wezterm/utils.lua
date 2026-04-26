local wezterm = require("wezterm")

local M = {}

function M.is_emacs(pane)
    local process = pane:get_foreground_process_name()
    if process then
        return process:find("emacs") ~= nil or process:find("ssh") ~= nil
    end
    return false
end

-- Equalize panes along one axis. Groups panes that share a coordinate (e.g. same
-- top = same row), then adjusts one border toward the target size. Returns true if
-- an adjustment was made. Only one border can be moved per callback invocation, so
-- balance_panes calls this in a loop until everything converges.
local function equalize_axis(window, panes, group_key, sort_key, size_key, shrink_dir, grow_dir)
    local groups = {}
    for _, p in ipairs(panes) do
        local k = p[group_key]
        groups[k] = groups[k] or {}
        table.insert(groups[k], p)
    end
    for _, group in pairs(groups) do
        if #group < 2 then
            goto continue
        end
        table.sort(group, function(a, b) return a[sort_key] < b[sort_key] end)
        local total = 0
        for _, p in ipairs(group) do
            total = total + p[size_key]
        end
        local target = math.floor(total / #group)
        for i = 1, #group - 1 do
            local cumulative = 0
            for j = 1, i do
                cumulative = cumulative + group[j][size_key]
            end
            local diff = cumulative - i * target
            if diff > 1 or diff < -1 then
                group[i].pane:activate()
                local dir = diff > 0 and shrink_dir or grow_dir
                window:perform_action(
                    wezterm.action.AdjustPaneSize({ dir, math.abs(diff) }),
                    group[i].pane
                )
                return true
            end
        end
        ::continue::
    end
    return false
end

-- Emacs-style C-x = (balance-windows). Iteratively equalizes pane sizes
-- across rows (widths) and columns (heights). WezTerm only applies one
-- AdjustPaneSize per callback, so we loop and re-read sizes each iteration.
function M.balance_panes(window, pane)
    local tab = pane:tab()
    for _ = 1, 10 do
        local panes = tab:panes_with_info()
        if #panes < 2 then
            break
        end
        local adjusted = equalize_axis(window, panes, "top", "left", "width", "Left", "Right")
            or equalize_axis(window, panes, "left", "top", "height", "Up", "Down")
        if not adjusted then
            break
        end
    end
    pane:activate()
end

return M
