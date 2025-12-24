# BO2 Custom HUD System

Clean, responsive HUD replacement for Black Ops 2 Zombies with enhanced features.

## Features

- **Custom Perk Icons** - Shows all perks in a centered row at the top
- **Round Counter** - Large red round display on bottom left
- **Ammo Display** - Real-time ammo counter with dual wield support
- **Points Tracker** - Live score updates with $ prefix
- **Weapon Names** - Shows current weapon with PaP indicator
- **Grenade Counter** - Tactical and lethal ammo (T: L:)
- **Afterlife System** - Lives counter and timer for Mob of the Dead
- **Generator Alerts** - Attack warnings for Origins map

## Installation

1. Add `bo2_hud_system.gsc` to your mod
2. Call `init()` in your main script
3. Compile and test

## Map Support

- **All Maps** - Basic HUD features
- **Mob of the Dead** - Afterlife counter and timer
- **Origins** - Generator attack alerts
- **Buried/Die Rise/etc** - Map-specific perks included

## Technical Notes

- Uses `setValue` instead of `setText` to prevent string overflow
- Optimized update rates for smooth performance
- Hides original HUD elements automatically
- Supports all BO2 weapons including wonder weapons

## Customization

Edit the positioning values in each HUD element setup to adjust layout. Color values are RGB from 0-1.

Works with most BO2 zombie mods and custom maps.