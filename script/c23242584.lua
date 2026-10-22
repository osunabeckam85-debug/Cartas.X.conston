-- Abyss Vanguard Shark
local s, id = GetID()
function s.initial_effect(c)
    -- 1. Invocación Especial masiva revelando desde la mano
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- 2. Buscar Mágica/Trampa de AGUA/Shark al Invocarse Especial
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1, id + 100)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- 3. Invocación Especial de un Nivel 4 o menor desde el Cementerio
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.gytg)
    e3:SetOperation(s.gyop)
    c:RegisterEffect(e3)

    -- 4. Otorga Efectos al Monstruo Xyz que lo use como Material
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_BE_MATERIAL)
    e4:SetCondition(s.efcon)
    e4:SetOperation(s.efop)
    c:RegisterEffect(e4)
end

-- Revelar e Invocar
function s.revfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsMonster() and not c:IsPublic()
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
            and Duel.IsExistingMatchingCard(s.revfilter, tp, LOCATION_HAND, 0, 1, c)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    local g = Duel.GetMatchingGroup(s.revfilter, tp, LOCATION_HAND, 0, c)
    if #g == 0 then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
    local sg = g:Select(tp, 1, #g, nil)
    Duel.ConfirmCards(1 - tp, sg)
    Duel.ShuffleHand(tp)

    if Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
        if ft <= 0 then return end
        
        local spg = sg:Filter(Card.IsCanBeSpecialSummoned, nil, e, 0, tp, false, false)
        if #spg > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
            local final_sp = spg:Select(tp, 1, ft, nil)
            Duel.SpecialSummon(final_sp, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end

-- Búsqueda de Mágicas/Trampas
function s.thfilter(c)
    return (c:IsSetCard(0x10f3) or c:IsSetCard(0x73) or c:ListsAttribute(ATTRIBUTE_WATER)) 
        and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
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

-- Revivir del GY Nivel 4 o menor
function s.gyfilter(c, e, tp)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:GetLevel() > 0 and c:GetLevel() <= 4 
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.gyfilter(chkc, e, tp) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 
        and Duel.IsExistingTarget(s.gyfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectTarget(tp, s.gyfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

function s.gyop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- Otorgar Inmune a Batalla y Doble Ataque al Xyz
function s.efcon(e, tp, eg, ep, ev, re, r, rp)
    return r == REASON_XYZ and e:GetHandler():GetReasonCard():IsAttribute(ATTRIBUTE_WATER)
end

function s.efop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local rc = c:GetReasonCard()
    
    -- No destruible por batalla
    local e1 = Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT + RESETS_STANDARD)
    rc:RegisterEffect(e1, true)

    -- Atacar dos veces
    local e2 = Effect.CreateEffect(rc)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetValue(1)
    e2:SetReset(RESET_EVENT + RESETS_STANDARD)
    rc:RegisterEffect(e2, true)
end
