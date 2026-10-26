-- Blue-Eyes Cosmic Burst Dragon
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Sincronía
    Synchro.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_LIGHT), 1, 1, Synchro.NonTuner(Card.IsRace, RACE_DRAGON), 1, 99)

    -- 1. Inafectable solo si fue Invocado por Sincronía
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetCondition(s.immcon)
    e1:SetValue(s.efilter)
    c:RegisterEffect(e1)

    -- 2. Destruir cartas según el Nivel de un "Blue-Eyes" en el GY (Efecto de Ignición)
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    -- 3. Negación Rápida (Efecto Rápido)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DISABLE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    -- 4. Reingresar cartas del GY al Deck e Invocar un Sincronía Blue-Eyes (Efecto de Ignición seguro para móviles)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TODECK)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.sptg2)
    e4:SetOperation(s.spop2)
    c:RegisterEffect(e4)
end

function s.immcon(e)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.efilter(e, te)
    return te:GetOwner() ~= e:GetHandler()
end

-- Filtro de Blue-Eyes en el Cementerio para destrucción por Nivel
function s.desfilter(c)
    return (c:IsSetCard(0xdd) or c:IsCode(89631139) or c:ListsCode(89631139)) and c:GetLevel() > 0
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.desfilter(chkc) end
    if chk == 0 then return Duel.IsExistingTarget(s.desfilter, tp, LOCATION_GRAVE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, s.desfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    local lv = g:GetFirst():GetLevel()
    local dt = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, dt, math.min(lv, #dt), 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    local lv = tc:GetLevel()
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, lv, nil)
    if #g > 0 then
        Duel.Destroy(g, REASON_EFFECT)
    end
end

-- Negación Rápida
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    Duel.NegateActivation(ev)
end

-- Reemplazo de Sincronía (Cambiado a efecto de Ignición para evitar errores de argumentos nulos en móvil)
function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(s.syncfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.syncfilter(c, e, tp)
    return c:IsSetCard(0xdd) and c:IsType(TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SYNCHRO, tp, false, false)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, 3, nil)
    if #g > 0 then
        if Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local sg = Duel.SelectMatchingCard(tp, s.syncfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp)
            if #sg > 0 then
                Duel.SpecialSummon(sg, SUMMON_TYPE_SYNCHRO, tp, tp, false, false, POS_FACEUP)
            end
        end
    end
end
