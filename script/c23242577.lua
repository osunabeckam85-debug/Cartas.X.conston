-- Majestic Power Tool Dragon (Tuner Synchro)
local s, id = GetID()
function s.initial_effect(c)
    -- Invocación por Sincronía
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, nil, 1, 1, Synchro.NonTuner(nil), 1, 99)
    
    -- 1. Al ser invocado por Sincronía: Invoca 2 Dragones de 5D's con Nivel 1 y efectos negados
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- 2. Material de Sincronía Nivel 12: Revive e invoca otro Sincronía de igual nivel
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1, id + 100)
    e2:SetCondition(s.matcon)
    e2:SetTarget(s.mattg)
    e2:SetOperation(s.matop)
    c:RegisterEffect(e2)
end

-- Lista de IDs de los Dragones de Yu-Gi-Oh! 5D's:
-- Stardust (44508094), Red Dragon Archfiend (70902743), Black Rose (73580471), 
-- Black-Winged (9012916), Ancient Fairy (25862681), Life Stream (25165047)
s.signer_list = {44508094, 70902743, 73580471, 9012916, 25862681, 25165047} 

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.spfilter(c, e, tp)
    return c:IsCode(table.unpack(s.signer_list)) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_MZONE) >= 2
            and not Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT)
            and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, 2, nil, e, tp) 
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 2, tp, LOCATION_EXTRA + LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 
        or Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) then return end
        
    local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, nil, e, tp)
    if #g >= 2 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = g:Select(tp, 2, 2, nil)
        
        for tc in aux.Next(sg) do
            if Duel.SpecialSummonStep(tc, 0, tp, tp, false, false, POS_FACEUP) then
                -- Negar efectos
                local e1 = Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_DISABLE)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD)
                tc:RegisterEffect(e1)
                local e2 = Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_DISABLE_EFFECT)
                e2:SetReset(RESET_EVENT + RESETS_STANDARD)
                tc:RegisterEffect(e2)
                -- Cambiar Nivel a 1
                local e3 = Effect.CreateEffect(e:GetHandler())
                e3:SetType(EFFECT_TYPE_SINGLE)
                e3:SetCode(EFFECT_CHANGE_LEVEL)
                e3:SetValue(1)
                e3:SetReset(RESET_EVENT + RESETS_STANDARD)
                tc:RegisterEffect(e3)
            end
        end
        Duel.SpecialSummonComplete()
    end
end

function s.matcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local sync = c:GetReasonCard()
    return r == REASON_SYNCHRO and sync:IsLevel(12)
end

function s.mattg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) >= 2
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 2, tp, LOCATION_EXTRA + LOCATION_GRAVE)
end

function s.extraspfilter(c, lvl, e, tp)
    return c:IsType(TYPE_SYNCHRO) and c:IsLevel(lvl) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.matop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        Duel.BreakEffect()
        local g = Duel.GetMatchingGroup(Card.IsType, tp, LOCATION_MZONE, LOCATION_MZONE, nil, TYPE_SYNCHRO)
        if #g > 0 and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
            local tc = g:Select(tp, 1, 1, nil):GetFirst()
            if tc then
                local lvl = tc:GetLevel()
                local exg = Duel.GetMatchingGroup(s.extraspfilter, tp, LOCATION_EXTRA, 0, nil, lvl, e, tp)
                if #exg > 0 then
                    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
                    local sg = exg:Select(tp, 1, 1, nil)
                    Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
                end
            end
        end
    end
end
