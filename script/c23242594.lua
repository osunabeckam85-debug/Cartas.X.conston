-- Evil HERO Infernal Claws
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Materiales: 1 Evil HERO Niv <= 4 + 1 Evil HERO Niv >= 5
    Fusion.AddProcMix(c, true, true, s.mfilter1, s.mfilter2)

    -- 1. Negar todas las cartas del rival al ser Invocado por Fusión
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.discon)
    e1:SetTarget(s.distg)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    -- 2. Gana ATK por cada monstruo en el campo
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    -- 3. Reciclar del GY para Invocar de Fusión desde el Extra Deck
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TODECK)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

function s.mfilter1(c, fc, sumtype, tp)
    return c:IsSetCard(0x6008, fc, sumtype, tp) and c:IsLevelBelow(4)
end

function s.mfilter2(c, fc, sumtype, tp)
    return c:IsSetCard(0x6008, fc, sumtype, tp) and c:IsLevelAbove(5)
end

function s.discon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsNegatable, tp, 0, LOCATION_ONFIELD, 1, nil) end
    local g = Duel.GetMatchingGroup(Card.IsNegatable, tp, 0, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, #g, 0, 0)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsNegatable, tp, 0, LOCATION_ONFIELD, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(e1)
        if tc:IsType(TYPE_MONSTER) then
            local e2 = e1:Clone()
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            tc:RegisterEffect(e2)
        end
    end
end

-- ATK proporcional a monstruos en campo
function s.atkval(e, c)
    return Duel.GetMatchingGroupCount(Card.IsMonster, 0, LOCATION_MZONE, LOCATION_MZONE, nil) * 300
end

-- Invocar Fusión desde Extra Deck barajando del GY
function s.fusionextrafilter(c, e, tp)
    return (c:IsSetCard(0x8) or c:IsSetCard(0x6008)) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 2, nil)
        and Duel.IsExistingMatchingCard(s.fusionextrafilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 2, tp, LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 2, 2, nil)
    if #g > 0 then
        if Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sg = Duel.SelectMatchingCard(tp, s.fusionextrafilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
            if #sg > 0 then
                Duel.SpecialSummon(sg, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)
            end
        end
    end
end
