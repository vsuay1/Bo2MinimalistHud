//==============================================================================
// BO2 HUD System - Custom HUD Elements
// Features: Perk icons, round counter, points/ammo, afterlife, generator alerts
//==============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    level endon("game_ended");
    for(;;)
    {
        level waittill("connected", player);
        player thread setupHUDSystem();
    }
}

setupHUDSystem()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // HUD Monitors
    self thread perk_hud_monitor();
    self thread round_counter_monitor();
    self thread points_ammo_monitor();
    self thread afterlife_monitor();
    self thread original_hud_hider();
    
    // Origins Generator HUD
    if(getDvar("mapname") == "zm_tomb")
    {
        self thread setupOriginGeneratorHUD();
    }
}

//==============================================================================
// PERK HUD SYSTEM
//==============================================================================

perk_hud_monitor()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // Store HUD elements
    self.perk_huds = [];
    max_perks = 9; // Support up to 9 perks
    
    for(i = 0; i < max_perks; i++)
    {
        hud = newClientHudElem(self);
        hud.alignX = "center";
        hud.alignY = "top";
        hud.horzAlign = "center";
        hud.vertAlign = "top";
        hud.x = 0; // Will be set dynamically
        hud.y = -5; // Top edge offset
        hud.foreground = 1;
        hud.alpha = 0;
        hud.hidewheninmenu = 1;
        hud setShader("white", 24, 24); // Smaller size
        
        self.perk_huds[i] = hud;
    }
    
    spacing = 30; // Spacing between icon centers
    
    for(;;)
    {
        wait 1; // Moderate check for perk changes
        
        // Get current perks
        all_perks = getAllAvailablePerks();
        current_perks = [];
        
        for(i = 0; i < all_perks.size; i++)
        {
            if(self hasperk(all_perks[i]))
            {
                current_perks[current_perks.size] = all_perks[i];
            }
        }
        
        // Update HUD with centering logic
        num_perks = current_perks.size;
        if(num_perks > 0)
        {
            // Calculate starting X to keep the row centered
            // A single perk (size 1) will be at x = 0.
            // Two perks will be at -15 and +15, etc.
            total_width = (num_perks - 1) * spacing;
            start_x = - (total_width / 2);
            
            for(i = 0; i < self.perk_huds.size; i++)
            {
                if(i < num_perks)
                {
                    perk = current_perks[i];
                    self.perk_huds[i].x = start_x + (i * spacing);
                    self.perk_huds[i] setShader(getPerkShader(perk), 24, 24);
                    self.perk_huds[i].alpha = 1;
                }
                else
                {
                    self.perk_huds[i].alpha = 0;
                }
            }
        }
        else
        {
            // No perks, hide all
            for(i = 0; i < self.perk_huds.size; i++)
            {
                self.perk_huds[i].alpha = 0;
            }
        }
    }
}

round_counter_monitor()
{
    self endon("disconnect");
    level endon("game_ended");
    
    self.custom_round_hud = newClientHudElem(self);
    self.custom_round_hud.alignX = "center";
    self.custom_round_hud.alignY = "bottom";
    self.custom_round_hud.horzAlign = "center";
    self.custom_round_hud.vertAlign = "bottom";
    self.custom_round_hud.x = -120; // Back to left side
    self.custom_round_hud.y = -20; // Original height
    self.custom_round_hud.foreground = 1;
    self.custom_round_hud.fontScale = 3.5; // Extra large for TikTok
    self.custom_round_hud.color = (1, 0, 0); // Vibrant Red
    self.custom_round_hud.hidewheninmenu = 1;
    self.custom_round_hud.alpha = 1;

    // Round Label - set once to avoid string overflow
    self.custom_round_label = newClientHudElem(self);
    self.custom_round_label.alignX = "center";
    self.custom_round_label.alignY = "bottom";
    self.custom_round_label.horzAlign = "center";
    self.custom_round_label.vertAlign = "bottom";
    self.custom_round_label.x = -120;
    self.custom_round_label.y = -55; // Original height above number
    self.custom_round_label.fontScale = 1.0;
    self.custom_round_label.color = (1, 1, 1);
    self.custom_round_label.hidewheninmenu = 1;
    self.custom_round_label.alpha = 1;
    self.custom_round_label setText("ROUND"); // Set once only

    for(;;)
    {
        round_num = 1;
        if(isDefined(level.round_number))
        {
            round_num = level.round_number;
        }
        
        self.custom_round_hud setValue(round_num);
        wait 0.5; // Moderate update for round changes
    }
}

points_ammo_monitor()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // Points HUD
    self.custom_points_hud = newClientHudElem(self);
    self.custom_points_hud.alignX = "center";
    self.custom_points_hud.alignY = "bottom";
    self.custom_points_hud.horzAlign = "center";
    self.custom_points_hud.vertAlign = "bottom";
    self.custom_points_hud.x = 120; // Aligned with ammo (shifted from 0)
    self.custom_points_hud.y = -65; // Now at the top of the stack
    self.custom_points_hud.foreground = 1;
    self.custom_points_hud.fontScale = 1.3; // Smaller
    self.custom_points_hud.color = (0.82, 0.70, 0.55); // Tan
    self.custom_points_hud.hidewheninmenu = 1;
    self.custom_points_hud.alpha = 1;

    // Points Prefix ($) - set once to avoid string overflow
    self.custom_points_prefix = newClientHudElem(self);
    self.custom_points_prefix.alignX = "right"; // Right align to anchor to the number
    self.custom_points_prefix.alignY = "bottom";
    self.custom_points_prefix.horzAlign = "center";
    self.custom_points_prefix.vertAlign = "bottom";
    self.custom_points_prefix.x = 105; // Offset to the left of points value (shifted right)
    self.custom_points_prefix.y = -65;
    self.custom_points_prefix.foreground = 1;
    self.custom_points_prefix.fontScale = 1.3;
    self.custom_points_prefix.color = (0, 1, 0); // Keeping $ prefix green
    self.custom_points_prefix.hidewheninmenu = 1;
    self.custom_points_prefix.alpha = 1;
    self.custom_points_prefix setText("$"); // Set once only

    // Ammo HUD - Split into separate elements for dual wield support
    // Left clip (for dual wield)
    self.custom_ammo_clip_l = newClientHudElem(self);
    self.custom_ammo_clip_l.alignX = "right";
    self.custom_ammo_clip_l.alignY = "bottom";
    self.custom_ammo_clip_l.horzAlign = "center";
    self.custom_ammo_clip_l.vertAlign = "bottom";
    self.custom_ammo_clip_l.x = 85; // Left clip position
    self.custom_ammo_clip_l.y = -20;
    self.custom_ammo_clip_l.foreground = 1;
    self.custom_ammo_clip_l.fontScale = 2.5;
    self.custom_ammo_clip_l.color = (1, 1, 1);
    self.custom_ammo_clip_l.hidewheninmenu = 1;
    self.custom_ammo_clip_l.alpha = 0; // Hidden by default

    // First separator (between left and right clip)
    self.custom_ammo_sep1 = newClientHudElem(self);
    self.custom_ammo_sep1.alignX = "center";
    self.custom_ammo_sep1.alignY = "bottom";
    self.custom_ammo_sep1.horzAlign = "center";
    self.custom_ammo_sep1.vertAlign = "bottom";
    self.custom_ammo_sep1.x = 95; // Between clips
    self.custom_ammo_sep1.y = -20;
    self.custom_ammo_sep1.foreground = 1;
    self.custom_ammo_sep1.fontScale = 2.5;
    self.custom_ammo_sep1.color = (1, 1, 1);
    self.custom_ammo_sep1.hidewheninmenu = 1;
    self.custom_ammo_sep1.alpha = 0; // Hidden by default
    self.custom_ammo_sep1 setText("|"); // Set once only

    // Right clip (main clip)
    self.custom_ammo_clip_r = newClientHudElem(self);
    self.custom_ammo_clip_r.alignX = "right";
    self.custom_ammo_clip_r.alignY = "bottom";
    self.custom_ammo_clip_r.horzAlign = "center";
    self.custom_ammo_clip_r.vertAlign = "bottom";
    self.custom_ammo_clip_r.x = 110; // Right clip position
    self.custom_ammo_clip_r.y = -20;
    self.custom_ammo_clip_r.foreground = 1;
    self.custom_ammo_clip_r.fontScale = 2.5;
    self.custom_ammo_clip_r.color = (1, 1, 1);
    self.custom_ammo_clip_r.hidewheninmenu = 1;
    self.custom_ammo_clip_r.alpha = 1;

    // Second separator (between clip and stock)
    self.custom_ammo_sep2 = newClientHudElem(self);
    self.custom_ammo_sep2.alignX = "center";
    self.custom_ammo_sep2.alignY = "bottom";
    self.custom_ammo_sep2.horzAlign = "center";
    self.custom_ammo_sep2.vertAlign = "bottom";
    self.custom_ammo_sep2.x = 120; // Between clip and stock
    self.custom_ammo_sep2.y = -20;
    self.custom_ammo_sep2.foreground = 1;
    self.custom_ammo_sep2.fontScale = 2.5;
    self.custom_ammo_sep2.color = (1, 1, 1);
    self.custom_ammo_sep2.hidewheninmenu = 1;
    self.custom_ammo_sep2.alpha = 1;
    self.custom_ammo_sep2 setText("|"); // Set once only

    // Ammo stock
    self.custom_ammo_stock = newClientHudElem(self);
    self.custom_ammo_stock.alignX = "left";
    self.custom_ammo_stock.alignY = "bottom";
    self.custom_ammo_stock.horzAlign = "center";
    self.custom_ammo_stock.vertAlign = "bottom";
    self.custom_ammo_stock.x = 130; // Stock position
    self.custom_ammo_stock.y = -20;
    self.custom_ammo_stock.foreground = 1;
    self.custom_ammo_stock.fontScale = 2.5;
    self.custom_ammo_stock.color = (1, 1, 1);
    self.custom_ammo_stock.hidewheninmenu = 1;
    self.custom_ammo_stock.alpha = 1;

    // Weapon Name HUD
    self.custom_weapon_hud = newClientHudElem(self);
    self.custom_weapon_hud.alignX = "center";
    self.custom_weapon_hud.alignY = "bottom";
    self.custom_weapon_hud.horzAlign = "center";
    self.custom_weapon_hud.vertAlign = "bottom";
    self.custom_weapon_hud.x = 120; // Above ammo / below points
    self.custom_weapon_hud.y = -45; // Swapped with points
    self.custom_weapon_hud.foreground = 1;
    self.custom_weapon_hud.fontScale = 1.2; // Small text
    self.custom_weapon_hud.color = (1, 1, 1);
    self.custom_weapon_hud.hidewheninmenu = 1;
    self.custom_weapon_hud.alpha = 1;

    // Offhand HUD - Split into separate elements
    self.custom_offhand_t_label = newClientHudElem(self);
    self.custom_offhand_t_label.alignX = "right";
    self.custom_offhand_t_label.alignY = "bottom";
    self.custom_offhand_t_label.horzAlign = "center";
    self.custom_offhand_t_label.vertAlign = "bottom";
    self.custom_offhand_t_label.x = 90;
    self.custom_offhand_t_label.y = -5;
    self.custom_offhand_t_label.foreground = 1;
    self.custom_offhand_t_label.fontScale = 1.0;
    self.custom_offhand_t_label.color = (0.8, 0.8, 0.8);
    self.custom_offhand_t_label.hidewheninmenu = 1;
    self.custom_offhand_t_label.alpha = 1;
    self.custom_offhand_t_label setText("T:"); // Set once only

    self.custom_offhand_t_value = newClientHudElem(self);
    self.custom_offhand_t_value.alignX = "left";
    self.custom_offhand_t_value.alignY = "bottom";
    self.custom_offhand_t_value.horzAlign = "center";
    self.custom_offhand_t_value.vertAlign = "bottom";
    self.custom_offhand_t_value.x = 95;
    self.custom_offhand_t_value.y = -5;
    self.custom_offhand_t_value.foreground = 1;
    self.custom_offhand_t_value.fontScale = 1.0;
    self.custom_offhand_t_value.color = (0.8, 0.8, 0.8);
    self.custom_offhand_t_value.hidewheninmenu = 1;
    self.custom_offhand_t_value.alpha = 1;

    self.custom_offhand_l_label = newClientHudElem(self);
    self.custom_offhand_l_label.alignX = "right";
    self.custom_offhand_l_label.alignY = "bottom";
    self.custom_offhand_l_label.horzAlign = "center";
    self.custom_offhand_l_label.vertAlign = "bottom";
    self.custom_offhand_l_label.x = 130;
    self.custom_offhand_l_label.y = -5;
    self.custom_offhand_l_label.foreground = 1;
    self.custom_offhand_l_label.fontScale = 1.0;
    self.custom_offhand_l_label.color = (0.8, 0.8, 0.8);
    self.custom_offhand_l_label.hidewheninmenu = 1;
    self.custom_offhand_l_label.alpha = 1;
    self.custom_offhand_l_label setText("L:"); // Set once only

    self.custom_offhand_l_value = newClientHudElem(self);
    self.custom_offhand_l_value.alignX = "left";
    self.custom_offhand_l_value.alignY = "bottom";
    self.custom_offhand_l_value.horzAlign = "center";
    self.custom_offhand_l_value.vertAlign = "bottom";
    self.custom_offhand_l_value.x = 135;
    self.custom_offhand_l_value.y = -5;
    self.custom_offhand_l_value.foreground = 1;
    self.custom_offhand_l_value.fontScale = 1.0;
    self.custom_offhand_l_value.color = (0.8, 0.8, 0.8);
    self.custom_offhand_l_value.hidewheninmenu = 1;
    self.custom_offhand_l_value.alpha = 1;

    // Cache for weapon names to avoid string overflow
    self.cached_weapon = "";
    self.cached_weapon_name = "";

    for(;;)
    {
        // Update Points
        if(isDefined(self.score))
        {
            self.custom_points_hud setValue(self.score);
        }
        
        // Update Ammo & Weapon Name
        weapon = self getCurrentWeapon();
        if(isDefined(weapon) && weapon != "none")
        {
            stock = self getWeaponAmmoStock(weapon);
            clip_r = self getWeaponAmmoClip(weapon);
            clip_l = -1; // -1 means no dual-wield ammo found
            
            // Improved Detection: Only flag as dual-wield if specifically named or engine confirms it
            is_dw = isSubStr(weapon, "dw_") || isSubStr(weapon, "_dw") || weapon == "m1911_upgraded_zm" || weapon == "c96_upgraded_zm";
            
            if(is_dw)
            {
                // Try engine function for dual-wield name
                lh_weapon = weapondualwieldweaponname(weapon);
                
                // Fallback to manual mapping for known variants
                if(!isDefined(lh_weapon) || lh_weapon == "none" || lh_weapon == weapon)
                {
                    lh_weapon = "none";
                    if(weapon == "m1911_upgraded_zm") lh_weapon = "m1911_upgraded_lh_zm";
                    else if(weapon == "c96_upgraded_zm") lh_weapon = "c96_upgraded_lh_zm";
                    else if(weapon == "fivesevendw_zm") lh_weapon = "fivesevendw_lh_zm";
                    else if(weapon == "fivesevendw_upgraded_zm") lh_weapon = "fivesevendw_upgraded_lh_zm";
                }
                
                // Final Check: Must be a VALID, DIFFERENT weapon with a clip
                if(isDefined(lh_weapon) && lh_weapon != "none" && lh_weapon != weapon && weaponClipSize(lh_weapon) > 0)
                {
                    clip_l = self getWeaponAmmoClip(lh_weapon);
                }
            }

            // Low Ammo Color Logic
            max_clip = weaponClipSize(weapon);
            is_low = false;
            if(max_clip > 0)
            {
                // Turn red if clip is 1/3 or less (e.g. 10 for a 30 clip)
                if(clip_r <= (max_clip / 3) || clip_r <= 5) is_low = true;
            }
            
            if(is_dw && clip_l >= 0)
            {
                max_clip_l = weaponClipSize(lh_weapon);
                if(max_clip_l > 0 && (clip_l <= (max_clip_l / 3) || clip_l <= 5)) is_low = true;
            }

            // Set colors for all ammo elements
            ammo_color = (1, 1, 1); // White
            if(is_low) ammo_color = (1, 0, 0); // Red
            
            self.custom_ammo_clip_l.color = ammo_color;
            self.custom_ammo_clip_r.color = ammo_color;
            self.custom_ammo_sep1.color = ammo_color;
            self.custom_ammo_sep2.color = ammo_color;
            self.custom_ammo_stock.color = ammo_color;

            // Display ammo based on dual wield status
            if(clip_l >= 0)
            {
                // Dual wield: L | R | Stock
                self.custom_ammo_clip_l setValue(clip_l);
                self.custom_ammo_clip_l.alpha = 1;
                self.custom_ammo_sep1.alpha = 1;
                self.custom_ammo_clip_r setValue(clip_r);
            }
            else
            {
                // Single weapon: R | Stock (hide left clip)
                self.custom_ammo_clip_l.alpha = 0;
                self.custom_ammo_sep1.alpha = 0;
                self.custom_ammo_clip_r setValue(clip_r);
            }
            self.custom_ammo_stock setValue(stock);
            
            // Cache weapon name to avoid repeated setText calls
            if(weapon != self.cached_weapon)
            {
                self.cached_weapon = weapon;
                self.cached_weapon_name = getWeaponDisplayName(weapon);
                self.custom_weapon_hud setText(self.cached_weapon_name);
            }
        }
        else
        {
            self.custom_ammo_clip_l.alpha = 0;
            self.custom_ammo_sep1.alpha = 0;
            self.custom_ammo_clip_r setValue(0);
            self.custom_ammo_stock setValue(0);
            if(self.cached_weapon != "")
            {
                self.cached_weapon = "";
                self.cached_weapon_name = "";
                self.custom_weapon_hud setText("");
            }
        }
        
        // Update Offhand Ammo using setValue
        weapons = self getWeaponsList();
        l_ammo = 0;
        t_ammo = 0;
        for(i = 0; i < weapons.size; i++)
        {
            w = weapons[i];
            // Common Lethals
            if(isSubStr(w, "frag") || isSubStr(w, "sticky") || isSubStr(w, "claymore") || isSubStr(w, "tomahawk"))
            {
                l_ammo += self getWeaponAmmoClip(w);
            }
            // Common Tacticals
            else if(isSubStr(w, "cymbal") || isSubStr(w, "emp") || isSubStr(w, "black_hole") || isSubStr(w, "scavenger_grenade"))
            {
                t_ammo += self getWeaponAmmoClip(w);
            }
        }
        self.custom_offhand_t_value setValue(t_ammo);
        self.custom_offhand_l_value setValue(l_ammo);

        wait 0.1; // Fast update for responsive ammo reading
    }
}

original_hud_hider()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // Initial brute force - run 100 times
    for(i = 0; i < 100; i++)
    {
        self setclientuivisibilityflag("hud_visible", false);
        wait 0.1;
    }
    
    // Continue hiding at slower rate to prevent overflow
    for(;;)
    {
        self setclientuivisibilityflag("hud_visible", false);
        
        // Hide Original Perk Icons
        if(isDefined(self.perk_hud))
        {
            keys = getArrayKeys(self.perk_hud);
            for(j = 0; j < keys.size; j++)
            {
                perk_icon = self.perk_hud[keys[j]];
                if(isDefined(perk_icon))
                {
                    perk_icon.alpha = 0;
                }
            }
        }
        
        // Hide Original Score HUD
        if(isDefined(self.score_hud))
        {
            self.score_hud.alpha = 0;
        }
        
        wait 1.0; // Moderate rate since we're not using setText frequently
    }
}

afterlife_monitor()
{
    self endon("disconnect");
    level endon("game_ended");

    // Only run on Mob of the Dead
    if(level.script != "zm_prison")
        return;

    // Afterlife Label - set once to avoid string overflow
    self.afterlife_label = newClientHudElem(self);
    self.afterlife_label.alignX = "center";
    self.afterlife_label.alignY = "bottom";
    self.afterlife_label.horzAlign = "center";
    self.afterlife_label.vertAlign = "bottom";
    self.afterlife_label.x = -120;
    self.afterlife_label.y = -85; // Above the "ROUND" label
    self.afterlife_label.fontScale = 1.0;
    self.afterlife_label.color = (0.3, 0.7, 1); // Ghostly Blue
    self.afterlife_label.hidewheninmenu = 1;
    self.afterlife_label.alpha = 1;
    self.afterlife_label setText("AFTERLIFE"); // Set once only

    // Afterlife Number
    self.afterlife_hud = newClientHudElem(self);
    self.afterlife_hud.alignX = "center";
    self.afterlife_hud.alignY = "bottom";
    self.afterlife_hud.horzAlign = "center";
    self.afterlife_hud.vertAlign = "bottom";
    self.afterlife_hud.x = -120;
    self.afterlife_hud.y = -65; // Below the "AFTERLIFE" label
    self.afterlife_hud.fontScale = 2.0;
    self.afterlife_hud.color = (1, 1, 1);
    self.afterlife_hud.hidewheninmenu = 1;
    self.afterlife_hud.alpha = 1;

    // Afterlife Timer HUD
    self.afterlife_timer_hud = newClientHudElem(self);
    self.afterlife_timer_hud.alignX = "center";
    self.afterlife_timer_hud.alignY = "bottom";
    self.afterlife_timer_hud.horzAlign = "center";
    self.afterlife_timer_hud.vertAlign = "bottom";
    self.afterlife_timer_hud.x = -120;
    self.afterlife_timer_hud.y = -105; // Above the "AFTERLIFE" label
    self.afterlife_timer_hud.fontScale = 1.5;
    self.afterlife_timer_hud.color = (0, 0.8, 1); // Bright Ghostly Blue
    self.afterlife_timer_hud.hidewheninmenu = 1;
    self.afterlife_timer_hud.alpha = 0; // Hidden by default

    manual_timer = 52;
    wasInAfterlife = false;

    for(;;)
    {
        // 1. Update Afterlife Count
        num_lives = 0;
        if(isDefined(self.lives))
        {
            num_lives = self.lives;
        }
        
        self.afterlife_hud setValue(num_lives);
        
        // Dynamic color for count
        if(num_lives == 0)
            self.afterlife_hud.color = (1, 0, 0);
        else
            self.afterlife_hud.color = (1, 1, 1);

        // 2. Update Afterlife Timer
        // Check if player is in Afterlife (ghost mode)
        isInAfterlife = isDefined(self.afterlife) && self.afterlife;
        
        if(isInAfterlife)
        {
            // Reset timer on entry
            if(!wasInAfterlife)
            {
                manual_timer = 52;
                wasInAfterlife = true;
            }

            self.afterlife_timer_hud.alpha = 1;
            
            // Manual countdown as fallback
            manual_timer -= 1.0; // Decrement by 1 second to match wait time
            if(manual_timer < 0) manual_timer = 0;
            
            self.afterlife_timer_hud setValue(int(manual_timer));
            
            // Optional: Blink if low
            if(manual_timer <= 10)
            {
                if(int(manual_timer * 10) % 10 < 5) self.afterlife_timer_hud.color = (1, 0, 0);
                else self.afterlife_timer_hud.color = (0, 0.8, 1);
            }
            else
            {
                self.afterlife_timer_hud.color = (0, 0.8, 1);
            }
        }
        else
        {
            self.afterlife_timer_hud.alpha = 0;
            wasInAfterlife = false;
        }

        wait 1.0; // Moderate update for afterlife changes
    }
}

//==============================================================================
// ORIGINS GENERATOR HUD SYSTEM
//==============================================================================

setupOriginGeneratorHUD()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // Wait for capture zones to be initialized
    flag_wait("capture_zones_init_done");
    
    // Generator Label - set once to avoid string overflow
    self.generator_label = newClientHudElem(self);
    self.generator_label.alignX = "center";
    self.generator_label.alignY = "bottom";
    self.generator_label.horzAlign = "center";
    self.generator_label.vertAlign = "bottom";
    self.generator_label.x = -120;
    self.generator_label.y = -125; // Above the afterlife label
    self.generator_label.fontScale = 1.0;
    self.generator_label.color = (1, 0, 0); // Red
    self.generator_label.hidewheninmenu = 1;
    self.generator_label.alpha = 0; // Hidden by default
    self.generator_label setText("GENERATOR ATTACK"); // Set once only
    
    // Generator Number (same style as afterlife number)
    self.generator_alert_hud = newClientHudElem(self);
    self.generator_alert_hud.alignX = "center";
    self.generator_alert_hud.alignY = "bottom";
    self.generator_alert_hud.horzAlign = "center";
    self.generator_alert_hud.vertAlign = "bottom";
    self.generator_alert_hud.x = -120;
    self.generator_alert_hud.y = -105; // Below the label, above afterlife
    self.generator_alert_hud.fontScale = 2.0;
    self.generator_alert_hud.color = (1, 1, 1); // White
    self.generator_alert_hud.hidewheninmenu = 1;
    self.generator_alert_hud.alpha = 0; // Hidden by default
    
    // Monitor for generator attacks using existing system
    self thread monitorOriginGeneratorAttacks();
}

monitorOriginGeneratorAttacks()
{
    self endon("disconnect");
    level endon("game_ended");
    
    for(;;)
    {
        // Wait for the generator_under_attack flag (from real Origins code)
        flag_wait("generator_under_attack");
        
        // Find which generator is being attacked
        attacked_generator = getOriginAttackedGenerator();
        
        if(isDefined(attacked_generator))
        {
            generator_number = attacked_generator.script_int;
            
            // Show both label and number (like afterlife system)
            self.generator_label.alpha = 1;
            self.generator_alert_hud setValue(generator_number);
            self.generator_alert_hud.alpha = 1;
            
            // Flash effect
            self thread flashOriginGeneratorAlert();
        }
        
        // Wait for attack to end
        flag_waitopen("generator_under_attack");
        
        // Hide alert
        self.generator_label fadeOverTime(1);
        self.generator_label.alpha = 0;
        self.generator_alert_hud fadeOverTime(1);
        self.generator_alert_hud.alpha = 0;
        
        wait 1;
    }
}

getOriginAttackedGenerator()
{
    // Check all generators to see which one is being attacked
    if(!isDefined(level.zone_capture) || !isDefined(level.zone_capture.zones))
        return undefined;
        
    foreach(generator in level.zone_capture.zones)
    {
        if(isDefined(generator) && generator ent_flag("attacked_by_recapture_zombies"))
        {
            return generator;
        }
    }
    
    // Fallback: check for current recapture target
    if(isDefined(level.zone_capture.recapture_target))
    {
        return level.zone_capture.zones[level.zone_capture.recapture_target];
    }
    
    return undefined;
}

flashOriginGeneratorAlert()
{
    self endon("disconnect");
    level endon("game_ended");
    
    // Flash red and white for both label and number (like afterlife system)
    for(i = 0; i < 6; i++)
    {
        if(flag("generator_under_attack"))
        {
            // Flash the label red/white
            self.generator_label.color = (1, 1, 1); // White
            self.generator_alert_hud.color = (1, 0, 0); // Red number
            wait 0.25;
            self.generator_label.color = (1, 0, 0); // Red
            self.generator_alert_hud.color = (1, 1, 1); // White number
            wait 0.25;
        }
        else
        {
            break;
        }
    }
}

//==============================================================================
// HELPER FUNCTIONS
//==============================================================================

getAllAvailablePerks()
{
    // BO2 perk list including DLC perks
    all_perks = [];
    all_perks[all_perks.size] = "specialty_armorvest";                    // Juggernog
    all_perks[all_perks.size] = "specialty_fastreload";                   // Speed Cola
    all_perks[all_perks.size] = "specialty_rof";                          // Double Tap Root Beer 2.0
    
    // Quick Revive: Disabled on Mob of the Dead (zm_prison)
    if(level.script != "zm_prison")
    {
        all_perks[all_perks.size] = "specialty_quickrevive";              // Quick Revive
    }

    all_perks[all_perks.size] = "specialty_longersprint";                 // Stamin-Up
    all_perks[all_perks.size] = "specialty_flakjacket";                   // PhD Flopper
    all_perks[all_perks.size] = "specialty_deadshot";                     // Deadshot Daiquiri
    
    // Electric Cherry: ONLY on Origins (zm_tomb) or Mob of the Dead (zm_prison)
    if(level.script == "zm_tomb" || level.script == "zm_prison")
    {
        all_perks[all_perks.size] = "specialty_grenadepulldeath";         // Electric Cherry
    }
    
    // Vulture Aid: Only on Buried (zm_buried)
    if(level.script == "zm_buried")
    {
        all_perks[all_perks.size] = "specialty_nomotionsensor";           // Vulture Aid
    }
    
    // Who's Who: Only on Die Rise (zm_highrise)
    if(level.script == "zm_highrise")
    {
        all_perks[all_perks.size] = "specialty_finalstand";               // Who's Who
    }
    
    return all_perks;
}

getPerkShader(perk)
{
    switch(perk)
    {
        case "specialty_armorvest":
            return "specialty_juggernaut_zombies";
        case "specialty_fastreload":
            return "specialty_fastreload_zombies";
        case "specialty_rof":
            return "specialty_doubletap_zombies";
        case "specialty_quickrevive":
            return "specialty_quickrevive_zombies";
        case "specialty_longersprint":
            return "specialty_marathon_zombies";
        case "specialty_flakjacket":
            // PhD has different names depending on map, usually this works
            return "specialty_divetonuke_zombies"; 
        case "specialty_deadshot":
            return "specialty_ads_zombies";
        case "specialty_scavenger":
            return "specialty_tombstone_zombies";
        case "specialty_grenadepulldeath":
            return "specialty_electric_cherry_zombie";
        case "specialty_nomotionsensor":
            return "specialty_vulture_zombies";
        case "specialty_finalstand":
            return "specialty_chugabud_zombies";
        default:
            return "temp_texture"; // Fallback
    }
}

getWeaponDisplayName(weapon)
{
    name = weapon; // Fallback
    
    // Check for upgraded version first to append (PaP)
    is_upgraded = isSubStr(weapon, "upgraded");
    
    // Check for each weapon based on its ID contained in the string
    // Snipers
    if(isSubStr(weapon, "dsr50")) name = "DSR 50";
    else if(isSubStr(weapon, "barretm82")) name = "Barrett M82A1";
    else if(isSubStr(weapon, "svu")) name = "SVU-AS";
    else if(isSubStr(weapon, "ballista")) name = "Ballista";
    
    // SMGs
    else if(isSubStr(weapon, "ak74u")) name = "AK74u";
    else if(isSubStr(weapon, "mp5k")) name = "MP5";
    else if(isSubStr(weapon, "pdw57")) name = "PDW-57";
    else if(isSubStr(weapon, "qcw05")) name = "Chicom";
    else if(isSubStr(weapon, "uzi")) name = "Uzi";
    else if(isSubStr(weapon, "thompson")) name = "M1927";
    else if(isSubStr(weapon, "mp40")) name = "MP40";
    else if(isSubStr(weapon, "evoskorpion")) name = "Skorpion EVO";
    
    // ARs
    else if(isSubStr(weapon, "fnfal")) name = "FAL";
    else if(isSubStr(weapon, "m14")) name = "M14";
    else if(isSubStr(weapon, "saritch")) name = "SMR";
    else if(isSubStr(weapon, "m16")) name = "M16";
    else if(isSubStr(weapon, "tar21")) name = "MTAR";
    else if(isSubStr(weapon, "galil")) name = "Galil";
    else if(isSubStr(weapon, "an94")) name = "AN-94";
    else if(isSubStr(weapon, "type95")) name = "Type 25";
    else if(isSubStr(weapon, "xm8")) name = "M8A1";
    else if(isSubStr(weapon, "ak47")) name = "AK-47";
    else if(isSubStr(weapon, "hk416")) name = "M27";
    else if(isSubStr(weapon, "scar")) name = "SCAR-H";
    else if(isSubStr(weapon, "mp44")) name = "STG-44";
    
    // Shotguns
    else if(isSubStr(weapon, "870mcs")) name = "Remington 870";
    else if(isSubStr(weapon, "rottweil72")) name = "Olympia";
    else if(isSubStr(weapon, "saiga12")) name = "S12";
    else if(isSubStr(weapon, "srm1216")) name = "M1216";
    else if(isSubStr(weapon, "ksg")) name = "KSG";
    
    // LMGs
    else if(isSubStr(weapon, "lsat")) name = "LSAT";
    else if(isSubStr(weapon, "hamr")) name = "HAMR";
    else if(isSubStr(weapon, "rpd")) name = "RPD";
    else if(isSubStr(weapon, "mg08")) name = "MG-08";
    else if(isSubStr(weapon, "minigun_alcatraz")) name = "Death Machine";
    
    // Pistols
    else if(isSubStr(weapon, "m1911")) name = "M1911";
    else if(isSubStr(weapon, "rnma")) name = "Remington Army";
    else if(isSubStr(weapon, "judge")) name = "Executioner";
    else if(isSubStr(weapon, "kard")) name = "KAP-40";
    else if(isSubStr(weapon, "fiveseven")) name = "Five-Seven";
    else if(isSubStr(weapon, "fivesevendw")) name = "Five-Seven Dual";
    else if(isSubStr(weapon, "beretta93r")) name = "B23R";
    else if(isSubStr(weapon, "python")) name = "Python";
    else if(isSubStr(weapon, "c96")) name = "Mauser C96";
    
    // Launchers
    else if(isSubStr(weapon, "usrpg")) name = "RPG";
    else if(isSubStr(weapon, "m32")) name = "War Machine";
    
    // Wonder Weapons
    else if(isSubStr(weapon, "ray_gun")) name = "Ray Gun";
    else if(isSubStr(weapon, "raygun_mark2")) name = "Ray Gun Mark II";
    else if(isSubStr(weapon, "slowgun")) name = "Paralyzer";
    else if(isSubStr(weapon, "slipgun")) name = "Sliquifier";
    else if(isSubStr(weapon, "blundergat")) name = "Blundergat";
    else if(isSubStr(weapon, "blundersplat")) name = "Acidgat";
    else if(isSubStr(weapon, "staff_fire")) name = "Fire Staff";
    else if(isSubStr(weapon, "staff_water")) name = "Ice Staff";
    else if(isSubStr(weapon, "staff_air")) name = "Wind Staff";
    else if(isSubStr(weapon, "staff_lightning")) name = "Lightning Staff";
    else if(isSubStr(weapon, "staff_revive")) name = "Staff of Ra";
    
    // Specials / Melee / Equipment
    else if(isSubStr(weapon, "knife_ballistic")) name = "Ballistic Knife";
    else if(isSubStr(weapon, "bouncing_tomahawk")) name = "Hell's Retriever";
    else if(isSubStr(weapon, "upgraded_tomahawk")) name = "Hell's Redeemer";
    else if(isSubStr(weapon, "spoon_zm_alcatraz")) name = "Golden Spoon";
    else if(isSubStr(weapon, "spork_zm_alcatraz")) name = "Golden Spork";
    else if(isSubStr(weapon, "one_inch_punch")) name = "One Inch Punch";
    else if(isSubStr(weapon, "cymbal_monkey")) name = "Monkey Bomb";
    else if(isSubStr(weapon, "time_bomb")) name = "Time Bomb";
    else if(isSubStr(weapon, "claymore")) name = "Claymore";
    else if(isSubStr(weapon, "frag_grenade")) name = "Frag Grenade";
    else if(isSubStr(weapon, "sticky_grenade")) name = "Semtex";
    
    if(is_upgraded && name != weapon)
    {
        name = name + " (PaP)";
    }
    
    return name;
}