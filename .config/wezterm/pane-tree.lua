local wezterm = require("wezterm")

local M = {}
M._trees = {}
M._synthesized = {}

local function find_leaf(node, pane_id)
    if not node then return nil end
    if node.type == "leaf" then
        return node.pane_id == pane_id and node or nil
    end
    return find_leaf(node.first, pane_id) or find_leaf(node.second, pane_id)
end

local function collect_leaf_ids(node)
    if not node then return {} end
    if node.type == "leaf" then return { node.pane_id } end
    local ids = collect_leaf_ids(node.first)
    for _, id in ipairs(collect_leaf_ids(node.second)) do
        ids[#ids + 1] = id
    end
    return ids
end

local function count_leaves(node)
    if not node then return 0 end
    if node.type == "leaf" then return 1 end
    return count_leaves(node.first) + count_leaves(node.second)
end

local function tree_depth(node)
    if not node or node.type == "leaf" then return 0 end
    local d1 = tree_depth(node.first)
    local d2 = tree_depth(node.second)
    return 1 + (d1 > d2 and d1 or d2)
end

local function remove_leaf(root, pane_id)
    if not root then return nil end
    if root.type == "leaf" then
        return root.pane_id == pane_id and nil or root
    end
    local leaf = find_leaf(root, pane_id)
    if not leaf then return root end
    local parent = leaf.parent
    if not parent then return nil end
    local sibling = parent.first == leaf and parent.second or parent.first
    local grandparent = parent.parent
    sibling.parent = grandparent
    if not grandparent then return sibling end
    if grandparent.first == parent then
        grandparent.first = sibling
    else
        grandparent.second = sibling
    end
    return root
end

local function find_lca_impl(node, id1, id2)
    if not node or node.type == "leaf" then return nil end
    local in_first_1 = find_leaf(node.first, id1) ~= nil
    local in_first_2 = find_leaf(node.first, id2) ~= nil
    if in_first_1 and in_first_2 then return find_lca_impl(node.first, id1, id2) end
    if not in_first_1 and not in_first_2 then return find_lca_impl(node.second, id1, id2) end
    return node
end

local function collect_splits_bfs(root)
    if not root or root.type == "leaf" then return {} end
    local queue = { root }
    local result = {}
    local head = 1
    while head <= #queue do
        local node = queue[head]
        head = head + 1
        if node.type == "split" then
            result[#result + 1] = node
            if node.first.type == "split" then queue[#queue + 1] = node.first end
            if node.second.type == "split" then queue[#queue + 1] = node.second end
        end
    end
    return result
end

local function driver_for_split(node)
    if node.first.type == "leaf" then return node.first.pane_id end
    if node.second.type == "leaf" then return node.second.pane_id end
    return nil
end

local function synthesize_from_rects(panes)
    if #panes == 1 then
        return { type = "leaf", pane_id = panes[1].pane:pane_id(), parent = nil }
    end

    local function try_split(group, axis, coord_start, coord_end)
        local boundaries = {}
        for _, p in ipairs(group) do
            local edge = axis == "V" and (p.left + p.width) or (p.top + p.height)
            if edge > coord_start and edge < coord_end then
                boundaries[edge] = true
            end
        end
        for boundary in pairs(boundaries) do
            local first_group, second_group = {}, {}
            local valid = true
            for _, p in ipairs(group) do
                local start = axis == "V" and p.left or p.top
                local finish = start + (axis == "V" and p.width or p.height)
                if finish <= boundary then
                    first_group[#first_group + 1] = p
                elseif start >= boundary then
                    second_group[#second_group + 1] = p
                else
                    valid = false
                    break
                end
            end
            if valid and #first_group > 0 and #second_group > 0 then
                return first_group, second_group, axis
            end
        end
        return nil
    end

    local total_left = math.huge
    local total_top = math.huge
    local total_right = 0
    local total_bottom = 0
    for _, p in ipairs(panes) do
        if p.left < total_left then total_left = p.left end
        if p.top < total_top then total_top = p.top end
        local r = p.left + p.width
        local b = p.top + p.height
        if r > total_right then total_right = r end
        if b > total_bottom then total_bottom = b end
    end

    local first_group, second_group, axis
    first_group, second_group, axis = try_split(panes, "V", total_left, total_right)
    if not first_group then
        first_group, second_group, axis = try_split(panes, "H", total_top, total_bottom)
    end

    if not first_group then
        return { type = "leaf", pane_id = panes[1].pane:pane_id(), parent = nil }
    end

    local first_child = synthesize_from_rects(first_group)
    local second_child = synthesize_from_rects(second_group)
    local node = { type = "split", axis = axis, first = first_child, second = second_child, parent = nil }
    first_child.parent = node
    second_child.parent = node
    return node
end

local function ensure_tree(tab, tab_id)
    if M._trees[tab_id] then return end
    local panes = tab:panes_with_info()
    if #panes == 1 then
        M._trees[tab_id] = { type = "leaf", pane_id = panes[1].pane:pane_id(), parent = nil }
    else
        M._trees[tab_id] = synthesize_from_rects(panes)
        M._synthesized[tab_id] = true
    end
end

function M.wrap_split(direction)
    return function(window, pane)
        local tab = pane:tab()
        local tab_id = tab:tab_id()
        local source_id = pane:pane_id()

        if not M._trees[tab_id] then
            M._trees[tab_id] = { type = "leaf", pane_id = source_id, parent = nil }
        end

        local before = {}
        for _, p in ipairs(tab:panes_with_info()) do
            before[p.pane:pane_id()] = true
        end

        local action
        if direction == "vertical" then
            action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" })
        else
            action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" })
        end
        window:perform_action(action, pane)

        wezterm.time.call_after(0.05, function()
            local after_panes = tab:panes_with_info()
            local new_pane_id = nil
            for _, p in ipairs(after_panes) do
                local id = p.pane:pane_id()
                if not before[id] then
                    new_pane_id = id
                    break
                end
            end
            if not new_pane_id then return end

            local axis = direction == "horizontal" and "V" or "H"
            local leaf = find_leaf(M._trees[tab_id], source_id)
            if not leaf then return end

            local new_leaf = { type = "leaf", pane_id = new_pane_id, parent = nil }
            local source_leaf = { type = "leaf", pane_id = source_id, parent = nil }
            local split = {
                type = "split",
                axis = axis,
                first = source_leaf,
                second = new_leaf,
                parent = leaf.parent,
            }
            source_leaf.parent = split
            new_leaf.parent = split

            local parent = leaf.parent
            if not parent then
                M._trees[tab_id] = split
            elseif parent.first == leaf then
                parent.first = split
            else
                parent.second = split
            end
        end)
    end
end

function M.get_tree(tab_id)
    return M._trees[tab_id]
end

function M.find_lca(tab_id, id1, id2)
    return find_lca_impl(M._trees[tab_id], id1, id2)
end

function M.driver_for_split(tab_id, split_node)
    return driver_for_split(split_node)
end

function M.balance(window, pane)
    local tab = pane:tab()
    local tab_id = tab:tab_id()
    ensure_tree(tab, tab_id)

    local root = M._trees[tab_id]
    if not root or root.type == "leaf" then return end

    local max_iter = 2 * tree_depth(root) + 2
    for _ = 1, max_iter do
        local panes = tab:panes_with_info()
        if #panes < 2 then break end

        local pane_map = {}
        for _, p in ipairs(panes) do
            pane_map[p.pane:pane_id()] = p
        end

        local splits = collect_splits_bfs(root)
        local adjusted = false

        for _, split in ipairs(splits) do
            local driver_id = driver_for_split(split)
            if not driver_id then goto continue end

            local first_ids = collect_leaf_ids(split.first)
            local second_ids = collect_leaf_ids(split.second)
            local first_count = #first_ids
            local second_count = #second_ids

            local first_size = 0
            local second_size = 0
            for _, id in ipairs(first_ids) do
                local info = pane_map[id]
                if info then
                    first_size = first_size + (split.axis == "V" and info.width or info.height)
                end
            end
            for _, id in ipairs(second_ids) do
                local info = pane_map[id]
                if info then
                    second_size = second_size + (split.axis == "V" and info.width or info.height)
                end
            end

            local total = first_size + second_size
            if total == 0 then goto continue end
            local target_first = math.floor(total * first_count / (first_count + second_count))
            local diff = first_size - target_first

            if math.abs(diff) <= 1 then goto continue end

            local driver_pane = nil
            for _, p in ipairs(panes) do
                if p.pane:pane_id() == driver_id then
                    driver_pane = p.pane
                    break
                end
            end
            if not driver_pane then goto continue end

            local dir
            if split.axis == "V" then
                dir = diff > 0 and "Left" or "Right"
            else
                dir = diff > 0 and "Up" or "Down"
            end

            driver_pane:activate()
            window:perform_action(
                wezterm.action.AdjustPaneSize({ dir, math.abs(diff) }),
                driver_pane
            )
            adjusted = true
            break

            ::continue::
        end

        if not adjusted then break end
    end
    pane:activate()
end

function M.install()
    wezterm.on("update-status", function(window, pane)
        local tab = pane:tab()
        if not tab then return end
        local tab_id = tab:tab_id()
        local root = M._trees[tab_id]
        if not root then return end

        local live = {}
        for _, p in ipairs(tab:panes_with_info()) do
            live[p.pane:pane_id()] = true
        end

        local shadow_ids = collect_leaf_ids(root)
        for _, id in ipairs(shadow_ids) do
            if not live[id] then
                M._trees[tab_id] = remove_leaf(M._trees[tab_id], id)
                if not M._trees[tab_id] then break end
            end
        end
    end)
end

return M
