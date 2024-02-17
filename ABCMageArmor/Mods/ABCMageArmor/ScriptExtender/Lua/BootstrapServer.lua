local MAGE_ARMOR_SPELLS = {
    "Target_MageArmor",
    "Shout_MageArmor_ArmorOfShadows",
}

---Test if the given character has an action point remaining
---@param character CHARACTER character ID
---@return boolean canUseAction true if character has at least 1 AP
local function canUseAction(character)
    for resourceUuid, resourceAmount in pairs(Ext.Entity.Get(character).ActionResources.Resources) do
        local resourceIsActionPoint = Ext.StaticData.Get(resourceUuid, "ActionResource").Name == "ActionPoint"

        if resourceIsActionPoint then
            return resourceAmount[1].Amount > 0
        end
    end

    return false
end

---Test if the given character already has the Mage Armor condition
---@param character CHARACTER character ID
---@return boolean alreadyHasMageArmor true if character already has mage armor
local function alreadyHasMageArmor(character)
    local statuses = Ext.Entity.Get(character).ServerCharacter.StatusManager.Statuses

    for _, status in pairs(statuses) do
        if status.StatusId == "MAGE_ARMOR" then
            return true
        end
    end

    return false
end

---Test if the given character knows a Mage Armor spell
---@param character CHARACTER character to check
---@return string? knowsMageArmor the mage armor spell the character knows
local function knowsMageArmor(character)
    for _, mageArmorSpellId in ipairs(MAGE_ARMOR_SPELLS) do
        if Osi.HasSpell(character, mageArmorSpellId) == 1 then
            return mageArmorSpellId
        end
    end
    return nil
end

---Have the given character cast a Mage Armor spell if able
---@param character CHARACTER character ID
local function castMageArmorIfAble(character)
    local inCombat = Osi.IsInCombat(character) == 1
    local knownMageArmorSpell = knowsMageArmor(character)

    if (not inCombat and
        knownMageArmorSpell ~= nil and
        canUseAction(character) and
        not alreadyHasMageArmor(character)
    ) then
        print("Character " .. character .. "is casting " .. knownMageArmorSpell)
        Osi.UseSpell(character, knownMageArmorSpell, character)
    end
end

---Have everyone in the party cast a Mage Armor spell if able
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