local function canUseAction(character)
    for resourceUuid, resourceAmount in pairs(Ext.Entity.Get(character).ActionResources.Resources) do
        local resourceIsActionPoint = Ext.StaticData.Get(resourceUuid, "ActionResource").Name == "ActionPoint"

        if resourceIsActionPoint then
            return resourceAmount[1].Amount > 0
        end
    end

    return false
end

local function alreadyHasMageArmor(character)
    local statuses = Ext.Entity.Get(character).ServerCharacter.StatusManager.Statuses

    for _, status in pairs(statuses) do
        if status.StatusId == "MAGE_ARMOR" then
            return true
        end
    end

    return false
end

local MAGE_ARMOR = "Shout_MageArmor_ArmorOfShadows"

local function castMageArmorIfAble(character)
    local knowsMageArmor = Osi.HasSpell(character, MAGE_ARMOR) == 1
    local inCombat = Osi.IsInCombat(character) == 1

    print("Mage armor pre-check")
    if knowsMageArmor and (not inCombat) and canUseAction(character) and (not alreadyHasMageArmor(character)) then
        print("Character " .. character .. "is casting " .. MAGE_ARMOR)
        Osi.UseSpell(character, MAGE_ARMOR, character, character)
    end
end


local function everyoneCastMageArmor()
    for k,v in pairs(Osi.DB_Players:Get(nil)) do
        local character = v[1]

        castMageArmorIfAble(character)
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", everyoneCastMageArmor)
Ext.Osiris.RegisterListener("UserCharacterLongRested", 2, "after", castMageArmorIfAble)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", castMageArmorIfAble)
Ext.Osiris.RegisterListener("LearnedSpell", 2, "after", function(character, spellId)
    if spellId == MAGE_ARMOR then castMageArmorIfAble(character) end
end)
Ext.Osiris.RegisterListener("Equipped", 2, "after", function(item, character) castMageArmorIfAble(character) end)
Ext.Osiris.RegisterListener("Unequipped", 2, "after", function(item, character) castMageArmorIfAble(character) end)