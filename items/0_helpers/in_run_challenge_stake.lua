local RB = RuleBender

local function has_applied_challenge_stake()
    if not G
        or not G.GAME
        or not G.GAME.challenge
        or type(G.GAME.stake) ~= "number"
    then
        return false
    end

    local stakes = RB.challenge_stakes
    local get_base_stake_index = stakes and stakes.get_base_stake_index
    local base_stake_index = type(get_base_stake_index) == "function"
        and get_base_stake_index()
        or 1

    return G.GAME.stake ~= base_stake_index
end

local function challenge_deck_info_tabs(show_remaining)
    local tabs = {}

    if show_remaining then
        tabs[#tabs + 1] = {
            label = localize("b_remaining"),
            chosen = true,
            tab_definition_function = G.UIDEF.view_deck,
            tab_definition_function_args = true,
        }
        tabs[#tabs + 1] = {
            label = localize("b_full_deck"),
            tab_definition_function = G.UIDEF.view_deck,
        }
    else
        tabs[#tabs + 1] = {
            label = localize("b_full_deck"),
            chosen = true,
            tab_definition_function = G.UIDEF.view_deck,
        }
    end

    tabs[#tabs + 1] = {
        label = localize("b_stake"),
        tab_definition_function = G.UIDEF.current_stake,
    }

    return tabs
end

if type(G.UIDEF.deck_info) == "function" and not RB.challenge_deck_info_hook_installed then
    RB.challenge_deck_info_hook_installed = true

    local deck_info_ref = G.UIDEF.deck_info

    function G.UIDEF.deck_info(show_remaining)
        if not has_applied_challenge_stake() then
            return deck_info_ref(show_remaining)
        end

        return create_UIBox_generic_options({
            contents = {
                create_tabs({
                    tabs = challenge_deck_info_tabs(show_remaining),
                    tab_h = 8,
                    snap_to_nav = true,
                }),
            },
        })
    end
end
