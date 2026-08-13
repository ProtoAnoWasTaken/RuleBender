G.C.RULE_BENDER = HEX("FDA200")

RuleBender = rawget(_G, "RuleBender") or {}

local RB = RuleBender
local mod = SMODS.current_mod

RB.mod = mod
RB.mod_path = mod.path
RB.item_sort_info_cache = RB.item_sort_info_cache or {}
RB.joker_categories = RB.joker_categories or {}

if type(loc_colour) == "function" and not RB.loc_colour_hook_installed then
    RB.loc_colour_hook_installed = true

    local loc_colour_ref = loc_colour

    function loc_colour(colour_key, default)
        if colour_key == "rule_bender" then
            return G.C.RULE_BENDER or default
        end

        return loc_colour_ref(colour_key, default)
    end
end

mod.optional_features = {
    retrigger_joker = true,
    post_trigger = true,
}

local filesystem = SMODS.NFS or love.filesystem

local function get_joker_category(relative_path)
    if relative_path:match("^items/joker/") then
        return "joker"
    end

    if relative_path:match("^items/factor/") then
        return "factor"
    end

    if relative_path:match("^items/agent/") then
        return "agent"
    end

    return nil
end

local function register_joker_categories(relative_path, file_path)
    local category = get_joker_category(relative_path)

    if not category or not RB.priority_organizer then
        return
    end

    for _, sort_info in ipairs(RB.priority_organizer.get_sort_infos(relative_path, file_path)) do
        if sort_info.object_type == "Joker" then
            RB.joker_categories[sort_info.key] = category
        end
    end
end

local function load_folder(relative_folder)
    local folder_path = RB.mod_path .. relative_folder

    if not filesystem.getInfo(folder_path) then
        return
    end

    local entries = filesystem.getDirectoryItems(folder_path)

    table.sort(entries, function(left, right)
        local left_relative_path = relative_folder .. "/" .. left
        local right_relative_path = relative_folder .. "/" .. right
        local left_path = RB.mod_path .. left_relative_path
        local right_path = RB.mod_path .. right_relative_path
        local left_info = filesystem.getInfo(left_path)
        local right_info = filesystem.getInfo(right_path)

        if left_info and right_info and left_info.type ~= right_info.type then
            return left_info.type == "directory"
        end

        if RB.priority_organizer and left_info and right_info
            and left_info.type == "file" and right_info.type == "file"
        then
            return RB.priority_organizer.compare_files(
                left_relative_path,
                left_path,
                right_relative_path,
                right_path
            )
        end

        return left:lower() < right:lower()
    end)

    for _, entry in ipairs(entries) do
        local relative_path = relative_folder .. "/" .. entry
        local entry_path = RB.mod_path .. relative_path
        local info = filesystem.getInfo(entry_path)

        if info and info.type == "directory" then
            load_folder(relative_path)
        elseif info and info.type == "file" and entry:lower():match("%.lua$") then
            register_joker_categories(relative_path, entry_path)

            local initializer, load_error = SMODS.load_file(relative_path)

            if initializer then
                local success, result = pcall(initializer)

                if not success then
                    sendErrorMessage("[Rule Bender] Error in " .. relative_path .. ": " .. tostring(result))
                end
            else
                sendErrorMessage("[Rule Bender] Failed to load " .. relative_path .. ": " .. tostring(load_error))
            end
        end
    end
end

load_folder("localization")
load_folder("items")

if RB.collection_sorter then
    RB.collection_sorter.install()
end
