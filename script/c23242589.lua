-- Dragón de Leyenda de Ojos Azules
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    Synchro.AddProcedure(c, nil, 1, 1, Synchro.NonTuner(nil), 1, 99)

    -- 1. Proteger Mágicas contra destrucción por efectos del rival
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_SZONE, 0)
    e1:SetTarget(aux.TargetBoolFunction(Card.IsType, TYPE_SPELL))
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- 2. Cero daño de batalla para ti
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CHANGE_DAMAGE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(1, 0)
    e2:SetValue(s.damval)
    c:RegisterEffect(e2)

    -- 3. No puede atacar directamente
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
    c:RegisterEffect(e3)

    -- 4. Destruir cartas al atacar según los Blue-Eyes en el GY
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_ATTACK_ANNOUNCE)
    e4:SetTarget(s.destg)
    e4:SetOperation(s.desop)
    c:RegisterEffect(e4)
end

function s.damval(e, re, val, r, rp, rc)
    if bit.band(r, REASON_BATTLE) ~= 0 then
        return 0
    end
    return val
end

-- Filtro de Blue-Eyes en el GY para contar cuántas cartas destruir
function s.beFilter(c)
    return c:IsSetCard(0xdd) or c:IsCode(89631139) or c:ListsCode(89631139)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    local ct = Duel.GetMatchingGroupCount(s.beFilter, tp, LOCATION_GRAVE, 0, nil)
    if chk == 0 then return ct > 0 and Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, nil) end
    local g = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    local ct = Duel.GetMatchingGroupCount(s.beFilter, tp, LOCATION_GRAVE, 0, nil)
    if ct <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, aux.TRUE, tp, 0, LOCATION_ONFIELD, 1, ct, nil)
    if #g > 0 then
        Duel.Destroy(g, REASON_EFFECT)
    end
end
