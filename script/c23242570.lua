-- Predaplant Spore Garden (Corregido)
local s, id = GetID()
function s.initial_effect(c)
    -- Activar la carta
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 1. Buscar o recuperar Fusión / Predaplant
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCost(s.thcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- 2. Colocar 1 Contador Predador en TODAS las cartas del campo
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_COUNTER)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.cnttg)
    e3:SetOperation(s.cntop)
    c:RegisterEffect(e3)

    -- 3. Protección
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetValue(s.tgval)
    c:RegisterEffect(e4)

    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_SZONE)
    e5:SetValue(s.indval)
    c:RegisterEffect(e5)
end

s.counter_place_list = {COUNTER_PREDATOR}

function s.thfilter(c)
    return (c:IsSetCard(0x10f3) or c:IsSetCard(0x46)) and c:IsAbleToHand()
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, nil)
    if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            Duel.SendtoHand(sg, nil, REASON_EFFECT)
            Duel.ConfirmCards(1-tp, sg)
        end
    end
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local has_counter = Duel.GetCounter(0, 1, 1, COUNTER_PREDATOR) > 0
    if chk == 0 then
        if has_counter then return true end
        return e:GetHandler():GetFlagEffect(id) == 0
    end
    if not has_counter then
        e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
    end
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, g)
    end
end

function s.cnttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
end

function s.cntop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
    for tc in aux.Next(g) do
        tc:AddCounter(COUNTER_PREDATOR, 1)
    end
end

function s.tgval(e, re, rp)
    local rc = re:GetHandler()
    return rc and rc:GetCounter(COUNTER_PREDATOR) > 0
end

function s.indval(e, re, rp)
    local rc = re:GetHandler()
    return rc and rc:GetCounter(COUNTER_PREDATOR) > 0
end
