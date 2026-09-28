-- Hamon, Divine Lord of Striking Thunder
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Invocación Especial enviando a Slifer al GY desde el Deck
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- 1. Protección de Inmunitat a Destrucción por Efecto (a sí mismo)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    -- 2. Proteger Cartas Mágicas de tu campo
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_ONFIELD, 0)
    e3:SetTarget(s.spmfilter)
    e3:SetValue(aux.indoval)
    c:RegisterEffect(e3)

    -- 3. Gana 1000 ATK/DEF por cada carta en el campo
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_SET_BASE_ATTACK)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)

    local e5 = e4:Clone()
    e5:SetCode(EFFECT_SET_BASE_DEFENSE)
    c:RegisterEffect(e5)

    -- 4. Puede atacar a todos los monstruos del adversario
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_ATTACK_ALL)
    e6:SetValue(1)
    c:RegisterEffect(e6)

    -- 5. Regresar a la mano en la End Phase
    local e7 = Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id, 0))
    e7:SetCategory(CATEGORY_TOHAND)
    e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e7:SetCode(EVENT_PHASE + PHASE_END)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1)
    e7:SetTarget(s.rthtg)
    e7:SetOperation(s.rthop)
    c:RegisterEffect(e7)

    -- 6. Buscar Bestia Divina al ser destruido
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 1))
    e8:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e8:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e8:SetCode(EVENT_DESTROYED)
    e8:SetProperty(EFFECT_FLAG_DELAY)
    e8:SetTarget(s.thtg)
    e8:SetOperation(s.thop)
    c:RegisterEffect(e8)
end

-- Invocación mandando a Slifer (ID: 10000020)
function s.spfilter(c)
    return c:IsCode(10000020) and c:IsAbleToGrave()
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_DECK, 0, 1, nil)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, c)
    local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_DECK, 0, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local sg = g:SelectUnselect(Group.CreateGroup(), tp, false, true, 1, 1)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if sg then
        Duel.SendtoGrave(sg, REASON_COST)
        sg:DeleteGroup()
    end
end

-- Filtro para proteger Magias
function s.spmfilter(e, c)
    return c:IsType(TYPE_SPELL)
end

-- ATK/DEF (1000 x cartas en campo)
function s.atkval(e, c)
    return Duel.GetFieldGroupCount(c:GetControler(), LOCATION_ONFIELD, LOCATION_ONFIELD) * 1000
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

-- Buscar Bestia Divina
function s.thfilter(c)
    return c:IsRace(RACE_DIVINE) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end
