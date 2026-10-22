-- Número C37: Enterrada de la Esperanza Dragón Araña del Abismo
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Invocación Xyz: 3 monstruos AGUA Niv 5 o sobre cualquier Xyz Pez/Serpiente Marina R3/R4/R5
    Xyz.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_WATER), 5, 3, s.ovfilter, aux.Stringid(id, 0))

    -- 1. Inafectado por otras cartas
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.efilter)
    c:RegisterEffect(e1)

    -- 2. Bloqueo de GY y Desterrados del rival
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0, 1)
    e2:SetValue(s.actlimit)
    c:RegisterEffect(e2)

    -- 3. Limpieza Total e Innegable (Efecto Rápido)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_DISABLE + CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCost(s.cost)
    e3:SetTarget(s.cleartg)
    e3:SetOperation(s.clearop)
    c:RegisterEffect(e3)

    -- 4. Resurrección al ser enviado al GY
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_TO_GRAVE)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

function s.ovfilter(c, tp, lc)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WATER, lc, SUMMON_TYPE_XYZ, tp) and (c:IsRace(RACE_FISH, lc, SUMMON_TYPE_XYZ, tp) or c:IsRace(RACE_SEASERPENT, lc, SUMMON_TYPE_XYZ, tp)) and c:IsType(TYPE_XYZ, lc, SUMMON_TYPE_XYZ, tp) and c:GetRank() >= 3 and c:GetRank() <= 5
end

function s.efilter(e, te)
    return te:GetOwner() ~= e:GetHandler()
end

function s.actlimit(e, re, tp)
    local loc = re:GetActivateLocation()
    return loc == LOCATION_GRAVE or loc == LOCATION_REMOVED
end

-- Costo de desacoplar 1 material corregido para móviles
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():CheckRemoveOverlayCard(tp, 1, REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp, 1, 1, REASON_COST)
end

function s.cleartg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil) end
    Duel.SetChainLimit(s.chlimit)
end

function s.chlimit(e, ep, tp)
    return tp == ep
end

function s.clearop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
    for tc in aux.Next(g) do
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
        if tc:IsMonster() then
            local e3 = e1:Clone()
            e3:SetCode(EFFECT_SET_ATTACK_FINAL)
            e3:SetValue(0)
            tc:RegisterEffect(e3)
        end
    end
end

function s.spfilter(c, e, tp)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_XYZ) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local ft = math.min(2, Duel.GetLocationCount(tp, LOCATION_MZONE))
    if ft <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, LOCATION_GRAVE, 0, 1, ft, nil, e, tp)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end
