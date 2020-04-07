VERSION = "0.1.3"

SLASH_TEST1 = "/test1"
SLASH_ROTUS1 = "/rotus"

local msgPrefix = "|cff352838[|r|cff915ea7R|r|cffc572dcotusGang|r|cff352838]|r "

local rotusItemId = 13468
local rotusItemLink = "\124cff1eff00\124Hitem:13468::::::::60:::::\124h[Black Lotus]\124h\124r"
local rotusItemLinkItemInfo = select(2,GetItemInfo(13468))
local gatheringSpellid = 2366

local currentlyPickingGuid = ""

local zones = {};
zones["Eastern Plaguelands"] = "EPL"
zones["Winterspring"] = "WS"
zones["Silithus"] = "Silithus"
zones["Burning Steppes"] = "Steppes"

local channel = "GUILD"
--local channel = "RAID"
local debug = false

local RotusGang_lastPickedHour = {};
local RotusGang_lastPickedMinute = {};
local RotusGang_lastPickedBy = {};

now = GetTime();
antiSpam = {};

SlashCmdList["TEST"] = function(msg)
  print(msgPrefix .. "Hello World!");
--   C_ChatInfo.SendAddonMessage("RG9", "test", "GUILD");
end

SlashCmdList["ROTUS"] = function(cmd)

  if (cmd == "lost") then
    C_ChatInfo.SendAddonMessage("RG9", "lost,"..GetZoneText(), channel);
    return
  end

  if (cmd == "ping") then
    C_ChatInfo.SendAddonMessage("RG9", "ping", channel);
    return
  end

  for zone,shorthand in pairs(zones) do
    local msg = "";
    if(lastPickedHour[zone] ~=  nil and lastPickedMinute[zone] ~= nil) then
      local nextWindowFromHours, nextWindowFromMinutes = addMinutes(lastPickedHour[zone], lastPickedMinute[zone], 45)
      local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)

      msg = lastPickedBy[zone] .. " picked the " .. rotusItemLinkItemInfo .. " in " .. zones[zone] .. " at " .. addLeadingZero(lastPickedHour[zone]) .. ":" .. addLeadingZero(lastPickedMinute[zone]) .. "! Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. "."
    else
      msg = "No timer currently for " .. shorthand .. "."
    end

    if(cmd == "chat") then
      if UnitInRaid("player") then
        SendChatMessage("[RotusGang] " .. msg, "RAID");
      else
        SendChatMessage("[RotusGang] " .. msg, "PARTY");
      end
    else
      C_ChatInfo.SendAddonMessage("RG9", "broadcast," .. msgPrefix .. msg, channel);
    end
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

    if(prefix == "RG9") then
      local hour, min = GetGameTime();

      local msgType, param1 = strsplit(",", msg);

      if(msgType == "test") then
        print(msgPrefix .. fromName .. " is testing broadcasting");
      elseif(msgType == "ping") then
        print(msgPrefix .. "Ping request received from " .. fromName .. ".")
        C_ChatInfo.SendAddonMessage("RG9", "pong,".. VERSION, channel);
      elseif(msgType == "pong") then
        if param1 ~= nil then reportedVersion = param1 else reportedVersion = "?" end
        print(msgPrefix .. fromName .. " replied with a pong (v".. reportedVersion ..")")
      elseif(msgType == "picking") then
        if param1 ~= nil then pickZone = param1 else pickZone = "?" end
        print(msgPrefix ..  fromName .. " is picking a " .. rotusItemLink .. " in " .. pickZone .. "!")
      elseif(msgType == "interrupted") then
        print(msgPrefix .. fromName .. "'s attempt was interrupted!")
      elseif(msgType == "failed") then
        print(msgPrefix .. fromName .. "'s attempt to pick up the " .. rotusItemLink .. " failed!")
      elseif(msgType == "picked") then
        local zone = param1

        lastPickedHour[zone] = hour
        lastPickedMinute[zone] = min
        lastPickedBy[zone] = fromName
  
        local nextWindowFromHours, nextWindowFromMinutes = addMinutes(hour, min, 45)
        local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)
  
  
        print(msgPrefix .. lastPickedBy[zone] .. " picked the " .. rotusItemLink .. " in " .. zones[zone] .. " at " .. addLeadingZero(hour) .. ":" .. addLeadingZero(min) .. "! Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. ".")
      elseif(msgType == "lost") then
        zone = param1

        lastPickedHour[zone] = hour
        lastPickedMinute[zone] = min
        lastPickedBy[zone] = "Someone"
  
        local nextWindowFromHours, nextWindowFromMinutes = addMinutes(hour, min, 45)
        local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)
  
        print(msgPrefix .. lastPickedBy[zone] .. " picked the " .. rotusItemLink .. " at " .. addLeadingZero(hour) .. ":" .. addLeadingZero(min) .. " :( Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. ".")      
      elseif(msgType == "broadcast") then
        print(param1)
      end
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
          C_ChatInfo.SendAddonMessage("RG9", "picked," .. GetZoneText(), channel);
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
        C_ChatInfo.SendAddonMessage("RG9", "picking," .. GetZoneText() , channel);
      end
    end
  end

  if(type == "UNIT_SPELLCAST_INTERRUPTED") then
    local _, actor, guid, spellId = ...
    if(actor == "player" and spellId == gatheringSpellid and guid == currentlyPickingGuid) then
      if(debounce("interrupted", 0.5)) then
        if debug then print("interrupted"); end
        C_ChatInfo.SendAddonMessage("RG9", "interrupted," .. GetZoneText(), channel);
      end
    end
  end


  if(type == "UNIT_SPELLCAST_FAILED") then
    local _, actor, guid, spellId = ...

    if(actor == "player" and spellId == gatheringSpellid) then
      if(currentlyPickingGuid == guid) then
        if(debounce("failed", 0.5)) then
          if debug then print("failed pickup") end
          C_ChatInfo.SendAddonMessage("RG9", "failed," .. GetZoneText(), channel);
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

function addMinutes(hours, minutes, addedMinutes) 
  if(minutes + addedMinutes <= 59) then
    return hours, minutes + addedMinutes
  else
    if(hours + 1 <= 23) then
      return hours + 1, minutes + addedMinutes - 60
    else
      return hours + 1 - 24, minutes + addedMinutes - 60
    end
  end
end

function addLeadingZero(num)
  if(num < 10) then
    return "0" .. num
  else
    return num
  end
end
