# RABuffs

An addon to track raid wide and your personal buffs and personal weapon enchants.

It provides a panel of clickable buttons that light up when a buff is found.

You can click on the panel to buff up, which saves space from your action bars.

A lot of the functionality is also available in macros via the /rab and /rabq commands.

## 1.14.2 / HermesProxy port

This version targets the 1.14.2 Classic client (Interface 11402), as used with HermesProxy to
play on 1.12.1 servers. The original 1.12.1 code is not compatible with that client. Changes:

- `RABuffs_compat.lua` maps the 1.12 API calls RABuffs used to their modern replacements
  (group, power, spellbook, container, addon-message and aura functions).
- Buffs are matched by icon file ID. The modern client no longer returns icon paths.
- Bars are secure action buttons. Addons can no longer cast spells, target units or use items
  directly. Clicking a bar still picks the best target and casts on it.
- In combat, a bar click can't pick a new target (WoW restriction). Bars still update, and
  ctrl+click output still works. Showing, hiding and moving the window waits until combat ends.
- Chat hiding and colouring use chat message filters. The addon no longer replaces `ChatFrame_OnEvent`.
- Fixed bugs: soulstones in the backpack were not found, the health query crashed when everyone
  was dead, and tooltip text crashed in a party because party members have no raid subgroup.

![screenshot](ss.png?raw=true "screenshot")
![screenshot2](ss2.png?raw=true "screenshot2")
