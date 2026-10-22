-- Abyss Shark Domain
local s, id = GetID()
function s.initial_effect(c)
    -- Activar carta
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- 1. Aumento de 500 ATK/DEF a monstruos de AGUA
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_MZONE, 0)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsAttribute, ATTRIBUTE_WATER))
    e2:SetValue(500)
    c:RegisterEffect(e2)

    local e3 = e2:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)

    -- 3. Acoplar hasta 2 materiales desde cualquier Cementerio
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.atttg)
    e4:SetOperation(s.attop)
    c:RegisterEffect(e4)

    -- 4. Buscar Mágica Subida de Rango (Rank-Up-Magic)
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.rumtg)
    e5:SetOperation(s.rumop)
    c:RegisterEffect(e5)
end

-- Búsqueda al activar basada en Monstruos Xyz de AGUA que controles
function s.xyzfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_WATER)
end

function s.thfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsAbleToHand()
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local count = Duel.GetMatchingGroupCount(s.xyzfilter, tp, LOCATION_MZONE, 0, nil)
    if count > 0 and Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) 
        and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
        
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, count, nil)
        if #g > 0 then
            Duel.SendtoHand(g, nil, REASON_EFFECT)
            Duel.ConfirmCards(1 - tp, g)
        end
    end
end

-- Acoplar materiales desde el Cementerio
function s.matfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsMonster() and not c:IsForbidden()
end

function s.atttg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    if chk == 0 then
        return Duel.IsExistingTarget(s.xyzfilter, tp, LOCATION_MZONE, 0, 1, nil)
            and Duel.IsExistingTarget(s.matfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, nil)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    local g1 = Duel.SelectTarget(tp, s.xyzfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATTACH)
    local g2 = Duel.SelectTarget(tp, s.matfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, 2, nil)
    e:SetLabelObject(g1:GetFirst())
end

function s.attop(e, tp, eg, ep, ev, re, r, rp)
    local xyz = e:GetLabelObject()
    if not xyz or not xyz:IsRelateToEffect(e) or xyz:IsFacedown() then return end
    local g = Duel.GetTargetCards(e):Filter(Card.IsLocation, xyz, LOCATION_GRAVE)
    if #g > 0 then
        Duel.Overlay(xyz, g)
    end
end

-- Buscar Rank-Up-Magic
function s.rumfilter(c)
    return c:IsSetCard(0x95) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.rumtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.rumfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.rumop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.rumfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
