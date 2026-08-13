local backer_atlases = {
    "red",
    "green",
    "black",
    "blue",
    "purple",
    "orange",
    "gold",
}

for _, colour in ipairs(backer_atlases) do
    SMODS.Atlas({
        key = "challenge_" .. colour,
        path = colour .. "_challenge.png",
        px = 71,
        py = 95,
    })
end
