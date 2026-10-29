-- E-HERO Darkness Neos
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Procedimiento de Fusión seguro para móviles: 2 monstruos "HÉROE"
    Fusion.AddProcMix(c, true, true, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x8), aux.FilterBoolFunctionEx(Card.IsSetCard, 0x8))

    -- 1. Búsqueda de Mágica de Fusión al ser Invocado por Fusión
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- 2. No puede ser destruido en batalla
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    -- 3. Negación automática al ser seleccionado por efectos o ataques
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_SELECTABLE)
    e3:SetOperation(s.negotarget)
    c:RegisterEffect(e3)

    -- 4. Negar cartas boca arriba del rival en la Fase de Batalla (Efecto Rápido)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_DISABLE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetHintTiming(TIMING_BATTLE_PHASE, TIMINGS_CHECK_MONSTER + TIMING_BATTLE_PHASE)
    e4:SetCountLimit(1)
    e4:SetCondition(s.negcon)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)
end

function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.thfilter(c)
    return (c:IsSetCard(0x46) or c:ListsCode(24094653) or c:IsCode(24094653)) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK + LOCATION_GRAVE, 0, 1, nil) end
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

-- Negar selección automáticamente
function s.negotarget(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_CARD, 0, id)
end

-- Negar cartas del rival en Fase de Batalla
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    local ph = Duel.GetCurrentPhase()
    return ph >= PHASE_BATTLE_START and ph <= PHASE_BATTLE
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
    end
end
