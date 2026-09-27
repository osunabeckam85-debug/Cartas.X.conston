-- Predaplant Apex Dominion
local s, id = GetID()
function s.initial_effect(c)
    -- Activar Campo
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- 1. Colocar contador automáticamente cuando una carta entra al campo
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetRange(LOCATION_FZONE)
    e2:SetOperation(s.cntop)
    c:RegisterEffect(e2)

    local e3 = e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    local e4 = e2:Clone()
    e4:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
    c:RegisterEffect(e4)

    local e5 = e2:Clone()
    e5:SetCode(EVENT_MSET)
    c:RegisterEffect(e5)

    local e6 = e2:Clone()
    e6:SetCode(EVENT_SSET)
    c:RegisterEffect(e6)

    -- 2. Reciclar GY/Desterrado según contadores en campo y robar 1
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 0))
    e7:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW)
    e7:SetType(EFFECT_TYPE_IGNITION)
    e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e7:SetRange(LOCATION_FZONE)
    e7:SetCountLimit(1)
    e7:SetTarget(s.tdtg)
    e7:SetOperation(s.tdop)
    c:RegisterEffect(e7)

    -- 3. Protección de Destrucción acumulativa (remover contadores en su lugar)
    local e8 = Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e8:SetCode(EFFECT_DESTROY_REPLACE)
    e8:SetRange(LOCATION_FZONE)
    e8:SetTarget(s.reptg)
    e8:SetValue(s.repval)
    e8:SetOperation(s.repop)
    c:RegisterEffect(e8)
end

s.counter_place_list = {COUNTER_PREDATOR}

function s.counterfilter(c)
    return c:GetCounter(COUNTER_PREDATOR) > 0
end

function s.cntfilter(c)
    return c:IsLocation(LOCATION_ONFIELD)
end

function s.cntop(e, tp, eg, ep, ev, re, r, rp)
    local g = eg:Filter(s.cntfilter, nil)
    for tc in aux.Next(g) do
        tc:AddCounter(COUNTER_PREDATOR, 1)
    end
end

-- Reciclar y robar
function s.tdfilter(c)
    return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToDeck()
end

function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    local cg = Duel.GetMatchingGroup(s.counterfilter, 0, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
    local total_counters = 0
    for tc in aux.Next(cg) do
        total_counters = total_counters + tc:GetCounter(COUNTER_PREDATOR)
    end

    if chkc then return chkc:IsLocation(LOCATION_GRAVE + LOCATION_REMOVED) and chkc:IsControler(tp) and s.tdfilter(chkc) end
    if chk == 0 then
        return total_counters > 0 
            and Duel.IsPlayerCanDraw(tp, 1)
            and Duel.IsExistingTarget(s.tdfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, total_counters, nil)
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp, s.tdfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, total_counters, total_counters, nil)
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, #g, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.tdop(e, tp, eg, ep, ev, re, r, rp)
    local tg = Duel.GetTargetCards(e)
    if #tg > 0 and Duel.SendtoDeck(tg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
        Duel.ShuffleDeck(tp)
        Duel.BreakEffect()
        Duel.Draw(tp, 1, REASON_EFFECT)
    end
end

-- Protección acumulativa por contadores
function s.repfilter(c, tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0x10f3) and c:IsReason(REASON_BATTLE + REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return eg:IsExists(s.repfilter, 1, nil, tp) 
            and Duel.IsCanRemoveCounter(tp, 1, 1, COUNTER_PREDATOR, 1, REASON_EFFECT)
    end
    return Duel.SelectEffectYesNo(tp, e:GetHandler(), aux.Stringid(id, 1))
end

function s.repval(e, c)
    return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
    Duel.RemoveCounter(tp, 1, 1, COUNTER_PREDATOR, 1, REASON_EFFECT)
end
