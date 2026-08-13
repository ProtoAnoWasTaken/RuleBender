## Rule Bender — Stakes for Every Challenge
**Rule Bender** is a Balatro mod that lets every Challenge be played at every Stake. Each Challenge remembers its own highest completed Stake, follows normal Stake-unlock rules, and can be replayed with a Challenge Backer earned from your overall progress.

This mod was scripted by [ProtoAno](https://github.com/ProtoAnoWasTaken) (ProtoAnoWasTaken). It is intended to make Challenge Mode feel like a proper parallel progression track without changing what makes individual Challenges themselves interesting.

## FAQ
> **Does this mod have any dependencies?**
>> This mod requires [Steamodded](https://github.com/Steamodded/smods/).

> **How do Stakes work in Challenges?**
>> Each Challenge has its own Stake unlocks. Complete the required previous Stakes as normal, or use **Unlock All** to unlock every option.

> **What does the Challenge progress bar count?**
>> Existing Challenge completions count as White Stake. Higher supported Stakes are tracked separately, with the bar changing colour from White through Gold.

> **What do I get for completing Stake tiers?**
>> Completing a tier earns its Belt achievement and Challenge Backer. Rule Bender includes Rule Breaker, seven Belt achievements, and Completionist+++.

> **Can I use modded Stakes?**
>> Yes. They work in Challenges, but do not increase the progress maximum unless their mod registers a reward tier.

> **Can another mod add a reward tier for its Stake?**
>> Yes. After Rule Bender loads, register both a Stake and its earned Challenge Backer with `RuleBender.register_challenge_stake_tier`:
>> ```lua
>> RuleBender.register_challenge_stake_tier({
>>    stake_key = "stake_example",
>>    name = "Example",
>>    colour = "#7f55c7",
>>    backer = {
>>        key = "example",
>>        name = "Example Backer",
>>        atlas = "example_challenge_backer",
>>        pos = {x = 0, y = 0},
>>    },
>> })
>> ```
>> This creates a progress tier and unlockable backer. The owning mod may add its own achievement.

> **Does Rule Bender work with modded Challenges?**
>> Yes, with the exception of Hardcore Challenges from [Aikoyori's Challenges](https://github.com/Aikoyori/Balatro-Aikoyoris-Shenanigans), since those are separate. White-Stake completion is preserved, and later completions are tracked per Stake.

> **Why isn't the mod loaded?**
>> Make sure Rule Bender is only one folder deep in your Mods directory.
