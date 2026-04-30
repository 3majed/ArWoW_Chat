-- Addon: WoWAR (Version: 12.02) (Date: 2026-03-19)
-- Authors: Platine, Dragonarab[DiNaSoR]
-- Based on: UTF8 library by Kyle Smith
-- Enhanced: Added diacritics, Persian/Urdu support, performance optimizations, and bug fixes
-------------------------------------------------------------------------------------------------------

local debug_show_form = 0;

-------------------------------------------------------------------------------------------------------
-- Arabic Diacritics (Harakat/Tashkeel)
-------------------------------------------------------------------------------------------------------
AS_USE_PRESENTATION_DIACRITICS = false;

AS_DiacriticPresentationForms = {
   ["\217\139"] = "\239\185\176", -- ً  FATHATAN → ﹰ  FE70
   ["\217\140"] = "\239\185\178", -- ٌ  DAMMATAN → ﹲ  FE72
   ["\217\141"] = "\239\185\180", -- ٍ  KASRATAN → ﹴ  FE74
   ["\217\142"] = "\239\185\182", -- َ  FATHA    → ﹶ  FE76
   ["\217\143"] = "\239\185\184", -- ُ  DAMMA    → ﹸ  FE78
   ["\217\144"] = "\239\185\186", -- ِ  KASRA    → ﹺ  FE7A
   ["\217\145"] = "\239\185\188", -- ّ  SHADDA   → ﹼ  FE7C
   ["\217\146"] = "\239\185\190", -- ْ  SUKUN    → ﹾ  FE7E
   ["\239\185\176"] = "\239\185\176",
   ["\239\185\178"] = "\239\185\178",
   ["\239\185\180"] = "\239\185\180",
   ["\239\185\182"] = "\239\185\182",
   ["\239\185\184"] = "\239\185\184",
   ["\239\185\186"] = "\239\185\186",
   ["\239\185\188"] = "\239\185\188",
   ["\239\185\190"] = "\239\185\190",
};

AS_Diacritics = {
   ["\217\139"] = true,  -- FATHATAN (ً) U+064B
   ["\217\140"] = true,  -- DAMMATAN (ٌ) U+064C
   ["\217\141"] = true,  -- KASRATAN (ٍ) U+064D
   ["\217\142"] = true,  -- FATHA (َ) U+064E
   ["\217\143"] = true,  -- DAMMA (ُ) U+064F
   ["\217\144"] = true,  -- KASRA (ِ) U+0650
   ["\217\145"] = true,  -- SHADDA (ّ) U+0651
   ["\217\146"] = true,  -- SUKUN (ْ) U+0652
   ["\239\185\176"] = true, -- ﹰ FE70
   ["\239\185\178"] = true, -- ﹲ FE72
   ["\239\185\180"] = true, -- ﹴ FE74
   ["\239\185\182"] = true, -- ﹶ FE76
   ["\239\185\184"] = true, -- ﹸ FE78
   ["\239\185\186"] = true, -- ﹺ FE7A
   ["\239\185\188"] = true, -- ﹼ FE7C
   ["\239\185\190"] = true, -- ﹾ FE7E
   ["\217\147"] = true,  -- MADDAH ABOVE (ٓ) U+0653
   ["\217\148"] = true,  -- HAMZA ABOVE (ٔ) U+0654
   ["\217\149"] = true,  -- HAMZA BELOW (ٕ) U+0655
   ["\217\176"] = true,  -- SUPERSCRIPT ALEF (ٰ) U+0670
};

function AS_IsDiacritic(char)
   return AS_Diacritics[char] == true;
end

-------------------------------------------------------------------------------------------------------
AS_TATWEEL = "\217\128";  -- TATWEEL (ـ) U+0640

-------------------------------------------------------------------------------------------------------
AS_ArabicIndicNumerals = {
   ["\217\160"] = true,  -- ٠ U+0660
   ["\217\161"] = true,  -- ١ U+0661
   ["\217\162"] = true,  -- ٢ U+0662
   ["\217\163"] = true,  -- ٣ U+0663
   ["\217\164"] = true,  -- ٤ U+0664
   ["\217\165"] = true,  -- ٥ U+0665
   ["\217\166"] = true,  -- ٦ U+0666
   ["\217\167"] = true,  -- ٧ U+0667
   ["\217\168"] = true,  -- ٨ U+0668
   ["\217\169"] = true,  -- ٩ U+0669
};

-------------------------------------------------------------------------------------------------------
AS_ArabicPunctuation = {
   ["\216\159"] = true,  -- ؟ Arabic Question Mark U+061F
   ["\216\155"] = true,  -- ؛ Arabic Semicolon U+061B
   ["\216\140"] = true,  -- ، Arabic Comma U+060C
   ["\217\170"] = true,  -- ٪ Arabic Percent Sign U+066A
   ["\217\171"] = true,  -- ٫ Arabic Decimal Separator U+066B
   ["\217\172"] = true,  -- ٬ Arabic Thousands Separator U+066C
};

-------------------------------------------------------------------------------------------------------
-- AS_Reshaping_Rules
-------------------------------------------------------------------------------------------------------
AS_Reshaping_Rules = {
   -- ===== BASIC ARABIC ALPHABET (28 letters + variants) =====
   ["\216\167"] = { isolated = "\216\167", initial = "\216\167", middle = "\239\186\142", final = "\239\186\142" },                 -- ALEF (ا) U+0627
   ["\216\162"] = { isolated = "\239\186\129", initial = "\239\186\129", middle = "\239\186\142", final = "\239\186\142" },         -- ALEF WITH MADDA ABOVE (آ) U+0622
   ["\216\163"] = { isolated = "\216\163", initial = "\216\163", middle = "\239\186\132", final = "\239\186\132" },                 -- ALEF WITH HAMZA ABOVE (أ) U+0623
   ["\216\165"] = { isolated = "\216\165", initial = "\216\165", middle = "\239\186\136", final = "\239\186\136" },                 -- ALEF WITH HAMZA BELOW (إ) U+0625
   ["\216\168"] = { isolated = "\216\168", initial = "\239\186\145", middle = "\239\186\146", final = "\239\186\144" },             -- BEH (ب) U+0628
   ["\216\170"] = { isolated = "\216\170", initial = "\239\186\151", middle = "\239\186\152", final = "\239\186\150" },             -- TEH (ت) U+062A
   ["\216\171"] = { isolated = "\216\171", initial = "\239\186\155", middle = "\239\186\156", final = "\239\186\154" },             -- THEH (ث) U+062B
   ["\216\172"] = { isolated = "\216\172", initial = "\239\186\159", middle = "\239\186\160", final = "\239\186\158" },             -- JEEM (ج) U+062C
   ["\216\173"] = { isolated = "\216\173", initial = "\239\186\163", middle = "\239\186\164", final = "\239\186\162" },             -- HAH (ح) U+062D
   ["\216\174"] = { isolated = "\216\174", initial = "\239\186\167", middle = "\239\186\168", final = "\239\186\166" },             -- KHAH (خ) U+062E
   ["\216\175"] = { isolated = "\216\175", initial = "\216\175", middle = "\239\186\170", final = "\239\186\170" },                 -- DAL (د) U+062F
   ["\216\176"] = { isolated = "\216\176", initial = "\216\176", middle = "\239\186\172", final = "\239\186\172" },                 -- THAL (ذ) U+0630
   ["\216\177"] = { isolated = "\216\177", initial = "\216\177", middle = "\239\186\174", final = "\239\186\174" },                 -- REH (ر) U+0631
   ["\216\178"] = { isolated = "\216\178", initial = "\216\178", middle = "\239\186\176", final = "\239\186\176" },                 -- ZAIN (ز) U+0632
   ["\216\179"] = { isolated = "\216\179", initial = "\239\186\179", middle = "\239\186\180", final = "\239\186\178" },             -- SEEN (س) U+0633
   ["\216\180"] = { isolated = "\216\180", initial = "\239\186\183", middle = "\239\186\184", final = "\239\186\182" },             -- SHEEN (ش) U+0634
   ["\216\181"] = { isolated = "\216\181", initial = "\239\186\187", middle = "\239\186\188", final = "\239\186\186" },             -- SAD (ص) U+0635
   ["\216\182"] = { isolated = "\216\182", initial = "\239\186\191", middle = "\239\187\128", final = "\239\186\190" },             -- DAD (ض) U+0636
   ["\216\183"] = { isolated = "\216\183", initial = "\239\187\131", middle = "\239\187\132", final = "\239\187\130" },             -- TAH (ط) U+0637
   ["\216\184"] = { isolated = "\216\184", initial = "\239\187\135", middle = "\239\187\136", final = "\239\187\134" },             -- ZAH (ظ) U+0638
   ["\216\185"] = { isolated = "\216\185", initial = "\239\187\139", middle = "\239\187\140", final = "\239\187\138" },             -- AIN (ع) U+0639
   ["\216\186"] = { isolated = "\216\186", initial = "\239\187\143", middle = "\239\187\144", final = "\239\187\142" },             -- GHAIN (غ) U+063A
   ["\217\129"] = { isolated = "\217\129", initial = "\239\187\147", middle = "\239\187\148", final = "\239\187\146" },             -- FEH (ف) U+0641
   ["\217\130"] = { isolated = "\217\130", initial = "\239\187\151", middle = "\239\187\152", final = "\239\187\150" },             -- QAF (ق) U+0642
   ["\217\131"] = { isolated = "\217\131", initial = "\239\187\155", middle = "\239\187\156", final = "\239\187\154" },             -- KAF (ك) U+0643
   ["\217\132"] = { isolated = "\217\132", initial = "\239\187\159", middle = "\239\187\160", final = "\239\187\158" },             -- LAM (ل) U+0644
   ["\217\133"] = { isolated = "\217\133", initial = "\239\187\163", middle = "\239\187\164", final = "\239\187\162" },             -- MEEM (م) U+0645
   ["\217\134"] = { isolated = "\217\134", initial = "\239\187\167", middle = "\239\187\168", final = "\239\187\166" },             -- NOON (ن) U+0646
   ["\217\138"] = { isolated = "\217\138", initial = "\239\187\179", middle = "\239\187\180", final = "\239\187\178" },             -- YEH (ي) U+064A
   ["\216\166"] = { isolated = "\216\166", initial = "\239\186\139", middle = "\239\186\140", final = "\239\186\138" },             -- YEH WITH HAMZA ABOVE (ئ) U+0626
   ["\217\137"] = { isolated = "\217\137", initial = "\217\137", middle = "\217\137", final = "\239\187\176" },                     -- ALEF MAKSURA (ى) U+0649
   ["\217\136"] = { isolated = "\217\136", initial = "\217\136", middle = "\239\187\174", final = "\239\187\174" },                 -- WAW (و) U+0648
   ["\216\164"] = { isolated = "\216\164", initial = "\216\164", middle = "\239\186\134", final = "\239\186\134" },                 -- WAW WITH HAMZA ABOVE (ؤ) U+0624
   ["\217\135"] = { isolated = "\239\187\169", initial = "\239\187\171", middle = "\239\187\172", final = "\239\187\170" },         -- HEH (ه) U+0647
   ["\216\169"] = { isolated = "\216\169", initial = "\216\169", middle = "\216\169", final = "\239\186\148" },                     -- TEH MARBUTA (ة) U+0629
   ["\239\187\187"] = { isolated = "\239\187\187", initial = "\239\187\187", middle = "\239\187\188", final = "\239\187\188" },     -- LAM WITH ALEF ligature
   ["\239\187\181"] = { isolated = "\239\187\181", initial = "\239\187\181", middle = "\239\187\182", final = "\239\187\182" },     -- LAM WITH ALEF WITH MADDA ligature
   ["\217\132\216\163"] = { isolated = "\239\187\183", initial = "\239\187\183", middle = "\239\187\184", final = "\239\187\184" }, -- LAM WITH ALEF WITH HAMZA ABOVE
   ["\217\132\216\165"] = { isolated = "\239\187\185", initial = "\239\187\185", middle = "\239\187\186", final = "\239\187\186" }, -- LAM WITH ALEF WITH HAMZA BELOW
   ["\216\161"] = { isolated = "\216\161", initial = "\216\161", middle = "\216\161", final = "\216\161" },                         -- HAMZA (ء) U+0621

   -- ===== TATWEEL (Kashida) =====
   ["\217\128"] = { isolated = "\217\128", initial = "\217\128", middle = "\217\128", final = "\217\128" },                         -- TATWEEL (ـ) U+0640

   -- ===== PERSIAN/URDU EXTENSIONS =====
   ["\217\190"] = { isolated = "\217\190", initial = "\239\173\152", middle = "\239\173\153", final = "\239\173\151" },             -- PEH (پ) U+067E → FB58/FB59/FB57
   ["\218\134"] = { isolated = "\218\134", initial = "\239\173\188", middle = "\239\173\189", final = "\239\173\187" },             -- TCHEH (چ) U+0686 → FB7C/FB7D/FB7B
   ["\218\152"] = { isolated = "\218\152", initial = "\218\152", middle = "\239\174\139", final = "\239\174\139" },                 -- JEH (ژ) U+0698 → FB8B
   ["\218\175"] = { isolated = "\218\175", initial = "\239\174\148", middle = "\239\174\149", final = "\239\174\147" },             -- GAF (گ) U+06AF → FB94/FB95/FB93
   ["\218\169"] = { isolated = "\218\169", initial = "\239\174\144", middle = "\239\174\145", final = "\239\174\143" },             -- KEHEH (ک) U+06A9 → FB90/FB91/FB8F
   ["\218\140"] = { isolated = "\218\140", initial = "\218\140", middle = "\239\174\133", final = "\239\174\133" },                 -- DAHAL (ڌ) U+068C → FB85
   ["\219\140"] = { isolated = "\219\140", initial = "\239\175\190", middle = "\239\175\191", final = "\239\175\189" },             -- FARSI YEH (ی) U+06CC → FBFE/FBFF/FBFD
   ["\218\129"] = { isolated = "\218\129", initial = "\218\129", middle = "\218\129", final = "\218\129" },                         -- HAMZA ON HIGH (ځ) U+0681
};

AS_Reshaping_Rules2 = {
   -- ===== LAM-ALEF LIGATURES (mandatory in Arabic typography) =====
   ["\217\132" .. "\216\167"] = { isolated = "\239\187\187", initial = "\239\187\187", middle = "\239\187\188", final = "\239\187\188" }, -- LAM + ALEF (لا)
   ["\217\132" .. "\216\163"] = { isolated = "\239\187\183", initial = "\239\187\183", middle = "\239\187\184", final = "\239\187\184" }, -- LAM + ALEF HAMZA ABOVE (لأ)
   ["\217\132" .. "\216\165"] = { isolated = "\239\187\185", initial = "\239\187\185", middle = "\239\187\186", final = "\239\187\186" }, -- LAM + ALEF HAMZA BELOW (لإ)
   ["\217\132" .. "\216\162"] = { isolated = "\239\187\181", initial = "\239\187\181", middle = "\239\187\182", final = "\239\187\182" }, -- LAM + ALEF MADDA (لآ)
};

AS_Reshaping_Rules3 = {
   --["ا".."ل".."آ"] = {isolated = "ﻵا",  initial="ﻵا", middle="ﻵا", final="ﻶا"},        -- Arabic ligature ALEF+LAM+(ALEF with MADA)
};

-------------------------------------------------------------------------------------------------------
-- VERSION AND CAPABILITY INFO
-------------------------------------------------------------------------------------------------------
AS_RESHAPER_VERSION = "2.0.0";
AS_RESHAPER_CAPABILITIES = {
   diacritics = true,
   persian = true,
   tatweel = true,
   arabic_indic_numerals = true,
   extended_punctuation = true,
};

-------------------------------------------------------------------------------------------------------
-- Utility: Strip diacritics from Arabic text
-------------------------------------------------------------------------------------------------------
function AS_StripDiacritics(s)
   if not s or #s == 0 then return "" end
   local resultParts = {};
   local bytes = strlen(s);
   local pos = 1;
   while pos <= bytes do
      local charbytes = AS_UTF8charbytes(s, pos);
      local char = strsub(s, pos, pos + charbytes - 1);
      if not AS_IsDiacritic(char) then
         resultParts[#resultParts + 1] = char;
      end
      pos = pos + charbytes;
   end
   return table.concat(resultParts);
end

-------------------------------------------------------------------------------------------------------
-- Utility: Check if a string contains Arabic characters
-------------------------------------------------------------------------------------------------------
function AS_ContainsArabic(s)
   if not s or #s == 0 then return false end
   local bytes = strlen(s);
   local pos = 1;
   while pos <= bytes do
      local charbytes = AS_UTF8charbytes(s, pos);
      local char = strsub(s, pos, pos + charbytes - 1);
      if AS_Reshaping_Rules[char] then return true end
      pos = pos + charbytes;
   end
   return false;
end

function AS_IsArabicLetter(char)       return AS_Reshaping_Rules[char] ~= nil; end
function AS_IsArabicIndicNumeral(char) return AS_ArabicIndicNumerals[char] == true; end
function AS_IsArabicPunctuation(char)  return AS_ArabicPunctuation[char] == true; end
function AS_GetReshaperVersion()       return AS_RESHAPER_VERSION; end

-------------------------------------------------------------------------------------------------------

-- returns the number of bytes used by the UTF-8 character at byte
function AS_UTF8charbytes(s, i)
   -- argument defaults
   i = i or 1;

   -- argument checking
   if (type(s) ~= "string") then
      error("bad argument #1 to 'AS_UTF8charbytes' (string expected, got " .. type(s) .. ")");
   end
   if (type(i) ~= "number") then
      error("bad argument #2 to 'QTR_UFT8charbytes' (number expected, got " .. type(i) .. ")");
   end

   local c = strbyte(s, i);

   -- determine bytes needed for character, based on RFC 3629
   -- validate byte 1
   if (c > 0 and c <= 127) then
      -- UTF8-1
      return 1;
   elseif (c >= 194 and c <= 223) then
      -- UTF8-2
      local c2 = strbyte(s, i + 1);

      if (not c2) then
         error("UTF-8 string terminated early");
      end

      -- validate byte 2
      if (c2 < 128 or c2 > 191) then
         error("Invalid UTF-8 character");
      end

      return 2;
   elseif (c >= 224 and c <= 239) then
      -- UTF8-3
      local c2 = strbyte(s, i + 1);
      local c3 = strbyte(s, i + 2);

      if (not c2 or not c3) then
         error("UTF-8 string terminated early");
      end

      -- validate byte 2
      if (c == 224 and (c2 < 160 or c2 > 191)) then
         error("Invalid UTF-8 character")
      elseif (c == 237 and (c2 < 128 or c2 > 159)) then
         error("Invalid UTF-8 character");
      elseif (c2 < 128 or c2 > 191) then
         error("Invalid UTF-8 character");
      end

      -- validate byte 3
      if (c3 < 128 or c3 > 191) then
         error("Invalid UTF-8 character");
      end

      return 3;
   elseif (c >= 240 and c <= 244) then
      -- UTF8-4
      local c2 = strbyte(s, i + 1);
      local c3 = strbyte(s, i + 2);
      local c4 = strbyte(s, i + 3);

      if ((not c2) or (not c3) or (not c4)) then
         error("UTF-8 string terminated early");
      end

      -- validate byte 2
      if (c == 240 and (c2 < 144 or c2 > 191)) then
         error("Invalid UTF-8 character");
      elseif (c == 244 and (c2 < 128 or c2 > 143)) then
         error("Invalid UTF-8 character");
      elseif (c2 < 128 or c2 > 191) then
         error("Invalid UTF-8 character");
      end

      -- validate byte 3
      if (c3 < 128 or c3 > 191) then
         error("Invalid UTF-8 character");
      end

      -- validate byte 4
      if (c4 < 128 or c4 > 191) then
         error("Invalid UTF-8 character");
      end

      return 4;
   else
      error("Invalid UTF-8 character: " .. c);
   end
end

-------------------------------------------------------------------------------------------------------

-- returns the number of characters in a UTF-8 string
function AS_UTF8len(s)
   local len = 0;
   if (s) then -- argument checking
      local pos = 1;
      local bytes = strlen(s);
      while (pos <= bytes) do
         len = len + 1;
         pos = pos + AS_UTF8charbytes(s, pos);
      end
   end
   return len;
end

-------------------------------------------------------------------------------------------------------

-- function finding character c in the string s and return true or false
function AS_UTF8find(s, c)
   local odp = false;
   if (s and c) then           -- check if arguments are not empty (nil)
      local pos = 1;
      local bytes = strlen(s); -- number of length of the string s in bytes
      local charbytes;
      local char1;

      while (pos <= bytes) do
         charbytes = AS_UTF8charbytes(s, pos);        -- count of bytes of the character
         char1 = strsub(s, pos, pos + charbytes - 1); -- current character from the string s
         if (char1 == c) then
            odp = true;
         end
         pos = pos + AS_UTF8charbytes(s, pos);
      end
   end
   return odp;
end

-------------------------------------------------------------------------------------------------------

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
function AS_UTF8sub(s, i, j)
   j = j or -1; -- argument defaults, is not required

   -- argument checking
   if (type(s) ~= "string") then
      error("bad argument #1 to 'AS_UTF8sub' (string expected, got " .. type(s) .. ")");
   end
   if (type(i) ~= "number") then
      error("bad argument #2 to 'AS_UTF8sub' (number expected, got " .. type(i) .. ")");
   end
   if (type(j) ~= "number") then
      error("bad argument #3 to 'AS_UTF8sub' (number expected, got " .. type(j) .. ")");
   end

   local pos       = 1;
   local bytes     = strlen(s);
   local len       = 0;

   -- only set l if i or j is negative
   local l         = (i >= 0 and j >= 0) or AS_UTF8len(s);
   local startChar = (i >= 0) and i or l + i + 1;
   local endChar   = (j >= 0) and j or l + j + 1;

   -- can't have start before end!
   if (startChar > endChar) then
      return "";
   end

   -- byte offsets to pass to string.sub
   local startByte, endByte = 1, bytes;

   while (pos <= bytes) do
      len = len + 1;

      if (len == startChar) then
         startByte = pos;
      end

      pos = pos + AS_UTF8charbytes(s, pos);

      if (len == endChar) then
         endByte = pos - 1;
         break;
      end
   end

   return strsub(s, startByte, endByte);
end

-------------------------------------------------------------------------------------------------------

local AS_NonConnecting = {
   ["\216\167"] = true,  -- ALEF (ا)
   ["\216\162"] = true,  -- ALEF WITH MADDA ABOVE (آ)
   ["\216\163"] = true,  -- ALEF WITH HAMZA ABOVE (أ)
   ["\216\165"] = true,  -- ALEF WITH HAMZA BELOW (إ)
   ["\216\175"] = true,  -- DAL (د)
   ["\216\176"] = true,  -- THAL (ذ)
   ["\216\177"] = true,  -- REH (ر)
   ["\216\178"] = true,  -- ZAIN (ز)
   ["\217\136"] = true,  -- WAW (و)
   ["\216\164"] = true,  -- WAW WITH HAMZA ABOVE (ؤ)
   ["\217\137"] = true,  -- ALEF MAKSURA (ى)
   ["\216\169"] = true,  -- TEH MARBUTA (ة)
   ["\216\161"] = true,  -- HAMZA (ء)
   ["\218\152"] = true,  -- JEH (ژ)
   ["\218\140"] = true,  -- DAHAL (ڌ)
};

local function AS_IsNonConnecting(char)
   return AS_NonConnecting[char] == true;
end

local function AS_IsWordSeparator(char)
   if not char or char == '' or char == 'X' then return true end
   local spaces = '( )?؟!,.;:،؛٪\n\r\t"';
   if AS_UTF8find(spaces, char) then return true end
   if char == "\216\161" then return true end
   if (#char == 1) and (char >= "0") and (char <= "9") then return true end
   if AS_ArabicPunctuation[char] then return true end
   if AS_ArabicIndicNumerals[char] then return true end
   return false;
end

local function AS_IsAsciiDigit(char)
   return char and (#char == 1) and (char >= "0") and (char <= "9");
end

local function AS_IsAnyDigit(char)
   return AS_IsAsciiDigit(char) or (AS_ArabicIndicNumerals[char] == true);
end

local AS_NumberSeparators = {
   ["."] = true,
   [","] = true,
   ["\217\171"] = true, -- ٫ Arabic Decimal Separator U+066B
   ["\217\172"] = true, -- ٬ Arabic Thousands Separator U+066C
};

local function AS_IsNumberSeparator(char)
   return AS_NumberSeparators[char] == true;
end

local function AS_FixDigitRunsForRTL(s)
   if not s or #s == 0 then return "" end

   local out = {};
   local bytes = strlen(s);
   local pos = 1;

   while pos <= bytes do
      if strsub(s, pos, pos) == "|" then
         local nextChar = (pos + 1 <= bytes) and strsub(s, pos + 1, pos + 1) or "";

         if (nextChar == "c") and (pos + 9 <= bytes) then
            out[#out + 1] = strsub(s, pos, pos + 9);
            pos = pos + 10;
         elseif (nextChar == "r") then
            out[#out + 1] = "|r";
            pos = pos + 2;
         elseif (nextChar == "H") then
            local firstH = string.find(s, "|h", pos, true);
            if not firstH then
               out[#out + 1] = strsub(s, pos);
               break;
            end
            local secondH = string.find(s, "|h", firstH + 2, true);
            if not secondH then
               out[#out + 1] = strsub(s, pos);
               break;
            end
            out[#out + 1] = strsub(s, pos, secondH + 1);
            pos = secondH + 2;
         elseif (nextChar == "T") then
            local endT = string.find(s, "|t", pos, true);
            if not endT then
               out[#out + 1] = strsub(s, pos);
               break;
            end
            out[#out + 1] = strsub(s, pos, endT + 1);
            pos = endT + 2;
         else
            out[#out + 1] = "|";
            pos = pos + 1;
         end
      else
         local charbytes = AS_UTF8charbytes(s, pos);
         local ch = strsub(s, pos, pos + charbytes - 1);

         if AS_IsAnyDigit(ch) then
            local run = { ch };
            pos = pos + charbytes;

            while pos <= bytes do
               if strsub(s, pos, pos) == "|" then break end

               local cb2 = AS_UTF8charbytes(s, pos);
               local ch2 = strsub(s, pos, pos + cb2 - 1);

               if AS_IsAnyDigit(ch2) then
                  run[#run + 1] = ch2;
                  pos = pos + cb2;
               elseif AS_IsNumberSeparator(ch2) then
                  local lookPos = pos + cb2;
                  if (lookPos <= bytes) and (strsub(s, lookPos, lookPos) ~= "|") then
                     local cb3 = AS_UTF8charbytes(s, lookPos);
                     local ch3 = strsub(s, lookPos, lookPos + cb3 - 1);
                     if AS_IsAnyDigit(ch3) then
                        run[#run + 1] = ch2;
                        pos = pos + cb2;
                     else
                        break;
                     end
                  else
                     break;
                  end
               else
                  break;
               end
            end

            for i = #run, 1, -1 do
               out[#out + 1] = run[i];
            end
         else
            out[#out + 1] = ch;
            pos = pos + charbytes;
         end
      end
   end

   return table.concat(out);
end

-------------------------------------------------------------------------------------------------------

-- Reverses the order of UTF-8 letters with ReShaping
function AS_UTF8reverse(s)
   if not s or #s == 0 then return "" end

   local resultParts = {};
   local resultIndex = 1;
   local bytes = strlen(s);
   local pos = 1;
   local prevChar = nil;
   local prevConnectsRight = false;

   while (pos <= bytes) do
      local charbytes1 = AS_UTF8charbytes(s, pos);
      local char1 = strsub(s, pos, pos + charbytes1 - 1);

      local attachedDiacritics = {};
      local nextPos = pos + charbytes1;
      while nextPos <= bytes do
         local diacBytes = AS_UTF8charbytes(s, nextPos);
         local diacChar = strsub(s, nextPos, nextPos + diacBytes - 1);
         if AS_IsDiacritic(diacChar) then
            attachedDiacritics[#attachedDiacritics + 1] = diacChar;
            nextPos = nextPos + diacBytes;
         else
            break;
         end
      end
      pos = nextPos;

      if AS_IsDiacritic(char1) then
         local diacOut = char1;
         if AS_USE_PRESENTATION_DIACRITICS and AS_DiacriticPresentationForms[char1] then
            diacOut = AS_DiacriticPresentationForms[char1];
         end
         resultParts[resultIndex] = diacOut;
         resultIndex = resultIndex + 1;
      else
         local char2 = nil;
         local charbytes2 = 0;
         local lookPos = pos;

         while lookPos <= bytes do
            local tempBytes = AS_UTF8charbytes(s, lookPos);
            local tempChar = strsub(s, lookPos, lookPos + tempBytes - 1);
            if AS_IsDiacritic(tempChar) then
               lookPos = lookPos + tempBytes;
            else
               char2 = tempChar;
               charbytes2 = tempBytes;
               break;
            end
         end

         local ligatureApplied = false;
         local ligatureForm = nil;

         if char2 and AS_Reshaping_Rules2[char1 .. char2] then
            ligatureForm = AS_Reshaping_Rules2[char1 .. char2];
            ligatureApplied = true;
            pos = lookPos + charbytes2;

            while pos <= bytes do
               local skipBytes = AS_UTF8charbytes(s, pos);
               local skipChar = strsub(s, pos, pos + skipBytes - 1);
               if AS_IsDiacritic(skipChar) then
                  pos = pos + skipBytes;
               else
                  break;
               end
            end

            lookPos = pos;
            char2 = nil;
            while lookPos <= bytes do
               local tempBytes = AS_UTF8charbytes(s, lookPos);
               local tempChar = strsub(s, lookPos, lookPos + tempBytes - 1);
               if AS_IsDiacritic(tempChar) then
                  lookPos = lookPos + tempBytes;
               else
                  char2 = tempChar;
                  break;
               end
            end
         end

         local isCurrentSeparator = AS_IsWordSeparator(char1);
         local isNextSeparator = AS_IsWordSeparator(char2);
         local isCurrentArabic = ligatureApplied or (AS_Reshaping_Rules[char1] ~= nil);

         if (not isCurrentSeparator) and (not isCurrentArabic) then
            isCurrentSeparator = true;
         end

         if isCurrentSeparator then
            local outputChar = char1;
            if (char1 == "<") then outputChar = ">";
            elseif (char1 == ">") then outputChar = "<";
            elseif (char1 == "(") then outputChar = ")";
            elseif (char1 == ")") then outputChar = "(";
            elseif (char1 == "[") then outputChar = "]";
            elseif (char1 == "]") then outputChar = "[";
            elseif (char1 == "{") then outputChar = "}";
            elseif (char1 == "}") then outputChar = "{";
            end

            resultParts[resultIndex] = outputChar;
            resultIndex = resultIndex + 1;
            prevChar = nil;
            prevConnectsRight = false;
         else
            local connectedFromLeft = (prevChar ~= nil) and prevConnectsRight;
            local currentConnectsRight = false;

            if ligatureApplied then
               currentConnectsRight = false;
            elseif AS_IsNonConnecting(char1) then
               currentConnectsRight = false;
            elseif not isNextSeparator and char2 and AS_Reshaping_Rules[char2] then
               currentConnectsRight = true;
            else
               currentConnectsRight = false;
            end

            local position;
            if connectedFromLeft and currentConnectsRight then
               position = 2;
            elseif connectedFromLeft and not currentConnectsRight then
               position = 3;
            elseif not connectedFromLeft and currentConnectsRight then
               position = 1;
            else
               position = 0;
            end

            local outputChar;
            if ligatureApplied and ligatureForm then
               if position == 0 then
                  outputChar = ligatureForm.isolated;
               elseif position == 1 then
                  outputChar = ligatureForm.initial;
               elseif position == 2 then
                  outputChar = ligatureForm.middle;
               else
                  outputChar = ligatureForm.final;
               end
            else
               local rules = AS_Reshaping_Rules[char1];
               if rules then
                  if position == 0 then
                     outputChar = rules.isolated;
                  elseif position == 1 then
                     outputChar = rules.initial;
                  elseif position == 2 then
                     outputChar = rules.middle;
                  else
                     outputChar = rules.final;
                  end
               else
                  outputChar = char1;
               end
            end

            if (debug_show_form == 1) then
               outputChar = tostring(position) .. outputChar;
            end

            for _, diac in ipairs(attachedDiacritics) do
               if AS_USE_PRESENTATION_DIACRITICS and AS_DiacriticPresentationForms[diac] then
                  outputChar = outputChar .. AS_DiacriticPresentationForms[diac];
               else
                  outputChar = outputChar .. diac;
               end
            end

            resultParts[resultIndex] = outputChar;
            resultIndex = resultIndex + 1;
            prevChar = char1;
            prevConnectsRight = currentConnectsRight;
         end
      end
   end

   local reversed = {};
   for i = resultIndex - 1, 1, -1 do
      reversed[#reversed + 1] = resultParts[i];
   end

   return AS_FixDigitRunsForRTL(table.concat(reversed));
end

-------------------------------------------------------------------------------------------------------
-- the function create testing frame to determine the length of text in a frame

function AS_CreateTestLine()
   -- 3.3.5a: simple hidden frame for measuring Arabic text line width
   AS_TestLine = CreateFrame("Frame", "AS_TestLine", UIParent);
   AS_TestLine:SetHeight(150);
   AS_TestLine:SetWidth(300);
   AS_TestLine:ClearAllPoints();
   AS_TestLine:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -300);
   local CHchild = CreateFrame("Frame", nil, AS_TestLine);
   CHchild:SetPoint("TOPLEFT", AS_TestLine, "TOPLEFT", 0, 0);
   CHchild:SetSize(552, 100);
   AS_TestLine.text = CHchild:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
   AS_TestLine.text:SetPoint("TOPLEFT", CHchild, "TOPLEFT", 2, 0);
   AS_TestLine.text:SetText("");
   AS_TestLine.text:SetSize(DEFAULT_CHAT_FRAME:GetWidth(), 0);
   AS_TestLine.text:SetJustifyH("LEFT");
   AS_TestLine:Hide(); -- the frame is invisible in the game
end

-------------------------------------------------------------------------------------------------------
-- the function prepares Arabic text to be displayed in a specific window width

function AS_ReverseAndPrepareLineText(Atext, Awidth, AfontSize)
   local retstr = "";
   if (Atext and Awidth and AfontSize) then
      if (AS_TestLine == nil) then -- a own frame for displaying the translation of texts and determining the length
         AS_CreateTestLine();
      end
      Atext = string.gsub(Atext, " #", "#");
      Atext = string.gsub(Atext, "# ", "#");
      local bytes = strlen(Atext);
      local pos = 1;
      local counter = 0;
      local link_start_stop = false;
      local newstr = "";
      local nextstr = "";
      local charbytes;
      local newstrR;
      local char1 = "";
      local char2 = "";
      local last_space = 0;
      while (pos <= bytes) do                                     -- UWAGA: tekst arabski jest podany wprost, od lewej są poszczególne znaki
         charbytes = AS_UTF8charbytes(Atext, pos);                -- count of bytes (liczba bajtów znaku)
         char1 = strsub(Atext, pos, pos + charbytes - 1);         -- pobrany znak litery
         newstr = newstr .. char1;                                -- dodaję kolejny odczytany znak

         if ((char2 .. char1 == "|r") and (pos < bytes)) then     -- start of the link
            link_start_stop = true;
         elseif ((char2 .. char1 == "|c") and (pos < bytes)) then -- end of the link
            link_start_stop = false;
         end

         if ((char1 == '#') or ((char1 == " ") and (link_start_stop == false))) then -- mamy spację, nie wewnątrz linku
            last_space = 0;
            nextstr = "";
         else
            nextstr = nextstr .. char1; -- znaki kolejne po ostatniej spacji
            last_space = last_space + charbytes;
         end
         if (link_start_stop == false) then -- nie jesteśmy wewnątrz linku - można sprawdzać
            AS_TestLine:SetWidth(Awidth);   -- set the frame width to the text
            AS_TestLine.text:SetFont(QTR_Font2, AfontSize);
            AS_TestLine.text:SetText(AS_UTF8reverse(newstr));
            if ((char1 == '#') or (AS_TestLine.text:GetHeight() > AfontSize * 1.5)) then -- tekst nie mieści się już w 1 linii
               newstr = string.sub(newstr, 1, strlen(newstr) - last_space);              -- tekst do ostatniej spacji
               newstr = string.gsub(newstr, "#", "");
               retstr = retstr .. AS_AddSpaces(AS_UTF8reverse(newstr), Awidth, AfontSize) .. "\n";
               newstr = nextstr;
               nextstr = "";
               counter = 0;
            end
         end
         char2 = char1; -- zapamiętaj znak, potrzebne w następnej pętli
         pos = pos + charbytes;
      end
      retstr = retstr .. AS_AddSpaces(AS_UTF8reverse(newstr), Awidth, AfontSize);
      retstr = string.gsub(retstr, "#", "");
      retstr = string.gsub(retstr, " \n", "\n"); -- space before newline code is useless
      retstr = string.gsub(retstr, "\n ", "\n"); -- space after newline code is useless
   end

   return retstr;
end

-------------------------------------------------------------------------------------------------------
-- the function appends spaces to the left of the given text so that the text is aligned to the right

function AS_AddSpaces(txt, width, fontsize)
   local chars_limitC = 300;    -- so much max. characters can fit on one line

   if (AS_TestLine == nil) then -- a own frame for displaying the translation of texts and determining the length
      AS_CreateTestLine();
   end
   local count = 0;
   local text = txt;
   AS_TestLine.text:SetWidth(width);
   AS_TestLine.text:SetFont(QTR_Font2, fontsize);
   AS_TestLine.text:SetText(text);
   while ((AS_TestLine.text:GetHeight() < fontsize * 1.5) and (count < chars_limitC)) do
      count = count + 1;
      text = " " .. text;
      AS_TestLine.text:SetText(text);
   end
   if (count < chars_limitC) then -- failed to properly add leading spaces
      for i = 2, count, 1 do      -- spaces are added to the left of the text
         txt = " " .. txt;
      end
   end
   AS_TestLine.text:SetText(txt);

   return (txt);
end
