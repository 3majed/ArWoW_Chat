local ADDON_NAME, ns = ...

-- Tracks whether compatibility hooks have already been applied
local elvuiHooked = false
local pratHooked = false
local chatterHooked = false
local dragonUIHooked = false
local leatrixHooked = false

-- ============================================================================
-- ElvUI Compatibility Support
-- Integrates with ElvUI's Chat and Misc modules to fix Arabic text display
-- ============================================================================
local function InstallElvUIHooks()
   -- Try to locate the main ElvUI engine object
   local elvuiEngine = _G.ElvUI and _G.ElvUI[1]
   if (not elvuiEngine or not elvuiEngine.GetModule) then 
      return false 
   end
   
   local didHook = false

   -- -------------------------------------------------------------------------
   -- 1. Chat Module Hooks (Handles standard chat frames and the copy window)
   -- -------------------------------------------------------------------------
   local okChat, chatModule = pcall(elvuiEngine.GetModule, elvuiEngine, "Chat")
   if (okChat and chatModule) then
      
      -- Hook SetupChat: Called when ElvUI sets up the initial chat frames
      hooksecurefunc(chatModule, "SetupChat", function()
         if (not ns.IsEnabled()) then return end
         ns.ApplyFonts()
      end)
      
      -- Hook CopyChat: Called when a user clicks ElvUI's "Copy Text" button
      -- The stored messages are already appropriately formatted by the ChatFrame filters.
      -- We just need to enforce our Arabic font onto the copy text editBox
      hooksecurefunc(chatModule, "CopyChat", function(self)
         if (not ns.IsEnabled() or not self.copyChatFrame or not self.copyChatFrame.editBox) then return end
         
         local _, size, flags = self.copyChatFrame.editBox:GetFont()
         self.copyChatFrame.editBox:SetFont(ns.CHAT_FONT, size or 13, flags or "")
      end)
      
      -- Hook SetChatFont: Called whenever a user changes ElvUI chat font sizes/styles
      hooksecurefunc(chatModule, "SetChatFont", function(_, _, chatFrame)
         if (not ns.IsEnabled()) then return end
         
         if (chatFrame) then
            ns.ApplyFontToChatFrame(chatFrame)
            
            local editBox = chatFrame.editBox or ((chatFrame.GetName and _G[chatFrame:GetName() .. "EditBox"]) or nil)
            if (editBox) then 
               ns.ApplyFontToEditBox(editBox) 
            end
         else
            ns.ApplyFonts()
         end
      end)
      
      didHook = true
   end
   
   -- -------------------------------------------------------------------------
   -- 2. Misc Module Hooks (Handles chat bubble text rendering)
   -- -------------------------------------------------------------------------
   local okMisc, miscModule = pcall(elvuiEngine.GetModule, elvuiEngine, "Misc")
   if (okMisc and miscModule) then
      
      -- Hook SkinBubble: Ensures 3D chat bubbles use the Arabic font when Skinner activates
      hooksecurefunc(miscModule, "SkinBubble", function(_, frame)
         if (not ns.IsEnabled() or not frame) then return end
         ns.ApplyBubbleFontToFrame(frame, ns.GetBubbleTextRegion(frame))
      end)
      
      -- Hook UpdateBubbleBorder: Catches updates to bubble UI dynamically
      hooksecurefunc(miscModule, "UpdateBubbleBorder", function(frameOrSelf, maybeFrame)
         if (not ns.IsEnabled()) then return end
         
         local frame = maybeFrame or frameOrSelf
         if (frame and frame.GetObjectType) then 
            ns.ApplyBubbleFontToFrame(frame, ns.GetBubbleTextRegion(frame)) 
         end
      end)
      
      didHook = true
   end
   
   return didHook
end

-- ============================================================================
-- Prat-3.0 Compatibility Support
-- Integrates with Prat's CopyChat and Bubbles modules to fix Arabic text display
-- ============================================================================
local function InstallPratHooks()
   local didHook = false
   
   -- -------------------------------------------------------------------------
   -- 1. Prat Bubbles Hook
   -- -------------------------------------------------------------------------
   local bubblesModule = _G.Prat and type(_G.Prat.GetModule) == "function" and _G.Prat:GetModule("Bubbles", true)
   if (bubblesModule) then
      hooksecurefunc(bubblesModule, "FormatCallback", function(self, frame, fontstring)
         if (not ns.IsEnabled() or not frame or not frame:IsShown()) then return end
         
         -- Prat reformats everything and limits text width.
         -- Redo ArWoW's processing to restore multiline right-to-left wrapped Arabic
         ns.ProcessBubbleRegion(frame, fontstring)
         
         -- Prevent Prat from severely capping the fontstring width, which truncates wrapped lines
         if (fontstring.ArWoWStableBubbleWidth) then
            fontstring:SetWidth(fontstring.ArWoWStableBubbleWidth)
         end
      end)
      didHook = true
   end
   
   return didHook
end

-- ============================================================================
-- Chatter Compatibility Support
-- Integrates with Chatter's Copy Chat and Chat Font modules
-- ============================================================================
local function InstallChatterHooks()
   if (not IsAddOnLoaded("Chatter") or not _G.Chatter or type(_G.Chatter.GetModule) ~= "function") then return false end
   
   local didHook = false
   
   -- -------------------------------------------------------------------------
   -- 1. Chatter CopyChat Font Hook
   -- -------------------------------------------------------------------------
   local copyChatModule = _G.Chatter:GetModule("Chat Copy", true)
   if (copyChatModule and type(copyChatModule.Copy) == "function") then
      hooksecurefunc(copyChatModule, "Copy", function(self)
         if (not ns.IsEnabled() or not self.editBox) then return end
         
         -- Enforce Janna font onto the Copy Chat window when opened
         local _, size, flags = self.editBox:GetFont()
         self.editBox:SetFont(ns.CHAT_FONT, size or 13, flags or "")
         
         -- Disable Chatter's native bounding box wrapping just like Prat
         self.editBox:SetWidth(4000)
      end)
      didHook = true
   end

   -- -------------------------------------------------------------------------
   -- 2. Chatter ChatFont Hook
   -- -------------------------------------------------------------------------
   local chatFontModule = _G.Chatter:GetModule("Chat Font", true)
   if (chatFontModule and type(chatFontModule.SetFont) == "function") then
      hooksecurefunc(chatFontModule, "SetFont", function(_, cf)
         if (not ns.IsEnabled()) then return end
         if (cf) then
            ns.ApplyFontToChatFrame(cf)
         else
            ns.ApplyFonts()
         end
      end)
      didHook = true
   end
   
   -- -------------------------------------------------------------------------
   -- 3. Chatter EditBox Hook
   -- -------------------------------------------------------------------------
   local editBoxModule = _G.Chatter:GetModule("Edit Box", true)
   if (editBoxModule and type(editBoxModule.Decorate) == "function") then
      hooksecurefunc(editBoxModule, "Decorate", function(_, chatframe)
         if (not ns.IsEnabled() or not chatframe) then return end
         local editBox = _G[chatframe:GetName() .. "EditBox"]
         if (editBox) then ns.ApplyFontToEditBox(editBox) end
      end)
      
      -- Also catch when SharedMedia dynamically updates EditBox fonts
      if (type(editBoxModule.LibSharedMedia_Registered) == "function") then
         hooksecurefunc(editBoxModule, "LibSharedMedia_Registered", function()
            if (ns.IsEnabled()) then ns.ApplyFonts() end
         end)
      end
      
      if (type(editBoxModule.OnEnable) == "function") then
         hooksecurefunc(editBoxModule, "OnEnable", function()
            if (ns.IsEnabled()) then ns.ApplyFonts() end
         end)
      end
      
      didHook = true
   end
   
   return didHook
end

-- ============================================================================
-- DragonUI Compatibility Support
-- Hooks DragonUI's ChatModsModule to support its Chat Copy Window
-- ============================================================================
local function InstallDragonUIHooks()
   -- Support DragonUI if it is fully loaded and exposes the chat mods system function
   if (not IsAddOnLoaded("DragonUI") or not _G.DragonUI or type(_G.DragonUI.ApplyChatModsSystem) ~= "function") then 
      return false 
   end
   
   local didHook = false
   
   -- -------------------------------------------------------------------------
   -- 1. DragonUI ApplyChatModsSystem Hook
   -- -------------------------------------------------------------------------
   -- We hook the main module application callback since DragonUI_ChatCopyBox 
   -- doesn't exist globally until PEW/Apply fires
   hooksecurefunc(_G.DragonUI, "ApplyChatModsSystem", function()
      if (not ns.IsEnabled()) then return end
      
      -- Apply Janna Arabic font correctly wrapped when generating double click Copy Frames
      if (_G.DragonUI_ChatCopyBox) then
         local _, size, flags = _G.DragonUI_ChatCopyBox:GetFont()
         _G.DragonUI_ChatCopyBox:SetFont(ns.CHAT_FONT, size or 13, flags or "")
         
         -- DragonUI creates the ChatCopyBox as a multiline EditBox, which destroys UTF-8 Arabic words due to native Left-to-Right bounding.
         -- Setting the width significantly past the screen prevents Blizzard's native system from wrapping words, retaining Arabic shaping.
         _G.DragonUI_ChatCopyBox:SetWidth(4000)
         
         -- Protect against DragonUI updating the Editbox back over the Arabic format when redisplayed since Editboxes persist Show/Hides.
         if (not _G.DragonUI_ChatCopyBox.ArWoWHooked) then
            _G.DragonUI_ChatCopyBox:HookScript("OnShow", function(self)
               if (not ns.IsEnabled()) then return end
               local _, csize, cflags = self:GetFont()
               self:SetFont(ns.CHAT_FONT, csize or 13, cflags or "")
               self:SetWidth(4000)
            end)
            _G.DragonUI_ChatCopyBox.ArWoWHooked = true
         end
         
         didHook = true
      end
   end)
   
   return didHook
end

-- ============================================================================
-- Leatrix Plus Compatibility Support
-- Hooks Leatrix Plus's Recent Chat Windows
-- ============================================================================
local function InstallLeatrixHooks()
   -- Support Leatrix Plus if it is fully loaded
   if (not IsAddOnLoaded("Leatrix_Plus") or not _G.LeaPlusLC) then 
      return false 
   end
   
   local LeaPlusLC = _G.LeaPlusLC
   local didHook = false
   
   -- Leatrix dynamically triggers a script that creates the copy frame EditBox when the chat Double Click/Menu activates.
   -- It assigns the resulting active EditBox pointer to LeaPlusLC.RecentChatEdit
   if (LeaPlusLC) then
      local function WrapLeatrixCopyBox()
         if (not ns.IsEnabled()) then return end
         
         local editBox = LeaPlusLC.RecentChatEdit
         if (editBox and not editBox.ArWoWHooked) then
            local _, size, flags = editBox:GetFont()
            editBox:SetFont(ns.CHAT_FONT, size or 13, flags or "")
            -- Disable bounding limit wrap
            editBox:SetWidth(4000)
            
            editBox:HookScript("OnShow", function(self)
               if (not ns.IsEnabled()) then return end
               local _, csize, cflags = self:GetFont()
               self:SetFont(ns.CHAT_FONT, csize or 13, cflags or "")
               self:SetWidth(4000)
            end)
            
            editBox.ArWoWHooked = true
         end
      end
      
      -- Instead of hooking an explicit function creation or trying to guess context menu timing, 
      -- continuously scan while the Leatrix Chat Window is visibly open. This catches every 
      -- dynamically spawned EditBox recreation instantly.
      local leatrixScanner = CreateFrame("Frame")
      leatrixScanner:SetScript("OnUpdate", function()
         if (LeaPlusLC.RecentChatFrame and LeaPlusLC.RecentChatFrame:IsShown()) then
            WrapLeatrixCopyBox()
         end
      end)
      
      didHook = true
   end
   
   return didHook
end

-- ============================================================================
-- Primary Compatibility Entry Point
-- Called directly from ArWoW_Chat.lua -> ApplySupport()
-- ============================================================================
function ns.InstallCompatibilityHooks()
   -- Add other third-party UI addon initializers here in the future
   if (not elvuiHooked) then 
      elvuiHooked = InstallElvUIHooks() 
   end
   
   if (not pratHooked) then 
      pratHooked = InstallPratHooks() 
   end
   
   if (not chatterHooked) then
      chatterHooked = InstallChatterHooks()
   end
   
   if (not dragonUIHooked) then
      dragonUIHooked = InstallDragonUIHooks()
   end
   
   if (not leatrixHooked) then
      leatrixHooked = InstallLeatrixHooks()
   end
end
