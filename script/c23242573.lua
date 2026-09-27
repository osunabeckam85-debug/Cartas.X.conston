-- Mini Slifer the Sky Dragon
local s, id = GetID()
function s.initial_effect(c)
    -- 1. Invocación Especial desde la mano si hay un monstruo de efecto
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- 2. Gana 1000 ATK/DEF por cada carta en la mano
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_SET_BASE_ATTACK)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    local e3 = e2:Clone()
    e3:SetCode(EFFECT_SET_BASE_DEFENSE)
    c:RegisterEffect(e3)

    -- 3. Negación (Cuesta 500 ATK, límite = N° de cartas en mano)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_NEGATE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.negcon)
    e4:SetCost(s.negcost)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)

    -- 4. Regresar a la mano en la End Phase
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetCategory(CATEGORY_TOHAND)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_PHASE + PHASE_END)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.rthtg)
    e5:SetOperation(s.rthop)
    c:RegisterEffect(e5)

    -- 5. Al ser destruido: Buscar Slifer y Monster Reborn
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 2))
    e6:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetTarget(s.thtg)
    e6:SetOperation(s.thop)
    c:RegisterEffect(e6)
end

-- Condición Invocación Especial
function s.spfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil)
end

-- Cálculo ATK/DEF (1000 x mano)
function s.atkval(e, c)
    return Duel.GetFieldGroupCount(c:GetControler(), LOCATION_HAND, 0) * 1000
end

-- Negación
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local hand_ct = Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0)
    if chk == 0 then return hand_ct > 0 and e:GetHandler():GetFlagEffect(id) < hand_ct end
    e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.NegateActivation(ev) and c:IsRelateToEffect(e) and c:IsFaceup() then
        -- Perder 500 ATK/DEF
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(-500)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e2)
    end
end

-- Regresar a la mano
function s.rthtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, e:GetHandler(), 1, 0, 0)
end

function s.rthop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
    end
end

-- Buscar Slifer (10000020) y Monstruo Renacido (83764718)
function s.thfilter1(c)
    return (c:IsCode(10000020) or c:IsCode(83764718)) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, 10000020)
            and Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil, 83764718)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local g1 = Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode), tp, LOCATION_DECK + LOCATION_GRAVE, 0, nil, 10000020)
    local g2 = Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode), tp, LOCATION_DECK + LOCATION_GRAVE, 0, nil, 83764718)
    if #g1 > 0 and #g2 > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg1 = g1:Select(tp, 1, 1, nil)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local sg2 = g2:Select(tp, 1, 1, nil)
        sg1:Merge(sg2)
        Duel.SendtoHand(sg1, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, sg1)
    end
end
