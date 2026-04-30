local ADDON_NAME = "ArWoW_Chat"
local CHAT_FONT = "Interface\\AddOns\\ArWoW_Chat\\Fonts\\Janna LT Regular.ttf"
local chatFrameFonts, chatEditFonts, chatEditHooks, chatEditTexts = {}, {}, {}, {}
local chatPreviewFrames, chatPreviewTexts, chatNormalizeLocks = {}, {}, {}
local bubbleProcessorFrame = CreateFrame("Frame")
local originalChatEditSendText, presentationToBaseMap
local filtersRegistered, fontHookInstalled, sendHookInstalled, headerHookInstalled = false, false, false, false
local WRAP_CHARACTER_LIMIT = 60
local WRAP_REFERENCE_FONT_SIZE = 12
local WRAP_CHARACTER_LIMIT_STEP = 6
local BUBBLE_SCAN_THROTTLE = 0.1
local CHAT_EVENTS = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_CHANNEL", "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM" }
local PREFIX_FORMATS = {
   CHAT_MSG_SAY = "CHAT_SAY_GET", CHAT_MSG_YELL = "CHAT_YELL_GET", CHAT_MSG_EMOTE = "CHAT_EMOTE_GET", CHAT_MSG_WHISPER = "CHAT_WHISPER_GET",
   CHAT_MSG_WHISPER_INFORM = "CHAT_WHISPER_INFORM_GET", CHAT_MSG_PARTY = "CHAT_PARTY_GET", CHAT_MSG_PARTY_LEADER = "CHAT_PARTY_LEADER_GET", CHAT_MSG_RAID = "CHAT_RAID_GET",
   CHAT_MSG_RAID_LEADER = "CHAT_RAID_LEADER_GET", CHAT_MSG_RAID_WARNING = "CHAT_RAID_WARNING_GET", CHAT_MSG_GUILD = "CHAT_GUILD_GET", CHAT_MSG_OFFICER = "CHAT_OFFICER_GET",
   CHAT_MSG_BATTLEGROUND = "CHAT_BATTLEGROUND_GET", CHAT_MSG_BATTLEGROUND_LEADER = "CHAT_BATTLEGROUND_LEADER_GET", CHAT_MSG_BN_WHISPER = "CHAT_BN_WHISPER_GET", CHAT_MSG_BN_WHISPER_INFORM = "CHAT_BN_WHISPER_INFORM_GET",
}
local ARABIC_MOJIBAKE_MAP = {
   ["\194\129"]="\217\190", ["\194\138"]="\217\185", ["\194\141"]="\218\134", ["\194\142"]="\218\152", ["\194\143"]="\218\136", ["\194\144"]="\218\175",
   ["\194\152"]="\218\169", ["\194\154"]="\218\145", ["\194\159"]="\218\186", ["\194\161"]="\216\140", ["\194\170"]="\218\190", ["\194\186"]="\216\155",
   ["\194\191"]="\216\159", ["\195\128"]="\219\129", ["\195\129"]="\216\161", ["\195\130"]="\216\162", ["\195\131"]="\216\163", ["\195\132"]="\216\164",
   ["\195\133"]="\216\165", ["\195\134"]="\216\166", ["\195\135"]="\216\167", ["\195\136"]="\216\168", ["\195\137"]="\216\169", ["\195\138"]="\216\170",
   ["\195\139"]="\216\171", ["\195\140"]="\216\172", ["\195\141"]="\216\173", ["\195\142"]="\216\174", ["\195\143"]="\216\175", ["\195\144"]="\216\176",
   ["\195\145"]="\216\177", ["\195\146"]="\216\178", ["\195\147"]="\216\179", ["\195\148"]="\216\180", ["\195\149"]="\216\181", ["\195\150"]="\216\182",
   ["\195\152"]="\216\183", ["\195\153"]="\216\184", ["\195\154"]="\216\185", ["\195\155"]="\216\186", ["\195\156"]="\217\128", ["\195\157"]="\217\129",
   ["\195\158"]="\217\130", ["\195\159"]="\217\131", ["\195\161"]="\217\132", ["\195\163"]="\217\133", ["\195\164"]="\217\134", ["\195\165"]="\217\135",
   ["\195\166"]="\217\136", ["\195\172"]="\217\137", ["\195\173"]="\217\138", ["\195\176"]="\217\139", ["\195\177"]="\217\140", ["\195\178"]="\217\141",
   ["\195\179"]="\217\142", ["\195\181"]="\217\143", ["\195\182"]="\217\144", ["\195\184"]="\217\145", ["\195\186"]="\217\146", ["\195\191"]="\219\146",
}
local function EnsureDB() if (type(ArWoWChatDB) ~= "table") then ArWoWChatDB = {} end if (ArWoWChatDB.enabled ~= "0") then ArWoWChatDB.enabled = "1" end return ArWoWChatDB end
local function IsEnabled() return (EnsureDB().enabled == "1") end
local function PrintStatus(message) if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage and message) then DEFAULT_CHAT_FRAME:AddMessage("|cffffff00ArWoW_Chat:|r " .. message) end end
local function NextUtf8(text, pos)
   local ok, charbytes = pcall(AS_UTF8charbytes, text, pos)
   if (not ok or not charbytes or charbytes < 1) then return "", 1, false end
   return string.sub(text, pos, pos + charbytes - 1), charbytes, true
end
local function DecodeArabicInput(text)
   if (not text or text == "") then return text or "" end
   local out, pos, bytes = {}, 1, string.len(text)
   while (pos <= bytes) do local char, charbytes, valid = NextUtf8(text, pos) if (valid and char ~= "") then out[#out + 1] = ARABIC_MOJIBAKE_MAP[char] or char end pos = pos + charbytes end
   return table.concat(out)
end
local function BuildPresentationMap()
   if (presentationToBaseMap) then return end
   presentationToBaseMap = {}
   for _, rules in ipairs({ AS_Reshaping_Rules, AS_Reshaping_Rules2 }) do
      if (rules) then
         for baseChar, forms in pairs(rules) do
            if (forms) then
               if (forms.isolated) then presentationToBaseMap[forms.isolated] = baseChar end
               if (forms.initial) then presentationToBaseMap[forms.initial] = baseChar end
               if (forms.middle) then presentationToBaseMap[forms.middle] = baseChar end
               if (forms.final) then presentationToBaseMap[forms.final] = baseChar end
            end
         end
      end
   end
end
local function UnshapeArabicText(text)
   if (not text or text == "") then return text or "" end
   BuildPresentationMap()
   local out, pos, bytes = {}, 1, string.len(text)
   while (pos <= bytes) do local char, charbytes, valid = NextUtf8(text, pos) if (valid and char ~= "") then out[#out + 1] = presentationToBaseMap[char] or char end pos = pos + charbytes end
   return table.concat(out)
end
local function NormalizeArabicText(text) return UnshapeArabicText(DecodeArabicInput(text)) end
local function ReverseArabicText(text) if (text and text ~= "" and AS_ContainsArabic and AS_ContainsArabic(text)) then return AS_UTF8reverse(text) end return text or "" end
local function IsArabicDisplayChar(char)
   return (AS_IsArabicLetter and AS_IsArabicLetter(char)) or (AS_IsDiacritic and AS_IsDiacritic(char)) or (AS_IsArabicIndicNumeral and AS_IsArabicIndicNumeral(char)) or (AS_IsArabicPunctuation and AS_IsArabicPunctuation(char))
end
local function GetProtectedMarkup(text, pos)
   if (string.sub(text, pos, pos) ~= "|") then return nil end
   if (string.sub(text, pos, pos + 1) == "|T") then local _, endPos = string.find(text, "|t", pos + 2, true) if (endPos) then return string.sub(text, pos, endPos), endPos - pos + 1 end end
   if (string.sub(text, pos, pos + 1) == "|c") then local _, endPos = string.find(text, "|r", pos + 2, true) if (endPos) then return string.sub(text, pos, endPos), endPos - pos + 1 end end
   if (string.sub(text, pos, pos + 1) == "|H") then
      local _, firstEnd = string.find(text, "|h", pos + 2, true)
      if (firstEnd) then local _, secondEnd = string.find(text, "|h", firstEnd + 1, true) if (secondEnd) then return string.sub(text, pos, secondEnd), secondEnd - pos + 1 end end
   end
   if (string.sub(text, pos, pos + 1) == "|r" or string.sub(text, pos, pos + 1) == "|h") then return string.sub(text, pos, pos + 1), 2 end
end
local function StripMarkup(text)
   local visible = text or ""
   visible = string.gsub(visible, "|c%x%x%x%x%x%x%x%x", "")
   visible = string.gsub(visible, "|r", "")
   visible = string.gsub(visible, "|H.-|h(.-)|h", "%1")
   return string.gsub(visible, "|T.-|t", "")
end
local function ParseEntries(text)
   local entries, leadingSpaces, currentToken, pos, bytes = {}, "", "", 1, string.len(text or "")
   while (pos <= bytes) do
      local markup, markupBytes = GetProtectedMarkup(text, pos)
      if (markup and markupBytes and markupBytes > 0) then
         if (currentToken ~= "") then entries[#entries + 1], currentToken = { token = currentToken, spacesAfter = "" }, "" end
         entries[#entries + 1] = { token = markup, spacesAfter = "" }
         pos = pos + markupBytes
      else
         local char, charbytes = NextUtf8(text, pos)
         if (char == " " or char == "\t") then
            if (currentToken ~= "") then entries[#entries + 1], currentToken = { token = currentToken, spacesAfter = "" }, "" end
            if (#entries > 0) then entries[#entries].spacesAfter = entries[#entries].spacesAfter .. char else leadingSpaces = leadingSpaces .. char end
         elseif (char ~= "") then
            currentToken = currentToken .. char
         end
         pos = pos + charbytes
      end
   end
   if (currentToken ~= "") then entries[#entries + 1] = { token = currentToken, spacesAfter = "" } end
   return leadingSpaces, entries
end
local function BuildVisualToken(token)
   if (not token or token == "" or string.sub(token, 1, 1) == "|") then return token or "" end
   if (not AS_ContainsArabic or not AS_ContainsArabic(token) or not string.find(token, "[A-Za-z0-9]")) then return ReverseArabicText(token) end
   local runs, currentRun, currentArabic, pos, bytes = {}, "", nil, 1, string.len(token)
   while (pos <= bytes) do
      local char, charbytes = NextUtf8(token, pos)
      local isArabic = IsArabicDisplayChar(char)
      if (currentArabic == nil or currentArabic == isArabic) then currentRun = currentRun .. char else runs[#runs + 1], currentRun = currentArabic and ReverseArabicText(currentRun) or currentRun, char end
      currentArabic, pos = isArabic, pos + charbytes
   end
   if (currentRun ~= "") then runs[#runs + 1] = currentArabic and ReverseArabicText(currentRun) or currentRun end
   local visual = {}
   for i = #runs, 1, -1 do visual[#visual + 1] = runs[i] end
   return table.concat(visual)
end
local function IsLeftToRightToken(token)
   local visibleToken = StripMarkup(token)
   return (visibleToken ~= "" and string.find(visibleToken, "[A-Za-z0-9]") and (not AS_ContainsArabic or not AS_ContainsArabic(visibleToken))) and true or false
end
local function ShapeArabicText(text)
   if (not text or text == "") then return text or "" end
   if (not AS_ContainsArabic or not AS_ContainsArabic(text)) then return text end
   local leadingSpaces, entries = ParseEntries(text)
   if (#entries == 0) then return ReverseArabicText(text) end
   local out = { leadingSpaces }
   local index = #entries
   while (index >= 1) do
      if (IsLeftToRightToken(entries[index].token)) then
         local startIndex = index
         while (startIndex > 1 and IsLeftToRightToken(entries[startIndex - 1].token)) do startIndex = startIndex - 1 end
         for i = startIndex, index do
            out[#out + 1] = BuildVisualToken(entries[i].token)
            if (i < index) then out[#out + 1] = entries[i].spacesAfter end
         end
         if (startIndex > 1) then out[#out + 1] = entries[startIndex - 1].spacesAfter end
         index = startIndex - 1
      else
         out[#out + 1] = BuildVisualToken(entries[index].token)
         if (index > 1) then out[#out + 1] = entries[index - 1].spacesAfter end
         index = index - 1
      end
   end
   return table.concat(out)
end
local function Utf8Length(text)
   if (not text or text == "") then return 0 end
   local ok, length = pcall(AS_UTF8len, text)
   if (ok and length) then return length end
   return string.len(text)
end
local function ResolveChatFrame(owner)
   if (not owner) then return nil end
   if (owner.chatFrame and owner.chatFrame.GetID) then return owner.chatFrame end
   if (owner.GetID and owner.GetName) then
      local ownerName = owner:GetName()
      if (ownerName and string.find(ownerName, "^ChatFrame%d+$")) then return owner end
   end
   if (owner.GetParent) then
      local parent = owner:GetParent()
      if (parent and parent.GetID and parent.GetName) then
         local parentName = parent:GetName()
         if (parentName and string.find(parentName, "^ChatFrame%d+$")) then return parent end
      end
   end
   return owner
end
local function GetOwnerFontSize(owner)
   local chatFrame = ResolveChatFrame(owner)
   if (chatFrame and FCF_GetChatWindowInfo and chatFrame.GetID) then
      local _, fontSize = FCF_GetChatWindowInfo(chatFrame:GetID())
      fontSize = tonumber(fontSize)
      if (fontSize and fontSize > 0) then return fontSize end
   end
   if (owner and owner.GetFont) then
      local _, fontSize = owner:GetFont()
      fontSize = tonumber(fontSize)
      if (fontSize and fontSize > 0) then return fontSize end
   end
   if (chatFrame and chatFrame ~= owner and chatFrame.GetFont) then
      local _, fontSize = chatFrame:GetFont()
      fontSize = tonumber(fontSize)
      if (fontSize and fontSize > 0) then return fontSize end
   end
   return WRAP_REFERENCE_FONT_SIZE
end
local function ComputeWrapCharacterLimit(fontSize)
   fontSize = (tonumber(fontSize) and tonumber(fontSize) > 0) and tonumber(fontSize) or WRAP_REFERENCE_FONT_SIZE
   return math.max(math.floor((WRAP_CHARACTER_LIMIT - ((fontSize - WRAP_REFERENCE_FONT_SIZE) * WRAP_CHARACTER_LIMIT_STEP)) + 0.5), 8)
end
local function GetWrapCharacterLimit(owner)
   local chatFrame = ResolveChatFrame(owner)
   if (chatFrame and chatFrame.ArWoWWrapLimit) then return chatFrame.ArWoWWrapLimit end
   return ComputeWrapCharacterLimit(GetOwnerFontSize(owner))
end
local function BuildTokenRun(entries, startIndex, endIndex)
   local parts, visibleCount = {}, 0
   for i = startIndex, endIndex do
      local tokenText = entries[i].token or ""
      parts[#parts + 1] = tokenText
      visibleCount = visibleCount + Utf8Length(StripMarkup(tokenText))
      if (i < endIndex) then
         local spaces = entries[i].spacesAfter or ""
         if (spaces ~= "") then parts[#parts + 1] = spaces end
         visibleCount = visibleCount + Utf8Length(spaces)
      end
   end
   return table.concat(parts), visibleCount
end
local function SplitVisualTextByCharacterLimit(text, firstLimit, nextLimit)
   if (not text or text == "") then return { text or "" } end
   firstLimit = (firstLimit and firstLimit > 0) and firstLimit or WRAP_CHARACTER_LIMIT
   nextLimit = (nextLimit and nextLimit > 0) and nextLimit or firstLimit
   local leadingSpaces, entries = ParseEntries(text)
   if (#entries == 0) then return { text } end
   local lines, currentLine, currentCount, currentLimit = {}, "", 0, firstLimit
   local function PushLine(lineText)
      if (lineText ~= "" or #lines == 0) then lines[#lines + 1] = lineText end
   end
   local index = #entries
   while (index >= 1) do
      local tokenText, tokenVisibleCount, separatorText, visibleCount
      if (IsLeftToRightToken(entries[index].token)) then
         local startIndex = index
         while (startIndex > 1 and IsLeftToRightToken(entries[startIndex - 1].token)) do startIndex = startIndex - 1 end
         tokenText, tokenVisibleCount = BuildTokenRun(entries, startIndex, index)
         separatorText = (currentLine ~= "") and (entries[index].spacesAfter or "") or ""
         visibleCount = tokenVisibleCount + Utf8Length(separatorText)
         index = startIndex - 1
      else
         tokenText = entries[index].token or ""
         tokenVisibleCount = Utf8Length(StripMarkup(tokenText))
         separatorText = (currentLine ~= "") and (entries[index].spacesAfter or "") or ""
         visibleCount = tokenVisibleCount + Utf8Length(separatorText)
         index = index - 1
      end
      if (currentLine ~= "" and currentCount + visibleCount > currentLimit) then
         PushLine(currentLine)
         currentLine = tokenText
         currentCount = tokenVisibleCount
         currentLimit = nextLimit
      else
         currentLine = tokenText .. separatorText .. currentLine
         currentCount = currentCount + visibleCount
      end
   end
   if (leadingSpaces ~= "") then currentLine = leadingSpaces .. currentLine end
   PushLine(currentLine)
   return lines
end
local function BuildWrappedVisualText(logicalText, firstLineLimit, nextLineLimit)
   local visualText = ShapeArabicText(logicalText)
   local lines = SplitVisualTextByCharacterLimit(visualText, firstLineLimit or WRAP_CHARACTER_LIMIT, nextLineLimit or WRAP_CHARACTER_LIMIT)
   if (#lines <= 1) then return visualText end
   visualText = table.concat(lines, "\n")
   visualText = string.gsub(visualText, " \n", "\n")
   visualText = string.gsub(visualText, "\n ", "\n")
   return visualText
end
local function GetMeasureText() if (not AS_TestLine and AS_CreateTestLine) then AS_CreateTestLine() end return AS_TestLine and AS_TestLine.text or nil end
local function SetMeasureFont(owner, width)
   local measureText = GetMeasureText()
   if (not measureText or not owner or not owner.GetFont) then return nil, 13 end
   local fontFile, fontSize, fontFlags = owner:GetFont()
   measureText:SetWidth(math.max(width or 32, 32))
   measureText:SetFont(fontFile or CHAT_FONT, fontSize or 13, fontFlags or "")
   return measureText, fontSize or 13
end
local function MeasureTextHeight(owner, width, text)
   local measureText, fontSize = SetMeasureFont(owner, width)
   if (not measureText) then return 0, fontSize end
   measureText:SetText(StripMarkup(text))
   return measureText:GetHeight() or 0, fontSize
end
local function FitsOnOneLine(owner, width, text, prefix)
   local height, fontSize = MeasureTextHeight(owner, width, (prefix or "") .. (text or ""))
   return (height <= (fontSize or 13) * 1.5)
end
local function GetWrapSafetyWidth(chatFrame) local _, fontSize = chatFrame:GetFont() return math.max(math.floor((fontSize or 13) * 0.9), 8) end
local function BuildLanguagePrefix(chatFrame, languageName) if (languageName and languageName ~= "" and languageName ~= "Universal" and languageName ~= chatFrame.defaultLanguage) then return "[" .. languageName .. "] " end return "" end
local function StripRealm(name) local dashPos = string.find(name or "", "-", 1, true) return (dashPos and dashPos > 1) and string.sub(name, 1, dashPos - 1) or (name or "") end
local function GetChatTimestampPrefix() if (CHAT_TIMESTAMP_FORMAT and BetterDate) then return BetterDate(CHAT_TIMESTAMP_FORMAT, time()) end return "" end
local function GetLeatrixTimestampPrefix(chatFrame)
   if (not chatFrame or not chatFrame.LeaPlusChatTimestampHooked or CHAT_TIMESTAMP_FORMAT or not LeaPlusDB or LeaPlusDB.ChatTimestamps ~= "On") then return "" end
   local formats = { [1] = "%I:%M:%S %p", [2] = "%I:%M %p", [3] = "%X", [4] = "%H:%M", [5] = "%M:%S", [6] = "%I:%M:%S" }
   local ok, stamp = pcall(date, "[" .. (formats[LeaPlusDB.ChatTimestampFormatMenu] or "%X") .. "]")
   if (not ok or not stamp) then stamp = date("[%X]") end
   if (LeaPlusDB.ChatTimestampUseChannelColor == "On") then return stamp end
   return string.format("|cff%02x%02x%02x%s|r", math.floor((LeaPlusDB.ChatTimestampRed or 115) + 0.5), math.floor((LeaPlusDB.ChatTimestampGreen or 115) + 0.5), math.floor((LeaPlusDB.ChatTimestampBlue or 115) + 0.5), stamp)
end
local function BuildVisiblePrefix(chatFrame, eventName, speakerName, languageName, channelName)
   local prefix = GetChatTimestampPrefix() if (prefix == "") then prefix = GetLeatrixTimestampPrefix(chatFrame) end
   if (eventName == "CHAT_MSG_TEXT_EMOTE") then return StripMarkup(prefix) end
   local visibleSpeaker, languagePrefix = StripRealm(speakerName), BuildLanguagePrefix(chatFrame, languageName)
   if (eventName == "CHAT_MSG_CHANNEL") then
      local cleanChannel = string.gsub(channelName or "", "%s%-%s.*", "")
      local ok, bodyPrefix = pcall(format, StripMarkup(CHAT_CHANNEL_GET or "%s: ") .. languagePrefix, "[" .. visibleSpeaker .. "]")
      return StripMarkup(prefix) .. ((cleanChannel ~= "") and ("[" .. cleanChannel .. "] ") or "") .. (ok and bodyPrefix or "")
   end
   local template = PREFIX_FORMATS[eventName] and _G[PREFIX_FORMATS[eventName]] or nil
   if (not template) then return StripMarkup(prefix) end
   local speakerToken = (eventName == "CHAT_MSG_EMOTE") and visibleSpeaker or ("[" .. visibleSpeaker .. "]")
   local ok, bodyPrefix = pcall(format, StripMarkup(template) .. languagePrefix, speakerToken)
   return StripMarkup(prefix) .. (ok and bodyPrefix or "")
end
local function WrapLogicalText(chatFrame, logicalText, prefixText, wrapWidth)
   if (not logicalText or logicalText == "") then return logicalText or "" end
   local wrapLimit = GetWrapCharacterLimit(chatFrame)
   local firstLineLimit = math.max(wrapLimit - Utf8Length(prefixText), 1)
   return BuildWrappedVisualText(logicalText, firstLineLimit, wrapLimit)
end
local function BuildWrappedMessage(chatFrame, eventName, messageText, speakerName, languageName, channelName)
   local logicalText = NormalizeArabicText(messageText)
   if (not logicalText or logicalText == "" or not AS_ContainsArabic or not AS_ContainsArabic(logicalText)) then return nil end
   local prefixText = BuildVisiblePrefix(chatFrame, eventName, speakerName, languageName, channelName)
   local wrapLimit = GetWrapCharacterLimit(chatFrame)
   local firstLineLimit = math.max(wrapLimit - Utf8Length(prefixText), 1)
   return BuildWrappedVisualText(logicalText, firstLineLimit, wrapLimit)
end
local function ResetBubbleQueue()
   bubbleProcessorFrame.ArWoWThrottle = nil
   bubbleProcessorFrame:SetScript("OnUpdate", nil)
end
local function IterateBubbleTextRegions(callback)
   if (not WorldFrame or not WorldFrame.GetNumChildren) then return end
   for i = 1, WorldFrame:GetNumChildren() do
      local bubbleFrame = select(i, WorldFrame:GetChildren())
      local backdrop = bubbleFrame and bubbleFrame.GetBackdrop and bubbleFrame:GetBackdrop()
      if (bubbleFrame and backdrop and backdrop.bgFile == "Interface\\Tooltips\\ChatBubble-Background") then
         for j = 1, bubbleFrame:GetNumRegions() do
            local region = select(j, bubbleFrame:GetRegions())
            if (region and region.GetObjectType and region:GetObjectType() == "FontString") then callback(bubbleFrame, region) end
         end
      end
   end
end
local function NormalizeBubbleMatchText(text)
   local visibleText = StripMarkup(text or "")
   visibleText = string.gsub(visibleText, "^%s+", "")
   visibleText = string.gsub(visibleText, "%s+$", "")
   return string.gsub(visibleText, "^%[(.-)%]$", "%1")
end
local function GetBubbleRegionWidth(region)
   local owner = region
   while (owner) do
      if (owner.GetWidth) then
         local width = tonumber(owner:GetWidth())
         if (width and width > 32) then return math.max(math.floor(width - 10), 32) end
      end
      owner = owner.GetParent and owner:GetParent() or nil
   end
   return 220
end
local function GetBubbleTextWidth(region, text)
   local measureText = GetMeasureText()
   if (not measureText or not region or not region.GetFont) then return nil end
   local fontFile, fontSize, fontFlags = region:GetFont()
   measureText:SetWidth(4096)
   measureText:SetFont(fontFile or CHAT_FONT, fontSize or 13, fontFlags or "")
   local maxWidth = 0
   for line in string.gmatch((text or "") .. "\n", "(.-)\n") do
      measureText:SetText(StripMarkup(line))
      maxWidth = math.max(maxWidth, measureText:GetStringWidth() or 0)
   end
   return math.max(math.floor(maxWidth + ((fontSize or 13) * 0.8)), 32)
end
local function SplitVisualTextByWidth(owner, width, text)
   if (not text or text == "") then return { text or "" } end
   local safeWidth = math.max(math.floor((width or 0) - GetWrapSafetyWidth(owner)), 32)
   local leadingSpaces, entries = ParseEntries(text)
   if (#entries == 0) then return { text } end
   local lines, currentLine = {}, ""
   local function PushLine(lineText)
      if (lineText ~= "" or #lines == 0) then lines[#lines + 1] = lineText end
   end
   local index = #entries
   while (index >= 1) do
      local tokenText, separatorText
      if (IsLeftToRightToken(entries[index].token)) then
         local startIndex = index
         while (startIndex > 1 and IsLeftToRightToken(entries[startIndex - 1].token)) do startIndex = startIndex - 1 end
         tokenText = BuildTokenRun(entries, startIndex, index)
         separatorText = (currentLine ~= "") and (entries[index].spacesAfter or "") or ""
         index = startIndex - 1
      else
         tokenText = entries[index].token or ""
         separatorText = (currentLine ~= "") and (entries[index].spacesAfter or "") or ""
         index = index - 1
      end
      local candidate = (currentLine ~= "") and (tokenText .. separatorText .. currentLine) or tokenText
      if (currentLine ~= "" and not FitsOnOneLine(owner, safeWidth, candidate)) then
         PushLine(currentLine)
         currentLine = tokenText
      else
         currentLine = candidate
      end
   end
   if (leadingSpaces ~= "") then currentLine = leadingSpaces .. currentLine end
   PushLine(currentLine)
   return lines
end
local function BuildBubbleVisualText(region, logicalText, wrapWidth)
   if (not logicalText or logicalText == "") then return logicalText or "" end
   local bubbleLines = {}
   for logicalLine in string.gmatch((logicalText or "") .. "\n", "(.-)\n") do
      local visualText = ShapeArabicText(logicalLine)
      local lines = SplitVisualTextByWidth(region, wrapWidth or GetBubbleRegionWidth(region), visualText)
      for i = 1, #lines do bubbleLines[#bubbleLines + 1] = lines[i] end
   end
   if (#bubbleLines == 0) then return "" end
   local bubbleText = table.concat(bubbleLines, "\n")
   bubbleText = string.gsub(bubbleText, " \n", "\n")
   bubbleText = string.gsub(bubbleText, "\n ", "\n")
   return bubbleText
end
local function BuildBubbleSourceText(text)
   if (not text or text == "") then return text or "" end
   return NormalizeBubbleMatchText(text)
end
local function BubbleNeedsRightJustify(logicalText, bubbleText)
   return (string.find(bubbleText or "", "\n", 1, true) ~= nil)
end
local function ProcessBubbleRegion(frame, region)
   if (not frame or not region or not frame.IsShown or not frame:IsShown()) then
      if (region) then region.ArWoWLastBubbleSourceText, region.ArWoWLastBubbleProcessedText, region.ArWoWStableBubbleWidth = nil, nil, nil end
      return
   end
   if (not region.GetText or not region.SetText or not region.GetFont or not region.SetFont or not region.SetJustifyH) then return end
   local currentText = region:GetText() or ""
   if (currentText == "") then
      region.ArWoWLastBubbleSourceText, region.ArWoWLastBubbleProcessedText, region.ArWoWStableBubbleWidth = nil, nil, nil
      return
   end
   local sourceText = (currentText == region.ArWoWLastBubbleProcessedText and region.ArWoWLastBubbleSourceText) and region.ArWoWLastBubbleSourceText or currentText
   local logicalText = NormalizeArabicText(BuildBubbleSourceText(sourceText))
   if (logicalText == "" or not AS_ContainsArabic or not AS_ContainsArabic(logicalText)) then
      region.ArWoWLastBubbleSourceText, region.ArWoWLastBubbleProcessedText, region.ArWoWStableBubbleWidth = nil, nil, nil
      return
   end
   local _, fontSize, fontFlags = region:GetFont()
   if (currentText ~= region.ArWoWLastBubbleProcessedText or not region.ArWoWStableBubbleWidth) then region.ArWoWStableBubbleWidth = GetBubbleRegionWidth(region) end
   region:SetFont(CHAT_FONT, fontSize or 13, fontFlags or "")
   local bubbleText = BuildBubbleVisualText(region, logicalText, region.ArWoWStableBubbleWidth)
   if (bubbleText ~= currentText) then region:SetText(bubbleText) end
   region:SetJustifyH(BubbleNeedsRightJustify(logicalText, bubbleText) and "RIGHT" or "CENTER")
   region.ArWoWLastBubbleSourceText = sourceText
   region.ArWoWLastBubbleProcessedText = bubbleText
end
local function ProcessBubbleQueue(_, elapsed)
   if (not IsEnabled()) then ResetBubbleQueue() return end
   bubbleProcessorFrame.ArWoWThrottle = (bubbleProcessorFrame.ArWoWThrottle or BUBBLE_SCAN_THROTTLE) - (elapsed or 0)
   if (bubbleProcessorFrame.ArWoWThrottle > 0) then return end
   bubbleProcessorFrame.ArWoWThrottle = BUBBLE_SCAN_THROTTLE
   IterateBubbleTextRegions(ProcessBubbleRegion)
end
local function GetEditBoxColor(editBox)
   local chatType = editBox and editBox.GetAttribute and editBox:GetAttribute("chatType")
   local info = (chatType and ChatTypeInfo and ChatTypeInfo[chatType]) or (ChatTypeInfo and ChatTypeInfo.SAY)
   if (chatType == "CHANNEL" and editBox and editBox.GetAttribute and GetChannelName and ChatTypeInfo) then
      local channel = GetChannelName(editBox:GetAttribute("channelTarget"))
      if (channel and channel > 0 and ChatTypeInfo["CHANNEL" .. tostring(channel)]) then info = ChatTypeInfo["CHANNEL" .. tostring(channel)] end
   end
   if (not info) then return 1, 1, 1 end
   return info.r or 1, info.g or 1, info.b or 1
end
local function ClearHighlight(editBox)
   if (editBox and editBox.HighlightText and editBox.GetCursorPosition) then local cursorPosition = editBox:GetCursorPosition() or 0 editBox:HighlightText(cursorPosition, cursorPosition) end
end
local function ShouldUsePreview(logicalText)
   return IsEnabled() and logicalText and logicalText ~= "" and string.sub(logicalText, 1, 1) ~= "/" and AS_ContainsArabic and AS_ContainsArabic(logicalText)
end
local function EnsurePreview(editBox)
   if (chatPreviewTexts[editBox]) then return chatPreviewTexts[editBox] end
   local previewFrame = CreateFrame("Frame", nil, editBox)
   if (previewFrame.SetClipsChildren) then previewFrame:SetClipsChildren(true) end
   local previewText = previewFrame:CreateFontString(nil, "ARTWORK")
   previewText:SetJustifyH("RIGHT")
   previewText:SetJustifyV("MIDDLE")
   if (previewText.SetWordWrap) then previewText:SetWordWrap(false) end
   if (previewText.SetNonSpaceWrap) then previewText:SetNonSpaceWrap(false) end
   previewFrame:Hide() previewText:Hide()
   chatPreviewFrames[editBox], chatPreviewTexts[editBox] = previewFrame, previewText
   return previewText
end
local function UpdateEditBoxLayout(editBox, logicalText)
   if (not editBox or not editBox.SetJustifyH or not editBox.SetTextColor) then return end
   local red, green, blue = GetEditBoxColor(editBox)
   local previewFrame, previewText = chatPreviewFrames[editBox], chatPreviewTexts[editBox]
   if (ShouldUsePreview(logicalText)) then
      previewText = EnsurePreview(editBox) previewFrame = chatPreviewFrames[editBox]
      local leftInset = 15 + ((editBox.header and editBox.header.GetWidth and editBox.header:GetWidth()) or 0)
      local _, fontSize, fontFlags = editBox:GetFont()
      previewFrame:ClearAllPoints() previewFrame:SetPoint("TOPLEFT", editBox, "TOPLEFT", leftInset, 0) previewFrame:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -13, 0) previewFrame:Show()
      previewText:ClearAllPoints() previewText:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", 0, 0) previewText:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", 0, 0)
      previewText:SetFont(CHAT_FONT, fontSize or 13, fontFlags or "") previewText:SetTextColor(red, green, blue, 1) previewText:SetText(ShapeArabicText(logicalText)) previewText:Show()
      editBox:SetTextColor(red, green, blue, 0) editBox:SetJustifyH("RIGHT") return
   end
   if (previewFrame) then previewFrame:Hide() end
   if (previewText) then previewText:SetText("") previewText:Hide() end
   editBox:SetTextColor(red, green, blue, 1) editBox:SetJustifyH(ShouldUsePreview(logicalText) and "RIGHT" or "LEFT")
end
local function RefreshEditBox(editBox)
   if (not editBox or not editBox.GetText or not editBox.SetText) then return end
   local rawText = editBox:GetText() or ""
   if (rawText == "") then chatEditTexts[editBox] = nil UpdateEditBoxLayout(editBox, nil) return end
   local logicalText = NormalizeArabicText(rawText)
   chatEditTexts[editBox] = logicalText
   if (logicalText ~= rawText) then chatNormalizeLocks[editBox] = true editBox:SetText(logicalText) if (editBox.SetCursorPosition) then editBox:SetCursorPosition(string.len(logicalText)) end chatNormalizeLocks[editBox] = nil end
   UpdateEditBoxLayout(editBox, logicalText)
end
local function InstallEditHooks(editBox)
   if (not editBox or not editBox.HookScript or chatEditHooks[editBox]) then return end
   editBox:HookScript("OnTextChanged", function(self) if (chatNormalizeLocks[self]) then return end if (not IsEnabled()) then chatEditTexts[self] = nil UpdateEditBoxLayout(self, nil) return end RefreshEditBox(self) end)
   editBox:HookScript("OnMouseUp", function(self) local logicalText = chatEditTexts[self] if (logicalText and ShouldUsePreview(logicalText)) then ClearHighlight(self) UpdateEditBoxLayout(self, logicalText) end end)
   editBox:HookScript("OnEditFocusGained", function(self) UpdateEditBoxLayout(self, chatEditTexts[self]) end)
   chatEditHooks[editBox] = true
end
local function ApplyFontToChatFrame(chatFrame)
   if (not chatFrame or not chatFrame.GetFont or not chatFrame.SetFont) then return end
   if (not chatFrameFonts[chatFrame]) then local font, size, flags = chatFrame:GetFont() chatFrameFonts[chatFrame] = { font = font, size = size, flags = flags } end
   local _, size, flags = chatFrame:GetFont() chatFrame:SetFont(CHAT_FONT, size or 13, flags or "") chatFrame.ArWoWWrapLimit = ComputeWrapCharacterLimit(size)
end
local function RestoreFontToChatFrame(chatFrame)
   local fontData = chatFrameFonts[chatFrame]
   if (fontData and fontData.font and fontData.size) then chatFrame:SetFont(fontData.font, fontData.size, fontData.flags) end
   if (chatFrame) then chatFrame.ArWoWWrapLimit = nil end
end
local function ApplyFontToEditBox(editBox)
   if (not editBox or not editBox.GetFont or not editBox.SetFont) then return end
   InstallEditHooks(editBox)
   editBox.chatFrame = ResolveChatFrame(editBox)
   if (not chatEditFonts[editBox]) then local font, size, flags = editBox:GetFont() chatEditFonts[editBox] = { font = font, size = size, flags = flags } end
   local _, size, flags = editBox:GetFont() editBox:SetFont(CHAT_FONT, size or 13, flags or "")
   if (IsEnabled()) then RefreshEditBox(editBox) end
end
local function RestoreFontToEditBox(editBox)
   local fontData = chatEditFonts[editBox]
   if (fontData and fontData.font and fontData.size) then editBox:SetFont(fontData.font, fontData.size, fontData.flags) end
   chatEditTexts[editBox] = nil UpdateEditBoxLayout(editBox, nil)
end
local function ApplyFonts()
   for index = 1, (NUM_CHAT_WINDOWS or 0) do
      local chatFrame = _G["ChatFrame" .. tostring(index)] if (chatFrame) then ApplyFontToChatFrame(chatFrame) end
      local editBox = _G["ChatFrame" .. tostring(index) .. "EditBox"] if (editBox) then ApplyFontToEditBox(editBox) end
   end
   if (GMChatFrame) then ApplyFontToChatFrame(GMChatFrame) end
end
local function RestoreFonts() for chatFrame in pairs(chatFrameFonts) do RestoreFontToChatFrame(chatFrame) end for editBox in pairs(chatEditFonts) do RestoreFontToEditBox(editBox) end end
local function ArabicChatFilter(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
   if (not IsEnabled()) then return false end
   local shapedText = BuildWrappedMessage(self, event, arg1, arg2, arg3, arg4)
   if (shapedText and shapedText ~= arg1) then return false, shapedText, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12 end
   return false
end
local function RegisterFilters() if (filtersRegistered) then return end for i = 1, #CHAT_EVENTS do ChatFrame_AddMessageEventFilter(CHAT_EVENTS[i], ArabicChatFilter) end filtersRegistered = true end
local function UnregisterFilters() if (not filtersRegistered) then return end for i = 1, #CHAT_EVENTS do ChatFrame_RemoveMessageEventFilter(CHAT_EVENTS[i], ArabicChatFilter) end filtersRegistered = false end
local function InstallSendHook()
   if (sendHookInstalled or not ChatEdit_SendText) then return end
   originalChatEditSendText = ChatEdit_SendText
   ChatEdit_SendText = function(editBox, addHistory)
      if (not IsEnabled() or not editBox or not editBox.GetText or not editBox.SetText) then return originalChatEditSendText(editBox, addHistory) end
      local rawText = editBox:GetText() or ""
      local logicalText = chatEditTexts[editBox] or NormalizeArabicText(rawText)
      if (logicalText ~= rawText) then editBox:SetText(logicalText) end
      chatEditTexts[editBox] = nil
      return originalChatEditSendText(editBox, addHistory)
   end
   sendHookInstalled = true
end
local function InstallFontHook()
   if (fontHookInstalled) then return end
   hooksecurefunc("FCF_SetChatWindowFontSize", function(_, chatFrame)
      if (not IsEnabled()) then return end
      if (chatFrame) then
         ApplyFontToChatFrame(chatFrame)
         local editBox = chatFrame.editBox or ((chatFrame.GetName and _G[chatFrame:GetName() .. "EditBox"]) or nil)
         if (editBox) then ApplyFontToEditBox(editBox) end
      else
         ApplyFonts()
      end
   end)
   fontHookInstalled = true
end
local function InstallHeaderHook()
   if (headerHookInstalled) then return end
   hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
      if (not editBox) then return end
      local logicalText = chatEditTexts[editBox]
      if ((not logicalText or logicalText == "") and editBox.GetText) then
         local currentText = editBox:GetText() or ""
         if (currentText ~= "") then logicalText = NormalizeArabicText(currentText) chatEditTexts[editBox] = logicalText end
      end
      UpdateEditBoxLayout(editBox, logicalText)
   end)
   headerHookInstalled = true
end
local function ApplySupport()
   InstallSendHook() InstallFontHook() InstallHeaderHook()
   if (IsEnabled()) then bubbleProcessorFrame.ArWoWThrottle = 0 bubbleProcessorFrame:SetScript("OnUpdate", ProcessBubbleQueue) RegisterFilters() ApplyFonts() else ResetBubbleQueue() UnregisterFilters() RestoreFonts() end
end
local function SetEnabled(enabled) EnsureDB().enabled = enabled and "1" or "0" ApplySupport() end
local function SlashCommand(msg)
   msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))
   if (msg == "" or msg == "toggle") then SetEnabled(not IsEnabled())
   elseif (msg == "on" or msg == "enable") then SetEnabled(true)
   elseif (msg == "off" or msg == "disable") then SetEnabled(false)
   elseif (msg ~= "status") then PrintStatus("Usage: /archat on|off|toggle|status") return end
   PrintStatus(IsEnabled() and "Arabic chat is enabled." or "Arabic chat is disabled.")
end
SlashCmdList.ARWOW_CHAT = SlashCommand
SLASH_ARWOW_CHAT1 = "/archat"
SLASH_ARWOW_CHAT2 = "/arwowchat"
local addonFrame = CreateFrame("Frame", "ArWoW_ChatFrame")
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
addonFrame:SetScript("OnEvent", function(self, event, arg1)
   if (event == "ADDON_LOADED") then
      if (arg1 ~= ADDON_NAME) then return end
      EnsureDB() ApplySupport() self:UnregisterEvent("ADDON_LOADED")
   elseif (event == "UPDATE_CHAT_WINDOWS") then
      ApplySupport()
   end
end)
