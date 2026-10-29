-- Evil HERO Skarlet
local s, id = GetID()
function s.initial_effect(c)
    -- Invocación Especial revelando un HÉROE en la mano
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Búsqueda de Fusión y soporte de HÉROE al ser Invocado Especial
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1, id)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- Efecto propio de Skarlet: Invocar Evil HERO desde la mano con ATK <= 1400
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    c:RegisterEffect(e3)
    local e3b = e3:Clone()
    e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3b)
    e3:SetTarget(s.sktg)
    e3:SetOperation(s.skop)
    e3b:SetTarget(s.sktg)
    e3b:SetOperation(s.skop)

    -- Spam de Héroes nivel 5 o menor con efectos negados
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.sptg2)
    e4:SetOperation(s.spop2)
    c:RegisterEffect(e4)

    -- Resurrección si hay Fusión
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 3))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_GRAVE)
    e5:SetCountLimit(1, id + 100)
    e5:SetCondition(s.spcon3)
    e5:SetTarget(s.sptg3)
    e5:SetOperation(s.spop3)
    c:RegisterEffect(e5)

    -- Reciclar Fusión y hasta 2 Héroes al ser destruido (Versión segura para móviles)
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 4))
    e6:SetCategory(CATEGORY_TOHAND)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetTarget(s.thtg2)
    e6:SetOperation(s.thop2)
    c:RegisterEffect(e6)
end

function s.revfilter(c)
    return c:IsSetCard(0x8) and not c:IsPublic()
end

function s.spcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.revfilter, tp, LOCATION_HAND, 0, 1, c)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp, c)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
    local g = Duel.SelectMatchingCard(tp, s.revfilter, tp, LOCATION_HAND, 0, 1, 1, c)
    if #g > 0 then
        Duel.ConfirmCards(1 - tp, g)
        Duel.ShuffleHand(tp)
    end
end

function s.fusionfilter(c)
    return c:IsSetCard(0x46) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.heroSupportDeck(c)
    return (c:IsSetCard(0x8) or c:ListsCode(89943723)) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.fusionfilter, tp, LOCATION_DECK, 0, 1, nil)
        and Duel.IsExistingMatchingCard(s.heroSupportDeck, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 2, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g1 = Duel.SelectMatchingCard(tp, s.fusionfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g2 = Duel.SelectMatchingCard(tp, s.heroSupportDeck, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g1 > 0 and #g2 > 0 then
        g1:Merge(g2)
        Duel.SendtoHand(g1, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g1)
    end
end

function s.skfilter(c, e, tp, atk)
    return c:IsSetCard(0x6008) and c:IsAttackBelow(atk) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sktg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.skfilter, tp, LOCATION_HAND, 0, 1, nil, e, tp, e:GetHandler():GetAttack()) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
end

function s.skop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    local c = e:GetHandler()
    local atk = c:IsRelateToEffect(c) and c:GetAttack() or 1400
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.skfilter, tp, LOCATION_HAND, 0, 1, 1, nil, e, tp, atk)
    if #g > 0 then
        Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
    end
end

function s.spmfilter(c, e, tp)
    return c:IsSetCard(0x8) and c:IsLevelBelow(5) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP)
end

function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.spmfilter, tp, LOCATION_HAND, 0, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if ft <= 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spmfilter, tp, LOCATION_HAND, 0, 1, ft, nil, e, tp)
    if #g > 0 then
        for tc in aux.Next(g) do
            if Duel.SpecialSummonStep(tc, 0, tp, tp, false, false, POS_FACEUP) then
                local e1 = Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_DISABLE)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD)
                tc:RegisterEffect(e1)
                local e2 = e1:Clone()
                e2:SetCode(EFFECT_DISABLE_EFFECT)
                tc:RegisterEffect(e2)
            end
        end
        Duel.SpecialSummonComplete()
    end
end

function s.fusfieldfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_FUSION)
end

function s.spcon3(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(s.fusfieldfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.sptg3(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop3(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- Filtros seguros para reciclaje al ser destruido
function s.recfusfilter(c)
    return c:IsSetCard(0x46) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.recherolective(c)
    return c:IsSetCard(0x8) and c:IsMonster() and c:IsAbleToHand()
end

function s.thtg2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.recfusfilter, tp, LOCATION_GRAVE, 0, 1, nil)
        and Duel.IsExistingMatchingCard(s.recherolective, tp, LOCATION_GRAVE, 1, 2, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 3, tp, LOCATION_GRAVE)
end

function s.thop2(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g1 = Duel.SelectMatchingCard(tp, s.recfusfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
    if #g1 > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local g2 = Duel.SelectMatchingCard(tp, s.recherolective, tp, LOCATION_GRAVE, 0, 1, 2, nil)
        if #g2 > 0 then
            g1:Merge(g2)
            Duel.SendtoHand(g1, nil, REASON_EFFECT)
            Duel.ConfirmCards(1 - tp, g1)
        end
    end
end
