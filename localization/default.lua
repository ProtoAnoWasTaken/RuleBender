local loc = {
    descriptions = {
        Mod = {
            RuleBender = {
                name = "Rule Bender",
                text = {
                    "Add Stakes to your Challenges.",
                },
            },
        },
    },
}

if SMODS and SMODS.current_mod and SMODS.current_mod.manifest then
    local manifest = SMODS.current_mod.manifest
    local description = loc.descriptions.Mod.RuleBender

    if description and description.text then
        manifest.description = description.text
    end
end

return loc
