-- Slifer the Sky Dragon - Ultimate Divine
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Invocación Especial Sacrificando 1 Slifer el Dragón del Cielo
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- 1. Inmunidad a cartas que no sean Bestia Divina
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    -- 2. Gana 1000 ATK/DEF por cada carta en la mano de AMBOS jugadores
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_SET_BASE_ATTACK)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)

    local e4 = e3:Clone()
    e4:SetCode(EFFECT_SET_BASE_DEFENSE)
    c:RegisterEffect(e4)

    -- 3. Invocaciones Especiales del rival pasan a Posición de Defensa inmediatamente
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetRange(LOCATION_MZONE)
    e5:SetOperation(s.posop)
    c:RegisterEffect(e5)

    -- 4. Cadena de ataques continuos
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_DAMAGE_STEP_END)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)

    -- 5. Sacrificar 1000 ATK para buscar carta de Bestia Divina o Slifer
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 0))
    e7:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e7:SetType(EFFECT_TYPE_IGNITION)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetCost(s.thcost)
    e7:SetTarget(s.thtg)
    e7:SetOperation(s.thop)
    c:RegisterEffect(e7)
end

-- Filtro para detectar Slifer (oficial 10000020 o anime 511600399)
function s.rfilter(c)
    return (c:IsCode(10000020) or c:IsCode(511600399) or c:ListsCode(10000020)) and c:IsReleasable()
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > -1
        and Duel.IsExistingMatchingCard(s.rfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RELEASE)
    local g = Duel.SelectMatchingCard(tp, s.rfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.Release(g, REASON_COST)
    end
end

-- Filtro de Inmunidad (Solo afectado por Divine-Beast)
function s.efilter(e, te)
    return not (te:IsActiveType(TYPE_MONSTER) and te:GetHandler():IsRace(RACE_DIVINE))
end

-- ATK/DEF (Ambas manos)
function s.atkval(e, c)
    return Duel.GetFieldGroupCount(c:GetControler(), LOCATION_HAND, LOCATION_HAND) * 1000
end

-- Cambio de Posición a Defensa
function s.posfilter(c, tp)
    return c:IsControler(1 - tp) and c:IsPosition(POS_FACEUP_ATTACK)
end

function s.posop(e, tp, eg, ep, ev, re, r, rp)
    local g = eg:Filter(s.posfilter, nil, tp)
    if #g > 0 then
        Duel.ChangePosition(g, POS_FACEUP_DEFENSE)
    end
end

-- Relanzamiento de ataque
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local d = Duel.GetAttackTarget()
    if c == Duel.GetAttacker() and d and d:IsMonster() and c:CanAttack() then
        if Duel.IsExistingMatchingCard(Card.IsCanBeAttackTarget, tp, 0, LOCATION_MZONE, 1, nil) then
            Duel.ChainAttack()
        end
    end
end

-- Costo: Perder 1000 ATK/DEF
function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:GetAttack() >= 1000 and c:GetDefense() >= 1000 end
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(-1000)
    e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
    c:RegisterEffect(e1)
    local e2 = e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)
end

-- Búsqueda
function s.thfilter(c)
    return (c:IsRace(RACE_DIVINE) or c:ListsCode(10000020) or c:ListsRace(RACE_DIVINE)) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
