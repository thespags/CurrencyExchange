local exchangeFrame
local buttonSpace = 40
local indent = 25
local scripts = {}
local items

local function linkSplit(link, name)
    if not link then
        return {}
    end
    local subLink = string.match(link, name .. ":([%-%w:]+)")
    local t = {}
    local i = 0
    for v in string.gmatch(subLink, "([%-%w]*):?") do
        i = i + 1
        t[i] =  v ~= "" and v or nil
    end
    return t
end

local createFrame = function()
    items = GetMerchantNumItems()
    exchangeFrame = CreateFrame("Frame", "CurrencyExchange", UIParent, "UIPanelDialogTemplate")
    exchangeFrame:SetSize((items + 1) * buttonSpace, 120)
    exchangeFrame:SetPoint("TOPLEFT", "MerchantFrame", "TOPRIGHT", 10, 0)
    exchangeFrame:SetMovable(true)
    exchangeFrame:EnableMouse(true)
    exchangeFrame:SetClampedToScreen(true)
    exchangeFrame:SetScript("OnMouseDown", exchangeFrame.StartMoving)
    exchangeFrame:SetScript("OnMouseUp", exchangeFrame.StopMovingOrSizing)

    local closeFrame = _G["CurrencyExchangeClose"]
    closeFrame:SetPoint("TOPRIGHT", 2, 1)

    local title = exchangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Currency Exchange")

    local editBoxText = exchangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editBoxText:SetPoint("TOP", -40, -40)
    editBoxText:SetText("Amount:")

    local editBox = CreateFrame("EditBox", "CurrencyExchangeAmount", exchangeFrame, "InputBoxTemplate")
    editBox:SetNumeric(true)
    editBox:SetSize(60, 20)
    editBox:SetPoint("TOP", 30, -35)
    editBox:SetAutoFocus(false)
    editBox:SetText("1")

    local attentionText = exchangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    attentionText:SetPoint("TOP", 0, -60)
    attentionText:SetText("Click on an icon to buy. Automatically exchanges.")
    attentionText:SetFont("Fonts\\ARIALN.TTF", 8)

    for i=1,items do
        local iconButton = CreateFrame("Button", "CurrencyExchangeButton" .. i, exchangeFrame, "SecureActionButtonTemplate")
        iconButton:SetSize(30, 30)
        local xPoint = indent + (i - 1) * buttonSpace
        iconButton:SetPoint("TOPLEFT", xPoint, -75)
        local icon = select(2, GetMerchantItemInfo(i))
        iconButton:SetNormalTexture(icon)
        iconButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

        local currency = select(9, GetMerchantItemInfo(i))
        local value = iconButton:CreateFontString("CurrencyExchangeValue" .. i, "OVERLAY", "GameFontNormal")
        value:SetPoint("CENTER", 0, -2)
        value:SetFont("Fonts\\ARIALN.TTF", 15, "OUTLINE")
        value:SetText(C_CurrencyInfo.GetCurrencyInfo(currency)["quantity"])

        local currencyLink = select(3, GetMerchantItemCostItem(i, 1))
        local costCurrency = tonumber(linkSplit(currencyLink, "currency")[1])
        local buy = function(self, event, number)
            number = number or tonumber(editBox:GetText())
            local amount = C_CurrencyInfo.GetCurrencyInfo(costCurrency)["quantity"]
            if (number > amount) then     
                local f = scripts[costCurrency]
                _ = f and f(self, event, number - amount)
            end
            BuyMerchantItem(i, number)
        end
        scripts[currency] = buy
        iconButton:SetScript("OnClick", buy)
    end
    return exchangeFrame
end

local isTarget = function(expectedId)
    local targetGUID = UnitGUID("target")
    local npcId = targetGUID and select(6, strsplit("-", targetGUID))
    return npcId == expectedId
end
local UsuriBrightcoin = "35790"

local openFrame = CreateFrame("Frame")
openFrame:RegisterEvent("MERCHANT_SHOW")
openFrame:SetScript("OnEvent", function(self, event)
    if isTarget(UsuriBrightcoin) then
        exchangeFrame = exchangeFrame or createFrame()
        exchangeFrame:Show()
    end
end)

local closeFrame = CreateFrame("Frame")
closeFrame:RegisterEvent("MERCHANT_CLOSED")
closeFrame:SetScript("OnEvent", function(self, event)
    exchangeFrame:Hide()
end)

local updateFrame = CreateFrame("Frame")
updateFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
updateFrame:SetScript("OnEvent", function(self, event)
    if exchangeFrame and exchangeFrame:IsVisible() and items then
        for i=1,items do
            local currency = select(9, GetMerchantItemInfo(i))
            local value = _G["CurrencyExchangeValue" .. i]
            value:SetText(C_CurrencyInfo.GetCurrencyInfo(currency)["quantity"])
        end
    end
end)