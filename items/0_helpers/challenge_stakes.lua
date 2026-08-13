local RB = rawget(_G, "RuleBender") or {}

RuleBender = RB
RB.challenge_stakes = RB.challenge_stakes or {}

local challenge_stakes = RB.challenge_stakes

challenge_stakes.progress_colours = {
    HEX("c7d6d9"),
    HEX("cc4846"),
    HEX("4d8276"),
    HEX("445457"),
    HEX("1685cb"),
    HEX("6059a0"),
    HEX("a66040"),
    HEX("f2c255"),
}

challenge_stakes.tiers = {
    {
        key = "stake_white",
        name = "White",
        backer_key = "default",
    },
    {
        key = "stake_red",
        name = "Red",
        backer_key = "red",
    },
    {
        key = "stake_green",
        name = "Green",
        backer_key = "green",
    },
    {
        key = "stake_black",
        name = "Black",
        backer_key = "black",
    },
    {
        key = "stake_blue",
        name = "Blue",
        backer_key = "blue",
    },
    {
        key = "stake_purple",
        name = "Purple",
        backer_key = "purple",
    },
    {
        key = "stake_orange",
        name = "Orange",
        backer_key = "orange",
    },
    {
        key = "stake_gold",
        name = "Gold",
        backer_key = "gold",
    },
}

challenge_stakes.backers = {
    {
        key = "default",
        name = "Challenge Deck",
        description = {
            "The default",
            "deck backer for",
            "Challenges",
        },
        tier = 1,
    },
    {
        key = "red",
        name = "Red Backer",
        tier = 2,
    },
    {
        key = "green",
        name = "Green Backer",
        tier = 3,
    },
    {
        key = "black",
        name = "Black Backer",
        tier = 4,
    },
    {
        key = "blue",
        name = "Blue Backer",
        tier = 5,
    },
    {
        key = "purple",
        name = "Purple Backer",
        tier = 6,
    },
    {
        key = "orange",
        name = "Orange Backer",
        tier = 7,
    },
    {
        key = "gold",
        name = "Gold Backer",
        tier = 8,
    },
}

local function normalise_tier_colour(colour)
    if type(colour) ~= "string" then
        return colour
    end

    local hex = colour:gsub("#", "")

    if type(HEX) == "function" and hex:match("^%x%x%x%x%x%x$") then
        return HEX(hex)
    end

    return nil
end

function challenge_stakes.get_tier_colour(tier_index)
    local tier = challenge_stakes.tiers[tier_index]

    if tier and tier.colour then
        return tier.colour
    end

    return challenge_stakes.progress_colours[tier_index]
        or (G and G.C and G.C.WHITE)
end

function challenge_stakes.register_reward_tier(definition)
    if type(definition) ~= "table" then
        return false
    end

    local stake_key = definition.stake_key
    local backer_definition = definition.backer

    if type(stake_key) ~= "string" or stake_key == ""
        or type(backer_definition) ~= "table"
        or type(backer_definition.key) ~= "string"
        or backer_definition.key == ""
        or not backer_definition.atlas
        or type(backer_definition.pos) ~= "table"
    then
        return false
    end

    for _, tier in ipairs(challenge_stakes.tiers) do
        if tier.key == stake_key then
            return false
        end
    end

    for _, backer in ipairs(challenge_stakes.backers) do
        if backer.key == backer_definition.key then
            return false
        end
    end

    local tier = {
        key = stake_key,
        name = definition.name or definition.stake_name or stake_key,
        backer_key = backer_definition.key,
        colour = normalise_tier_colour(definition.colour or backer_definition.colour),
    }
    local backer = {}

    for key, value in pairs(backer_definition) do
        backer[key] = value
    end

    backer.pos = {
        x = backer_definition.pos.x or 0,
        y = backer_definition.pos.y or 0,
    }
    backer.name = backer.name or tier.name .. " Backer"
    backer.tier = #challenge_stakes.tiers + 1

    challenge_stakes.tiers[#challenge_stakes.tiers + 1] = tier
    challenge_stakes.backers[#challenge_stakes.backers + 1] = backer

    return tier, backer
end

RB.register_challenge_stake_tier = challenge_stakes.register_reward_tier
RB.register_reward_tier = challenge_stakes.register_reward_tier
challenge_stakes.register_challenge_stake_tier = challenge_stakes.register_reward_tier

local function get_profile()
    if not G or not G.SETTINGS or not G.PROFILES then
        return nil
    end

    return G.PROFILES[G.SETTINGS.profile]
end

local function get_challenge_progress()
    local profile = get_profile()

    if not profile then
        return nil
    end

    profile.challenge_progress = profile.challenge_progress or {}
    profile.challenge_progress.completed = profile.challenge_progress.completed or {}
    profile.challenge_progress.rb_stakes = profile.challenge_progress.rb_stakes or {}
    profile.challenge_progress.rb_selected_stakes = profile.challenge_progress.rb_selected_stakes or {}
    profile.challenge_progress.rb_backer = profile.challenge_progress.rb_backer or "default"

    return profile.challenge_progress
end

local function get_stake_index(stake_key)
    local stake = G and G.P_STAKES and G.P_STAKES[stake_key]

    if stake then
        return stake.order
    end

    for index, candidate in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake) or {}) do
        if candidate.key == stake_key then
            return index
        end
    end

    return nil
end

function challenge_stakes.get_base_stake_index()
    for index, stake in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake) or {}) do
        if stake.key == "stake_white" or stake.key == "white" then
            return index
        end
    end

    return 1
end

function challenge_stakes.get_stake(index)
    return G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake and G.P_CENTER_POOLS.Stake[index]
end

function challenge_stakes.get_tier_index(stake_key)
    for index, tier in ipairs(challenge_stakes.tiers) do
        if tier.key == stake_key then
            return index
        end
    end

    return nil
end

function challenge_stakes.is_base_stake(stake_key)
    local base_stake = challenge_stakes.get_stake(challenge_stakes.get_base_stake_index())

    return base_stake and stake_key == base_stake.key
end

function challenge_stakes.is_stake_complete(challenge_id, stake_key)
    local progress = get_challenge_progress()

    if not progress or not challenge_id or not stake_key then
        return false
    end

    if challenge_stakes.is_base_stake(stake_key) then
        return progress.completed[challenge_id] == true
    end

    return progress.rb_stakes[challenge_id] and progress.rb_stakes[challenge_id][stake_key] == true
end

local function get_stake_pool_index(stake_key)
    for index, stake in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake) or {}) do
        if stake.key == stake_key then
            return index
        end
    end

    return nil
end

function challenge_stakes.get_highest_completed_stake_index(challenge_id)
    local progress = get_challenge_progress()

    if not progress or not challenge_id then
        return nil
    end

    local highest_index = nil
    local highest_rank = nil

    local function consider_stake(stake_key)
        local stake_index = get_stake_pool_index(stake_key)
        local stake = stake_index and challenge_stakes.get_stake(stake_index)

        if not stake then
            return
        end

        local stake_rank = stake.stake_level or stake.order or stake_index

        if not highest_rank
            or stake_rank > highest_rank
            or (stake_rank == highest_rank and stake_index > highest_index)
        then
            highest_index = stake_index
            highest_rank = stake_rank
        end
    end

    if progress.completed[challenge_id] then
        local base_stake = challenge_stakes.get_stake(challenge_stakes.get_base_stake_index())

        if base_stake then
            consider_stake(base_stake.key)
        end
    end

    for stake_key, completed in pairs(progress.rb_stakes[challenge_id] or {}) do
        if completed then
            consider_stake(stake_key)
        end
    end

    return highest_index
end

function challenge_stakes.are_stake_requirements_complete(challenge_id, stake)
    if not stake then
        return false
    end

    for _, required_stake_key in ipairs(stake.applied_stakes or {}) do
        if not challenge_stakes.is_stake_complete(challenge_id, required_stake_key) then
            return false
        end
    end

    return true
end

function challenge_stakes.is_stake_unlocked(challenge_id, stake)
    local profile = get_profile()

    if not challenge_id or not stake then
        return false
    end

    if profile and profile.all_unlocked then
        return true
    end

    if challenge_stakes.is_base_stake(stake.key) then
        return true
    end

    return challenge_stakes.are_stake_requirements_complete(challenge_id, stake)
end

function challenge_stakes.get_unlocked_stake_indexes(challenge_id)
    local indexes = {}

    for index, stake in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Stake) or {}) do
        if challenge_stakes.is_stake_unlocked(challenge_id, stake) then
            indexes[#indexes + 1] = index
        end
    end

    return indexes
end

function challenge_stakes.is_tier_complete(tier_index)
    local tier = challenge_stakes.tiers[tier_index]

    if not tier then
        return false
    end

    for _, challenge in ipairs((G and G.CHALLENGES) or {}) do
        if challenge.id and not challenge_stakes.is_stake_complete(challenge.id, tier.key) then
            return false
        end
    end

    return true
end

function challenge_stakes.is_gold_challenge_completion_complete()
    return challenge_stakes.is_tier_complete(challenge_stakes.get_tier_index("stake_gold"))
end

function challenge_stakes.is_completionist_plus_plus_complete()
    local achievement = G and G.ACHIEVEMENTS and G.ACHIEVEMENTS.completionist_plus_plus
    local earned = G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED

    return (achievement and achievement.earned == true)
        or (earned and earned.completionist_plus_plus == true)
end

local function get_next_uncompleted_stake_index(challenge_id, unlocked_indexes)
    for _, index in ipairs(unlocked_indexes) do
        local stake = challenge_stakes.get_stake(index)

        if stake and not challenge_stakes.is_stake_complete(challenge_id, stake.key) then
            return index
        end
    end

    return unlocked_indexes[#unlocked_indexes]
end

function challenge_stakes.get_selected_stake_index(challenge_id)
    local progress = get_challenge_progress()
    local unlocked_indexes = challenge_stakes.get_unlocked_stake_indexes(challenge_id)

    if not progress or #unlocked_indexes == 0 then
        return challenge_stakes.get_base_stake_index()
    end

    local selected_key = progress.rb_selected_stakes[challenge_id]
    local selected_index = get_stake_index(selected_key)

    for _, index in ipairs(unlocked_indexes) do
        if index == selected_index then
            return index
        end
    end

    return get_next_uncompleted_stake_index(challenge_id, unlocked_indexes)
end

function challenge_stakes.set_selected_stake_index(challenge_id, index)
    local progress = get_challenge_progress()
    local stake = challenge_stakes.get_stake(index)

    if not progress or not stake or not challenge_stakes.is_stake_unlocked(challenge_id, stake) then
        return false
    end

    progress.rb_selected_stakes[challenge_id] = stake.key

    if G and type(G.save_settings) == "function" then
        G:save_settings()
    end

    return true
end

function challenge_stakes.get_stake_name(index)
    local stake = challenge_stakes.get_stake(index)

    if not stake then
        return "Stake"
    end

    return localize({
        type = "name_text",
        key = stake.key,
        set = stake.set,
    })
end

function challenge_stakes.get_stake_preview(index)
    local stake_sprite = get_stake_sprite(index)

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.BLACK,
            r = 0.1,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0,
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = localize("k_stake"),
                            scale = 0.4,
                            colour = G.C.L_BLACK,
                            vert = true,
                        },
                    },
                },
            },
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0.1,
                },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = {
                            align = "cm",
                            padding = 0,
                        },
                        nodes = {
                            {
                                n = G.UIT.O,
                                config = {
                                    colour = G.C.BLUE,
                                    object = stake_sprite,
                                    hover = true,
                                    can_collide = false,
                                },
                            },
                        },
                    },
                    G.UIDEF.stake_description(index),
                },
            },
        },
    }
end

function challenge_stakes.stake_selection_ui(args)
    args = args or {}

    local challenge = G and G.CHALLENGES and G.CHALLENGES[args._id]
    local challenge_id = challenge and challenge.id
    local unlocked_indexes = challenge_stakes.get_unlocked_stake_indexes(challenge_id)
    local selected_index = challenge_stakes.get_selected_stake_index(challenge_id)
    local selected_option = 1

    for option, index in ipairs(unlocked_indexes) do
        if index == selected_index then
            selected_option = option
        end
    end

    local middle = {
        n = G.UIT.R,
        config = {
            align = "cm",
            minh = 1.7,
            minw = 7.3,
        },
        nodes = {
            {
                n = G.UIT.O,
                config = {
                    id = nil,
                    func = "rb_challenge_stake_preview",
                    object = Moveable(),
                    rb_challenge_id = challenge_id,
                },
            },
        },
    }

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.CLEAR,
            minh = 2.03,
            minw = 8.3,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    colour = G.C.L_BLACK,
                    padding = 0.15,
                    r = 0.1,
                    emboss = 0.05,
                },
                nodes = {
                    create_option_cycle({
                        options = unlocked_indexes,
                        opt_callback = "rb_change_challenge_stake",
                        current_option = selected_option,
                        colour = G.C.RED,
                        w = 6,
                        mid = middle,
                        rb_challenge_id = challenge_id,
                    }),
                },
            },
        },
    }
end

G.UIDEF.rb_challenge_stake = challenge_stakes.stake_selection_ui

G.FUNCS.rb_change_challenge_stake = function(args)
    if not args or not args.cycle_config or not args.to_val then
        return
    end

    local challenge_id = args.cycle_config.rb_challenge_id

    if challenge_id then
        challenge_stakes.set_selected_stake_index(challenge_id, args.to_val)
    end
end

G.FUNCS.rb_challenge_stake_preview = function(e)
    local challenge_id = e and e.config and e.config.rb_challenge_id
    local selected_index = challenge_stakes.get_selected_stake_index(challenge_id)

    if not selected_index or e.config.id == selected_index then
        return
    end

    if e.config.object then
        e.config.object:remove()
    end

    e.config.object = UIBox({
        definition = challenge_stakes.get_stake_preview(selected_index),
        config = {
            offset = {
                x = 0,
                y = 0,
            },
            align = "cm",
            parent = e,
        },
    })
    e.config.id = selected_index
end

function challenge_stakes.record_completion()
    if not G or not G.GAME or not G.GAME.challenge or G.GAME.rb_stake_completion_recorded then
        return
    end

    local challenge_id = G.GAME.challenge
    local stake = challenge_stakes.get_stake(G.GAME.stake)
    local progress = get_challenge_progress()

    if not stake or not progress then
        return
    end

    G.GAME.rb_stake_completion_recorded = true
    progress.rb_stakes[challenge_id] = progress.rb_stakes[challenge_id] or {}

    local applied_stakes = SMODS.build_stake_chain(stake) or {}

    for index in pairs(applied_stakes) do
        local applied_stake = challenge_stakes.get_stake(index)

        if applied_stake and not challenge_stakes.is_base_stake(applied_stake.key) then
            progress.rb_stakes[challenge_id][applied_stake.key] = true
        end
    end

    if not challenge_stakes.is_base_stake(stake.key) then
        progress.rb_stakes[challenge_id][stake.key] = true
    end

    if G and type(G.save_settings) == "function" then
        G:save_settings()
    end

    if type(check_for_unlock) == "function" then
        check_for_unlock({
            type = "rb_challenge_stakes",
        })
    end
end

function challenge_stakes.is_base_challenge(challenge)
    return challenge and challenge.mod == nil and challenge.original_mod == nil
end

function challenge_stakes.get_progress_stake_indexes()
    local indexes = {}
    local included_indexes = {}

    for _, tier in ipairs(challenge_stakes.tiers) do
        local index = get_stake_index(tier.key)

        if index and not included_indexes[index] then
            indexes[#indexes + 1] = index
            included_indexes[index] = true
        end
    end

    table.sort(indexes)

    return indexes
end

function challenge_stakes.get_progress()
    local progress = {
        tally = 0,
        of = 0,
    }
    local stake_indexes = challenge_stakes.get_progress_stake_indexes()
    local base_stake_index = challenge_stakes.get_base_stake_index()

    for _, challenge in ipairs((G and G.CHALLENGES) or {}) do
        if challenge.id then
            if get_challenge_progress() and get_challenge_progress().completed[challenge.id] then
                progress.tally = progress.tally + 1
            end

            for _, stake_index in ipairs(stake_indexes) do
                local stake = challenge_stakes.get_stake(stake_index)
                local include_stake = challenge_stakes.is_base_challenge(challenge) or stake_index ~= base_stake_index

                if include_stake and stake then
                    progress.of = progress.of + 1

                    if stake_index ~= base_stake_index and challenge_stakes.is_stake_complete(challenge.id, stake.key) then
                        progress.tally = progress.tally + 1
                    end
                end
            end
        end
    end

    return progress
end

function challenge_stakes.get_progress_colour(progress)
    if not progress or progress.of <= 0 then
        return challenge_stakes.get_tier_colour(1)
    end

    local tier_count = #challenge_stakes.tiers
    local stage = math.floor((progress.tally / progress.of) * tier_count) + 1

    stage = math.max(1, math.min(tier_count, stage))

    return challenge_stakes.get_tier_colour(stage)
end

function challenge_stakes.get_progress_row()
    local progress = challenge_stakes.get_progress()

    return {
        n = G.UIT.R,
        config = {
            align = "cm",
            minh = 0.8,
            r = 0.1,
            minw = 4.5,
            colour = G.C.L_BLACK,
            emboss = 0.05,
            progress_bar = {
                max = progress.of,
                ref_table = progress,
                ref_value = "tally",
                empty_col = G.C.L_BLACK,
                filled_col = challenge_stakes.get_progress_colour(progress),
            },
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0.05,
                    r = 0.1,
                    minw = 4.5,
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = progress.tally .. "/" .. progress.of .. " Completed with Stake",
                            scale = 0.3,
                            colour = G.C.WHITE,
                            shadow = true,
                        },
                    },
                },
            },
        },
    }
end

function challenge_stakes.get_backer(backer_key)
    for _, backer in ipairs(challenge_stakes.backers) do
        if backer.key == backer_key then
            return backer
        end
    end

    return challenge_stakes.backers[1]
end

function challenge_stakes.is_backer_unlocked(backer)
    local profile = get_profile()

    if not backer then
        return false
    end

    if profile and profile.all_unlocked then
        return true
    end

    return backer.tier == 1 or challenge_stakes.is_tier_complete(backer.tier)
end

function challenge_stakes.get_selected_backer()
    local progress = get_challenge_progress()
    local backer = challenge_stakes.get_backer(progress and progress.rb_backer)

    if challenge_stakes.is_backer_unlocked(backer) then
        return backer
    end

    return challenge_stakes.backers[1]
end

function challenge_stakes.set_selected_backer(backer_key)
    local progress = get_challenge_progress()
    local backer = challenge_stakes.get_backer(backer_key)

    if not progress or not challenge_stakes.is_backer_unlocked(backer) then
        return false
    end

    progress.rb_backer = backer.key

    if G and type(G.save_settings) == "function" then
        G:save_settings()
    end

    return true
end

function challenge_stakes.get_backer_description(backer)
    if backer.description then
        return backer.description
    end

    local tier = challenge_stakes.tiers[backer.tier]

    return {
        "A reward for",
        "completing Challenges",
        "at " .. tier.name .. " Stake",
    }
end

function challenge_stakes.get_backer_unlock_description(backer)
    if backer.unlock_description then
        return backer.unlock_description
    end

    local fraction = tostring(backer.tier) .. "/" .. tostring(#challenge_stakes.tiers) .. "ths"

    if backer.tier == 1 then
        fraction = "1/" .. tostring(#challenge_stakes.tiers) .. "th"
    end

    return {
        "Complete " .. fraction,
        "of all Stake Challenges",
    }
end

function challenge_stakes.get_backer_sprite_info(backer)
    local atlas_key = "centers"
    local pos = {
        x = 0,
        y = 0,
    }

    if not backer or backer.key == "default" then
        pos = {
            x = 0,
            y = 4,
        }
    elseif backer.atlas then
        atlas_key = backer.atlas
        pos = backer.pos or pos
    else
        atlas_key = "rb_challenge_" .. backer.key
    end

    local atlas = type(atlas_key) == "table"
        and atlas_key
        or (G and G.ASSET_ATLAS and G.ASSET_ATLAS[atlas_key])

    if not atlas then
        atlas_key = "centers"
        pos = {
            x = 0,
            y = 4,
        }
    end

    return atlas_key, pos
end

function challenge_stakes.apply_gold_backer_shader(sprite)
    sprite.draw = function(current_sprite)
        current_sprite.ARGS.send_to_shader = current_sprite.ARGS.send_to_shader or {}
        current_sprite.ARGS.send_to_shader[1] = math.min(current_sprite.VT.r * 3, 1)
            + G.TIMERS.REAL / 18
            + (current_sprite.juice and current_sprite.juice.r * 20 or 0)
            + 1
        current_sprite.ARGS.send_to_shader[2] = G.TIMERS.REAL

        Sprite.draw_shader(current_sprite, "dissolve")
        Sprite.draw_shader(current_sprite, "voucher", nil, current_sprite.ARGS.send_to_shader)
    end
end

function challenge_stakes.set_backer_sprite(card, backer)
    if not card or not card.children then
        return
    end

    local atlas_key, pos = challenge_stakes.get_backer_sprite_info(backer)
    local atlas = type(atlas_key) == "table"
        and atlas_key
        or (G and G.ASSET_ATLAS and G.ASSET_ATLAS[atlas_key])

    if not atlas then
        return
    end

    if card.children.back then
        card.children.back:remove()
    end

    card.children.back = Sprite(card.T.x, card.T.y, card.T.w, card.T.h, atlas, pos)
    card.children.back.states.hover = card.states.hover
    card.children.back.states.click = card.states.click
    card.children.back.states.drag = card.states.drag
    card.children.back.states.collide.can = false
    card.children.back:set_role({
        major = card,
        role_type = "Glued",
        draw_major = card,
    })

    if backer and (backer.key == "gold" or backer.shiny) then
        challenge_stakes.apply_gold_backer_shader(card.children.back)
    end
end

function challenge_stakes.clear_backer_area(area)
    if not area or not area.cards then
        return
    end

    for card_index = #area.cards, 1, -1 do
        local card = area:remove_card(area.cards[card_index])

        if card then
            card:remove()
        end
    end
end

function challenge_stakes.populate_backer_area(area, backer)
    if not area or area.REMOVED or not area.cards then
        return
    end

    local _, pos = challenge_stakes.get_backer_sprite_info(backer)

    challenge_stakes.clear_backer_area(area)

    for card_index = 1, 10 do
        local card = Card(
            area.T.x,
            area.T.y,
            G.CARD_W,
            G.CARD_H,
            pseudorandom_element(G.P_CARDS),
            G.P_CENTERS.c_base,
            {
                playing_card = card_index,
                bypass_back = pos,
                galdur_selector = true,
            }
        )

        card.sprite_facing = "back"
        card.facing = "back"
        challenge_stakes.set_backer_sprite(card, backer)
        area:emplace(card)
    end
end

function challenge_stakes.create_backer_area(backer)
    local area = CardArea(
        G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
        G.ROOM.T.h,
        G.CARD_W,
        G.CARD_H,
        {
            card_limit = 5,
            type = "deck",
            highlight_limit = 0,
            deck_height = 0.75,
            thin_draw = 1,
        }
    )

    challenge_stakes.populate_backer_area(area, backer)

    return area
end

function challenge_stakes.get_backer_description_ui(backer)
    local unlocked = challenge_stakes.is_backer_unlocked(backer)
    local description = unlocked
        and challenge_stakes.get_backer_description(backer)
        or challenge_stakes.get_backer_unlock_description(backer)
    local uses_default_description = not backer.description
    local description_nodes = {}

    for line_index, line in ipairs(description) do
        if unlocked and uses_default_description and backer.tier > 1 and line_index == #description then
            local tier = challenge_stakes.tiers[backer.tier]

            description_nodes[#description_nodes + 1] = {
                n = G.UIT.R,
                config = {
                    align = "cm",
                },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = {
                            align = "cm",
                            padding = 0.03,
                        },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = "at",
                                    scale = 0.33,
                                    colour = G.C.UI.TEXT_DARK,
                                },
                            },
                        },
                    },
                    {
                        n = G.UIT.C,
                        config = {
                            align = "cm",
                            padding = 0.03,
                        },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = tier.name .. " Stake",
                                    scale = 0.33,
                                    colour = challenge_stakes.get_tier_colour(backer.tier),
                                },
                            },
                        },
                    },
                },
            }
        else
            description_nodes[#description_nodes + 1] = {
                n = G.UIT.R,
                config = {
                    align = "cm",
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = line,
                            scale = 0.33,
                            colour = G.C.UI.TEXT_DARK,
                        },
                    },
                },
            }
        end
    end

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.CLEAR,
        },
        nodes = description_nodes,
    }
end

function challenge_stakes.get_backer_name_ui(backer)
    local unlocked = challenge_stakes.is_backer_unlocked(backer)

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            colour = G.C.CLEAR,
        },
        nodes = {
            {
                n = G.UIT.O,
                config = {
                    object = DynaText({
                        string = {
                            unlocked and backer.name or localize("k_locked"),
                        },
                        maxw = 4,
                        colours = {
                            G.C.WHITE,
                        },
                        shadow = true,
                        bump = true,
                        scale = 0.5,
                        pop_in = 0,
                        silent = true,
                    }),
                },
            },
        },
    }
end

function challenge_stakes.get_backer_preview(backer, area)
    return {
        n = G.UIT.R,
        config = {
            align = "cm",
            minh = 3.3,
            minw = 5,
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    colour = G.C.BLACK,
                    padding = 0.15,
                    r = 0.1,
                    emboss = 0.05,
                },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = {
                            align = "cm",
                        },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = {
                                    align = "cm",
                                    shadow = false,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.O,
                                        config = {
                                            object = area,
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        n = G.UIT.C,
                        config = {
                            align = "cm",
                            minw = 4,
                            maxw = 4,
                            minh = 1.7,
                            r = 0.1,
                            colour = G.C.L_BLACK,
                            padding = 0.1,
                        },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = {
                                    align = "cm",
                                    r = 0.1,
                                    minw = 4,
                                    maxw = 4,
                                    minh = 0.6,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.O,
                                        config = {
                                            id = backer.key,
                                            func = "rb_challenge_backer_name",
                                            object = UIBox({
                                                definition = challenge_stakes.get_backer_name_ui(backer),
                                                config = {
                                                    offset = {
                                                        x = 0,
                                                        y = 0,
                                                    },
                                                },
                                            }),
                                        },
                                    },
                                },
                            },
                            {
                                n = G.UIT.R,
                                config = {
                                    align = "cm",
                                    colour = G.C.WHITE,
                                    minh = 1.7,
                                    r = 0.1,
                                },
                                nodes = {
                                    {
                                        n = G.UIT.O,
                                        config = {
                                            id = backer.key,
                                            func = "rb_challenge_backer_description",
                                            object = UIBox({
                                                definition = challenge_stakes.get_backer_description_ui(backer),
                                                config = {
                                                    offset = {
                                                        x = 0,
                                                        y = 0,
                                                    },
                                                },
                                            }),
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

function challenge_stakes.style_backer_pip_row(cycle)
    local cycle_container = cycle and cycle.nodes and cycle.nodes[1]
    local cycle_main = cycle_container and cycle_container.nodes and cycle_container.nodes[2]
    local pip_row = cycle_main and cycle_main.nodes and cycle_main.nodes[2]

    if pip_row and pip_row.config then
        pip_row.config.colour = G.C.L_BLACK
        pip_row.config.minw = 5
        pip_row.config.minh = 0.2
        pip_row.config.padding = 0.06
        pip_row.config.r = 0.1
        pip_row.config.emboss = 0.05
    end

    return cycle
end

function challenge_stakes.backer_selection_ui()
    local selected_backer = challenge_stakes.get_selected_backer()
    local current_option = 1
    local backer_keys = {}

    for index, backer in ipairs(challenge_stakes.backers) do
        backer_keys[index] = backer.key

        if backer.key == selected_backer.key then
            current_option = index
        end
    end

    challenge_stakes.viewed_backer_key = selected_backer.key
    local area = challenge_stakes.create_backer_area(selected_backer)
    local cycle = challenge_stakes.style_backer_pip_row(create_option_cycle({
        options = backer_keys,
        current_option = current_option,
        opt_callback = "rb_change_challenge_backer",
        colour = G.C.RED,
        w = 3.5,
        mid = challenge_stakes.get_backer_preview(selected_backer, area),
        rb_backer_area = area,
    }))

    return {
        n = G.UIT.R,
        config = {
            align = "cm",
            minh = 3.8,
        },
        nodes = {
            cycle,
        },
    }
end

G.FUNCS.rb_change_challenge_backer = function(args)
    if not args or not args.cycle_config or not args.to_val then
        return
    end

    local backer = challenge_stakes.get_backer(args.to_val)

    if backer then
        challenge_stakes.viewed_backer_key = backer.key
        challenge_stakes.populate_backer_area(args.cycle_config.rb_backer_area, backer)
        challenge_stakes.set_selected_backer(backer.key)
    end
end

G.FUNCS.rb_challenge_backer_name = function(e)
    local backer = challenge_stakes.get_backer(challenge_stakes.viewed_backer_key)

    if e.config.id == backer.key then
        return
    end

    if e.config.object then
        e.config.object:remove()
    end

    e.config.object = UIBox({
        definition = challenge_stakes.get_backer_name_ui(backer),
        config = {
            offset = {
                x = 0,
                y = 0,
            },
            align = "cm",
            parent = e,
        },
    })
    e.config.id = backer.key
end

G.FUNCS.rb_challenge_backer_description = function(e)
    local backer = challenge_stakes.get_backer(challenge_stakes.viewed_backer_key)

    if e.config.id == backer.key then
        return
    end

    if e.config.object then
        e.config.object:remove()
    end

    e.config.object = UIBox({
        definition = challenge_stakes.get_backer_description_ui(backer),
        config = {
            offset = {
                x = 0,
                y = 0,
            },
            align = "cm",
            parent = e,
        },
    })
    e.config.id = backer.key
end

if type(G.UIDEF.challenges) == "function" and not challenge_stakes.challenges_ui_hook_installed then
    challenge_stakes.challenges_ui_hook_installed = true

    local challenges_ui_ref = G.UIDEF.challenges

    function G.UIDEF.challenges(from_game_over)
        local definition = challenges_ui_ref(from_game_over)
        local profile = get_profile()
        local challenge_panel = definition and definition.nodes and definition.nodes[1]

        if profile and profile.challenges_unlocked and challenge_panel and challenge_panel.nodes then
            challenge_panel.nodes[#challenge_panel.nodes + 1] = challenge_stakes.get_progress_row()
            challenge_panel.nodes[#challenge_panel.nodes + 1] = challenge_stakes.backer_selection_ui()
        end

        return definition
    end
end

function challenge_stakes.get_challenge_stake_badge(challenge_id)
    local stake_index = challenge_stakes.get_highest_completed_stake_index(challenge_id)
    local stake_sprite = stake_index and type(get_stake_sprite) == "function"
        and get_stake_sprite(stake_index, 0.32)
        or nil

    return {
        n = G.UIT.C,
        config = {
            align = "cm",
            minw = 0.34,
            maxw = 0.34,
            padding = 0.01,
        },
        nodes = {
            stake_sprite and {
                n = G.UIT.O,
                config = {
                    object = stake_sprite,
                    hover = true,
                    can_collide = false,
                },
            },
        },
    }
end

local function resize_challenge_button(button)
    local button_container = button and button.nodes and button.nodes[1]
    local label_nodes = button_container and button_container.nodes

    for _, label_node in ipairs(label_nodes or {}) do
        if label_node.config then
            label_node.config.minw = 3.66
            label_node.config.maxw = 3.46
        end
    end
end

function challenge_stakes.add_challenge_list_badges(definition, page)
    local rows = definition and definition.nodes
    local page_index = tonumber(page) or 0
    local page_size = (G and G.CHALLENGE_PAGE_SIZE) or 10

    if not rows then
        return definition
    end

    for row_index, row in ipairs(rows) do
        local challenge_index = page_index * page_size + row_index
        local challenge = G and G.CHALLENGES and G.CHALLENGES[challenge_index]
        local badge = challenge_stakes.get_challenge_stake_badge(challenge and challenge.id)

        if row.nodes and #row.nodes > 2 then
            resize_challenge_button(row.nodes[2])
            table.insert(row.nodes, #row.nodes, badge)
        end
    end

    return definition
end

if type(G.UIDEF.challenge_list_page) == "function"
    and not challenge_stakes.challenge_list_page_hook_installed
then
    challenge_stakes.challenge_list_page_hook_installed = true

    local challenge_list_page_ref = G.UIDEF.challenge_list_page

    function G.UIDEF.challenge_list_page(page)
        local definition = challenge_list_page_ref(page)

        return challenge_stakes.add_challenge_list_badges(definition, page)
    end
end

local function get_challenge_scaling(challenge)
    local scaling = nil

    for _, rule in ipairs((challenge and challenge.rules and challenge.rules.custom) or {}) do
        if rule.id == "scaling" and type(rule.value) == "number" then
            scaling = rule.value
        end
    end

    return scaling
end

local function get_stake_scaling_increase()
    local increase = 0

    for _, stake_index in ipairs((G and G.GAME and G.GAME.applied_stakes) or {}) do
        local stake = challenge_stakes.get_stake(stake_index)

        if stake and (stake.key == "stake_green" or stake.key == "green"
            or stake.key == "stake_purple" or stake.key == "purple")
        then
            increase = increase + 1
        end
    end

    return increase
end

if Game and type(Game.start_run) == "function" and not challenge_stakes.scaling_hook_installed then
    challenge_stakes.scaling_hook_installed = true

    local game_start_run_ref = Game.start_run

    function Game:start_run(args)
        local selected_backer = args and args.challenge and challenge_stakes.get_selected_backer()

        if selected_backer then
            challenge_stakes.pending_backer_key = selected_backer.key
        end

        game_start_run_ref(self, args)

        if selected_backer and G and G.GAME and G.GAME.challenge then
            G.GAME.rb_challenge_backer = selected_backer.key
        end

        challenge_stakes.pending_backer_key = nil

        local challenge_scaling = get_challenge_scaling(args and args.challenge)

        if challenge_scaling and G and G.GAME and G.GAME.challenge then
            G.GAME.modifiers.scaling = challenge_scaling + get_stake_scaling_increase()
        end
    end
end

function challenge_stakes.get_saved_challenge_backer_key()
    local saved_game = G and G.SAVED_GAME
    local saved_state = saved_game and saved_game.GAME

    if saved_state and saved_state.challenge then
        return saved_state.rb_challenge_backer
    end

    return nil
end

if type(G.UIDEF.run_setup_option) == "function"
    and not challenge_stakes.run_setup_preview_hook_installed
then
    challenge_stakes.run_setup_preview_hook_installed = true

    local run_setup_option_ref = G.UIDEF.run_setup_option

    function G.UIDEF.run_setup_option(setup_type)
        local previous_context = challenge_stakes.continue_preview_context
        challenge_stakes.continue_preview_context = setup_type == "Continue"

        local success, output = pcall(run_setup_option_ref, setup_type)
        challenge_stakes.continue_preview_context = previous_context

        if not success then
            error(output, 0)
        end

        return output
    end
end

function challenge_stakes.get_card_backer_key(card)
    if not card or not card.playing_card or not G then
        return nil
    end

    local params = card.params or {}

    if params.sleeve_card then
        return nil
    end

    if params.viewed_back then
        if challenge_stakes.continue_preview_context then
            return challenge_stakes.get_saved_challenge_backer_key()
        end

        return nil
    end

    if card.back ~= "selected_back" then
        return nil
    end

    if G.GAME and G.GAME.challenge then
        return G.GAME.rb_challenge_backer or challenge_stakes.pending_backer_key
    end

    return nil
end

function challenge_stakes.apply_selected_backer_to_card(card)
    local backer_key = challenge_stakes.get_card_backer_key(card)

    if not backer_key or not card.children.back then
        return
    end

    challenge_stakes.set_backer_sprite(card, challenge_stakes.get_backer(backer_key))
end

if Card and type(Card.set_sprites) == "function" and not challenge_stakes.backer_card_hook_installed then
    challenge_stakes.backer_card_hook_installed = true

    local card_set_sprites_ref = Card.set_sprites

    function Card:set_sprites(center, front)
        card_set_sprites_ref(self, center, front)
        challenge_stakes.apply_selected_backer_to_card(self)
    end
end

if type(G.FUNCS.start_challenge_run) == "function" and not challenge_stakes.start_run_hook_installed then
    challenge_stakes.start_run_hook_installed = true

    function G.FUNCS.start_challenge_run(e)
        local challenge = e and e.config and G.CHALLENGES[e.config.id]

        if not challenge then
            return
        end

        if G.OVERLAY_MENU then
            G.FUNCS.exit_overlay_menu()
        end

        local stake_index = challenge_stakes.get_selected_stake_index(challenge.id)

        G.FUNCS.start_run(e, {
            stake = stake_index,
            challenge = challenge,
        })
    end
end

if type(win_game) == "function" and not challenge_stakes.win_game_hook_installed then
    challenge_stakes.win_game_hook_installed = true

    local win_game_ref = win_game

    function win_game(...)
        win_game_ref(...)
        challenge_stakes.record_completion()
    end
end
