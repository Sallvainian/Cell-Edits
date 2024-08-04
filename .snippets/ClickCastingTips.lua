-------------------------------------------------
-- 2024-07-03 19:50:03 GMT+8
-- show tips for click-casting bindings (spell only)
-- config
-------------------------------------------------
local point = "TOPRIGHT"
local relativePoint = "TOPLEFT"
local relativeTo = CellMainFrame
local offsetX = -5
local offsetY = 0

-------------------------------------------------
-- function codes
-------------------------------------------------
local L = Cell.L
local F = Cell.funcs
local P = Cell.pixelPerfectFuncs

local tooltip = CreateFrame("GameTooltip", "CellClickCastingTips", CellMainFrame, "CellTooltipTemplate,BackdropTemplate")
tooltip:SetBackdrop({bgFile = Cell.vars.whiteTexture, edgeFile = Cell.vars.whiteTexture, edgeSize = P:Scale(1)})
tooltip:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
tooltip:SetBackdropBorderColor(Cell:GetAccentColorRGB())
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

------------------------------------------------------------------------------
-- If you want to use Button4 and Button5 as extra modifer keys
-- remove the '} --' section from below 
-- as well as the '--' that comments out Buttons 4 and 5
------------------------------------------------------------------------------
local mouseButtons = {"Left", "Middle", "Right"} -- , "Button4", "Button5"}
local mouseKeyIDs = {
    ["Left"] = 1,
    ["Middle"] = 3,
    ["Right"] = 2,
    -- ["Button4"] = 4,
    -- ["Button5"] = 5,
}

local function GetBindingDisplay(modifier, key)
    modifier = modifier:gsub("%-", "|cff777777+|r")
    modifier = modifier:gsub("alt", "Alt")
    modifier = modifier:gsub("ctrl", "Ctrl")
    modifier = modifier:gsub("shift", "Shift")
    modifier = modifier:gsub("meta", "Command")
    
    if strfind(key, "^NUM") then
        key = _G["KEY_"..key]
    elseif strlen(key) ~= 1 then
        key = L[key]
    end
    
    return modifier..key
end

local function DecodeKeyboard(fullKey)
    fullKey = string.gsub(fullKey, "alt", "alt-")
    fullKey = string.gsub(fullKey, "ctrl", "ctrl-")
    fullKey = string.gsub(fullKey, "shift", "shift-")
    local modifier, key = strmatch(fullKey, "^(.*-)(.+)$")
    if not modifier then -- no modifier
        modifier = ""
        key = fullKey
    end
    return modifier, key
end

local function DecodeDB(t)
    local modifier, bindKey, bindType, bindAction
    
    if t[1] ~= "notBound" then
        local dash, key
        modifier, dash, key = strmatch(t[1], "^(.*)type(-*)(.+)$")
        
        if dash == "-" then
            if key == "SCROLLUP" then
                bindKey = "ScrollUp"
            elseif key == "SCROLLDOWN" then
                bindKey = "ScrollDown"
            else
                modifier, bindKey = DecodeKeyboard(key)
            end
        else -- normal mouse button
            bindKey = F:GetIndex(mouseKeyIDs, tonumber(key))
        end
    else
        modifier, bindKey = "", "notBound"
    end
    
    if not t[3] then
        bindType = "general"
        bindAction = t[2]
    else
        bindType = t[2]
        bindAction = t[3]
    end
    
    return modifier, bindKey, bindType, bindAction
end

local function GetCurrentModifiers()
    local currentModifiers = ""
    if IsAltKeyDown() then
        currentModifiers = currentModifiers .. "alt-"
    end
    if IsControlKeyDown() then
        currentModifiers = currentModifiers .. "ctrl-"
    end
    if IsShiftKeyDown() then
        currentModifiers = currentModifiers .. "shift-"
    end
    return currentModifiers
end

local function ShowTips()
    tooltip:SetOwner(CellMainFrame, "ANCHOR_NONE")
    tooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    
    local clickCastingTable = Cell.vars.clickCastings["useCommon"] and Cell.vars.clickCastings["common"] or Cell.vars.clickCastings[Cell.vars.playerSpecID]
    local currentModifiers = GetCurrentModifiers()
    
    for _, button in ipairs(mouseButtons) do
        local found = false
        for _, t in pairs(clickCastingTable) do
            local modifier, bindKey, bindType, bindAction = DecodeDB(t)
            if bindType == "spell" and modifier == currentModifiers and bindKey == button then
                local bindActionDisplay, icon
                bindAction, icon = F:GetSpellInfo(bindAction)
                if bindAction then
                    bindActionDisplay = bindAction.." |T"..icon..":16:16|t"  -- Ensures uniform icon size
                else
                    bindActionDisplay = "|cFFFF3030"..L["Invalid"]
                end
                tooltip:AddDoubleLine(GetBindingDisplay(modifier, bindKey), "|cFFFFFFFF"..bindActionDisplay)
                found = true
                break
            end
        end
        if not found then
            tooltip:AddDoubleLine(GetBindingDisplay(currentModifiers, button), "|cFFFF3030"..L["Invalid"])
        end
    end
    
    -- Iterate over all regions and adjust spacing and font size for FontString objects. 
    for i = 1, select("#", tooltip:GetRegions()) do
        local region = select(i, tooltip:GetRegions())
        if region:GetObjectType() == "FontString" then
            region:SetFont(region:GetFont(), 12)  -- Set a consistent font size
            region:SetSpacing(2)  -- Adjust the spacing for better readability
            region:SetHeight(16)  -- Set a consistent height for each line
        end
    end
    
    tooltip:Show()
end

local function HideTips()
    tooltip:Hide()
end

local function UpdateTooltip()
    if tooltip:IsVisible() then
        tooltip:ClearLines()
        ShowTips()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MODIFIER_STATE_CHANGED")
frame:SetScript("OnEvent", UpdateTooltip)

F:IterateAllUnitButtons(function(b)
        b:HookScript("OnEnter", ShowTips)
        b:HookScript("OnLeave", HideTips)
end)

