-- Número 32: Draco Tiburón de Superficie Veiss
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Invocación Xyz: 2 monstruos AGUA Niv 4/5 o sobre un Xyz AGUA Rango 4
    Xyz.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_WATER), 4, 2, s.ovfilter, aux.Stringid(id, 0))

    -- 1. Succión: Acoplar monstruo del adversario
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 1))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.atttg)
    e1:SetOperation(s.attop)
    c:RegisterEffect(e1)

    -- 2. Protección continua mientras tenga material de Pez/Serpiente Marina/Shark
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE, 0)
    e2:SetCondition(s.protcon)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsAttribute, ATTRIBUTE_WATER))
    e2:SetValue(1)
    c:RegisterEffect(e2)

    local e3 = e2:Clone()
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)

    -- 3. Negación Rápida de Mágica/Trampa/Monstruo
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_NEGATE + CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.negcon)
    e4:SetCost(aux.dxmcostgen(1, 1, nil))
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)
end

function s.ovfilter(c, tp, lc)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WATER, lc, SUMMON_TYPE_XYZ, tp) and c:IsType(TYPE_XYZ, lc, SUMMON_TYPE_XYZ, tp) and c:GetRank() == 4
end

function s.atttg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsControler(1 - tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsCanBeAttachedTo(e:GetHandler()) end
    if chk == 0 then return e:GetHandler():IsType(TYPE_XYZ) and Duel.IsExistingTarget(Card.IsCanBeAttachedTo, tp, 0, LOCATION_MZONE, 1, nil, e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATTACH)
    local g = Duel.SelectTarget(tp, Card.IsCanBeAttachedTo, tp, 0, LOCATION_MZONE, 1, 1, nil, e:GetHandler())
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, g, 1, 0, 0)
end

function s.attop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
        Duel.Overlay(c, tc)
    end
end

function s.protfilter(c)
    return c:IsRace(RACE_FISH + RACE_SEASERPENT) or c:IsSetCard(0x10f3) or c:IsSetCard(0x73)
end

function s.protcon(e)
    return e:GetHandler():GetOverlayGroup():IsExists(s.protfilter, 1, nil)
end

function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0, CATEGORY_DESTROY, eg, 1, 0, 0)
    end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg, REASON_EFFECT)
    end
end
