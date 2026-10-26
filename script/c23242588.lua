-- Dragón Legendario de Ojos Rojos
local s, id = GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Sincronía
    Synchro.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_DARK), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0x3b), 1, 99)

    -- 1. Efecto al ser Sincronizado: Barajar y robar / Invocar Red-Eyes o ganar LP
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW + CATEGORY_SPECIAL_SUMMON + CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.syncon)
    e1:SetTarget(s.syntg)
    e1:SetOperation(s.synop)
    c:RegisterEffect(e1)

    -- 2. Atacar a todos los monstruos y daño de penetración doble
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_ATTACK_ALL)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_PIERCE)
    e3:SetValue(DOUBLE_PIERCE or 1)
    c:RegisterEffect(e3)

    -- 3. Castigo constante de 500 LP por acciones del rival
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetOperation(s.burnop1)
    c:RegisterEffect(e4)

    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetRange(LOCATION_MZONE)
    e5:SetOperation(s.burnop2)
    c:RegisterEffect(e5)
end

function s.syncon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.syntg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, nil)
        and Duel.IsPlayerCanDraw(tp, 1) end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.synop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeck, tp, LOCATION_GRAVE, 0, 1, 99, nil)
    if #g > 0 then
        local ct = Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
        if ct > 0 then
            Duel.BreakEffect()
            if Duel.Draw(tp, 1, REASON_EFFECT) > 0 then
                -- Verificar si había Red-Eyes o Mágica entre las cartas barajadas
                for tc in aux.Next(g) do
                    if tc:IsSetCard(0x3b) and tc:IsMonster() and tc:IsCanBeSpecialSummoned(e, 0, tp, false, false) and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
                        if Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
                            Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
                            break
                        end
                    elseif tc:IsType(TYPE_SPELL) then
                        Duel.Recover(tp, tc:GetTextAttack() > 0 and tc:GetTextAttack() or 1000, REASON_EFFECT)
                        break
                    end
                end
            end
        end
    end
end

-- Castigo de 500 LP
function s.burnop1(e, tp, eg, ep, ev, re, r, rp)
    if rp ~= tp then
        Duel.Damage(1 - tp, 500, REASON_EFFECT)
    end
end

function s.burnop2(e, tp, eg, ep, ev, re, r, rp)
    local g = eg:Filter(Card.IsControler, nil, 1 - tp)
    if #g > 0 then
        Duel.Damage(1 - tp, 500 * #g, REASON_EFFECT)
    end
end
