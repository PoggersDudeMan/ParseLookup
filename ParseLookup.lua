local MENU_TEXT = "Release the Files"
local POPUP_NAME = "WCL_LINK_POPUP"

local REGION_BY_ID = {
    [1] = "us",
    [2] = "kr",
    [3] = "eu",
    [4] = "tw",
    [5] = "cn",
}

local ZONE = 47

-- URL

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

-- Popup

StaticPopupDialogs[POPUP_NAME] = {

    text = "WarcraftLogs URL (Ctrl+C to copy and close)",
    button1 = "Close",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,

    OnShow = function(self)

        local box = self.EditBox or _G[self:GetName() .. "EditBox"]

        if box then

            box:SetText(self.wclURL or "")
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

        end

    end,


    OnHide = function(self)

        local box =
            self.EditBox or
            _G[self:GetName() .. "EditBox"]

        if box then
            box:SetScript("OnKeyDown", nil)
        end

    end,
}

local function ShowPopup(url)

    local popup = StaticPopup_Show(POPUP_NAME)

    if popup then
        popup.wclURL = url

        local box =
            popup.EditBox or
            _G[popup:GetName() .. "EditBox"]

        if box then
            box:SetText(url)
            box:HighlightText()
            box:SetFocus()
        end
    end

end

-- Name handling

local function SplitNameRealm(fullName)

    if not fullName then
        return
    end

    local name, realm = strsplit("-", fullName, 2)

    if realm == "" then
        realm = nil
    end

    return name, realm
end

local function GetMenuText(className, unit)

    if className then
        return "Release the " .. className .. " Files"
    end


    if unit and UnitExists(unit) then

        local class = UnitClass(unit)

        if class then
            return "Release the " .. class .. " Files"
        end

    end


    return "Release the Files"

end

-- Modern Menu Name Detection

local function JoinNameRealm(name, realm)

    if not name then
        return
    end

    if realm and realm ~= "" then
        return name .. "-" .. realm
    end

    return name
end

local function GetLFGInfo(owner, contextData)

    local name
    local realm
    local className

    -- normal unit menus

    if contextData and contextData.unit then

        if UnitExists(contextData.unit) then

            name, realm =
                UnitFullName(contextData.unit)

            local _, class =
                UnitClass(contextData.unit)

            return name, realm, class

        end

    end

    -- context data

    if contextData then

        if contextData.name then

            return
                contextData.name,
                contextData.server or contextData.realm,
                contextData.className

        end

    end

    -- LFG applicant

    if owner and owner.memberIdx then

        local parent = owner:GetParent()

        if parent and parent.applicantID then

            local memberInfo =
                C_LFGList.GetApplicantMemberInfo(
                    parent.applicantID,
                    owner.memberIdx
                )

            if memberInfo then

                name, realm =
                    SplitNameRealm(memberInfo)


                local _, class =
                    C_LFGList.GetApplicantMemberInfo(
                        parent.applicantID,
                        owner.memberIdx
                    )

                return name, realm, class

            end

        end

    end

    -- LFG search result

    if owner and owner.resultID then

        local info =
            C_LFGList.GetSearchResultInfo(owner.resultID)


        if info then

            name, realm =
                SplitNameRealm(info.leaderName)


            return
                name,
                realm,
                info.className

        end

    end

end

-- Add Button

local function AddWCLButton(owner, rootDescription, contextData)

    local name, realm, className =
        GetLFGInfo(owner, contextData)


    if not name then
        return
    end

    rootDescription:CreateDivider()

    rootDescription:CreateButton(

        GetMenuText(
            className,
            contextData and contextData.unit
        ),

        function()

            local url =
                BuildWCLURL(
                    name,
                    realm
                )

            if url then
                ShowPopup(url)
            end

        end
    )

end

-- Register Modern Menus

local registered = false

local function Initialize()

    if registered then
        return
    end


    if not Menu or not Menu.ModifyMenu then
        return
    end


    registered = true


    local menus = {

        -- normal player menus

        "MENU_UNIT_PLAYER",
        "MENU_UNIT_SELF",
        "MENU_UNIT_TARGET",
        "MENU_UNIT_PARTY",
        "MENU_UNIT_RAID_PLAYER",
        "MENU_UNIT_FRIEND",
        "MENU_UNIT_GUILD",


        -- LFG menus

        "MENU_LFG_FRAME_MEMBER_APPLY",
        "MENU_LFG_FRAME_SEARCH_ENTRY",

    }



    for _, menu in ipairs(menus) do

        Menu.ModifyMenu(
            menu,
            AddWCLButton
        )

    end


end

-- Wait for Retail Menu API

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript(
    "OnEvent",
    function()

        C_Timer.After(
            1,
            Initialize
        )

    end
)
