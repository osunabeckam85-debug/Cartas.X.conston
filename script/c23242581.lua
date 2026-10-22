-- Número C32: Draco Tiburón Veiss de Armadura Completa
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Invocación Xyz: 3 monstruos AGUA Niv 4/5 o sobre "Número 32: Draco Tiburón"
    Xyz.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_WATER), 5, 3, s.ovfilter, aux.Stringid(id, 0))

    -- 1. Aumento de ATK/DEF (+500 por cada material AGUA)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)

    local e2 = e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)

    -- 2. Sin daño de batalla ni de efectos
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CHANGE_DAMAGE)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(1, 0)
    e3:SetCondition(s.damcon)
    e3:SetValue(0)
    c:RegisterEffect(e3)

    local e4 = e3:Clone()
    e4:SetCode(EFFECT_NO_EFFECT_DAMAGE)
    c:RegisterEffect(e4)

    -- 3. Negación Rápida acumulativa basada en Estrellas
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetCategory(CATEGORY_DISABLE)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.discon)
    e5:SetCost(aux.dxmcostgen(1, 1, nil))
    e5:SetTarget(s.distg)
    e5:SetOperation(s.disop)
    c:RegisterEffect(e5)
end

function s.ovfilter(c, tp, lc)
    return c:IsFaceup() and (c:IsCode(65676461) or c:IsCode(32390585))
end

function s.atkval(e, c)
    return c:GetOverlayGroup():FilterCount(Card.IsAttribute, nil, ATTRIBUTE_WATER) * 500
end

function s.damcon(e)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsAttribute, 1, nil, ATTRIBUTE_WATER)
end

function s.discon(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and Duel.IsChainNegatable(ev)
end

function s.gyfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and (c:GetLevel() > 0 or c:GetRank() > 0)
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.gyfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, eg, 1, 0, 0)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectMatchingCard(tp, s.gyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    local tc = g:GetFirst()
    if tc then
        local count = math.max(tc:GetLevel(), tc:GetRank())
        if count > 0 then
            Duel.NegateActivation(ev)
            c:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1, count)
        end
    end
end

