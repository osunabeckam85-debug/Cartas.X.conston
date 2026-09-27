-- Starving Venom Supreme Predator Dragon
local s, id = GetID()
function s.initial_effect(c)
    -- Invocación por Fusión
    c:EnableReviveLimit()
    Fusion.AddProcMixRep(c, true, true, s.matfilter1, 1, 1, s.matfilter2, 1, 99)

    -- Guardar chequeo de materiales de OSCURIDAD
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_MATERIAL_CHECK)
    e0:SetValue(s.valcheck)
    c:RegisterEffect(e0)

    -- 1. Gana 1000 ATK por cada contador en el campo
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)

    -- 2. Si se usaron 2+ OSCURIDAD: Monstruos Invocados Especial cambian a Nivel 1 y OSCURIDAD
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CHANGE_LEVEL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    e2:SetCondition(s.darkcon)
    e2:SetTarget(s.lvtg)
    e2:SetValue(1)
    e2:SetLabelObject(e0)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    e3:SetCondition(s.darkcon)
    e3:SetTarget(s.lvtg)
    e3:SetValue(ATTRIBUTE_DARK)
    e3:SetLabelObject(e0)
    c:RegisterEffect(e3)

    -- 3. Negación múltiple de Nivel 5+ según cantidad de contadores en el campo
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_DISABLE)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCost(s.discost)
    e4:SetTarget(s.distg)
    e4:SetOperation(s.disop)
    c:RegisterEffect(e4)

    -- 4. Copiar nombre de cualquier carta en el campo
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.nametg)
    e5:SetOperation(s.nameop)
    c:RegisterEffect(e5)

    -- 5. Inmunidad a cartas con contadores
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetValue(s.tgval)
    c:RegisterEffect(e6)

    local e7 = Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_SINGLE)
    e7:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e7:SetRange(LOCATION_MZONE)
    e7:SetValue(s.indval)
    c:RegisterEffect(e7)

    -- 6. Respuesta cuando es seleccionado: Negar + Robar / Ganar ATK
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id, 2))
    e8:SetCategory(CATEGORY_NEGATE + CATEGORY_DRAW + CATEGORY_ATKCHANGE)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_BECOME_TARGET)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCondition(s.negcon)
    e8:SetTarget(s.negtg)
    e8:SetOperation(s.negop)
    c:RegisterEffect(e8)
end

s.counter_place_list = {COUNTER_PREDATOR}

function s.matfilter1(c, fc, sumtype, tp)
    return c:IsSetCard(0x10f3, fc, sumtype, tp) or c:IsSetCard(0x52, fc, sumtype, tp)
end

function s.matfilter2(c, fc, sumtype, tp)
    return c:IsAttribute(ATTRIBUTE_DARK, fc, sumtype, tp)
end

function s.valcheck(e, c)
    local g = c:GetMaterial()
    if #g >= 2 and g:FilterCount(Card.IsAttribute, nil, ATTRIBUTE_DARK) == #g then
        e:SetLabel(1)
    else
        e:SetLabel(0)
    end
end

function s.atkval(e, c)
    return Duel.GetCounter(0, 1, 1, COUNTER_PREDATOR) * 1000
end

function s.darkcon(e)
    local c = e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_FUSION) and e:GetLabelObject():GetLabel() == 1
end

function s.lvtg(e, c)
    return c ~= e:GetHandler() and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

-- Costo de negación con recuento dinámico de límites por contadores
function s.discost(e, tp, eg, ep, ev, re, r, rp, chk)
    local max_ct = Duel.GetCounter(0, 1, 1, COUNTER_PREDATOR)
    if chk == 0 then return max_ct > 0 and e:GetHandler():GetFlagEffect(id) < max_ct end
    e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
end

function s.disfilter(c)
    return c:IsFaceup() and c:IsLevelAbove(5) and not c:IsDisabled()
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.disfilter(chkc) end
    if chk == 0 then return Duel.IsExistingTarget(s.disfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
    local g = Duel.SelectTarget(tp, s.disfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e1)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(e2)
    end
end

-- Copiar nombre
function s.nametg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsOnField() end
    if chk == 0 then return Duel.IsExistingTarget(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    Duel.SelectTarget(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
end

function s.nameop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) then
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_CODE)
        e1:SetValue(tc:GetCode())
        e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(e1)
    end
end

function s.tgval(e, re, rp)
    local rc = re:GetHandler()
    return rc and rc:GetCounter(COUNTER_PREDATOR) > 0
end

function s.indval(e, re, rp)
    local rc = re:GetHandler()
    return rc and rc:GetCounter(COUNTER_PREDATOR) > 0
end

-- Reacción al ser seleccionado
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsContains(e:GetHandler()) and rp ~= tp
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local rc = re:GetHandler()
    if Duel.NegateActivation(ev) then
        if rc:IsType(TYPE_SPELL + TYPE_TRAP) then
            Duel.Draw(tp, 1, REASON_EFFECT)
        elseif rc:IsType(TYPE_MONSTER) then
            local atk = rc:GetTextAttack()
            if atk > 0 and c:IsRelateToEffect(e) and c:IsFaceup() then
                local e1 = Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(atk)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
                c:RegisterEffect(e1)
            end
        end
    end
end
