
VERSION = "0.2.7"

SLASH_TEST1 = "/test1"
SLASH_ROTUS1 = "/rotus"

local msgPrefix = "|cff352838[|r|cff915ea7R|r|cffc572dcotusGang|r|cff352838]|r "

local rotusItemId = 13468
local rotusItemLink = "\124cff1eff00\124Hitem:13468::::::::60:::::\124h[Black Lotus]\124h\124r"
local rotusItemLinkItemInfo = "[Black Lotus]"
local gatheringSpellid = 2366
local timeSinceLastUpdate = 0;
local currentlyPickingGuid = ""

local zones = {};
zones["Eastern Plaguelands"] = "Eastern Plaguelands"
zones["Winterspring"] = "Winterspring"
zones["Silithus"] = "Silithus"
zones["Burning Steppes"] = "Burning Steppes"

local channel = "GUILD"
--local channel = "RAID"
local debug = false

now = GetTime();
antiSpam = {};

SlashCmdList["TEST"] = function(msg)
  print(msgPrefix .. "Hello World!");
  if(debounce("pickingSound", 60)) then
    PlaySoundFile("Interface\\AddOns\\RotusGang\\kaching.ogg", "Master");
  end

  print(isSerialCurrent(getCurrentSerial()))
--   C_ChatInfo.SendAddonMessage("RG9", "test", "GUILD");
end

SlashCmdList["ROTUS"] = function(cmd)

  if(cmd == "fake") then 
    C_ChatInfo.SendAddonMessage("RG9", "picked,Silithus", channel);
    return
  end

  if (cmd == "lost") then
    C_ChatInfo.SendAddonMessage("RG9", "lost,"..GetZoneText(), channel);
    return
  end

  if (cmd == "ping") then
    C_ChatInfo.SendAddonMessage("RG9", "ping", channel);
    return
  end

  if(cmd == "arrow") then
    if(RotusGang_arrowHidden) then 
      print(msgPrefix .. "Minimap arrow enabled.")
      Minimap:SetPlayerTexture("Interface\\Minimap\\MinimapArrow")
      RotusGang_arrowHidden = false
    else
      print(msgPrefix .. "Minimap arrow disabled.")
      Minimap:SetPlayerTexture("Interface\\AddOns\\RotusGang\\Invisible")
      RotusGang_arrowHidden = true
    end
    return
  end

  local numTimers = 0;

  for zone,shorthand in pairs(zones) do
    local msg = "";
    if(RotusGang_lastPickedHour[zone] ~=  nil and RotusGang_lastPickedMinute[zone] ~= nil) then

      if(isSerialCurrent(RotusGang_lastPickedSerial[zone])) then
        local nextWindowFromHours, nextWindowFromMinutes = addMinutes(RotusGang_lastPickedHour[zone], RotusGang_lastPickedMinute[zone], 45)
        local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)

        msg = RotusGang_lastPickedBy[zone] .. " picked the " .. rotusItemLinkItemInfo .. " in " .. zones[zone] .. " at " .. addLeadingZero(RotusGang_lastPickedHour[zone]) .. ":" .. addLeadingZero(RotusGang_lastPickedMinute[zone]) .. "! Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. "."

        numTimers = numTimers + 1;

        if(cmd == "chat") then
          if UnitInRaid("player") then
            SendChatMessage("[RotusGang] " .. msg, "RAID");
          else
            SendChatMessage("[RotusGang] " .. msg, "PARTY");
          end
        else
          C_ChatInfo.SendAddonMessage("RG9", "broadcast," .. msgPrefix .. msg, channel);
        end  
      else
          RotusGang_lastPickedSerial[zone] = nil;
          RotusGang_lastPickedHour[zone] = nil;
          RotusGang_lastPickedMinute[zone] = nil;
          RotusGang_lastPickedBy[zone] = nil;
      end
    end
  end

  if(numTimers == 0) then
    print("You dont have any timers to share");      
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
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("UNIT_SPELLCAST_SENT")
f:RegisterEvent("UNIT_SPELLCAST_FAILED")
f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

f:SetScript("OnEvent", function(event,...)
  local type = ...

  if(type == "VARIABLES_LOADED") then
    if(RotusGang_lastPickedSerial == nil) then
      RotusGang_lastPickedSerial = {};
    end
    if(RotusGang_lastPickedHour == nil) then
      RotusGang_lastPickedHour = {};
    end
    if(RotusGang_lastPickedMinute == nil) then
      RotusGang_lastPickedMinute = {};
    end
    if(RotusGang_lastPickedBy == nil) then
      RotusGang_lastPickedBy = {};
    end
    if(RotusGang_arrowHidden == nil) then
      RotusGang_arrowHidden = false;
    else
      if(RotusGang_arrowHidden) then 
        Minimap:SetPlayerTexture("Interface\\AddOns\\RotusGang\\Invisible")
      else
        Minimap:SetPlayerTexture("Interface\\Minimap\\MinimapArrow")
      end
    end

    C_ChatInfo.SendAddonMessage("RG9", "syncRequest", channel);
  end

  if(type == "CHAT_MSG_ADDON") then
    local type, prefix, msg, distributionChannel, fromGuid, fromName = ...

    if(prefix == "RG9" and distributionChannel == channel) then
      local hour, min = GetGameTime();

      local msgType, param1, param2, param3, param4, param5 = strsplit(",", msg);

      if(msgType == "test") then
        print(msgPrefix .. fromName .. " is testing broadcasting");
      elseif(msgType == "ping") then
        print(msgPrefix .. "Ping request received from " .. fromName .. ".")
        C_ChatInfo.SendAddonMessage("RG9", "pong,".. VERSION, channel);
      elseif(msgType == "pong") then
        if param1 ~= nil then reportedVersion = param1 else reportedVersion = "?" end
        print(msgPrefix .. fromName .. " replied with a pong (v".. reportedVersion ..")")
      elseif(msgType == "picking") then
        if(debounce("pickingSound", 60)) then
          PlaySoundFile("Interface\\AddOns\\RotusGang\\lotus.ogg", "Master");
        end
        if param1 ~= nil then pickZone = param1 else pickZone = "?" end
        print(msgPrefix ..  fromName .. " is picking a " .. rotusItemLink .. " in " .. pickZone .. "!")
      elseif(msgType == "interrupted") then
        print(msgPrefix .. fromName .. "'s attempt was interrupted!")
      elseif(msgType == "failed") then
        print(msgPrefix .. fromName .. "'s attempt to pick up the " .. rotusItemLink .. " failed!")
      elseif(msgType == "picked") then
        if(debounce("pickedSound", 60)) then
          PlaySoundFile("Interface\\AddOns\\RotusGang\\kaching.ogg", "Master");
        end

        local zone = param1

        local day = date("%d");
        local year = date("%Y");
        local month = date("%m");

        RotusGang_lastPickedSerial[zone] = year..month..day..addLeadingZero(hour)..addLeadingZero(min)
        RotusGang_lastPickedHour[zone] = hour
        RotusGang_lastPickedMinute[zone] = min
        RotusGang_lastPickedBy[zone] = fromName
  
        local nextWindowFromHours, nextWindowFromMinutes = addMinutes(hour, min, 45)
        local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)
  
  
        print(msgPrefix .. RotusGang_lastPickedBy[zone] .. " picked the " .. rotusItemLink .. " in " .. zones[zone] .. " at " .. addLeadingZero(hour) .. ":" .. addLeadingZero(min) .. "! Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. ".")
      elseif(msgType == "lost") then
        zone = param1

        local day = date("%d");
        local year = date("%Y");
        local month = date("%m");
        
        RotusGang_lastPickedSerial[zone] = year..month..day..addLeadingZero(hour)..addLeadingZero(min)
        RotusGang_lastPickedHour[zone] = hour
        RotusGang_lastPickedMinute[zone] = min
        RotusGang_lastPickedBy[zone] = "Someone"
  
        local nextWindowFromHours, nextWindowFromMinutes = addMinutes(hour, min, 45)
        local nextWindowToHours, nextWindowToMinutes = addMinutes(nextWindowFromHours, nextWindowFromMinutes, 30)
  
        print(msgPrefix .. RotusGang_lastPickedBy[zone] .. " picked the " .. rotusItemLink .. " at " .. addLeadingZero(hour) .. ":" .. addLeadingZero(min) .. " :( Next window " .. addLeadingZero(nextWindowFromHours) .. ":" .. addLeadingZero(nextWindowFromMinutes) .. " - " .. addLeadingZero(nextWindowToHours) .. ":" .. addLeadingZero(nextWindowToMinutes) .. ".")      
      elseif(msgType == "broadcast") then
        print(param1)
      elseif(msgType == "syncRequest") then
        if debug then print("received sync request from " .. fromName) end;

        for zone,shorthand in pairs(zones) do
          if(RotusGang_lastPickedSerial[zone] ~= nil) then
            if(isSerialCurrent(RotusGang_lastPickedSerial[zone])) then
              if debug then print("sending sync response for " .. zone) end;
              C_ChatInfo.SendAddonMessage("RG9", "syncResponse," .. zone .. "," .. RotusGang_lastPickedSerial[zone] .. "," .. RotusGang_lastPickedHour[zone] .. "," .. RotusGang_lastPickedMinute[zone] .. "," .. RotusGang_lastPickedBy[zone], channel);
            end
          end
        end
      elseif(msgType == "syncResponse") then
        if(debounce("syncResponse", 1)) then
          if debug then print("received sync response from " .. fromName) end;

          if(RotusGang_lastPickedSerial[param1] == nil) then
            if(isSerialCurrent(param2)) then 
              print(msgPrefix .. "Received new timer for " .. param1)

              RotusGang_lastPickedSerial[param1] = tonumber(param2)
              RotusGang_lastPickedHour[param1] = tonumber(param3)
              RotusGang_lastPickedMinute[param1] = tonumber(param4)
              RotusGang_lastPickedBy[param1] = param5
            end 
          else
            local currentSerial = tonumber(RotusGang_lastPickedSerial[param1]) 
            local incomingSerial = tonumber(param2)

            if(isSerialCurrent(incomingSerial) and incomingSerial > currentSerial) then
              print(msgPrefix .. "Received new timer for " .. param1)

              RotusGang_lastPickedSerial[param1] = tonumber(param2)
              RotusGang_lastPickedHour[param1] = tonumber(param3)
              RotusGang_lastPickedMinute[param1] = tonumber(param4)
              RotusGang_lastPickedBy[param1] = param5
            end
          end
        end
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


f:SetScript("OnUpdate", function(self, elapsed)
  timeSinceLastUpdate = timeSinceLastUpdate + elapsed;

  if (timeSinceLastUpdate > 60.0) then

    if debug then print("Polling for sync"); end;

    C_ChatInfo.SendAddonMessage("RG9", "syncRequest", channel);

    timeSinceLastUpdate = 0;
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

function getCurrentSerial() 
  local currentHour, currentMin = GetGameTime();
  currentHour = addLeadingZero(currentHour);
  currentMin = addLeadingZero(currentMin);
  local currentDay = date("%d");
  local currentYear = date("%Y");
  local currentMonth = date("%m");

  return tonumber(currentYear..currentMonth..currentDay..currentHour..currentMin)
end

function isSerialCurrent(serial, toCompare)
  local threshold = 120 -- 120 minutes for now

  if toCompare == nil then toCompare = getCurrentSerial() end

  local serialYear = tonumber(string.sub(tostring(serial), 1, 4));
  local serialMonth = tonumber(string.sub(tostring(serial), 5, 6));
  local serialDay = tonumber(string.sub(tostring(serial), 7, 8));
  local serialHours = tonumber(string.sub(tostring(serial), 9, 10));
  local serialMinutes = tonumber(string.sub(tostring(serial), 11, 12));

  local serialTime = time({year=serialYear, month=serialMonth, day=serialDay, hour=serialHours, min=serialMinutes, sec=0})

  local toCompareYear = tonumber(string.sub(tostring(toCompare), 1, 4));
  local toCompareMonth = tonumber(string.sub(tostring(toCompare), 5, 6));
  local toCompareDay = tonumber(string.sub(tostring(toCompare), 7, 8));
  local toCompareHours = tonumber(string.sub(tostring(toCompare), 9, 10));
  local toCompareMinutes = tonumber(string.sub(tostring(toCompare), 11, 12));

  local toCompareTime = time({year=toCompareYear, month=toCompareMonth, day=toCompareDay, hour=toCompareHours, min=toCompareMinutes, sec=0})

  local diff = (toCompareTime - serialTime) / 60 

  if(diff > threshold) then
    -- old timer
    return false
  elseif(diff < (threshold * -1)) then
    -- timer is in the future
    return false
  else
    -- timer is in within threshold
    return true
  end

end