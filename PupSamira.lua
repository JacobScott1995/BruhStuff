if game.local_player.champ_name ~= "Samira" then
    return
end

do
    local function AutoUpdate()
        local Version = 1
        local file_name = "PupSamira.lua"
        local url = "https://raw.githubusercontent.com/JacobScott1995/BruhStuff/main/PupSamira.lua"
        local web_version = http:get("https://raw.githubusercontent.com/JacobScott1995/BruhStuff/main/Samira.version.txt")
        console:log("Samira Version: " .. Version)
        console:log("Samira Web Version: " .. tonumber(web_version))
        if tonumber(web_version) == Version then
            console:log("Samira Loaded!")
        else
            http:download_file(url, file_name)
            console:log("New Samira Update Available")
            console:log("Please Reload with F5")
        end
    end
    AutoUpdate()
end


if not file_manager:file_exists("PKDamageLib.lua") then
    local file_name = "PKDamageLib.lua"
    local url = "http://raw.githubusercontent.com/Astraanator/test/main/Champions/PKDamageLib.lua"
    http:download_file(url, file_name)
end
if not file_manager:file_exists("DreamPred.lib") then
    local file_name = "DreamPred.lib"
    local url = "https://cdn.discordapp.com/attachments/941603243618869268/1041196229289316372/DreamPred.lib"
    http:download_file(url, file_name)
end

require "PKDamageLib"
require "DreamPred"

SimpleSamira_Category = menu:add_category("Pup Samira")
SimpleSamira_enabled = menu:add_checkbox("Enabled", SimpleSamira_Category, 1)

Combo_combokey = menu:add_keybinder("Combo Key", SimpleSamira_Category, 32)
pCombo = menu:add_subcategory("Combo Features", SimpleSamira_Category)
pHarass = menu:add_subcategory("Harass Features", SimpleSamira_Category)
pDraw = menu:add_subcategory("Drawings", SimpleSamira_Category)
pCombo_useq = menu:add_checkbox("Use Q", pCombo, 1)
pCombo_usew = menu:add_checkbox("Use W", pCombo, 1)
pCombo_usee = menu:add_checkbox("Use E", pCombo, 1)
pCombo_user = menu:add_checkbox("Use R", pCombo, 1)
pCombo_instantS = menu:add_keybinder("Instant S Combo", pCombo, 84)
pDrawQ = menu:add_checkbox("Draw Q", pDraw, 1)
pDrawW = menu:add_checkbox("Draw W", pDraw, 1)
pDrawE = menu:add_checkbox("Draw E", pDraw, 1)
pDrawR = menu:add_checkbox("Draw R", pDraw, 1)
pHarassQ = menu:add_checkbox("Use Q", pHarass, 1)
pHarassQPer = menu:add_slider("Minimum Mana % For Q", pHarass, 1, 100, 25)

local_player = game.local_player
e_target = nil

local function Ready(spell)
    return spellbook:can_cast(spell)
end

local function IsValid(unit)
    if (unit and unit.is_targetable and unit.is_alive and unit.is_visible and unit.object_id and unit.health > 0) then
        return true
    end
    return false
end

local function GetEnemyHeroes()
    local _EnemyHeroes = {}
    player = game.players
    for i, unit in ipairs(players) do
        if unit and unit.is_enemy then
            table.insert(_EnemyHeroes, unit)
        end
    end
    return _EnemyHeroes
end

local function GetAllyHeroes()
    local _AllyHeroes = {}
    players = game.players
    for i, unit in ipairs(players) do
        if unit and not unit.is_enemy and unit.object_id ~= local_player.object_id then
            table.insert(_AllyHeroes, unit)
        end
    end
    return _AllyHeroes
end

local function GetEnemyCount(pos, range)
    count = 0
    local enemies_in_range = {}
    for i, hero in ipairs(GetEnemyHeroes()) do
        Range = range * range
        if hero:distance_to(pos) < Range and IsValid(hero) then
            table.insert(enemies_in_range, enemy)
            count = count + 1
        end
    end
    return enemies_in_range, count
end

local function GetMinionCount(pos, range)
    count = 0
    local enemies_in_range = {}
    minions = game.minions
    for i, minion in ipairs(minions) do
        Range = range * range
        if minion.is_enemy and IsValid(minion) and minion:distance_to(pos) < Range then
            table.insert(enemies_in_range, minion)
            count = count + 1
        end
    end
    return enemies_in_range, count
end

local function IsImmobile(target)
    if target:has_buff_type(5) or target:has_buff_type(11) or target:has_buff_type(29) or target:has_buff_type(24) or
        target:has_buff_type(10) then
        return true
    end
    return false
end

local function GotBuff(unit, buffname)
    if unit:has_buff(buffname) then
        return 1
    end
    return 0
end

local function GetShieldedHealth(damageType, target)
    local shield = 0
    if damageType == "AD" then
        shield = target.shield
    elseif damageType == "AP" then
        shield = target.magic_shield
    elseif damageType == "ALL" then
        shield = target.shield
    end
    return target.health + shield
end

local function GetDistanceSqr2(p1, p2)
    p2x, p2y, p2z = p2.x, p2.y, p2.z
    p1x, p1y, p1z = p1.x, p1.y, p1.z
    local dx = p1x - p2x
    local dz = (p1z or p1y) - (p2z or p2y)
    return dx * dx + dz * dz
end

local function GetTargetsNear(radius, primary_target)
    local targets = {primary_target}
    local diameter_sqr = 4 * radius * radius
    counter = 0
    for i, target in ipairs(GetEnemyHeroes()) do
        if target.object_id ~= 0 and target.object_id ~= primary_target and IsValid(target) and
            GetDistanceSqr2(primary_target.origin, target) < diameter_sqr then
            table.insert(targets, target)
        end
    end
    for i in pairs(targets) do
        counter = counter + 1
    end
    return counter
end

local spellQ = {
    type = "linear",
    range = 950,
    range2 = 400,
    delay = 0.25,
    width = 91,
    speed = 500,
    collision = {
        ["Wall"] = true,
        ["Hero"] = true,
        ["Minion"] = true
    }
}

local spellW = {
    range = 390
}

local spellE = {
    type = "linear",
    range = 600,
    delay = 0,
    width = 300,
    speed = 1600,
    collision = {
        ["Wall"] = false,
        ["Hero"] = false,
        ["Minion"] = false
    }
}

local spellR = {
    range = 600

}

local function QDmg(target)
    return getdmg("Q", target, local_player, 1)
end

local function WDmg(target)
    return getdmg("W", target, local_player, 1)
end

local function EDmg(target)
    return getdmg("E", target, local_player, 1)
end

local function RDmg(target)
    return getdmg("R", target, local_player, 1)
end

local function CastQ(target)
    if Ready(SLOT_Q) then
        local pred = _G.DreamPred.GetPrediction(target, spellQ, local_player)
        if pred ~= nil and pred.castPosition and pred.hitChance > 0.15 and target:distance_to(local_player.origin) <=
            spellQ.range2 then
            spellbook:cast_spell(SLOT_Q, spellQ.delay, pred.castPosition.x, pred.castPosition.y, pred.castPosition.z)
        elseif pred ~= nil and pred.castPosition and pred.hitChance > 0.45 then
            spellbook:cast_spell(SLOT_Q, spellQ.delay, pred.castPosition.x, pred.castPosition.y, pred.castPosition.z)
        end
    end
end

local function CastW()
    if Ready(SLOT_W) then
        spellbook:cast_spell(SLOT_W)
    end
end

local function CastE(target)
    if Ready(SLOT_E) then
        spellbook:cast_spell_targetted(SLOT_E, target, spellE.delay)
    end
end

local function CastR(target)
    if Ready(SLOT_R) then
        spellbook:cast_spell(SLOT_R)
    end
end

local function HealthPercent(target)
    return ((target.health / target.max_health) * 100)
end

local function ManaPercent()
    return ((local_player.mana / local_player.max_mana) * 100)
end

local function ComboDmg(target)
    local q_dmg = 0
    local w_dmg = 0
    local e_dmg = 0
    local r_dmg = 0
    local aa_dmg = 0
    local elec_dmg = 0
    local dh_dmg = 0

    if local_player:has_buff("ASSETS/Perks/Styles/Domination/DarkHarvest/DarkHarvest.lua") and HealthPercent(target) <
        50 then
        local level = local_player.level
        if level > 18 then
            level = 18
        end
        local dh_stacks = local_player:get_buff("ASSETS/Perks/Styles/Domination/DarkHarvest/DarkHarvest.lua").stacks2
        local base = 20 + ((40 / 17) * (level - 1)) + (dh_stacks * 5) + (0.25 * local_player.bonus_attack_damage) +
                         (0.15 * local_player.ability_power)
        if local_player.bonus_attack_damage > local_player.ability_power then
            dh_dmg = target:calculate_phys_damage(base)
        else
            dh_dmg = target:calculate_magic_damage(base)
        end
    end

    if local_player:has_perk(Electrocute) then
        if local_player:has_buff("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua") then
            if level > 18 then
                level = 18
            end
            if local_player.bonus_attack_damage > local_player.ability_power then
                elec_dmg = target:calculate_phys_damage({30, 38.82, 47.65, 56.47, 65.29, 74.12, 82.94, 91.76, 100.59,
                                                         109.41, 118.24, 127.06, 135.88, 144.71, 153.53, 162.35, 171.18,
                                                         180})[level] + (0.4 * local_player.bonus_attack_damage) +
                               (0.25 * local_player.ability_power)
            else
                elec_dmg = target:calculate_magic_damage({30, 38.82, 47.65, 56.47, 65.29, 74.12, 82.94, 91.76, 100.59,
                                                          109.41, 118.24, 127.06, 135.88, 144.71, 153.53, 162.35,
                                                          171.18, 180})[level] +
                               (0.4 * local_player.bonus_attack_damage) + (0.25 * local_player.ability_power)
            end
        end
    end

    if Ready(SLOT_Q) then
        q_dmg = QDmg(target)
    end
    if Ready(SLOT_W) then
        w_dmg = WDmg(target)
    end
    if Ready(SLOT_E) then
        e_dmg = EDmg(target)
    end
    if Ready(SLOT_R) then
        r_dmg = RDmg(target)
    end

    aa_dmg = (2 * local_player.attack_speed * getdmg("AA", target, local_player, 2))

    return (q_dmg + w_dmg + e_dmg + r_dmg + aa_dmg + elec_dmg + dh_dmg)
end

local function on_cast_done(args)
    if game:is_key_down(menu:get_value(pCombo_instantS)) then
        local target = args.target
        if args.is_autoattack and target ~= nil then
            e_target = target
            if Ready(SLOT_W) and target:distance_to(local_player.origin) <= 380 then
                spellbook:cast_spell(SLOT_W)
            end
        end
        if args.spell_slot_id == 1 and e_target ~= nil then
            spellbook:cast_spell_targetted(SLOT_E, e_target)
        end
        if args.spell_slot_id == 2 and e_target ~= nil then
            spellbook:cast_spell(SLOT_Q, 0, e_target.origin.x, e_target.origin.y, e_target.origin.z)
            for i = 1, 200, 1 do
                issueorder:attack_unit(e_target)
                orbwalker:reset_aa()
                spellbook:cast_spell(SLOT_R)
            end
        end
        if args.spell_slot_id == 48 and e_target ~= nil then
            for i = 1, 100, 1 do
                issueorder:attack_unit(e_target)
                orbwalker:reset_aa()
                spellbook:cast_spell(SLOT_R)
            end
            e_target = nil
        end
        if Ready(SLOT_R) then
            spellbook:cast_spell(SLOT_R)
        end
    end
    if menu:get_value(pCombo_usee) == 1 then
        local target = args.target
        if Ready(SLOT_Q) and args.spell_slot_id == 2 then
            spellbook:cast_spell(SLOT_Q, 0, target.origin.x, target.origin.y, target.origin.z)
        end
    end
end

local function Combo()

    if menu:get_value(pCombo_usee) == 1 then
        target = selector:find_target(spellE.range, mode_health)
        if target.object_id ~= 0 and spellbook:can_cast(SLOT_E) and IsValid(target) then
            if target:distance_to(local_player.origin) <= spellE.range and HealthPercent(target) <= 35 then
                CastE(target)
            end
        end
    end
    if menu:get_value(pCombo_useq) == 1 then
        target = selector:find_target(spellQ.range, mode_health)
        if target.object_id ~= 0 and spellbook:can_cast(SLOT_Q) and IsValid(target) then
            if target:distance_to(local_player.origin) <= spellQ.range then
                CastQ(target)
            end
        end
    end
    if menu:get_value(pCombo_usew) == 1 then
        target = selector:find_target(spellQ.range, mode_health)
        if target.object_id ~= 0 and spellbook:can_cast(SLOT_W) and IsValid(target) then
            if target:distance_to(local_player.origin) <= spellW.range then
                CastW()
            end
        end
    end
end

local function Harass()
    if menu:get_value(pHarassQ) == 1 then
        target = selector:find_target(spellQ.range, mode_health)
        if target.object_id ~= 0 and spellbook:can_cast(SLOT_Q) and IsValid(target) then
            if target:distance_to(local_player.origin) <= spellQ.range then
                CastQ(target)
            end
        end
    end
end

local function LaneClear()

end

local function JungleClear()

end

local function LastHit()
end

local function on_tick()
    local mode = combo:get_mode()
    if game:is_key_down(menu:get_value(Combo_combokey)) or mode == MODE_COMBO then
        Combo()
    elseif mode == MODE_HARASS then
        Harass()
    elseif mode == MODE_LANECLEAR then
        LaneClear()
        JungleClear()
    elseif mode == MODE_LASTHIT then
        LastHit()
    end
    if Ready(SLOT_R) then
        spellbook:cast_spell(SLOT_R)
    end
    if game:is_key_down(menu:get_value(pCombo_instantS)) then
        target_aa = selector:find_target(spellW.range, mode_health)
        if target_aa == nil or not IsValid(target_aa) or target_aa:distance_to(local_player.origin) > spellW.range then
            issueorder:move(game.mouse_pos)
        end
        if target_aa ~= nil and target_aa.is_targetable and Ready(SLOT_W) then
            orbwalker:attack_target(target_aa)
        end
    end
end

local function on_draw()
    if local_player.is_alive then
        if menu:get_value(pDrawQ) == 1 then
            if Ready(SLOT_Q) then
                renderer:draw_circle(local_player.origin.x, local_player.origin.y, local_player.origin.z, spellQ.range,
                    0, 0, 255, 255)
            end
        end

        if menu:get_value(pDrawW) == 1 then
            if Ready(SLOT_W) then
                renderer:draw_circle(local_player.origin.x, local_player.origin.y, local_player.origin.z, spellW.range,
                    0, 0, 255, 255)
            end
        end
        if menu:get_value(pDrawE) == 1 then
            if Ready(SLOT_E) then
                renderer:draw_circle(local_player.origin.x, local_player.origin.y, local_player.origin.z, spellE.range,
                    255, 255, 0, 255)
            end
        end
        if menu:get_value(pDrawR) == 1 then
            if Ready(SLOT_R) then
                renderer:draw_circle(local_player.origin.x, local_player.origin.y, local_player.origin.z, spellR.range,
                    255, 255, 0, 255)

            end
        end
    end
end

client:set_event_callback("on_draw", on_draw)
client:set_event_callback("on_tick", on_tick)
client:set_event_callback("on_cast_done", on_cast_done)

