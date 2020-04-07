
SLASH_TEST1 = "/test1"
SLASH_ROTUS1 = "/rotus"

local msgPrefix = "|cff352838[|r|cff915ea7R|r|cffc572dcotusGang|r|cff352838]|r "

local rotusItemId = 13468
local rotusItemLink = select(2,GetItemInfo(rotusItemId))
local gatheringSpellid = 2366

local currentlyPickingGuid = ""

local debug = true

local lastPicked = 0;
local lastPickedBy = "";

now = GetTime();
antiSpam = {};

SlashCmdList["TEST"] = function(msg)
   print(prefix .. "Hello World!");
   C_ChatInfo.SendAddonMessage("RG9", "test", "GUILD");
end

SlashCmdList["ROTUS"] = function()
  local msg = "";
  if(lastPicked ~=  0) then

    local nextWindowFrom = lastPicked + 45 * 60
    local nextWindowTo = lastPicked + (45 + 30) * 60

    msg = "[RotusGang] " .. lastPickedBy .. " picked the " .. rotusItemLink .. " at " .. date("%H:%M", timestamp) .. "! Next window " .. date("%H:%M", nextWindowFrom) .. " - " .. date("%H:%M", nextWindowTo) .. "."
  else
    msg = "[RotusGang] No timer currently."
  end

  if UnitInRaid("player") then
    SendChatMessage(msg, "RAID");
  else
    SendChatMessage(msg, "PARTY");
  end
end

function debounce(type, seconds)
  if(antiSpam[type] == nil) then
		antiSpam[type] = GetTime();
    return true
	elseif GetTime() - antiSpam[type] > seconds then
		antiSpam[type] = GetTime();
		return true
	else
		return false
	end
end

local f = CreateFrame("Frame")
C_ChatInfo.RegisterAddonMessagePrefix("RG9");
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("UNIT_SPELLCAST_SENT")
--f:RegisterEvent("UNIT_SPELLCAST_STOP")
f:RegisterEvent("UNIT_SPELLCAST_FAILED")
f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")


f:SetScript("OnEvent", function(event,...)
  local type = ...

  if(type == "CHAT_MSG_ADDON") then
    local type, prefix, msg, channel, fromGuid, fromName = ...

    local timestamp = GetServerTime()
    if(msg == "test") then
      print(msgPrefix .. fromName .. " is testing broadcasting");
    elseif(msg == "picking") then
      print(msgPrefix .. date("%H:%M:%S", timestamp) .. ": " .. fromName .. " is picking a " .. rotusItemLink .. "!")
    elseif(msg == "interrupted") then
      print(msgPrefix .. date("%H:%M:%S", timestamp) .. ": " .. fromName .. " is interrupted!")
    elseif(msg == "failed") then
      print(msgPrefix .. date("%H:%M:%S", timestamp) .. ": " .. fromName .. " failed to pick up the " .. rotusItemLink .. "!")
    elseif(msg == "picked") then
      lastPicked = timestamp
      lastPickedBy = fromName
      local nextWindowFrom = timestamp + 45 * 60
      local nextWindowTo = timestamp + (45 + 30) * 60

      print(msgPrefix ..date("%H:%M:%S", timestamp) .. ": " .. fromName .. " picked the " .. rotusItemLink .. " at " .. date("%H:%M", timestamp) .. "! Next window " .. date("%H:%M", nextWindowFrom) .. " - " .. date("%H:%M", nextWindowTo) .. ".")
    end
  end

  if(type == "CHAT_MSG_LOOT") then
    local _, msg = ...
    local looterName = select(6, ...);
    local playerName = UnitName("player");
    local PATTERN_LOOT_ITEM_SELF = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
    if(looterName == playerName) then
      if msg:match(PATTERN_LOOT_ITEM_SELF) then
        itemLink = string.match(msg, PATTERN_LOOT_ITEM_SELF)
        local itemId = getItemId(itemLink)

        if(itemId == rotusItemId) then
          if debug then print("Broadcasted rotus pickup!"); end
          C_ChatInfo.SendAddonMessage("RG9", "picked", "GUILD");
        end
      end
    end
  end

  if(type == "UNIT_SPELLCAST_SENT") then
    local _, actor, target, guid, spellId = ...
    if(actor == "player" and spellId == gatheringSpellid and target == "Black Lotus") then
      if(debounce("picking", 0.5)) then
        if debug then print("started picking"); end
        currentlyPickingGuid = guid
        C_ChatInfo.SendAddonMessage("RG9", "picking", "GUILD");
      end
    end
  end

  if(type == "UNIT_SPELLCAST_INTERRUPTED") then
    local _, actor, guid, spellId = ...
    if(actor == "player" and spellId == gatheringSpellid and guid == currentlyPickingGuid) then
      if(debounce("interrupted", 0.5)) then
        if debug then print("interrupted"); end
        C_ChatInfo.SendAddonMessage("RG9", "interrupted", "GUILD");
      end
    end
  end


  if(type == "UNIT_SPELLCAST_FAILED") then
    local _, actor, guid, spellId = ...

    if(actor == "player" and spellId == gatheringSpellid) then
      if(currentlyPickingGuid == guid) then
        if(debounce("failed", 0.5)) then
          if debug then print("failed pickup") end
          C_ChatInfo.SendAddonMessage("RG9", "failed", "GUILD");
        end
      end
    end
  end

end);

function getItemId(itemString)
  if not itemString then
      return
  end
  local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemString, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return tonumber(Id)
end
