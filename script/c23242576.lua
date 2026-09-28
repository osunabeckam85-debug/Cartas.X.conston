-- Gandora the Divine Dragon of Destruction
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Invocación Especial no negable si no controlas monstruos
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- Invocación inmune a respuestas
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetOperation(s.sumsuc)
    c:RegisterEffect(e2)

    -- Destruir monstruos rivales + Ganar ATK/DEF (Innegable)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_DESTROY + CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CANNOT_NEGATE)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)

    -- End Phase: Mandar al GY e invocar a Slifer (ID: 10000020)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_TOGRAVE + CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_PHASE + PHASE_END)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CANNOT_NEGATE)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)

    -- Resucitar si Slifer va al Cementerio desde tu campo
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 2))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_TO_GRAVE)
    e5:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CANNOT_NEGATE)
    e5:SetRange(LOCATION_GRAVE)
    e5:SetCondition(s.revcon)
    e5:SetTarget(s.revtg)
    e5:SetOperation(s.revop)
    c:RegisterEffect(e5)
end

-- Condición de Invocación desde Mano
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0) == 0
end

function s.sumsuc(e, tp, eg, ep, ev, re, r, rp)
    Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

-- Destrucción masiva
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    local g = Duel.GetMatchingGroup(Card.IsMonster, tp, 0, LOCATION_MZONE, nil)
    if chk == 0 then return #g > 0 end
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, #g, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsMonster, tp, 0, LOCATION_MZONE, nil)
    local ct = Duel.Destroy(g, REASON_EFFECT)
    if ct > 0 and c:IsRelateToEffect(e) and c:IsFaceup() then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(ct * 500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
end

-- Enviar al GY en End Phase e invocar Slifer
function s.sliferfilter(c, e, tp)
    return c:IsCode(10000020) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SendtoGrave(c, REASON_EFFECT) > 0 and c:IsLocation(LOCATION_GRAVE) then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.sliferfilter), tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
        if #g > 0 then
            Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end

-- Resucitar a Gandora cuando Slifer toque el GY
function s.sliferchk(c, tp)
    return c:IsCode(10000020) and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.revcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.sliferchk, 1, nil, tp)
end

function s.revtg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.revop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
    end
end
