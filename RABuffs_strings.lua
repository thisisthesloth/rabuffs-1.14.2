-- RABuffs_strings.lua
--  Non-code storage for various code/title strings. Do not localize this file.
-- Version 0.10.3

sRAB_DownloadURL = "https://github.com/Lexiebean/Rabuffs/";

sRAB_Settings_UIHeader = "RABuffs";
sRAB_Settings_ReleaseNotes = "<h2 align=\"left\">Release notes</h2><p>- Issue: GoTW is mis-identified as MoTW on non-enUS clients.</p><p>- Issue: Failed casting of resurrection spells bans the target from further attempts for 70 seconds.</p><br/><br/>";

sRAB_LOCALIZATION, sRAB_Localization_UI, sRAB_Localization_Output, sRAB_Localization_SpellLayer = {}, "", "", "|c00ff9922Automatic spellbook|r";

sRAB_ChangeLog2 =     [[<html><body>
			<h1 align="center">RABuffs Version 0.10.3</h1>
			<h2>General</h2>
			<p> - Better cross-faction / TurtleWoW support.</p>
			<p> - Auto-Selfcast support.</p>
			<br/><br/></body></html>]];

sRAB_SpellNames = {};
sRAB_SpellIDs = {};

function sRAB_Localize(strings, spells)
 if (strings) then
  sRAB_LOCALIZATION_vui = "enUS";
  sRAB_LOCALIZATION_out = "enUS";
  sRAB_LOCALIZATION["enUS"](true,true,(GetLocale() == "enUS"));
  if (RABui_Settings.uilocale ~= "enUS" and sRAB_LOCALIZATION[RABui_Settings.uilocale] ~= nil) then
   sRAB_LOCALIZATION[RABui_Settings.uilocale](true, false);
   sRAB_LOCALIZATION_vui = RABui_Settings.uilocale;
  end
  if (RABui_Settings.outlocale ~= "enUS" and sRAB_LOCALIZATION[RABui_Settings.outlocale] ~= nil) then
   sRAB_LOCALIZATION[RABui_Settings.outlocale](false, true);
   sRAB_LOCALIZATION_out = RABui_Settings.outlocale;
  end
  if (RABui_Localize ~= nil) then
   RABui_Localize();
  end
 end
 if (spells) then
  sRAB_PseudoLocalize(true);
  if (sRAB_LOCALIZATION[GetLocale()] ~= nil) then
   sRAB_LOCALIZATION[GetLocale()](false, false, true);
  end
 end
end

function sRAB_PseudoLocalize(forceful)
 if (forceful) then 
  sRAB_SpellLayerLocale = "auto";
 end
 local _, _, i = GetSpellTabInfo(2);
 if (i == 0 or i == nil) then
  return; -- There is only one tab, "General", so no spells for us.
 end
 local sName, sTex, sArr, sManaCost = "", "", {}, {};
 local mana = 0;
 while true do
  i = i + 1;
  sName = RAB_GetSpellName(i,BOOKTYPE_SPELL)
  if (sName == nil) then break; end
  -- Icons are file IDs on the modern client; key by RAB_NormIcon and look up via RAB_IconKey.
  sTex = RAB_NormIcon(GetSpellBookItemTexture ~= nil and GetSpellBookItemTexture(i,BOOKTYPE_SPELL) or GetSpellTexture(i,BOOKTYPE_SPELL));
  mana = RAB_SpellManaCost(i);
  if (sTex ~= nil and ((sArr[sTex] == nil) or (mana > sManaCost[sTex]))) then
   sArr[sTex] = i;
   sManaCost[sTex] = mana;
  end
 end
 local key, val, mc, key2, val2;
 mc = RAB_UnitClass("player");
 for key, val in pairs(RAB_Buffs) do
  if (val.castClass == mc and val.textures ~= nil) then
    local t1, t2 = RAB_IconKey(val.textures[1]), RAB_IconKey(val.textures[2]);
    if (t1 ~= nil and sArr[t1] ~= nil) then
     if (forceful or sRAB_SpellNames[key] == nil) then sRAB_SpellNames[key] = RAB_GetSpellName(sArr[t1],BOOKTYPE_SPELL);  end
     sRAB_SpellIDs[key] = sArr[t1];
    end
    if (t2 ~= nil and sArr[t2] ~= nil and val.bigcast ~= nil) then
     if (forceful or sRAB_SpellNames[val.bigcast] == nil) then sRAB_SpellNames[val.bigcast] = RAB_GetSpellName(sArr[t2], BOOKTYPE_SPELL); end
     sRAB_SpellIDs[val.bigcast] = sArr[t2];
    end
  end
 end
end
function sRAB_FindSpellId(SpellName)
 local _, _, i = GetSpellTabInfo(2);
 if (i == 0 or i == nil) then
  return 0; -- There is only one tab, "General", so no spells for us.
 end
 local sName, iManaCost, sId = "", 0, 0;
 while true do
  i = i + 1;
  sName = RAB_GetSpellName(i, BOOKTYPE_SPELL);
  if (sName == nil) then
   break;
  elseif (sName == SpellName) then
   sId = i;
  elseif (sId ~= 0) then
   return sId;
  end
 end
 return sId;
end
function RAB_SpellManaCost(spell,book)
 book = book ~= nil and book or BOOKTYPE_SPELL;
 local cost = RAB_SpellBookCost(spell, book);
 if (cost ~= nil) then
  return cost;
 end
 RAB_Spelltip:SetOwner(RABFrame, "ANCHOR_LEFT");
 RAB_Spelltip:ClearLines();
 RAB_Spelltip:SetSpellBookItem(spell,book);
 local t = RAB_SpelltipTextLeft2:GetText();
 local _,_, mana = string.find(t ~= nil and t or "","(%d+) ");
 RAB_Spelltip:Hide();
 return (mana ~= nil and tonumber(mana) or 0);
end
