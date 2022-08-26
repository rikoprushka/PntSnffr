
-- Handle all the logic for actually sniffing the items
-- and proc'ing an interested or critical interaction
-- Triggered by RoyaleDegeneratePantySnifferMenu()
function RoyaleDegeneratePantySnifferLogic(item)
    -- Only trigger for the actual player sniffing, not everyone
    local player = getPlayer();
    if player:isLocalPlayer() == false then
        return;
    end

    -- Determine the reaction chance and the type
    -- 1-100 random chance.  Good/Bad determined by ItemID (Even Good, Odd Bad)
    local reactChance = ZombRand(100);
    local reactGood = (item:getID() % 2 == 0);

    -- Prepare some variables
    local emoteMessage = nil;
    local emoteColor = nil;
    local emoteAction = nil;

    -- Configuration for Max random message selections (match UI_EN.txt counts)
    local countCrit = 5;
    local countReact = 5;
    local countNeutral = 5;

    -- Write a ModID to the item so that we know we've recently sniffed these
    -- We'll check when you try to sniff the panties if you've already sniffed em recently
    -- You're allowed once an hour per pair of panties
    item:getModData().PantySniffer = RoyaleDegeneratePantySnifferGenerateActionID();

    -- 90% chance it's just a regular sniff and no benefits
    -- Run the halo text and call it a day
    if reactChance > 9 and reactChance ~= 69 then
        emoteMessage = getText("UI_SNIFF_NEUTRAL" .. ZombRand(1, countNeutral));
        HaloTextHelper.addText(player, emoteMessage, HaloTextHelper.getColorWhite());
        HaloTextHelper.update();
        return;
    end

    -- You're going to interact with the item, so we need some player information
    -- This will allow us to make you a little sick/drunk or happy/unhappy
    local playerStats = player:getStats();
    local playerDamage = player:getBodyDamage();

    -- Setup some variables to react postively or negatively to the item
    if reactGood == true then
        emoteType = "GOOD";
        emoteAction = "comehere";
        emoteColor = HaloTextHelper.getColorGreen();
    else
        emoteType = "BAD";
        emoteAction = "ceasefire";
        emoteColor = HaloTextHelper.getColorRed();
    end

    -- 10% Chance you react [Positive|Negative]ly to the sniffing
    if reactChance <= 9 then
        player:playEmote(emoteAction);
        local unHappy = playerDamage:getUnhappynessLevel()
        if reactGood then
            -- Increase happiness a little you pervert
            playerDamage:setUnhappynessLevel(unHappy - ZombRand(5));
        else
            -- Decrease happiness a little (gross)
            playerDamage:setUnhappynessLevel(unHappy + ZombRand(5));
        end
        emoteMessage = getText("UI_SNIFF_REACT_" .. emoteType .. ZombRand(1, countReact));
        HaloTextHelper.addTextWithArrow(player, emoteMessage, reactGood, emoteColor);
        HaloTextHelper.update();
        return;
    end

    -- 1% chance you just Crit on the item and are going to puke or get a little intoxicated
    if reactChance == 69 then
        player:playEmote(emoteAction);
        if reactGood then
            -- Really loving this, get a little tipsy for a moment
            if playerStats:getDrunkenness() < 12 then
                playerStats:setDrunkenness(12);
            end
        else
            -- Absolutely disgusting, get quesy you degenerate bastard
            if playerDamage:getFakeInfectionLevel() < 26 then
                playerDamage:setFakeInfectionLevel(26);
            end
        end
        player:SayShout(getText("UI_SNIFF_CRIT_" .. emoteType .. ZombRand(1, countCrit)));
        return;
    end

end

-- Generate an action ID that we can use to determine the last time you sniffed these panties
-- We use the date + hour so that you can only sniff the item once an hour and avoid potential abuse
-- Example output for August 15th, 1992 at 10 Am is "199281510"
function RoyaleDegeneratePantySnifferGenerateActionID()
    local gameTime = getGameTime()
    return gameTime:getYear() .. gameTime:getMonth() .. gameTime:getDay() .. gameTime:getHour()
end
    

-- Handle the right-click inventory menu items.  if it's clothing and it's underwear
-- then setup the "Sniff" action ability.  Then disable it if you've already sniffed
-- these recently (Using the ActionID Function)
function RoyaleDegeneratePantySnifferMenu(player, context, items)
    local items = ISInventoryPane.getActualItems(items)
    local actionID = RoyaleDegeneratePantySnifferGenerateActionID()
    for _, item in ipairs(items) do
        if item:getCategory() == "Clothing" then
            if item:getBodyLocation() == "UnderwearBottom" then
                local option = context:addOption(getText("UI_SNIFF"), item, RoyaleDegeneratePantySnifferLogic);
                if item:getModData().PantySniffer == actionID then
                    local toolTip = ISWorldObjectContextMenu.addToolTip();
                    option.toolTip = toolTip;
                    toolTip.description = getText("UI_SNIFF_ERROR");
                    option.notAvailable = true;
                end
                -- Only show one sniff menu option
                return;
            end
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(RoyaleDegeneratePantySnifferMenu);
