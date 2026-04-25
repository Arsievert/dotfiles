local wezterm = require("wezterm")

local M = {}

function M.is_emacs(pane)
    local process = pane:get_foreground_process_name()
    if process then
        return process:find("emacs") ~= nil
    end
    return false
end

function M.balance_panes(window, pane)
    local tab = pane:tab()
    local orig_pane = pane

    for _ = 1, 10 do
        local panes = tab:panes_with_info()
        if #panes < 2 then
            break
        end

        local adjusted = false

        local rows = {}
        for _, p in ipairs(panes) do
            rows[p.top] = rows[p.top] or {}
            table.insert(rows[p.top], p)
        end
        for _, row in pairs(rows) do
            if adjusted then
                break
            end
            if #row > 1 then
                table.sort(row, function(a, b) return a.left < b.left end)
                local total = 0
                for _, p in ipairs(row) do
                    total = total + p.width
                end
                local target = math.floor(total / #row)
                for i = 1, #row - 1 do
                    if adjusted then
                        break
                    end
                    local cumulative = 0
                    for j = 1, i do
                        cumulative = cumulative + row[j].width
                    end
                    local diff = cumulative - i * target
                    if diff > 1 then
                        row[i].pane:activate()
                        window:perform_action(
                            wezterm.action.AdjustPaneSize({ "Left", diff }),
                            row[i].pane
                        )
                        adjusted = true
                    elseif diff < -1 then
                        row[i].pane:activate()
                        window:perform_action(
                            wezterm.action.AdjustPaneSize({ "Right", -diff }),
                            row[i].pane
                        )
                        adjusted = true
                    end
                end
            end
        end

        if not adjusted then
            local cols = {}
            for _, p in ipairs(panes) do
                cols[p.left] = cols[p.left] or {}
                table.insert(cols[p.left], p)
            end
            for _, col in pairs(cols) do
                if adjusted then
                    break
                end
                if #col > 1 then
                    table.sort(col, function(a, b) return a.top < b.top end)
                    local total = 0
                    for _, p in ipairs(col) do
                        total = total + p.height
                    end
                    local target = math.floor(total / #col)
                    for i = 1, #col - 1 do
                        if adjusted then
                            break
                        end
                        local cumulative = 0
                        for j = 1, i do
                            cumulative = cumulative + col[j].height
                        end
                        local diff = cumulative - i * target
                        if diff > 1 then
                            col[i].pane:activate()
                            window:perform_action(
                                wezterm.action.AdjustPaneSize({ "Up", diff }),
                                col[i].pane
                            )
                            adjusted = true
                        elseif diff < -1 then
                            col[i].pane:activate()
                            window:perform_action(
                                wezterm.action.AdjustPaneSize({ "Down", -diff }),
                                col[i].pane
                            )
                            adjusted = true
                        end
                    end
                end
            end
        end

        if not adjusted then
            break
        end
    end

    orig_pane:activate()
end

return M
