local REGION_BY_ID = {
    [1] = "us",
    [2] = "kr",
    [3] = "eu",
    [4] = "tw",
    [5] = "cn",
}

local ZONE = 47 -- seasonal dungeon zone id

-- wcl url format
local function EncodeUrlPart(value)

    value = tostring(value or "")
    value = value:lower()
    value = value:gsub("%s+", "-")

    value = value:gsub("[^%w%-_%.~]", function(char)
        return string.format("%%%02X", string.byte(char))
    end)

    return value
end

local function BuildWCLURL(name, realm)

    if not name then
        return
    end

    realm = realm or GetRealmName()

    local region = REGION_BY_ID[GetCurrentRegion()] or "us"

    return string.format(
        "https://www.warcraftlogs.com/character/%s/%s/%s?zone=%d&metric=points_and_damage",
        region,
        EncodeUrlPart(realm),
        EncodeUrlPart(name),
        ZONE
    )
end

local function GetMenuText(unit)

    if unit and UnitExists(unit) then

        local localizedClass = UnitClass(unit)

        if localizedClass then
            return "Release the " .. localizedClass .. " Files"
        end

    end

    return "Release the Files"
end

local function ShowPopup(url)

    StaticPopupDialogs["WCL_LINK_POPUP"] = {

        text = "WarcraftLogs URL (Ctrl+C to copy and close)",
        button1 = "Close",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnShow = function(self)

            local box = self.EditBox or _G[self:GetName() .. "EditBox"]

            box:SetText(url)
            box:HighlightText()
            box:SetFocus()

            box:SetScript("OnKeyDown", function(editBox, key)

                if key == "C" and IsControlKeyDown() then

                    C_Timer.After(0.05, function()
                        self:Hide()
                    end)

                end

            end)

            box:SetPropagateKeyboardInput(true)

        end,


        OnHide = function(self)

            local box = self.EditBox or _G[self:GetName() .. "EditBox"]

            if box then
                box:SetScript("OnKeyDown", nil)
            end

        end,
    }


    StaticPopup_Show("WCL_LINK_POPUP")
end

local function AddWCLButton(owner, rootDescription, contextData)

    if not contextData then
        return
    end

    local name
    local realm
    local unit = contextData.unit

    -- Normal unit menus
    if unit and UnitExists(unit) then

        name, realm = UnitFullName(unit)

    else

        -- LFG menus
        name = contextData.name
        realm = contextData.server or contextData.realm

    end

    if not name then
        return
    end

    rootDescription:CreateDivider()

    rootDescription:CreateButton(
        GetMenuText(unit),

        function()

            local url = BuildWCLURL(name, realm)

            if url then
                ShowPopup(url)
            end

        end
    )
end

local function Initialize()

    if not Menu or not Menu.ModifyMenu then
        return
    end

    local menus = {

        -- normal unit menus
        "MENU_UNIT_PLAYER",
        "MENU_UNIT_SELF",
        "MENU_UNIT_TARGET",
        "MENU_UNIT_PARTY",
        "MENU_UNIT_RAID_PLAYER",
        "MENU_UNIT_FRIEND",
        "MENU_UNIT_GUILD",

        -- Group Finder / LFG menus
        "MENU_UNIT_LFG",
        "MENU_UNIT_LFG_LIST",
        "MENU_UNIT_LFG_LIST_ENTRY",
        "MENU_UNIT_APPLICANT",
        "MENU_UNIT_SEARCH",
    }


    for _, menu in ipairs(menus) do

        Menu.ModifyMenu(menu, AddWCLButton)

    end
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()

    C_Timer.After(1, Initialize)

end)
