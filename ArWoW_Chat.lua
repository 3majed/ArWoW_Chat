-- Addon: ArWoW_Chat
local AWC_AddonName = "ArWoW_Chat";
local AWC_Version = "0.1";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";
local QTR_Font2 = "Interface\\AddOns\\ArWoW_Chat\\Fonts\\Janna LT Regular.ttf";

local function AWC_EnsureDB()
  if (type(ArWoWChatDB) ~= "table") then
     ArWoWChatDB = {};
  end
  if (not ArWoWChatDB["enabled"]) then
     ArWoWChatDB["enabled"] = "1";
  end
  return ArWoWChatDB;
end

local function AWC_IsEnabled()
  return (AWC_EnsureDB()["enabled"] == "1");
end

local function QTR_ReverseText(text)
  if (not text or text == "") then
     return text or "";
  end
  if (AS_ContainsArabic and AS_ContainsArabic(text)) then
     return AS_UTF8reverse(text);
  end
  return text;
end

local QTR_ChatFiltersRegistered = false;
local QTR_ChatSendHookInstalled = false;
local QTR_ChatFontHookInstalled = false;
local QTR_ChatOriginalFrameFonts = {};
local QTR_ChatOriginalEditBoxFonts = {};
local QTR_ChatEditHooks = {};
local QTR_ChatEditNormalizeLock = {};
local QTR_ChatEditLogicalTexts = {};
local QTR_ChatEditPreviewFrames = {};
local QTR_ChatEditPreviewTexts = {};
local QTR_ChatEditPreviewCarets = {};
local QTR_ChatEditPreviewCaretBlinkStarts = {};
local QTR_ChatEditPreviewLastLines = {};
local QTR_ChatEditPreviewLineCounts = {};
local QTR_ChatEditPreviewOverflowing = {};
local QTR_ArabicPresentationToBaseMap = nil;
local QTR_ChatHeaderHookInstalled = false;
local QTR_ShapeChatText;
local QTR_GetChatLineMeasureText;
local QTR_MeasureChatEditPreviewTextWidth;
local QTR_BuildWrappedArabicPreviewText;
local QTR_OriginalChatEditSendText = nil;
local QTR_ChatMessageEvents = {
   "CHAT_MSG_SAY",
   "CHAT_MSG_YELL",
   "CHAT_MSG_EMOTE",
   "CHAT_MSG_TEXT_EMOTE",
   "CHAT_MSG_WHISPER",
   "CHAT_MSG_WHISPER_INFORM",
   "CHAT_MSG_PARTY",
   "CHAT_MSG_PARTY_LEADER",
   "CHAT_MSG_RAID",
   "CHAT_MSG_RAID_LEADER",
   "CHAT_MSG_RAID_WARNING",
   "CHAT_MSG_GUILD",
   "CHAT_MSG_OFFICER",
   "CHAT_MSG_CHANNEL",
   "CHAT_MSG_BATTLEGROUND",
   "CHAT_MSG_BATTLEGROUND_LEADER",
   "CHAT_MSG_BN_WHISPER",
   "CHAT_MSG_BN_WHISPER_INFORM",
   "CHAT_MSG_BN_CONVERSATION",
};
local QTR_ArabicInputMojibakeMap = {
   ["\194\129"] = "\217\190", -- 81 -> U+067E
   ["\194\138"] = "\217\185", -- 8A -> U+0679
   ["\194\141"] = "\218\134", -- 8D -> U+0686
   ["\194\142"] = "\218\152", -- 8E -> U+0698
   ["\194\143"] = "\218\136", -- 8F -> U+0688
   ["\194\144"] = "\218\175", -- 90 -> U+06AF
   ["\194\152"] = "\218\169", -- 98 -> U+06A9
   ["\194\154"] = "\218\145", -- 9A -> U+0691
   ["\194\159"] = "\218\186", -- 9F -> U+06BA
   ["\194\161"] = "\216\140", -- A1 -> U+060C
   ["\194\170"] = "\218\190", -- AA -> U+06BE
   ["\194\186"] = "\216\155", -- BA -> U+061B
   ["\194\191"] = "\216\159", -- BF -> U+061F
   ["\195\128"] = "\219\129", -- C0 -> U+06C1
   ["\195\129"] = "\216\161", -- C1 -> U+0621
   ["\195\130"] = "\216\162", -- C2 -> U+0622
   ["\195\131"] = "\216\163", -- C3 -> U+0623
   ["\195\132"] = "\216\164", -- C4 -> U+0624
   ["\195\133"] = "\216\165", -- C5 -> U+0625
   ["\195\134"] = "\216\166", -- C6 -> U+0626
   ["\195\135"] = "\216\167", -- C7 -> U+0627
   ["\195\136"] = "\216\168", -- C8 -> U+0628
   ["\195\137"] = "\216\169", -- C9 -> U+0629
   ["\195\138"] = "\216\170", -- CA -> U+062A
   ["\195\139"] = "\216\171", -- CB -> U+062B
   ["\195\140"] = "\216\172", -- CC -> U+062C
   ["\195\141"] = "\216\173", -- CD -> U+062D
   ["\195\142"] = "\216\174", -- CE -> U+062E
   ["\195\143"] = "\216\175", -- CF -> U+062F
   ["\195\144"] = "\216\176", -- D0 -> U+0630
   ["\195\145"] = "\216\177", -- D1 -> U+0631
   ["\195\146"] = "\216\178", -- D2 -> U+0632
   ["\195\147"] = "\216\179", -- D3 -> U+0633
   ["\195\148"] = "\216\180", -- D4 -> U+0634
   ["\195\149"] = "\216\181", -- D5 -> U+0635
   ["\195\150"] = "\216\182", -- D6 -> U+0636
   ["\195\152"] = "\216\183", -- D8 -> U+0637
   ["\195\153"] = "\216\184", -- D9 -> U+0638
   ["\195\154"] = "\216\185", -- DA -> U+0639
   ["\195\155"] = "\216\186", -- DB -> U+063A
   ["\195\156"] = "\217\128", -- DC -> U+0640
   ["\195\157"] = "\217\129", -- DD -> U+0641
   ["\195\158"] = "\217\130", -- DE -> U+0642
   ["\195\159"] = "\217\131", -- DF -> U+0643
   ["\195\161"] = "\217\132", -- E1 -> U+0644
   ["\195\163"] = "\217\133", -- E3 -> U+0645
   ["\195\164"] = "\217\134", -- E4 -> U+0646
   ["\195\165"] = "\217\135", -- E5 -> U+0647
   ["\195\166"] = "\217\136", -- E6 -> U+0648
   ["\195\172"] = "\217\137", -- EC -> U+0649
   ["\195\173"] = "\217\138", -- ED -> U+064A
   ["\195\176"] = "\217\139", -- F0 -> U+064B
   ["\195\177"] = "\217\140", -- F1 -> U+064C
   ["\195\178"] = "\217\141", -- F2 -> U+064D
   ["\195\179"] = "\217\142", -- F3 -> U+064E
   ["\195\181"] = "\217\143", -- F5 -> U+064F
   ["\195\182"] = "\217\144", -- F6 -> U+0650
   ["\195\184"] = "\217\145", -- F8 -> U+0651
   ["\195\186"] = "\217\146", -- FA -> U+0652
   ["\195\191"] = "\219\146", -- FF -> U+06D2
};


local function QTR_IsArabicChatEnabled()
  return AWC_IsEnabled();
end


local function QTR_GetSafeUtf8Char(text, pos)
  if (not text or text == "") then
     return "", 1, false;
  end

  local c = strbyte(text, pos);
  if (not c) then
     return "", 1, false;
  end

  local charbytes = 1;
  local isValid = true;

  if (c > 0 and c <= 127) then
     charbytes = 1;
  elseif (c >= 194 and c <= 223) then
     local c2 = strbyte(text, pos + 1);
     if (c2 and c2 >= 128 and c2 <= 191) then
        charbytes = 2;
     else
        isValid = false;
     end
  elseif (c >= 224 and c <= 239) then
     local c2 = strbyte(text, pos + 1);
     local c3 = strbyte(text, pos + 2);

     if (not c2 or not c3) then
        isValid = false;
     elseif (c == 224 and (c2 < 160 or c2 > 191)) then
        isValid = false;
     elseif (c == 237 and (c2 < 128 or c2 > 159)) then
        isValid = false;
     elseif (c2 < 128 or c2 > 191) then
        isValid = false;
     elseif (c3 < 128 or c3 > 191) then
        isValid = false;
     else
        charbytes = 3;
     end
  elseif (c >= 240 and c <= 244) then
     local c2 = strbyte(text, pos + 1);
     local c3 = strbyte(text, pos + 2);
     local c4 = strbyte(text, pos + 3);

     if (not c2 or not c3 or not c4) then
        isValid = false;
     elseif (c == 240 and (c2 < 144 or c2 > 191)) then
        isValid = false;
     elseif (c == 244 and (c2 < 128 or c2 > 143)) then
        isValid = false;
     elseif (c2 < 128 or c2 > 191) then
        isValid = false;
     elseif (c3 < 128 or c3 > 191) then
        isValid = false;
     elseif (c4 < 128 or c4 > 191) then
        isValid = false;
     else
        charbytes = 4;
     end
  else
     isValid = false;
  end

  if (not isValid) then
     return "", 1, false;
  end

  return string.sub(text, pos, pos + charbytes - 1), charbytes, true;
end


local function QTR_DecodeArabicChatInput(text)
  if (not text or text == "") then
     return text, false;
  end

  local decodedText = "";
  local changed = false;
  local bytes = string.len(text);
  local pos = 1;

  while (pos <= bytes) do
     local char1, charbytes, isValid = QTR_GetSafeUtf8Char(text, pos);
     if (isValid and char1 ~= "") then
        local mappedChar = QTR_ArabicInputMojibakeMap[char1];
        if (mappedChar) then
           decodedText = decodedText .. mappedChar;
           changed = true;
        else
           decodedText = decodedText .. char1;
        end
     else
        changed = true;
     end

     pos = pos + charbytes;
  end

  return decodedText, changed;
end


local function QTR_BuildArabicPresentationToBaseMap()
  if (QTR_ArabicPresentationToBaseMap) then
     return;
  end

  QTR_ArabicPresentationToBaseMap = {};

  if (AS_Reshaping_Rules) then
     for baseChar, forms in pairs(AS_Reshaping_Rules) do
        if (forms) then
           if (forms.isolated) then
              QTR_ArabicPresentationToBaseMap[forms.isolated] = baseChar;
           end
           if (forms.initial) then
              QTR_ArabicPresentationToBaseMap[forms.initial] = baseChar;
           end
           if (forms.middle) then
              QTR_ArabicPresentationToBaseMap[forms.middle] = baseChar;
           end
           if (forms.final) then
              QTR_ArabicPresentationToBaseMap[forms.final] = baseChar;
           end
        end
     end
  end

  if (AS_Reshaping_Rules2) then
     for baseChar, forms in pairs(AS_Reshaping_Rules2) do
        if (forms) then
           if (forms.isolated) then
              QTR_ArabicPresentationToBaseMap[forms.isolated] = baseChar;
           end
           if (forms.initial) then
              QTR_ArabicPresentationToBaseMap[forms.initial] = baseChar;
           end
           if (forms.middle) then
              QTR_ArabicPresentationToBaseMap[forms.middle] = baseChar;
           end
           if (forms.final) then
              QTR_ArabicPresentationToBaseMap[forms.final] = baseChar;
           end
        end
     end
  end
end


local function QTR_UnshapeArabicChatText(text)
  if (not text or text == "") then
     return text;
  end

  QTR_BuildArabicPresentationToBaseMap();
  if (not QTR_ArabicPresentationToBaseMap) then
     return text;
  end

  local normalizedText = "";
  local bytes = string.len(text);
  local pos = 1;

  while (pos <= bytes) do
     local char1, charbytes, isValid = QTR_GetSafeUtf8Char(text, pos);
     if (isValid and char1 ~= "") then
        normalizedText = normalizedText .. (QTR_ArabicPresentationToBaseMap[char1] or char1);
     end
     pos = pos + charbytes;
  end

  return normalizedText;
end


local function QTR_NormalizeArabicChatText(text)
  local decodedText = QTR_DecodeArabicChatInput(text);
  return QTR_UnshapeArabicChatText(decodedText);
end


local function QTR_ShouldUseArabicChatLayout(text)
  if (not text or text == "") then
     return false;
  end
  if (string.sub(text, 1, 1) == "/") then
     return false;
  end
  return (AS_ContainsArabic and AS_ContainsArabic(text));
end


local function QTR_GetChatEditBoxColor(editBox)
  local chatType = editBox and editBox.GetAttribute and editBox:GetAttribute("chatType");
  local info = (chatType and ChatTypeInfo and ChatTypeInfo[chatType]) or (ChatTypeInfo and ChatTypeInfo["SAY"]);

  if (chatType == "CHANNEL" and editBox and editBox.GetAttribute and GetChannelName and ChatTypeInfo) then
     local channel = GetChannelName(editBox:GetAttribute("channelTarget"));
     if (channel and channel > 0 and ChatTypeInfo["CHANNEL"..tostring(channel)]) then
        info = ChatTypeInfo["CHANNEL"..tostring(channel)];
     end
  end

  if (not info) then
     return 1, 1, 1;
  end

  return info.r or 1, info.g or 1, info.b or 1;
end


local function QTR_EnsureChatEditPreview(editBox)
  if (not editBox or not editBox.CreateFontString) then
     return nil;
  end

  if (QTR_ChatEditPreviewTexts[editBox]) then
     return QTR_ChatEditPreviewTexts[editBox];
  end

  local previewFrame = CreateFrame("Frame", nil, editBox);
  if (previewFrame.SetClipsChildren) then
     previewFrame:SetClipsChildren(true);
  end
  previewFrame:Hide();

  local previewText = previewFrame:CreateFontString(nil, "ARTWORK");
  if (previewText.SetDrawLayer) then
     previewText:SetDrawLayer("ARTWORK");
  end
  local fontFile, fontSize, fontFlags = editBox:GetFont();
  previewText:SetFont(QTR_Font2 or fontFile or Original_Font2, fontSize or 13, fontFlags or "");
  previewText:SetJustifyH("RIGHT");
  previewText:SetJustifyV("MIDDLE");
  if (previewText.SetWordWrap) then
     previewText:SetWordWrap(false);
  end
  if (previewText.SetNonSpaceWrap) then
     previewText:SetNonSpaceWrap(false);
  end
  previewText:SetText("");
  previewText:Hide();
  QTR_ChatEditPreviewFrames[editBox] = previewFrame;
  QTR_ChatEditPreviewTexts[editBox] = previewText;
  return previewText;
end


local function QTR_EnsureChatEditPreviewCaret(editBox)
   if (not editBox or not editBox.CreateTexture) then
       return nil;
   end

   if (QTR_ChatEditPreviewCarets[editBox]) then
       return QTR_ChatEditPreviewCarets[editBox];
   end

   local previewCaret = editBox:CreateTexture(nil, "OVERLAY");
   previewCaret:SetTexture(1, 1, 1, 0.9);
   previewCaret:SetWidth(2);
   previewCaret:Hide();
   QTR_ChatEditPreviewCarets[editBox] = previewCaret;
   return previewCaret;
end


local function QTR_ResetChatEditPreviewCaretBlink(editBox)
  QTR_ChatEditPreviewCaretBlinkStarts[editBox] = (GetTime and GetTime()) or 0;
end


local function QTR_HideChatEditPreviewCaret(editBox)
   local previewCaret = QTR_ChatEditPreviewCarets[editBox];
   if (previewCaret) then
       previewCaret:Hide();
   end
end


local function QTR_ClearChatEditBoxHighlight(editBox)
  if (not editBox or not editBox.HighlightText or not editBox.GetCursorPosition) then
     return;
  end

  local cursorPosition = editBox:GetCursorPosition() or 0;
  editBox:HighlightText(cursorPosition, cursorPosition);
end


local function QTR_ShouldUseArabicEditPreview(editBox, logicalText)
  if (not QTR_IsArabicChatEnabled() or not QTR_ShouldUseArabicChatLayout(logicalText)) then
     return false;
  end

  return true;
end


local function QTR_UpdateChatEditPreviewCaret(editBox, logicalText)
  local previewText = QTR_ChatEditPreviewTexts[editBox];
   local previewFrame = QTR_ChatEditPreviewFrames[editBox];
  if (not previewText or not logicalText or logicalText == "") then
     QTR_HideChatEditPreviewCaret(editBox);
     return;
  end

  if (editBox and editBox.HasFocus and not editBox:HasFocus()) then
     QTR_HideChatEditPreviewCaret(editBox);
     return;
  end

  if (editBox and editBox.GetCursorPosition and editBox.GetText) then
     local cursorPosition = editBox:GetCursorPosition() or 0;
     local currentText = editBox:GetText() or "";
     if (cursorPosition < string.len(currentText)) then
        QTR_HideChatEditPreviewCaret(editBox);
        return;
     end
  end

  local previewCaret = QTR_EnsureChatEditPreviewCaret(editBox);
  if (not previewCaret) then
     return;
  end

  if (not QTR_ChatEditPreviewCaretBlinkStarts[editBox]) then
     QTR_ResetChatEditPreviewCaretBlink(editBox);
  end

  local isOverflowing = QTR_ChatEditPreviewOverflowing[editBox];
  local previewWidth = (previewFrame and previewFrame.GetWidth and previewFrame:GetWidth()) or (previewText:GetWidth() or 0);
  local previewVisualText = (previewText.GetText and previewText:GetText()) or "";
  local textWidth = QTR_MeasureChatEditPreviewTextWidth(editBox, previewVisualText, true);
  local offsetX = -math.min(math.max(textWidth, 1), math.max(previewWidth, 1));
  local _, fontSize = editBox:GetFont();
  local textHeight = previewText:GetStringHeight() or (fontSize or 13);
  local caretHeight = math.max(math.floor(textHeight), 10);
  local blinkElapsed = ((GetTime and GetTime()) or 0) - (QTR_ChatEditPreviewCaretBlinkStarts[editBox] or 0);
  local blinkVisible = (math.fmod(math.floor(blinkElapsed * 2.2), 2) == 0);

  previewCaret:ClearAllPoints();
  previewCaret:SetWidth(2);
  previewCaret:SetHeight(caretHeight);
  if (isOverflowing and previewFrame) then
     previewCaret:SetPoint("CENTER", previewFrame, "LEFT", 0, 0);
  elseif (previewFrame) then
     previewCaret:SetPoint("CENTER", previewFrame, "RIGHT", offsetX, 0);
  else
     previewCaret:SetPoint("CENTER", previewText, "RIGHT", offsetX, 0);
  end
  previewCaret:SetAlpha(blinkVisible and 0.9 or 0);
  previewCaret:Show();
end


local function QTR_UpdateChatEditBoxLayout(editBox, logicalText)
  if (not editBox or not editBox.SetJustifyH or not editBox.SetTextColor) then
     return;
  end

  local red, green, blue = QTR_GetChatEditBoxColor(editBox);
  local useArabicPreview = QTR_ShouldUseArabicEditPreview(editBox, logicalText);
  local previewFrame = QTR_ChatEditPreviewFrames[editBox];
  local previewText = QTR_ChatEditPreviewTexts[editBox];

  if (useArabicPreview) then
     previewText = QTR_EnsureChatEditPreview(editBox);
     previewFrame = QTR_ChatEditPreviewFrames[editBox];
     if (previewText) then
        local leftInset = 15;
        if (editBox.header and editBox.header.GetWidth) then
           leftInset = leftInset + editBox.header:GetWidth();
        end
        local availableWidth = math.max((((editBox.GetWidth and editBox:GetWidth()) or 0) - leftInset - 17), 40);
        local previewVisualText = QTR_ShapeChatText(logicalText);
        local previewTextWidth = QTR_MeasureChatEditPreviewTextWidth(editBox, previewVisualText, true);
        local isOverflowing = (previewTextWidth > availableWidth);

        if (previewFrame) then
           previewFrame:ClearAllPoints();
           previewFrame:SetPoint("TOPLEFT", editBox, "TOPLEFT", leftInset, 0);
           previewFrame:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -13, 0);
           previewFrame:Show();
        end

        previewText:ClearAllPoints();

        local _, fontSize, fontFlags = editBox:GetFont();
        previewText:SetFont(QTR_Font2, fontSize or 13, fontFlags or "");
        previewText:SetTextColor(red, green, blue, 1);
        if (previewFrame) then
           previewText:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", 0, 0);
           previewText:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", 0, 0);
           if (isOverflowing) then
              QTR_ClearChatEditBoxHighlight(editBox);
           end
        end
        previewText:SetText(previewVisualText);
        previewText:Show();

        QTR_ChatEditPreviewLastLines[editBox] = previewVisualText;
        QTR_ChatEditPreviewLineCounts[editBox] = 1;
        QTR_ChatEditPreviewOverflowing[editBox] = isOverflowing;
     end

     editBox:SetTextColor(red, green, blue, 0);
     editBox:SetJustifyH("RIGHT");
     QTR_UpdateChatEditPreviewCaret(editBox, logicalText);
  else
     if (previewFrame) then
        previewFrame:Hide();
     end
     if (previewText) then
        previewText:SetText("");
        previewText:Hide();
     end

     QTR_ChatEditPreviewLastLines[editBox] = nil;
     QTR_ChatEditPreviewLineCounts[editBox] = nil;
     QTR_ChatEditPreviewOverflowing[editBox] = nil;
     QTR_HideChatEditPreviewCaret(editBox);
     editBox:SetTextColor(red, green, blue, 1);
     editBox:SetJustifyH("LEFT");
  end
end


local function QTR_NormalizeChatEditBoxText(editBox)
  if (not editBox or not editBox.GetText or not editBox.SetText) then
     return false;
  end

  local originalText = editBox:GetText() or "";
  if (originalText == "") then
     QTR_ChatEditLogicalTexts[editBox] = nil;
     QTR_UpdateChatEditBoxLayout(editBox, nil);
     return false;
  end

  local logicalText = QTR_NormalizeArabicChatText(originalText) or "";
  QTR_ChatEditLogicalTexts[editBox] = logicalText;
  if (logicalText == originalText) then
     QTR_UpdateChatEditBoxLayout(editBox, logicalText);
     return false;
  end

  QTR_ChatEditNormalizeLock[editBox] = true;
  editBox:SetText(logicalText);
  if (editBox.SetCursorPosition) then
     editBox:SetCursorPosition(string.len(logicalText));
  end
  QTR_ChatEditNormalizeLock[editBox] = nil;

  QTR_UpdateChatEditBoxLayout(editBox, logicalText);
  return true;
end


local function QTR_InstallArabicChatEditHook(editBox)
  if (not editBox or not editBox.HookScript or QTR_ChatEditHooks[editBox]) then
     return;
  end

  editBox:HookScript("OnTextChanged", function(self, userInput)
     if (QTR_ChatEditNormalizeLock[self]) then
        return;
     end

     if (userInput) then
        QTR_ResetChatEditPreviewCaretBlink(self);
     end

     if (not QTR_IsArabicChatEnabled()) then
        QTR_ChatEditLogicalTexts[self] = nil;
        QTR_UpdateChatEditBoxLayout(self, nil);
        return;
     end

     if (not userInput) then
        local currentText = self:GetText() or "";
        if (currentText == "") then
           QTR_ChatEditLogicalTexts[self] = nil;
           QTR_UpdateChatEditBoxLayout(self, nil);
        else
           local logicalText = QTR_ChatEditLogicalTexts[self] or QTR_NormalizeArabicChatText(currentText) or currentText;
           QTR_ChatEditLogicalTexts[self] = logicalText;
           QTR_UpdateChatEditBoxLayout(self, logicalText);
        end
        return;
     end

     QTR_NormalizeChatEditBoxText(self);
  end);

  editBox:HookScript("OnUpdate", function(self)
     if (QTR_ChatEditNormalizeLock[self]) then
        return;
     end

     if (not QTR_IsArabicChatEnabled()) then
        if (QTR_ChatEditPreviewTexts[self] or QTR_ChatEditPreviewCarets[self]) then
           QTR_UpdateChatEditBoxLayout(self, nil);
        end
        return;
     end

     local logicalText = QTR_ChatEditLogicalTexts[self];
     if ((not logicalText or logicalText == "") and self.GetText) then
        local currentText = self:GetText() or "";
        if (currentText ~= "") then
           logicalText = QTR_NormalizeArabicChatText(currentText) or currentText;
        end
     end

     QTR_UpdateChatEditBoxLayout(self, logicalText);
  end);

  editBox:HookScript("OnMouseUp", function(self)
     local logicalText = QTR_ChatEditLogicalTexts[self];
     if ((not logicalText or logicalText == "") and self.GetText) then
        logicalText = QTR_NormalizeArabicChatText(self:GetText() or "") or nil;
     end

     if (QTR_ShouldUseArabicEditPreview(self, logicalText)) then
        QTR_ClearChatEditBoxHighlight(self);
        QTR_UpdateChatEditBoxLayout(self, logicalText);
     end
  end);

  QTR_ChatEditHooks[editBox] = true;
end


local function QTR_IsMixedChatLatinRun(text)
  if (not text or text == "") then
     return false;
  end

  return (string.find(text, "[A-Za-z0-9]") ~= nil);
end


local function QTR_IsArabicChatCharacter(char)
  if (not char or char == "") then
     return false;
  end

  if (AS_IsArabicLetter and AS_IsArabicLetter(char)) then
     return true;
  end
  if (AS_IsDiacritic and AS_IsDiacritic(char)) then
     return true;
  end
  if (AS_IsArabicIndicNumeral and AS_IsArabicIndicNumeral(char)) then
     return true;
  end
  if (AS_IsArabicPunctuation and AS_IsArabicPunctuation(char)) then
     return true;
  end

  return false;
end


local function QTR_GetNextUtf8Char(text, pos)
   local char1, charbytes = QTR_GetSafeUtf8Char(text, pos);
   return char1, charbytes;
end


local function QTR_GetProtectedChatMarkup(text, pos)
  if (not text or not pos or string.sub(text, pos, pos) ~= "|") then
     return nil;
  end

  if (string.sub(text, pos, pos + 1) == "|T") then
     local textureStart, textureEnd = string.find(text, "|t", pos + 2, true);
     if (textureStart == pos + 2) then
        textureStart, textureEnd = string.find(text, "|t", pos, true);
     end
     if (textureStart) then
        return string.sub(text, pos, textureEnd), textureEnd - pos + 1;
     end
  elseif (string.sub(text, pos, pos + 1) == "|c") then
     local colorStart, colorEnd = string.find(text, "|r", pos + 2, true);
     if (colorStart) then
        return string.sub(text, pos, colorEnd), colorEnd - pos + 1;
     end
  elseif (string.sub(text, pos, pos + 1) == "|H") then
     local firstLinkStart, firstLinkEnd = string.find(text, "|h", pos + 2, true);
     if (firstLinkStart) then
        local secondLinkStart, secondLinkEnd = string.find(text, "|h", firstLinkEnd + 1, true);
        if (secondLinkStart) then
           return string.sub(text, pos, secondLinkEnd), secondLinkEnd - pos + 1;
        end
     end
  elseif (string.sub(text, pos, pos + 1) == "|r" or string.sub(text, pos, pos + 1) == "|h") then
     return string.sub(text, pos, pos + 1), 2;
  end

  return nil;
end


local function QTR_GetVisibleChatMeasureText(text)
  if (not text or text == "") then
     return text or "";
  end

  local visibleText = text;
  visibleText = string.gsub(visibleText, "|c%x%x%x%x%x%x%x%x", "");
  visibleText = string.gsub(visibleText, "|r", "");
  visibleText = string.gsub(visibleText, "|H.-|h(.-)|h", "%1");
  visibleText = string.gsub(visibleText, "|T.-|t", "");
  return visibleText;
end


local function QTR_ParseChatTextEntries(text)
  local entries = {};
  local leadingSpaces = "";

  if (not text or text == "") then
     return leadingSpaces, entries;
  end

  local currentToken = "";
  local pos = 1;
  local bytes = string.len(text);

  while (pos <= bytes) do
     local protectedMarkup, protectedBytes = QTR_GetProtectedChatMarkup(text, pos);
     if (protectedMarkup and protectedBytes and protectedBytes > 0) then
        if (currentToken ~= "") then
           table.insert(entries, {
              token = currentToken,
              spacesAfter = "",
           });
           currentToken = "";
        end

        table.insert(entries, {
           token = protectedMarkup,
           spacesAfter = "",
        });
        pos = pos + protectedBytes;
     else
        local char1, charbytes = QTR_GetNextUtf8Char(text, pos);
        if (not charbytes or charbytes < 1) then
           charbytes = 1;
        end

        if (char1 == " " or char1 == "\t") then
           if (currentToken ~= "") then
              table.insert(entries, {
                 token = currentToken,
                 spacesAfter = "",
              });
              currentToken = "";
           end

           if (#entries > 0) then
              entries[#entries].spacesAfter = entries[#entries].spacesAfter .. char1;
           else
              leadingSpaces = leadingSpaces .. char1;
           end
        elseif (char1 ~= "") then
           currentToken = currentToken .. char1;
        end

        pos = pos + charbytes;
     end
  end

  if (currentToken ~= "") then
     table.insert(entries, {
        token = currentToken,
        spacesAfter = "",
     });
  end

  return leadingSpaces, entries;
end


QTR_MeasureChatEditPreviewTextWidth = function(editBox, text, isVisualText)
  if (not editBox or not editBox.GetFont or not text or text == "") then
     return 0;
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return 0;
  end

  local fontFile, fontSize, fontFlags = editBox:GetFont();
  local frameWidth = (editBox.GetWidth and editBox:GetWidth()) or 0;
  if (frameWidth <= 0) then
     frameWidth = 600;
  end

  measureText:SetWidth(math.max(frameWidth * 4, 4096));
  measureText:SetFont(QTR_Font2 or fontFile or Original_Font2, fontSize or 13, fontFlags or "");
  measureText:SetText(QTR_GetVisibleChatMeasureText(isVisualText and text or QTR_ShapeChatText(text)));
  return measureText:GetStringWidth() or 0;
end


QTR_BuildWrappedArabicPreviewText = function(editBox, logicalText, availableWidth)
  local visualText = QTR_ShapeChatText(logicalText);
  if (not editBox or not logicalText or logicalText == "" or not availableWidth or availableWidth <= 0) then
     return visualText, visualText, 1;
  end

  if (QTR_MeasureChatEditPreviewTextWidth(editBox, logicalText, false) <= availableWidth) then
     return visualText, visualText, 1;
  end

  local leadingSpaces, entries = QTR_ParseChatTextEntries(logicalText);
  if (#entries == 0) then
     return visualText, visualText, 1;
  end

  local lines = {};
  local currentLine = leadingSpaces;
  local pendingSpaces = "";

  for i = 1, #entries do
     local prefixSpaces = ((currentLine ~= "") and pendingSpaces) or "";
     local candidateLine = currentLine .. prefixSpaces .. entries[i].token;
     if (currentLine ~= "" and QTR_MeasureChatEditPreviewTextWidth(editBox, candidateLine, false) > availableWidth) then
        table.insert(lines, currentLine);
        currentLine = entries[i].token;
     else
        currentLine = candidateLine;
     end

     pendingSpaces = entries[i].spacesAfter or "";
  end

  if (currentLine ~= "") then
     table.insert(lines, currentLine);
  end

  local visualLines = {};
  for i = 1, #lines do
     visualLines[i] = QTR_ShapeChatText(lines[i]);
  end

  local lastVisualLine = visualLines[#visualLines] or visualText;
  return table.concat(visualLines, "\n"), lastVisualLine, math.max(#visualLines, 1);
end


local function QTR_BuildMixedChatTokenVisual(token)
  if (not token or token == "") then
     return token or "";
  end
  if (not AS_ContainsArabic or not AS_ContainsArabic(token) or not QTR_IsMixedChatLatinRun(token)) then
     return QTR_ReverseText(token);
  end

  local runs = {};
  local currentRun = "";
  local currentRunIsArabic = nil;
  local pos = 1;
  local bytes = string.len(token);

  while (pos <= bytes) do
     local char1, charbytes = QTR_GetNextUtf8Char(token, pos);
     local isArabic = QTR_IsArabicChatCharacter(char1);

     if (currentRunIsArabic == nil or currentRunIsArabic == isArabic) then
        currentRun = currentRun .. char1;
     else
        if (currentRun ~= "") then
           if (currentRunIsArabic) then
              table.insert(runs, QTR_ReverseText(currentRun));
           else
              table.insert(runs, currentRun);
           end
        end

        currentRun = char1;
     end

     currentRunIsArabic = isArabic;
     pos = pos + charbytes;
  end

  if (currentRun ~= "") then
     if (currentRunIsArabic) then
        table.insert(runs, QTR_ReverseText(currentRun));
     else
        table.insert(runs, currentRun);
     end
  end

  local visualToken = "";
  for i = #runs, 1, -1 do
     visualToken = visualToken .. runs[i];
  end

  return visualToken;
end


local function QTR_BuildMixedChatVisualText(text)
  if (not text or text == "" or not AS_ContainsArabic or not AS_ContainsArabic(text) or not QTR_IsMixedChatLatinRun(text)) then
     return QTR_ReverseText(text);
  end

  local currentSpaces, rawEntries = QTR_ParseChatTextEntries(text);
  local entries = {};
  for i = 1, #rawEntries do
     table.insert(entries, {
        token = QTR_BuildMixedChatTokenVisual(rawEntries[i].token),
        spacesAfter = rawEntries[i].spacesAfter,
     });
  end

  if (#entries == 0) then
     return QTR_ReverseText(text);
  end

  local visualText = currentSpaces;
  for i = #entries, 1, -1 do
     visualText = visualText .. entries[i].token;
     if (i > 1) then
        visualText = visualText .. entries[i - 1].spacesAfter;
     end
  end

  return visualText;
end


local function QTR_CanSafelyShapeChatText(text)
  if (not text or text == "") then
     return false;
  end
  if (not AS_ContainsArabic or not AS_ContainsArabic(text)) then
     return false;
  end
  return true;
end


QTR_ShapeChatText = function(text)
  local logicalText = QTR_NormalizeArabicChatText(text);
  if (not QTR_CanSafelyShapeChatText(logicalText)) then
     return logicalText;
  end
   return QTR_BuildMixedChatVisualText(logicalText);
end


local function QTR_ApplyFontToChatFrame(chatFrame)
  if (not chatFrame or not chatFrame.GetFont or not chatFrame.SetFont) then
     return;
  end

  if (not QTR_ChatOriginalFrameFonts[chatFrame]) then
     local fontFile, fontSize, fontFlags = chatFrame:GetFont();
     QTR_ChatOriginalFrameFonts[chatFrame] = {
        font = fontFile,
        size = fontSize,
        flags = fontFlags,
     };
  end

  local _, fontSize, fontFlags = chatFrame:GetFont();
  chatFrame:SetFont(QTR_Font2, fontSize or 13, fontFlags or "");
end


local function QTR_RestoreFontToChatFrame(chatFrame)
  if (not chatFrame or not chatFrame.SetFont) then
     return;
  end

  local fontData = QTR_ChatOriginalFrameFonts[chatFrame];
  if (fontData and fontData.font and fontData.size) then
     chatFrame:SetFont(fontData.font, fontData.size, fontData.flags);
  end
end


local function QTR_ApplyFontToChatEditBox(editBox)
  if (not editBox or not editBox.GetFont or not editBox.SetFont) then
     return;
  end

   QTR_InstallArabicChatEditHook(editBox);

  if (not QTR_ChatOriginalEditBoxFonts[editBox]) then
     local fontFile, fontSize, fontFlags = editBox:GetFont();
     QTR_ChatOriginalEditBoxFonts[editBox] = {
        font = fontFile,
        size = fontSize,
        flags = fontFlags,
     };
  end

  local _, fontSize, fontFlags = editBox:GetFont();
  editBox:SetFont(QTR_Font2, fontSize or 13, fontFlags or "");

  if (QTR_IsArabicChatEnabled()) then
     local logicalText = QTR_ChatEditLogicalTexts[editBox] or QTR_NormalizeArabicChatText(editBox:GetText() or "") or nil;
     if (logicalText ~= nil and logicalText ~= "") then
        QTR_ChatEditLogicalTexts[editBox] = logicalText;
     end
     QTR_UpdateChatEditBoxLayout(editBox, logicalText);
  end
end


local function QTR_RestoreFontToChatEditBox(editBox)
  if (not editBox or not editBox.SetFont) then
     return;
  end

  local fontData = QTR_ChatOriginalEditBoxFonts[editBox];
  if (fontData and fontData.font and fontData.size) then
     editBox:SetFont(fontData.font, fontData.size, fontData.flags);
  end

  QTR_ChatEditLogicalTexts[editBox] = nil;
  QTR_UpdateChatEditBoxLayout(editBox, nil);
end


local function QTR_ApplyArabicChatFonts()
  for index = 1, (NUM_CHAT_WINDOWS or 0) do
     local chatFrame = _G["ChatFrame"..tostring(index)];
     if (chatFrame) then
        QTR_ApplyFontToChatFrame(chatFrame);
     end

     local editBox = _G["ChatFrame"..tostring(index).."EditBox"];
     if (editBox) then
        QTR_ApplyFontToChatEditBox(editBox);
     end
  end

  if (GMChatFrame) then
     QTR_ApplyFontToChatFrame(GMChatFrame);
  end
end


local function QTR_RestoreArabicChatFonts()
  for chatFrame in pairs(QTR_ChatOriginalFrameFonts) do
     QTR_RestoreFontToChatFrame(chatFrame);
  end

  for editBox in pairs(QTR_ChatOriginalEditBoxFonts) do
     QTR_RestoreFontToChatEditBox(editBox);
  end
end


local function QTR_GetChatEventColor(eventName)
  if (not ChatTypeInfo) then
     return 1, 1, 1;
  end

  local eventColors = {
     CHAT_MSG_SAY = ChatTypeInfo.SAY,
     CHAT_MSG_YELL = ChatTypeInfo.YELL,
     CHAT_MSG_WHISPER = ChatTypeInfo.WHISPER,
     CHAT_MSG_WHISPER_INFORM = ChatTypeInfo.WHISPER,
     CHAT_MSG_PARTY = ChatTypeInfo.PARTY,
     CHAT_MSG_PARTY_LEADER = ChatTypeInfo.PARTY,
     CHAT_MSG_RAID = ChatTypeInfo.RAID,
     CHAT_MSG_RAID_LEADER = ChatTypeInfo.RAID_WARNING,
     CHAT_MSG_RAID_WARNING = ChatTypeInfo.RAID_WARNING,
     CHAT_MSG_GUILD = ChatTypeInfo.GUILD,
     CHAT_MSG_OFFICER = ChatTypeInfo.GUILD,
     CHAT_MSG_BATTLEGROUND = ChatTypeInfo.BATTLEGROUND,
     CHAT_MSG_BATTLEGROUND_LEADER = ChatTypeInfo.BATTLEGROUND,
  };

  local colorInfo = eventColors[eventName];
  if (not colorInfo) then
     return 1, 1, 1;
  end

  return colorInfo.r or 1, colorInfo.g or 1, colorInfo.b or 1;
end


local function QTR_GetChatSpeakerLink(eventName, speakerName, speakerGuid)
  if (not speakerName or speakerName == "") then
     return "";
  end

  local displayName = speakerName;
  local dashPos = string.find(displayName, "-", 1, true);
  if (dashPos and dashPos > 1) then
     displayName = string.sub(displayName, 1, dashPos - 1);
  end

  local bracketedName = "["..displayName.."]";
  local chatType = eventName and string.sub(eventName, 10) or nil;
  if (chatType and string.sub(chatType, 1, 7) == "WHISPER") then
     chatType = "WHISPER";
  end

  local colorInfo = (chatType and ChatTypeInfo and ChatTypeInfo[chatType]) or nil;
  if (colorInfo and colorInfo.colorNameByClass and speakerGuid and speakerGuid ~= "" and GetPlayerInfoByGUID and RAID_CLASS_COLORS) then
     local _, englishClass = GetPlayerInfoByGUID(speakerGuid);
     local classColor = englishClass and RAID_CLASS_COLORS[englishClass] or nil;
     if (classColor) then
        return string.format("|cff%.2x%.2x%.2x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, bracketedName);
     end
  end

  return bracketedName;
end


local function QTR_GetChatTimestampPrefix()
  if (CHAT_TIMESTAMP_FORMAT and BetterDate) then
     return BetterDate(CHAT_TIMESTAMP_FORMAT, time());
  end
  return "";
end


local function QTR_GetLeatrixTimestampPrefix(chatFrame)
  if (not chatFrame or not chatFrame.LeaPlusChatTimestampHooked or CHAT_TIMESTAMP_FORMAT or not LeaPlusDB or LeaPlusDB["ChatTimestamps"] ~= "On") then
     return "";
  end

  local timestampFormats = {
     [1] = "%I:%M:%S %p",
     [2] = "%I:%M %p",
     [3] = "%X",
     [4] = "%H:%M",
     [5] = "%M:%S",
     [6] = "%I:%M:%S",
  };

  local formatString = "[" .. (timestampFormats[LeaPlusDB["ChatTimestampFormatMenu"]] or "%X") .. "]";
  local ok, timestampText = pcall(date, formatString);
  if (not ok or not timestampText) then
     timestampText = date("[%X]");
  end

  if (LeaPlusDB["ChatTimestampUseChannelColor"] == "On") then
     return timestampText;
  end

  local red = math.floor((LeaPlusDB["ChatTimestampRed"] or 115) + 0.5);
  local green = math.floor((LeaPlusDB["ChatTimestampGreen"] or 115) + 0.5);
  local blue = math.floor((LeaPlusDB["ChatTimestampBlue"] or 115) + 0.5);
  return string.format("|cff%02x%02x%02x%s|r", red, green, blue, timestampText);
end


local function QTR_GetChatTimestampPrefixes(chatFrame)
  local outputPrefix = QTR_GetChatTimestampPrefix();
  if (outputPrefix ~= "") then
     return outputPrefix, outputPrefix;
  end

  local renderedPrefix = QTR_GetLeatrixTimestampPrefix(chatFrame);
  return "", renderedPrefix;
end


QTR_GetChatLineMeasureText = function()
  if (not AS_TestLine and AS_CreateTestLine) then
     AS_CreateTestLine();
  end

  if (AS_TestLine and AS_TestLine.text) then
     return AS_TestLine.text;
  end

  return nil;
end


local function QTR_MeasureChatPrefixWidth(chatFrame, text)
  if (not chatFrame or not chatFrame.GetFont or not text or text == "") then
     return 0;
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return 0;
  end

  local fontFile, fontSize, fontFlags = chatFrame:GetFont();
  local frameWidth = (chatFrame.GetWidth and chatFrame:GetWidth()) or 0;
  if (frameWidth <= 0) then
     frameWidth = 600;
  end

  measureText:SetWidth(frameWidth * 2);
  measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
   measureText:SetText(QTR_GetVisibleChatMeasureText(text));
  return measureText:GetStringWidth() or 0;
end


local function QTR_AddChatLinePadding(text, chatFrame, width, secondLineIndent)
  if (not text or text == "" or not chatFrame or not chatFrame.GetFont or not width or width <= 0) then
     return text or "";
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return text;
  end

  local fontFile, fontSize, fontFlags = chatFrame:GetFont();
  local lineHeight = (fontSize or 13) * 1.5;
  local count = 0;
  local paddedText = text;
  local bestText = text;
  local indent = secondLineIndent or 0;

  measureText:SetWidth(width);
  measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
  measureText:SetText(QTR_GetVisibleChatMeasureText(paddedText));
  while (count < 300) do
     local candidateText = " " .. paddedText;
     measureText:SetText(QTR_GetVisibleChatMeasureText(candidateText));
     if (measureText:GetHeight() > lineHeight) then
        break;
     end

     paddedText = candidateText;
     bestText = candidateText;
     count = count + 1;
  end

  text = bestText;
  for i = 1, indent, 1 do
     if (string.sub(text, 1, 1) == " ") then
        text = string.sub(text, 2);
     else
        break;
     end
  end

  return text;
end


local function QTR_AddChatLinePaddingWithPrefix(prefixText, text, chatFrame, width, secondLineIndent)
  if (not prefixText or prefixText == "") then
     return QTR_AddChatLinePadding(text, chatFrame, width, secondLineIndent);
  end

  if (not text or text == "" or not chatFrame or not chatFrame.GetFont or not width or width <= 0) then
     return (prefixText or "") .. (text or "");
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return prefixText .. text;
  end

  local fontFile, fontSize, fontFlags = chatFrame:GetFont();
  local lineHeight = (fontSize or 13) * 1.5;
  local count = 0;
  local paddedText = text;
  local bestText = text;
  local indent = secondLineIndent or 0;

  measureText:SetWidth(width);
  measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
  measureText:SetText(QTR_GetVisibleChatMeasureText(prefixText .. paddedText));
  while (count < 300) do
     local candidateText = " " .. paddedText;
     measureText:SetText(QTR_GetVisibleChatMeasureText(prefixText .. candidateText));
     if (measureText:GetHeight() > lineHeight) then
        break;
     end

     paddedText = candidateText;
     bestText = candidateText;
     count = count + 1;
  end

  text = bestText;
  for i = 1, indent, 1 do
     if (string.sub(text, 1, 1) == " ") then
        text = string.sub(text, 2);
     else
        break;
     end
  end

  return prefixText .. text;
end


local function QTR_AddChatLinePaddingAgainstPrefix(prefixText, text, chatFrame, width, secondLineIndent)
  if (not prefixText or prefixText == "") then
     return QTR_AddChatLinePadding(text, chatFrame, width, secondLineIndent);
  end

  if (not text or text == "" or not chatFrame or not chatFrame.GetFont or not width or width <= 0) then
     return text or "";
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return text;
  end

  local fontFile, fontSize, fontFlags = chatFrame:GetFont();
  local lineHeight = (fontSize or 13) * 1.5;
  local count = 0;
  local paddedText = text;
  local bestText = text;
  local indent = secondLineIndent or 0;

  measureText:SetWidth(width);
  measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
  measureText:SetText(QTR_GetVisibleChatMeasureText(prefixText .. paddedText));
  while (count < 300) do
     local candidateText = " " .. paddedText;
     measureText:SetText(QTR_GetVisibleChatMeasureText(prefixText .. candidateText));
     if (measureText:GetHeight() > lineHeight) then
        break;
     end

     paddedText = candidateText;
     bestText = candidateText;
     count = count + 1;
  end

  text = bestText;
  for i = 1, indent, 1 do
     if (string.sub(text, 1, 1) == " ") then
        text = string.sub(text, 2);
     else
        break;
     end
  end

  return text;
end


local function QTR_ChatLineFitsWidth(text, chatFrame, width, prefixText)
   if (not text or text == "" or not chatFrame or not chatFrame.GetFont or not width or width <= 0) then
       return true;
   end

   local measureText = QTR_GetChatLineMeasureText();
   if (not measureText) then
       return true;
   end

   local fontFile, fontSize, fontFlags = chatFrame:GetFont();
   measureText:SetWidth(math.max(width * 4, 4096));
   measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
   measureText:SetText(QTR_GetVisibleChatMeasureText((prefixText or "") .. text));
   return ((measureText:GetStringWidth() or 0) <= width);
end


local function QTR_FormatArabicChatLine(text, chatFrame, width)
  if (not text or text == "" or not chatFrame or not chatFrame.GetFont) then
     return text or "";
  end

  local measureText = QTR_GetChatLineMeasureText();
  if (not measureText) then
     return text;
  end

  local fontFile, fontSize, fontFlags = chatFrame:GetFont();
  local retstr = "";
  local bytes = strlen(text);
  local pos = bytes;
  local second = 0;
  local linkStartStop = false;
  local newstr = "";
  local nextstr = "";
  local char1 = "";
  local char2 = "";
  local lastSpace = 0;

  while (pos > 0) do
     local c = strbyte(text, pos);
     while (c and c >= 128 and c <= 191) do
        pos = pos - 1;
        c = strbyte(text, pos);
     end

     char1, _, _ = QTR_GetSafeUtf8Char(text, pos);
     if (char1 == "") then
        char2 = "";
        pos = pos - 1;
        if (pos <= 0) then
           break;
        end
        newstr = newstr;
     else
        newstr = char1 .. newstr;

        if ((char1 .. char2 == "|r") and (pos < bytes)) then
           linkStartStop = true;
        elseif ((char1 .. char2 == "|c") and (pos < bytes)) then
           linkStartStop = false;
        elseif ((char1 .. char2 == "|h") and (pos < bytes)) then
           linkStartStop = true;
        elseif ((char1 .. char2 == "|H") and (pos < bytes)) then
           linkStartStop = false;
        end

        if ((char1 == " ") and (not linkStartStop)) then
           lastSpace = 0;
           nextstr = "";
        else
           nextstr = char1 .. nextstr;
           lastSpace = lastSpace + 1;
        end

        if (not linkStartStop) then
           measureText:SetWidth(width);
           measureText:SetFont(fontFile or QTR_Font2, fontSize or 13, fontFlags or "");
           measureText:SetText(QTR_GetVisibleChatMeasureText(newstr));
           if (measureText:GetHeight() > (fontSize or 13) * 1.5) then
              newstr = AS_UTF8sub(newstr, lastSpace + 1);
              retstr = retstr .. QTR_AddChatLinePadding(newstr, chatFrame, width, second) .. "\n";
              newstr = nextstr;
              nextstr = "";
              second = 3;
           end
        end

        char2 = char1;
     end
     pos = pos - 1;
  end

  retstr = retstr .. QTR_AddChatLinePadding(newstr, chatFrame, width, second);
  retstr = string.gsub(retstr, " \n", "\n");
  retstr = string.gsub(retstr, "\n ", "\n");
  return retstr;
end


local function QTR_BuildArabicChatOutput(chatFrame, eventName, messageText, speakerName, lineId, speakerGuid)
  if (not messageText or messageText == "") then
     return nil;
  end

  local decodedText = QTR_DecodeArabicChatInput(messageText);
  local normalizedText = QTR_UnshapeArabicChatText(decodedText);
  if (not AS_ContainsArabic or not AS_ContainsArabic(normalizedText)) then
     return nil;
  end

  local displayMessage = decodedText;
  if (normalizedText == decodedText) then
     if (not QTR_CanSafelyShapeChatText(normalizedText)) then
        return nil;
     end
     displayMessage = QTR_ShapeChatText(normalizedText);
  end

   local speakerLink = QTR_GetChatSpeakerLink(eventName, speakerName, speakerGuid);
  local noBreakSpace = "\194\160";
  local outputText = nil;
   local outputTimestampPrefix, layoutTimestampPrefix = QTR_GetChatTimestampPrefixes(chatFrame);
  local frameWidth = ((chatFrame and chatFrame.GetWidth and chatFrame:GetWidth()) or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.GetWidth and DEFAULT_CHAT_FRAME:GetWidth()) or 0);
  local availableWidth = frameWidth;

  if (eventName == "CHAT_MSG_SAY") then
     outputText = displayMessage .. noBreakSpace .. QTR_ReverseText("يتحدث:") .. noBreakSpace .. speakerLink;
  elseif (eventName == "CHAT_MSG_YELL") then
     outputText = displayMessage .. noBreakSpace .. QTR_ReverseText("يصرخ:") .. noBreakSpace .. speakerLink;
  elseif (eventName == "CHAT_MSG_WHISPER") then
     outputText = displayMessage .. noBreakSpace .. QTR_ReverseText("همس:") .. noBreakSpace .. speakerLink;
  elseif (eventName == "CHAT_MSG_WHISPER_INFORM") then
     outputText = displayMessage .. " :" .. speakerLink .. " " .. QTR_ReverseText("إلى");
  elseif (eventName == "CHAT_MSG_PARTY") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Party]";
  elseif (eventName == "CHAT_MSG_PARTY_LEADER") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Party Leader]";
  elseif (eventName == "CHAT_MSG_RAID") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Raid]";
  elseif (eventName == "CHAT_MSG_RAID_LEADER") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Raid Leader]";
  elseif (eventName == "CHAT_MSG_RAID_WARNING") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Raid Warning]";
  elseif (eventName == "CHAT_MSG_GUILD") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Guild]";
  elseif (eventName == "CHAT_MSG_OFFICER") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Officer]";
  elseif (eventName == "CHAT_MSG_BATTLEGROUND") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Battleground]";
  elseif (eventName == "CHAT_MSG_BATTLEGROUND_LEADER") then
     outputText = displayMessage .. " :" .. speakerLink .. " [Battleground Leader]";
  end

  if (not outputText) then
     return nil;
  end

  if (frameWidth and frameWidth > 32 and chatFrame) then
     if (QTR_ChatLineFitsWidth(outputText, chatFrame, frameWidth, layoutTimestampPrefix)) then
        if (outputTimestampPrefix ~= "") then
           return QTR_AddChatLinePaddingWithPrefix(outputTimestampPrefix, outputText, chatFrame, frameWidth, 0);
        end

        return QTR_AddChatLinePaddingAgainstPrefix(layoutTimestampPrefix, outputText, chatFrame, frameWidth, 0);
     end
  end

  if (layoutTimestampPrefix ~= "" and availableWidth and availableWidth > 0 and chatFrame) then
     availableWidth = availableWidth - QTR_MeasureChatPrefixWidth(chatFrame, layoutTimestampPrefix);
  end

  if (availableWidth and availableWidth > 32 and chatFrame) then
     if (QTR_ChatLineFitsWidth(outputText, chatFrame, availableWidth)) then
        outputText = QTR_AddChatLinePadding(outputText, chatFrame, availableWidth, 0);
     else
        outputText = QTR_FormatArabicChatLine(outputText, chatFrame, availableWidth);
     end
  end

   return outputTimestampPrefix .. outputText;
end


local function QTR_ArabicChatMessageFilter(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
  if (not QTR_IsArabicChatEnabled()) then
     return false;
  end

   local customOutput = QTR_BuildArabicChatOutput(self, event, arg1, arg2, arg11, arg12);
  if (customOutput and self and self.AddMessage) then
     local red, green, blue = QTR_GetChatEventColor(event);
     self:AddMessage(customOutput, red, green, blue);
     return true;
  end

  local shapedText = QTR_ShapeChatText(arg1);
  if (shapedText and shapedText ~= arg1) then
     return false, shapedText, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12;
  end

  return false;
end


local function QTR_RegisterArabicChatFilters()
  if (QTR_ChatFiltersRegistered) then
     return;
  end

  for _, eventName in ipairs(QTR_ChatMessageEvents) do
     ChatFrame_AddMessageEventFilter(eventName, QTR_ArabicChatMessageFilter);
  end
  QTR_ChatFiltersRegistered = true;
end


local function QTR_UnregisterArabicChatFilters()
  if (not QTR_ChatFiltersRegistered) then
     return;
  end

  for _, eventName in ipairs(QTR_ChatMessageEvents) do
     ChatFrame_RemoveMessageEventFilter(eventName, QTR_ArabicChatMessageFilter);
  end
  QTR_ChatFiltersRegistered = false;
end


local function QTR_InstallArabicChatSendHook()
  if (QTR_ChatSendHookInstalled or not ChatEdit_SendText) then
     return;
  end

  QTR_OriginalChatEditSendText = ChatEdit_SendText;
  ChatEdit_SendText = function(editBox, addHistory)
     if (not QTR_IsArabicChatEnabled() or not editBox or not editBox.GetText or not editBox.SetText) then
        return QTR_OriginalChatEditSendText(editBox, addHistory);
     end

     local originalText = editBox:GetText() or "";
     local logicalText = QTR_ChatEditLogicalTexts[editBox] or QTR_NormalizeArabicChatText(originalText) or "";
     if (string.sub(logicalText, 1, 1) == "/") then
        if (logicalText ~= originalText) then
           editBox:SetText(logicalText);
        end
        return QTR_OriginalChatEditSendText(editBox, addHistory);
     end

     local shapedText = QTR_ShapeChatText(logicalText);
     if (shapedText and shapedText ~= originalText) then
        if (addHistory) then
           ChatEdit_AddHistory(editBox);
           addHistory = nil;
        end
        editBox:SetText(shapedText);
     end

     return QTR_OriginalChatEditSendText(editBox, addHistory);
  end;

  QTR_ChatSendHookInstalled = true;
end


local function QTR_InstallArabicChatFontHook()
  if (QTR_ChatFontHookInstalled) then
     return;
  end

  hooksecurefunc("FCF_SetChatWindowFontSize", function()
     if (QTR_IsArabicChatEnabled()) then
        QTR_ApplyArabicChatFonts();
     end
  end);

  QTR_ChatFontHookInstalled = true;
end


local function QTR_InstallArabicChatHeaderHook()
  if (QTR_ChatHeaderHookInstalled) then
     return;
  end

  hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
     if (not editBox) then
        return;
     end

     local logicalText = QTR_ChatEditLogicalTexts[editBox];
     if ((not logicalText or logicalText == "") and editBox.GetText) then
        logicalText = QTR_NormalizeArabicChatText(editBox:GetText() or "") or nil;
        if (logicalText and logicalText ~= "") then
           QTR_ChatEditLogicalTexts[editBox] = logicalText;
        end
     end

     QTR_UpdateChatEditBoxLayout(editBox, logicalText);
  end);

  QTR_ChatHeaderHookInstalled = true;
end


local function QTR_ApplyArabicChatSupport()
  QTR_InstallArabicChatSendHook();
  QTR_InstallArabicChatFontHook();
   QTR_InstallArabicChatHeaderHook();

  if (QTR_IsArabicChatEnabled()) then
     QTR_RegisterArabicChatFilters();
     QTR_ApplyArabicChatFonts();
  else
     QTR_UnregisterArabicChatFilters();
     QTR_RestoreArabicChatFonts();
  end
end



local function AWC_PrintStatus(message)
  if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage and message) then
     DEFAULT_CHAT_FRAME:AddMessage("|cffffff00ArWoW_Chat:|r " .. message);
  end
end

local function AWC_SetEnabled(enabled)
  local db = AWC_EnsureDB();
  db["enabled"] = enabled and "1" or "0";
  QTR_ApplyArabicChatSupport();
end

local function AWC_SlashCommand(msg)
  msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"));
  if (msg == "" or msg == "toggle") then
     AWC_SetEnabled(not AWC_IsEnabled());
  elseif (msg == "on" or msg == "enable") then
     AWC_SetEnabled(true);
  elseif (msg == "off" or msg == "disable") then
     AWC_SetEnabled(false);
  elseif (msg ~= "status") then
     AWC_PrintStatus("Usage: /archat on|off|toggle|status");
     return;
  end
  if (AWC_IsEnabled()) then
     AWC_PrintStatus("Arabic chat is enabled.");
  else
     AWC_PrintStatus("Arabic chat is disabled.");
  end
end

SlashCmdList["ARWOW_CHAT"] = AWC_SlashCommand;
SLASH_ARWOW_CHAT1 = "/archat";
SLASH_ARWOW_CHAT2 = "/arwowchat";

local AWC_Frame = CreateFrame("Frame", "ArWoW_ChatFrame");
AWC_Frame:RegisterEvent("ADDON_LOADED");
AWC_Frame:RegisterEvent("UPDATE_CHAT_WINDOWS");
AWC_Frame:SetScript("OnEvent", function(self, event, arg1)
  if (event == "ADDON_LOADED") then
     if (arg1 ~= AWC_AddonName) then
        return;
     end
     AWC_EnsureDB();
     QTR_ApplyArabicChatSupport();
     self:UnregisterEvent("ADDON_LOADED");
  elseif (event == "UPDATE_CHAT_WINDOWS") then
     QTR_ApplyArabicChatSupport();
  end
end);

