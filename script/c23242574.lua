-- Karna - Shield of the Sky God
local s, id = GetID()
function s.initial_effect(c)
    -- 1. Invocación Especial si controlas al menos 1 monstruo
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- 2. ATK/DEF estático (1000 por cada carta en la mano)
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

    -- 3. Reducción de ATK al declarar ataque (Divide a la mitad x N° de monstruos)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_ATKCHANGE)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_ATTACK_ANNOUNCE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.atkcon)
    e4:SetOperation(s.atkop)
    c:RegisterEffect(e4)

    -- 4. Búsqueda de Bestia Divina / Soporte Divino al ser destruido
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e5:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_DESTROYED)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetTarget(s.thtg)
    e5:SetOperation(s.thop)
    c:RegisterEffect(e5)
end

-- Condición Invocación Especial
function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0) > 0
end

-- ATK/DEF según cartas en mano
function s.atkval(e, c)
    return Duel.GetFieldGroupCount(c:GetControler(), LOCATION_HAND, 0) * 1000
end

-- Efecto al atacar
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetAttacker():IsControler(1 - tp)
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetAttacker()
    if tc and tc:IsRelateToBattle() and tc:IsFaceup() then
        local m_count = Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0)
        if m_count > 0 then
            local current_atk = tc:GetAttack()
            local final_atk = current_atk
            for i = 1, m_count do
                final_atk = math.floor(final_atk / 2)
            end
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK_FINAL)
            e1:SetValue(final_atk)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
    end
end

-- Filtro para buscar Bestia Divina o carta que mencione RACE_DIVINE
function s.thfilter(c)
    return (c:IsRace(RACE_DIVINE) or c:ListsRace(RACE_DIVINE)) and c:IsAbleToHand()
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
