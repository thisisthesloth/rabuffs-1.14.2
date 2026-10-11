-- RABuffs_compat.lua
--  API bridge for the 1.14.2 client (WoW Classic Era engine, used by HermesProxy).
--  RABuffs was written against the 1.12.1 API; this file maps the old calls it relies on
--  to their modern equivalents so the rest of the addon can stay close to the original.

-- Lua / global helpers that may be missing on newer clients.
if (getglobal == nil) then getglobal = function (n) return _G[n]; end end
if (math.mod == nil) then math.mod = math.fmod; end
if (string.gfind == nil) then string.gfind = string.gmatch; end

-- Group API (1.12: GetNumRaidMembers / GetNumPartyMembers).
function RAB_NumRaidMembers()
 if (GetNumRaidMembers ~= nil) then return GetNumRaidMembers(); end
 return IsInRaid() and GetNumGroupMembers() or 0;
end
function RAB_NumPartyMembers()
 if (GetNumPartyMembers ~= nil) then return GetNumPartyMembers(); end
 if (IsInRaid()) then return 0; end
 return GetNumSubgroupMembers();
end
function RAB_UnitIsLeader(u)
 if (UnitIsGroupLeader ~= nil) then return UnitIsGroupLeader(u); end
 return UnitIsPartyLeader(u);
end

-- Player names arrive as "Name-Realm" on the modern client.
function RAB_StripRealm(name)
 if (name == nil) then return nil; end
 local _, _, short = string.find(name, "^([^%-]+)%-");
 return short or name;
end

function RAB_RealmName()
 return GetRealmName and GetRealmName() or GetCVar("realmName");
end

-- Power (1.12: UnitMana / UnitManaMax).
function RAB_UnitMana(u) return UnitPower(u); end
function RAB_UnitManaMax(u) return UnitPowerMax(u); end

-- Spellbook (1.12: GetSpellName).
function RAB_GetSpellName(i, book)
 if (GetSpellBookItemName ~= nil) then return GetSpellBookItemName(i, book); end
 return GetSpellName(i, book);
end

-- Containers (globals exist on 1.14.2; C_Container replaces them on later clients).
local C = C_Container;
function RAB_GetContainerNumSlots(bag)
 if (GetContainerNumSlots ~= nil) then return GetContainerNumSlots(bag); end
 return C.GetContainerNumSlots(bag);
end
function RAB_GetContainerItemLink(bag, slot)
 if (GetContainerItemLink ~= nil) then return GetContainerItemLink(bag, slot); end
 return C.GetContainerItemLink(bag, slot);
end
function RAB_GetContainerItemCount(bag, slot)
 if (GetContainerItemInfo ~= nil) then
  local _, count = GetContainerItemInfo(bag, slot);
  return count or 0;
 end
 local info = C.GetContainerItemInfo(bag, slot);
 return info and info.stackCount or 0;
end
function RAB_GetContainerItemCooldown(bag, slot)
 if (GetContainerItemCooldown ~= nil) then return GetContainerItemCooldown(bag, slot); end
 return C.GetContainerItemCooldown(bag, slot);
end

-- Addon messages (1.12: SendAddonMessage with no prefix registration).
local RAB_Prefixes = {"RAB/V", "RAB/VC", "RAB/BT", "CTRA"};
for _, p in ipairs(RAB_Prefixes) do
 if (C_ChatInfo ~= nil and C_ChatInfo.RegisterAddonMessagePrefix ~= nil) then
  C_ChatInfo.RegisterAddonMessagePrefix(p);
 elseif (RegisterAddonMessagePrefix ~= nil) then
  RegisterAddonMessagePrefix(p);
 end
end
function RAB_SendAddonMessage(prefix, msg, channel)
 if (channel == "RAID" and not IsInRaid()) then return; end
 if (channel == "PARTY" and not IsInGroup()) then return; end
 if (channel == "GUILD" and not IsInGuild()) then return; end
 if (C_ChatInfo ~= nil and C_ChatInfo.SendAddonMessage ~= nil) then
  C_ChatInfo.SendAddonMessage(prefix, msg, channel);
 else
  SendAddonMessage(prefix, msg, channel);
 end
end

-- Icons. 1.12 returned buff icons as "Interface\Icons\Name" strings and RABuffs stores the
-- short "Name" part. The modern client returns numeric file IDs, so every short name is
-- resolved to a comparable key (file ID, or a normalized lowercase path as a fallback).
local RAB_IconCache = {};
local RAB_IconReverse = nil;
local RAB_IconTex = nil;

function RAB_NormIcon(icon)
 if (type(icon) == "string") then
  icon = strlower(string.gsub(icon, "/", "\\"));
  if (strsub(icon, 1, 16) ~= "interface\\icons\\") then
   icon = "interface\\icons\\" .. icon;
  end
 end
 return icon;
end

function RAB_IconKey(name)
 if (name == nil) then return nil; end
 local key = RAB_IconCache[name];
 if (key == nil) then
  local path = "Interface\\Icons\\" .. name;
  if (GetFileIDFromPath ~= nil) then
   key = GetFileIDFromPath(path);
  end
  if (key == nil) then
   if (RAB_IconTex == nil) then
    RAB_IconTex = UIParent:CreateTexture(nil, "BACKGROUND");
    RAB_IconTex:Hide();
   end
   RAB_IconTex:SetTexture(path);
   key = RAB_IconTex:GetTexture();
  end
  key = (key ~= nil) and RAB_NormIcon(key) or false;
  RAB_IconCache[name] = key;
 end
 return key or nil;
end

-- Short texture name for an icon, if any RAB_Buffs entry knows it.
function RAB_IconShortName(icon)
 if (icon == nil) then return nil; end
 if (RAB_IconReverse == nil) then
  RAB_IconReverse = {};
  for _, val in pairs(RAB_Buffs) do
   if (val.textures ~= nil) then
    for _, tex in pairs(val.textures) do
     local k = RAB_IconKey(tex);
     if (k ~= nil and RAB_IconReverse[k] == nil) then RAB_IconReverse[k] = tex; end
    end
   end
  end
 end
 return RAB_IconReverse[RAB_NormIcon(icon)];
end

-- Auras. Returns name, iconKey, count, debuffType, expirationTime.
function RAB_UnitBuff(unit, i)
 local name, icon, count, dtype, _, expires = UnitBuff(unit, i);
 if (name == nil) then return nil; end
 return name, RAB_NormIcon(icon), count, dtype, expires;
end
function RAB_UnitDebuff(unit, i, filter)
 local name, icon, count, dtype, _, expires = UnitDebuff(unit, i, filter);
 if (name == nil) then return nil; end
 return name, RAB_NormIcon(icon), count, dtype, expires;
end

-- Spell cost (1.12 scanned the spell tooltip).
function RAB_SpellBookCost(i, book)
 if (GetSpellBookItemInfo ~= nil and GetSpellPowerCost ~= nil) then
  local _, spellId = GetSpellBookItemInfo(i, book);
  if (spellId ~= nil) then
   local costs = GetSpellPowerCost(spellId);
   local total = 0;
   if (costs ~= nil) then
    for _, c in pairs(costs) do
     total = total + (c.cost or 0);
    end
   end
   return total;
  end
 end
 return nil;
end

-- Secure casting.
--  Spell casting, targeting and item use are protected on the modern client. The casting
--  handlers in RABuffs_data.lua no longer call those functions directly; instead they record
--  what they want to do here, and the bar (a SecureActionButton) performs it on click.
RAB_PendingAction = nil;

function RAB_Action_Clear()
 RAB_PendingAction = nil;
end
function RAB_Action_Spell(spell, unit)
 RAB_PendingAction = {type="spell", spell=spell, unit=unit};
end
function RAB_Action_SetUnit(unit)
 if (RAB_PendingAction ~= nil) then RAB_PendingAction.unit = unit; end
end
function RAB_Action_Item(item, unit)
 RAB_PendingAction = {type="item", item=item, unit=unit};
end
function RAB_Action_Macro(text)
 RAB_PendingAction = {type="macro", macrotext=text};
end

-- Apply (or clear) the recorded action on a secure button. Must run out of combat.
function RAB_Action_Apply(button)
 if (InCombatLockdown()) then return false; end
 local a = RAB_PendingAction;
 button:SetAttribute("type", a and a.type or nil);
 button:SetAttribute("spell", a and a.spell or nil);
 button:SetAttribute("item", a and a.item or nil);
 button:SetAttribute("macrotext", a and a.macrotext or nil);
 button:SetAttribute("unit", a and a.unit or nil);
 return a ~= nil;
end
