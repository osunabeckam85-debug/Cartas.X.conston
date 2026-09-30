-- Custom Fusion Spell
local s, id = GetID()
function s.initial_effect(c)
    -- Activar
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Filtro para comprobar si el monstruo de Fusión puede ser invocado con sus materiales
function s.filter1(c, e, tp)
    return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false)
        and Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.filter1, tp, LOCATION_EXTRA, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.filter1, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
    local tc = g:GetFirst()
    if tc then
        -- Obtener los materiales requeridos por el monstruo de Fusión
        local mat = tc:GetMaterial()
        
        -- Invocación Especial desde el Extra Deck
        if Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP) > 0 then
            tc:CompleteProcedure()
            
            -- Cantidad de materiales (si no reconoce lista exacta, toma un valor base o de los requeridos)
            local mat_count = #mat > 0 and #mat or 2

            -- Otorgar efecto: Al atacar, duplica/multiplica el ataque según la cantidad de materiales
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
            e1:SetCode(EVENT_ATTACK_ANNOUNCE)
            e1:SetLabel(mat_count)
            e1:SetOperation(s.atkop)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
    end
end

-- Operación al declarar ataque: Multiplica el ATK
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local mult = e:GetLabel()
    if c:IsRelateToBattle() and c:IsFaceup() then
        local e1 = Effect.CreateEffect(e:GetOwner())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK_FINAL)
        e1:SetValue(c:GetAttack() * mult)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_DAMAGE_CAL)
        c:RegisterEffect(e1)
    end
end
