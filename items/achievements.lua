local achievement_definitions = {
    {
        key = "rule_breaker",
        name = "Rule Breaker",
        description = {
            "Complete all Challenges...",
            "on White Stake...",
        },
        tier = 1,
    },
    {
        key = "red_belt",
        name = "Red Belt",
        description = {
            "Complete all Challenges",
            "on Red Stake",
        },
        tier = 2,
    },
    {
        key = "green_belt",
        name = "Green Belt",
        description = {
            "Complete all Challenges",
            "on Green Stake",
        },
        tier = 3,
    },
    {
        key = "black_belt",
        name = "Black Belt",
        description = {
            "Complete all Challenges",
            "on Black Stake",
        },
        tier = 4,
    },
    {
        key = "blue_belt",
        name = "Blue Belt",
        description = {
            "Complete all Challenges",
            "on Blue Stake",
        },
        tier = 5,
    },
    {
        key = "purple_belt",
        name = "Purple Belt",
        description = {
            "Complete all Challenges",
            "on Purple Stake",
        },
        tier = 6,
    },
    {
        key = "orange_belt",
        name = "Orange Belt",
        description = {
            "Complete all Challenges",
            "on Orange Stake",
        },
        tier = 7,
    },
    {
        key = "gold_belt",
        name = "Gold Belt",
        description = {
            "Complete all Challenges",
            "on Gold Stake",
        },
        tier = 8,
    },
}

local function register_tier_achievement(order, definition)
    SMODS.Achievement({
        key = definition.key,
        order = order,
        bypass_all_unlocked = true,
        loc_txt = {
            name = definition.name,
            description = definition.description,
        },
        unlock_condition = function(self, args)
            return args and (args.type == "rb_challenge_stakes" or args.type == "win_stake")
                and RuleBender.challenge_stakes.is_tier_complete(definition.tier)
        end,
    })
end

for order, definition in ipairs(achievement_definitions) do
    register_tier_achievement(order, definition)
end

SMODS.Achievement({
    key = "completionist_plus_plus_plus",
    order = #achievement_definitions + 1,
    bypass_all_unlocked = true,
    loc_txt = {
        name = "Completionist+++",
        description = {
            "All the decks.",
            "All the stickers.",
            "All the challenges.",
        },
    },
    unlock_condition = function(self, args)
        return args and (args.type == "rb_challenge_stakes" or args.type == "win_stake")
            and RuleBender.challenge_stakes.is_completionist_plus_plus_complete()
            and RuleBender.challenge_stakes.is_gold_challenge_completion_complete()
    end,
})
