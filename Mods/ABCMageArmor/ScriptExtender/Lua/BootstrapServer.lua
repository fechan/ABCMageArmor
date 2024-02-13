local MAGE_ARMOR_SPELLS = {
    "Target_MageArmor",
    "Shout_MageArmor_ArmorOfShadows",
}

-- a mutex will be created for a character if ABC is already making them cast any Mage Armor spell
-- it will be removed when the cast completes or fails
local casting_mutexes = {}

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

---Test if the given spell is a Mage Armor spell
---@param spellId string spell ID to check
---@return boolean isSpellMageArmor true if it's a mage armor spell
local function isSpellMageArmor(spellId)
    for _, mageArmorSpellId in ipairs(MAGE_ARMOR_SPELLS) do
        if spellId == mageArmorSpellId then
            return true
        end
    end
    return false
end

---Test if the given character knows a Mage Armor spell
---@param character CHARACTER character to check
---@return boolean knowsMageArmor true if they know mage armor
local function knowsMageArmor(character)
    for _, mageArmorSpellId in ipairs(MAGE_ARMOR_SPELLS) do
        if Osi.HasSpell(character, mageArmorSpellId) then
            return true
        end
    end
    return false
end

---Release the mage armor casting mutex for the given character if the spellId
---is a mage armor spell
---@param spellId string spell ID
---@param character CHARACTER character ID
local function releaseCastingMutex(spellId, character)
    if isSpellMageArmor(spellId) then
        casting_mutexes[character] = nil
    end
end

---Have the given character cast a Mage Armor spell if able
---@param character CHARACTER character ID
local function castMageArmorIfAble(character)
    local noMutexHeld = casting_mutexes[character] == nil
    local inCombat = Osi.IsInCombat(character) == 1

    if (noMutexHeld and
        (not inCombat) and
        knowsMageArmor(character) and
        canUseAction(character) and
        (not alreadyHasMageArmor(character))
    ) then
        print("Character " .. character .. "is casting " .. MAGE_ARMOR)
        casting_mutexes[character] = true
        Osi.UseSpell(character, MAGE_ARMOR, character, character)
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
Ext.Osiris.RegisterListener("Unequipped", 2, "after", function(item, character) castMageArmorIfAble(character) end)

Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(spell, spellElement, storyActionID, caster, spellType) releaseCastingMutex(spell, caster) end)
Ext.Osiris.RegisterListener("CastSpellFailed", 5, "after", function(spell, spellElement, storyActionID, caster, spellType) releaseCastingMutex(spell, caster) end)