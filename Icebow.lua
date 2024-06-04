-- Icebow version 1.0
-- by Hopper and TychoVII

-- Distance from the corners
margin_amount_x = 60
margin_amount_y = 40
margin_weaponamount_x = 120
margin_netamount_x = 40
margin_netamount_y = 40

-- widest game aspect ratio allowed (2 == 2:1 width:height)
max_aspect_ratio = 2
-- narrowest game aspect ratio allowed
min_aspect_ratio = 1.6

-- largest scale factor for the graphics
max_scale_factor = 3.0
-- smallest scale factor for the graphics
min_scale_factor = 0.3
-- screen width at which the graphics are drawn at 1:1 scale
scale_width = 1920
-- scaling rate
scale_rate = 1.0
-- scale adjust for net stats
scale_netadjust = 1.5

-- weapon switch animation time, in ticks
weapon_switch = 10
-- opacity level for holstered weapons
weapon_undrawn_alpha = 0.5
-- bullet slide/fade animation time, in ticks
bullet_switch = 10

-- low ammo warning level, in clips
lowammo_level = 2
-- low ammo flash time, in ticks (active for second half of cycle)
lowammo_flash = 30

-- low health warning level, in native health units
lowhealth_level = 30
-- low health flash time, in ticks (active for second half of cycle)
lowhealth_flash = 30
-- damage effect time, in ticks
health_damage_flash = 15

-- radar ping animation time, in ticks
radar_ping = 60

-- top left corner of first digit in readouts
readout_digit_x = 25
readout_digit_y = 19

-- energy bar padding in image (where 0% and 100% are, relative to image edges)
energy_margin_left = 11
energy_margin_right = 11

-- health bar length in pixels, used when masking
healthbar_width = 335
-- health mask shift to reach start of health bar
healthbar_margin_left = 35
-- health mask shift to mask off icon area
healthbar_margin_icon = 27

-- width in pixels of an oxygen bar (there are 8 total)
oxygenbar_width = 31
-- oxygen mask shift to reach first bar
oxygenbar_margin_left = 24
-- height of an oxygen bar
oxygenbar_height = 38
-- bottom margin (from bottom of oxygen bar to bottom of image)
oxygenbar_margin_bottom = 9

-- tangent of skew angle for graphics (0.4 = tan(22 degrees))
skewtangent = 0.4

-- time in ticks for net standings row to show new player
anim_netscroll = 10
-- time in ticks for net standings rows to switch places
anim_netswap = 10

Triggers = {}
function Triggers.draw()

  if Screen.renderer == "software" then error("Icebow requires OpenGL") end
  
  -- net stats
  if #Game.players > 1 then
    local net_w = netheader.width
    local net_h = math.floor(45*scale*scale_netadjust)
    local net_x = sx + sw - margin_netamount_x*scalemargin - net_w
    local net_y = sy + sh - margin_netamount_y*scalemargin - 3*net_h
    
    local gametype = Game.type
    if gametype == "netscript" then
      gametype = Game.scoring_mode
    end
    netrow_header(net_x, net_y, net_w, net_h, gametype)
    
    local one, two = top_two()
--local one = Game.players[0]
--local two = Game.players[0]
    local ly = net_h
    local ny = 2*net_h
    local lplayer = one
    local nplayer = two
    if not one.local_ then
      ly = 2*net_h
      ny = net_h
      lplayer = two
      nplayer = one
    end
    
    netrow_nonlocal(net_x, net_y + ny, net_w, net_h, gametype, nplayer)
    netrow_local(net_x, net_y + ly, net_w, net_h, gametype, lplayer)
  end

  if Player.dead then return end
      
  local r_w = imgs["radar_underlay"].width
  local r_rad = math.floor(r_w / 2)
  local r_x = sx + math.floor(margin_amount_x*scale)
  local r_y = sy + sh - r_w - math.floor(margin_amount_y*scale)
  
  -- motion sensor
  if Player.motion_sensor.active then
    imgs["radar_underlay"]:draw(r_x, r_y)
    
    -- FOV indicator
    if Screen.field_of_view.horizontal > 0 then
      local fov = Screen.field_of_view.horizontal/2
      local fovm = imgs["radar_fov_mask"]
      Screen.clear_mask()
      Screen.masking_mode = MaskingModes["drawing"]
      fovm.rotation = 0 - fov
      fovm:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["erasing"]
      fovm.rotation = fov
      fovm:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["enabled"]
      imgs["radar_fov"]:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["disabled"]
    end
    
    -- ping animation
    local pingcycle = Game.ticks % radar_ping
    if pingcycle < (radar_ping / 2) then  
      local alpha = 1 - math.max(0, (pingcycle - (radar_ping / 4))/(radar_ping / 4))
      local ping = imgs["radar_ping"]
      ping.tint_color = { 1, 1, 1, alpha }
      
      local nrad = math.floor((pingcycle + 1) * r_rad / (radar_ping / 2))
      local off = r_rad - nrad
      ping:rescale(nrad * 2, nrad * 2)
      ping:draw(r_x + off, r_y + off)
    end
    
    -- compass
    if Player.compass.nw or Player.compass.ne or Player.compass.sw or Player.compass.se then
    
      -- draw each active quadrant into mask
      Screen.clear_mask()
      Screen.masking_mode = MaskingModes["drawing"]
      if Player.compass.nw then
        Screen.fill_rect(r_x, r_y, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.ne then
        Screen.fill_rect(r_x + r_rad, r_y, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.sw then
        Screen.fill_rect(r_x, r_y + r_rad, r_rad, r_rad, { 1, 1, 1, 1 })
      end
      if Player.compass.se then
        Screen.fill_rect(r_x + r_rad, r_y + r_rad, r_rad, r_rad, { 1, 1, 1, 1 })
      end

      Screen.masking_mode = MaskingModes["enabled"]
      imgs["radar_compass"]:draw(r_x, r_y)
      Screen.masking_mode = MaskingModes["disabled"]
    end
    
    -- blips
    local r_mult = (r_rad - imgs["radar_alien"].width) / 8
    for i = 1,#Player.motion_sensor.blips do
      local blip = Player.motion_sensor.blips[i - 1]
      local mult = blip.distance * r_mult
      local rad = math.rad(blip.direction)
      local xoff = r_x + r_rad + math.cos(rad) * mult
      local yoff = r_y + r_rad + math.sin(rad) * mult
      
      local alpha = 1 / (blip.intensity + 1)
      local img = imgs["radar_" .. blip.type.mnemonic]
      local img1 = imgs["radar_" .. blip.type.mnemonic .. "_overlay"]
      
      img.tint_color = { 1, 1, 1, alpha }
      img:draw(xoff - math.floor(img.width/2), yoff - math.floor(img.height/2))
      
      if blip.intensity == 0 then
        local pinghalf = pingcycle / 2
        local pingoff = pingcycle - (blip.distance * pinghalf / 8)
        if pingoff < 0 then pingoff = pinghalf end
        alpha = math.max(0, pinghalf - pingoff)/pinghalf
        img1.tint_color = { 1, 1, 1, alpha }
        img1:draw(xoff - math.floor(img1.width/2), yoff - math.floor(img1.height/2))
      end
    end
  end

  -- health/oxygen area
  local h_x = sx + sw - math.floor(margin_amount_x*scale) - imgs["health_underlay"].width
  local h_y = sy + math.floor(margin_amount_y*scale)
  
  -- oxygen
  local amt = Player.oxygen
  if amt > 0 then
    local pct = amt / 1350
    local bars = math.ceil(pct)
    local full = math.floor(pct)
    local part = pct - full
    
    -- underlay
    mask_oxygen(8, 0, h_x, h_y)
    imgs["oxygen_underlay"]:draw(h_x, h_y)
    
    -- full bars
    mask_oxygen(full, 0, h_x, h_y)
    imgs["oxygen_bars"]:draw(h_x, h_y)
    
    -- partial bar
    if part > 0 then
      mask_oxygen(bars, full, h_x, h_y)
      
      local offset = oxygenbar_margin_bottom * scale
      local barheight = oxygenbar_height * scale
      local vis = offset + (part * barheight)
      
      Screen.masking_mode = MaskingModes["erasing"]
      Screen.fill_rect(h_x, h_y, imgs["health_underlay"].width, imgs["health_underlay"].height - vis, { 1, 1, 1, 1 })
      
      Screen.masking_mode = MaskingModes["enabled"]
      imgs["oxygen_bars"]:draw(h_x, h_y)
    end
    
    -- overlay
    mask_oxygen(8, 0, h_x, h_y)
    imgs["oxygen_overlay"]:draw(h_x, h_y)
    
    Screen.masking_mode = MaskingModes["disabled"]
  else
    mask_oxygen(8, 0, h_x, h_y)
    imgs["oxygen_underlay"]:draw(h_x, h_y)
    imgs["oxygen_overlay"]:draw(h_x, h_y)
    Screen.masking_mode = MaskingModes["disabled"]
  end
  
  -- health
  local h_low = ""
  if Player.life <= 0 then
    h_low = "_low"
  elseif (Player.life < lowhealth_level) and ((Game.ticks % lowhealth_flash) >= math.floor(lowhealth_flash / 2)) then
    h_low = "_low"
  end
  
  imgs["health_underlay" .. h_low]:draw(h_x, h_y)
  amt = Player.life
  local odata = {}
  if amt > 0 then
    local more = imgs["health_life1"]
    odata["more"] = imgs["health_overlay1"]
    if h_low == "_low" then odata["more"] = imgs["health_overlay_low"] end
    local less = nil
    odata["less"] = odata["more"]
    if amt > 300 then
      amt = amt - 300
      more = imgs["health_life3"]
      odata["more"] = imgs["health_overlay3"]
      less = imgs["health_life2"]
      odata["less"] = imgs["health_overlay2"]
    elseif amt > 150 then
      amt = amt - 150
      more = imgs["health_life2"]
      odata["more"] = imgs["health_overlay2"]
      less = imgs["health_life1"]
      odata["less"] = imgs["health_overlay1"]
    end
    
    odata["amt"] = amt
    draw_health(more, amt, 0, true, h_x, h_y)
    draw_health(less, 150, amt, false, h_x, h_y)
  end
  
  -- damage effect
  amt = Player.life
  if amt >= damage_start then
    -- recovered from any damage, reset
    damage_start = amt
    damage_timer = 0
  elseif damage_timer == 0 then
    -- took damage outside of timer, reset timer
    damage_timer = Game.ticks + health_damage_flash
  end
  
  if Game.ticks < damage_timer then
    -- in timer, draw any damage
    local max = damage_start
    while max > 150 do
      max = max - 150
      amt = amt - 150
    end
    
    draw_damage(max, amt, h_x, h_y)
    if amt < 0 then
      draw_damage(150, amt + 150, h_x, h_y)
    end
  elseif damage_timer > 0 then
    -- leaving timer, reset
    damage_timer = 0
    damage_start = Player.life
  end
     
  --overlay
  draw_health(odata["more"], odata["amt"], 0, true, h_x, h_y)
  draw_health(odata["less"], 150, odata["amt"], false, h_x, h_y)
  
  -- weapon
  local w_x = sx + math.floor(margin_weaponamount_x*scale)
  local w_y = h_y
  
  local weapon = Player.weapons.desired
  if weapon then
    local wp = weapon.primary
    local ws = weapon.secondary
    local primary_ammo = nil
    local secondary_ammo = nil
        
    if wp and wp.ammo_type then
      primary_ammo = wp.ammo_type
    end
    draw_ammo(primary_ammo, "left", w_x, w_y) 
    
    local wr_x = w_x + dwidth(imgs["readout_left_underlay"])
    
    local dual_wield = false
    local right_drawn = false
    if ws and ws.ammo_type then
      secondary_ammo = ws.ammo_type
      if secondary_ammo == primary_ammo then
        if Player.items[weapon.type.mnemonic].count < 2 then
          secondary_ammo = nil
          ws = nil
        else
          dual_wield = true
        end
      else
        draw_ammo(secondary_ammo, "right", wr_x, w_y)
        right_drawn = true
      end
    end
    if not right_drawn then
        draw_weapon(weapon, "right", wr_x, w_y)
    end
    
    w_y = w_y + imgs["readout_left_underlay"].height
    
    if ((weapon.type == "fusion pistol") or (weapon.type == "flamethrower")) then
      draw_energy(wp.rounds, wp.total_rounds, w_x - damt(imgs["energy_underlay"]), w_y)
    else
      if secondary_ammo then
        local total = ws.total_rounds
        if weapon.type == "shotgun" then
          total = 1
        end
        draw_bullets(weapon, secondary_ammo, ws.rounds, total, 1, true, dual_wield, w_x, wr_x + dwidth(imgs["readout_right_underlay"]), w_y)
      end
      if primary_ammo then
        local rows = 1
        if weapon.type == "smg" then
          rows = 2
        elseif weapon.type == "assault rifle" then
          rows = 4
        end
        local total = wp.total_rounds
        if weapon.type == "shotgun" then
          total = 1
        end
        draw_bullets(weapon, primary_ammo, wp.rounds, total, rows, false, dual_wield, w_x, wr_x + dwidth(imgs["readout_right_underlay"]), w_y)
      end
    end
  
  end
    
end

function Triggers.resize()

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.x = 0
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.y = 0

  Screen.map_rect.width = Screen.width
  Screen.map_rect.x = 0
  Screen.map_rect.height = Screen.height
  Screen.map_rect.y = 0
  
  local h = math.min(Screen.height, Screen.width / min_aspect_ratio)
  local w = math.min(Screen.width, h*max_aspect_ratio)
  Screen.world_rect.width = w
  Screen.world_rect.x = (Screen.width - w)/2
  Screen.world_rect.height = h
  Screen.world_rect.y = (Screen.height - h)/2
  
  if Screen.map_overlay_active then
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
  end
    
  sx = Screen.world_rect.x
  sy = Screen.world_rect.y
  sw = Screen.world_rect.width
  sh = Screen.world_rect.height

  scalemargin = 1 + (sw - scale_width)*scale_rate/scale_width
  scale = math.min(max_scale_factor, math.max(min_scale_factor, scalemargin))

  for k in pairs(imgs) do
    rescale(imgs[k])
    -- imgs[k].dwidth = imgs[k].width
  end
  
  local rscale = scale
  scale = scale*scale_netadjust
  rescale(netheader)
  for k in pairs(netplayers) do
    rescale(netplayers[k])
  end
  for k in pairs(netteams) do
    rescale(netteams[k])
  end
  scale = rscale
  
  netf = Fonts.new{file = "squarishsans/Squarish Sans CT Medium SC.ttf", size = (18*scale*scale_netadjust), style = 0}

  local th = math.max(320, sh * 0.75)
  local tw = math.max(640, sw * 0.75)
  h = math.min(tw / 2, th)
  w = h*2
  Screen.term_rect.width = w
  Screen.term_rect.x = sx + (sw - w)/2
  Screen.term_rect.height = h
  Screen.term_rect.y = sy + (sh - h)/2
end

function Triggers.init()

  -- align weapon and item mnemonics
  ItemTypes["knife"].mnemonic = "fist"

  damage_start = 0
  damage_timer = 0
  
  imgs = {}
  imgs["health_angle_mask"] = Images.new{path = "resources/health/health_angle_mask.png"}
  imgs["health_bar_mask"] = Images.new{path = "resources/health/health_bar_mask.png"}
  
  imgs["health_damage"] = Images.new{path = "resources/health/health_damage.png"}
  imgs["health_life1"] = Images.new{path = "resources/health/health_life1.png"}
  imgs["health_life2"] = Images.new{path = "resources/health/health_life2.png"}
  imgs["health_life3"] = Images.new{path = "resources/health/health_life3.png"}

  imgs["health_underlay"] = Images.new{path = "resources/health/health_underlay.png"}
  imgs["health_overlay1"] = Images.new{path = "resources/health/health_overlay.png"}
  imgs["health_overlay2"] = Images.new{path = "resources/health/health_overlay.png"}
  imgs["health_overlay3"] = Images.new{path = "resources/health/health_overlay.png"}
  imgs["health_underlay_low"] = Images.new{path = "resources/health/health_underlay_low.png"}
  imgs["health_overlay_low"] = Images.new{path = "resources/health/health_overlay_low.png"}


  imgs["oxygen_underlay"] = Images.new{path = "resources/oxygen/oxygen_underlay.png"}
  imgs["oxygen_overlay"] = Images.new{path = "resources/oxygen/oxygen_overlay.png"}
  imgs["oxygen_bars"] = Images.new{path = "resources/oxygen/oxygen_bars.png"}
  
  imgs["radar_underlay"] = Images.new{path = "resources/radar/background.png"}
  imgs["radar_compass"] = Images.new{path = "resources/radar/compass.png"}
  imgs["radar_ping"] = Images.new{path = "resources/radar/ping.png"}
  
  imgs["radar_fov"] = Images.new{path = "resources/radar/range.png"}
  imgs["radar_fov_mask"] = Images.new{path = "resources/radar/range_mask.png"}
  
  imgs["radar_alien"] = Images.new{path = "resources/radar/dot_enemy.png"}
  imgs["radar_alien_overlay"] = Images.new{path = "resources/radar/dot_enemy_overlay.png"}
  imgs["radar_friend"] = Images.new{path = "resources/radar/dot_friendly.png"}
  imgs["radar_friend_overlay"] = Images.new{path = "resources/radar/dot_friendly_overlay.png"}
  imgs["radar_hostile player"] = Images.new{path = "resources/radar/dot_friendly.png"}
  imgs["radar_hostile player_overlay"] = Images.new{path = "resources/radar/dot_friendly_overlay.png"}
  
  imgs["digit_0"] = Images.new{path = "resources/numbers/0.png"}
  imgs["digit_1"] = Images.new{path = "resources/numbers/1.png"}
  imgs["digit_2"] = Images.new{path = "resources/numbers/2.png"}
  imgs["digit_3"] = Images.new{path = "resources/numbers/3.png"}
  imgs["digit_4"] = Images.new{path = "resources/numbers/4.png"}
  imgs["digit_5"] = Images.new{path = "resources/numbers/5.png"}
  imgs["digit_6"] = Images.new{path = "resources/numbers/6.png"}
  imgs["digit_7"] = Images.new{path = "resources/numbers/7.png"}
  imgs["digit_8"] = Images.new{path = "resources/numbers/8.png"}
  imgs["digit_9"] = Images.new{path = "resources/numbers/9.png"}
  
  imgs["readout_left_underlay"] = Images.new{path = "resources/weapons/weapon_background_blue.png"}
  imgs["readout_left_underlay_low"] = Images.new{path = "resources/weapons/weapon_background_red.png"}
  imgs["readout_right_underlay"] = Images.new{path = "resources/weapons/weapon_background_blue.png"}
  imgs["readout_right_underlay_low"] = Images.new{path = "resources/weapons/weapon_background_red.png"}

  imgs["energy_underlay"] = Images.new{path = "resources/weapons/weapon_background_energy.png"}
  imgs["energy_bar"] = Images.new{path = "resources/weapons/weapon_energy.png"}
  
  imgs["pistol ammo"] = Images.new{path = "resources/weapons/weapon_ammo_generic.png"}
  imgs["fusion pistol ammo"] = Images.new{path = "resources/weapons/weapon_ammo_fusion.png"}
  imgs["assault rifle ammo"] = Images.new{path = "resources/weapons/weapon_ammo_generic.png"}
  imgs["assault rifle grenades"] = Images.new{path = "resources/weapons/weapon_ammo_grenades.png"}
  imgs["missile launcher ammo"] = Images.new{path = "resources/weapons/weapon_ammo_spnkr.png"}
  imgs["flamethrower ammo"] = Images.new{path = "resources/weapons/weapon_ammo_flame.png"}
  imgs["shotgun ammo"] = Images.new{path = "resources/weapons/weapon_ammo_shotgun.png"}
  imgs["smg ammo"] = Images.new{path = "resources/weapons/weapon_ammo_generic.png"}
  
  imgs["pistol"] = Images.new{path = "resources/weapons/weapon_diagram_magnum.png"}
  imgs["fusion pistol"] = Images.new{path = "resources/weapons/weapon_diagram_fusion.png"}
  imgs["missile launcher"] = Images.new{path = "resources/weapons/weapon_diagram_spnkr.png"}
  imgs["flamethrower"] = Images.new{path = "resources/weapons/weapon_diagram_flame.png"}
  imgs["shotgun"] = Images.new{path = "resources/weapons/weapon_diagram_shotgun.png"}
  imgs["smg"] = Images.new{path = "resources/weapons/weapon_diagram_smg.png"}
  
  imgs["round_pistol ammo"] = Images.new{path = "resources/bullets/bullet_magnum.png"}
  imgs["empty_pistol ammo"] = Images.new{path = "resources/bullets/bullet_magnum_dis.png"}
  imgs["round_missile launcher ammo"] = Images.new{path = "resources/bullets/bullet_spnkr.png"}
  imgs["empty_missile launcher ammo"] = Images.new{path = "resources/bullets/bullet_spnkr_dis.png"}
  imgs["round_shotgun ammo"] = Images.new{path = "resources/bullets/bullet_shotgun.png"}
  imgs["empty_shotgun ammo"] = Images.new{path = "resources/bullets/bullet_shotgun_dis.png"}
  imgs["round_smg ammo"] = Images.new{path = "resources/bullets/bullet_smg.png"}
  imgs["empty_smg ammo"] = Images.new{path = "resources/bullets/bullet_smg_dis.png"}
  imgs["round_assault rifle ammo"] = Images.new{path = "resources/bullets/bullet_ar.png"}
  imgs["empty_assault rifle ammo"] = Images.new{path = "resources/bullets/bullet_ar_dis.png"}
  imgs["round_assault rifle grenades"] = Images.new{path = "resources/bullets/bullet_grenade.png"}
  imgs["empty_assault rifle grenades"] = Images.new{path = "resources/bullets/bullet_grenade_dis.png"}
        
  netheader = Images.new{path = "resources/HUD_Netstats/backdrop_black.png"}
  
  netplayers = { }
  netplayers["blue"] = Images.new{path = "resources/HUD_Netstats/backdrop_blue.png"}
  netplayers["green"] = Images.new{path = "resources/HUD_Netstats/backdrop_green.png"}
  netplayers["orange"] = Images.new{path = "resources/HUD_Netstats/backdrop_orange.png"}
  netplayers["red"] = Images.new{path = "resources/HUD_Netstats/backdrop_red.png"}
  netplayers["slate"] = Images.new{path = "resources/HUD_Netstats/backdrop_slate.png"}
  netplayers["violet"] = Images.new{path = "resources/HUD_Netstats/backdrop_violet.png"}
  netplayers["white"] = Images.new{path = "resources/HUD_Netstats/backdrop_white.png"}
  netplayers["yellow"] = Images.new{path = "resources/HUD_Netstats/backdrop_yellow.png"}
    
  netteams = { }
  netteams["blue"] = Images.new{path = "resources/HUD_Netstats/team_blue.png"}
  netteams["green"] = Images.new{path = "resources/HUD_Netstats/team_green.png"}
  netteams["orange"] = Images.new{path = "resources/HUD_Netstats/team_orange.png"}
  netteams["red"] = Images.new{path = "resources/HUD_Netstats/team_red.png"}
  netteams["slate"] = Images.new{path = "resources/HUD_Netstats/team_slate.png"}
  netteams["violet"] = Images.new{path = "resources/HUD_Netstats/team_violet.png"}
  netteams["white"] = Images.new{path = "resources/HUD_Netstats/team_white.png"}
  netteams["yellow"] = Images.new{path = "resources/HUD_Netstats/team_yellow.png"}

  Triggers.resize()
end

function rescale(img)
  if not img then return end
  local w = math.max(1, math.floor(img.unscaled_width * scale))
  local h = math.max(1, math.floor(img.unscaled_height * scale))
  img:rescale(w, h)
end

function mask_health(max, min, icon, strict, x, y)
  
  local pointsize = healthbar_width * scale / 150
  local iconshift = healthbar_margin_icon * scale
  local pointshift = healthbar_margin_left * scale
  Screen.clear_mask()
  local mask = imgs["health_angle_mask"]
  
  if icon then
    -- add area for icon
    Screen.masking_mode = MaskingModes["drawing"]
    Screen.fill_rect(x, y, mask.width, mask.height, { 1, 1, 1, 1 })
    
    -- subtract bars above max
    if max < 150 then
      Screen.masking_mode = MaskingModes["erasing"]
      mask:draw(x + iconshift, y)
    end
  end
  
  -- add mask up to max
  local shift = (150 - max) * pointsize
  Screen.masking_mode = MaskingModes["drawing"]
  mask:draw(x + pointshift + shift, y)
  
  
  -- delete mask below min
  shift = (150 - min) * pointsize
  Screen.masking_mode = MaskingModes["erasing"]
  mask:draw(x + pointshift + shift, y)
  
  -- remove anything outside of bar
  if strict then
    imgs["health_bar_mask"]:draw(x, y)
  end

  Screen.masking_mode = MaskingModes["enabled"]
end

function draw_health(img, max, min, icon, x, y)
  if not img then return end
  if max <= min then return end
  mask_health(max, min, icon, false, x, y)
  
  -- draw life bar
  img:draw(x, y)
  
  Screen.masking_mode = MaskingModes["disabled"]
end

function draw_damage(max, min, x, y)
  if max <= min then return end
  
  mask_health(max, 0, false, true, x, y)
  
  -- draw damage overlay 
  local pointsize = healthbar_width * scale / 150
  local pointshift = healthbar_margin_left * scale
  local shift = math.max(0, min) * pointsize
  imgs["health_damage"]:draw(x + pointshift - shift, y)
  
  Screen.masking_mode = MaskingModes["disabled"]
end

function mask_oxygen(max, min, x, y)
  if max < min then return end
  
  local barshift = oxygenbar_margin_left * scale
  local barsize = oxygenbar_width * scale
  local mask = imgs["health_angle_mask"]
  
  Screen.clear_mask()
  
  -- add area for icon
  Screen.masking_mode = MaskingModes["drawing"]
  Screen.fill_rect(x, y, mask.width, mask.height, { 1, 1, 1, 1 })
  
  -- subtract bars above max
  if max < 8 then
    Screen.masking_mode = MaskingModes["erasing"]
    mask:draw(x + barshift, y)
  end
  
  -- add bars starting at max
  if max > 0 then
    local shift = (8 - max) * barsize
    Screen.masking_mode = MaskingModes["drawing"]
    mask:draw(x + barshift + shift, y)
  end
  
  -- subtract bars starting at min
  if min > 0 then
    local shift = (8 - min) * barsize
    Screen.masking_mode = MaskingModes["erasing"]
    mask:draw(x + barshift + shift, y)
  end

  Screen.masking_mode = MaskingModes["enabled"]
end

function damt(img)
  if not img then return 0 end
  return math.floor(img.height * skewtangent)
end

function dwidth(img)
  if not img then return 0 end
  return math.floor(img.width - (img.height * skewtangent))
end

function draw_number(num, x, y)
  if num > 999 then num = 999 end
  local hundreds = math.floor(num / 100) % 10
  local tens = math.floor(num / 10) % 10
  local ones = num % 10
  
  local dw = dwidth(imgs["digit_0"])
  imgs["digit_" .. hundreds]:draw(x, y)
  imgs["digit_" .. tens]:draw(x + dw, y)
  imgs["digit_" .. ones]:draw(x + dw + dw, y)
end

function draw_energy(amt, total, x, y)
  imgs["energy_underlay"]:draw(x, y)
  if amt <= 0 then return end
  
  local left_off = energy_margin_left*scale
  local right_off = energy_margin_right*scale
  
  local i = imgs["energy_bar"]
  local iw = i.width - left_off - right_off
  i.crop_rect.width = left_off + (amt * iw / total)
  i:draw(x, y)
end

function draw_weapon(weapon, side, x, y)
  if ((not weapon) or (not weapon.type)) then
    return
  end
  
  local img = imgs[weapon.type.mnemonic]
  if not img then
    last_weapon = nil
    return
  end
  imgs["readout_" .. side .. "_underlay"]:draw(x, y)
  
  local off = imgs["readout_" .. side .. "_underlay"].width - img.width
  
  if (not last_weapon) or (not (last_weapon.which == weapon.type.mnemonic)) then
    last_weapon = {}
    last_weapon.which = weapon.type.mnemonic
    last_weapon.count = Player.items[weapon.type.mnemonic].count
    last_weapon.anim = Animation:new()
    if last_weapon.count > 1 then
      last_weapon.anim:set(off)
    else
      last_weapon.anim:set(0)
    end
  elseif last_weapon.count < Player.items[weapon.type.mnemonic].count then
    last_weapon.count = Player.items[weapon.type.mnemonic].count
    last_weapon.anim:target(0, off, weapon_switch)
  else
    last_weapon.anim:update()
  end

  
  off = last_weapon.anim:current()
  if off > 0 then
    if not weapon.secondary.weapon_drawn then
      img.tint_color = {1,1,1,weapon_undrawn_alpha}
    else
      img.tint_color = {1,1,1,1}
    end
    img:draw(x - off, y)
    if weapon.secondary.weapon_drawn and (not weapon.primary.weapon_drawn) then
      img.tint_color = {1,1,1,weapon_undrawn_alpha}
    else
      img.tint_color = {1,1,1,1}
    end
    img:draw(x + off, y)
  else
    img.tint_color = {1,1,1,1}
    img:draw(x, y) 
  end  
end

function draw_ammo(ammo_type, side, x, y)
  if not ammo_type then
    return
  end
  local img = imgs[ammo_type.mnemonic]
  if not img then
    return
  end

  local ct = Player.items[ammo_type].count
  local low = ""
  if ct <= 0 then
    low = "_low"
  elseif ct < 3 then
    if (Game.ticks % lowammo_flash) > (lowammo_flash / 2) then
      low = "_low"
    end
  end
  
  imgs["readout_" .. side .. "_underlay" .. low]:draw(x, y)
  img:draw(x, y)
  draw_number(ct, x + readout_digit_x*scale, y + readout_digit_y*scale)
end

function draw_bullets(weapon, ammo_type, rounds, total_rounds, rows, right_align, dual_wield, left_x, right_x, top_y)
  if not ammo_type then
    return
  end
  local img = imgs["round_" .. ammo_type.mnemonic]
  local img2 = imgs["empty_" .. ammo_type.mnemonic]
  if (not img) or (not img2) then
    return
  end
    
  local is_secondary = right_align
  if dual_wield then
    if is_secondary then
      right_align = false
    elseif (not right_align) and weapon.secondary.weapon_drawn then
      right_align = true
    end
  end

  local items_per_row = total_rounds / rows
  local w = dwidth(img)
  local h = img.height
  local off = damt(img)
  local lpos = left_x - off
  local rpos = right_x - (items_per_row*w) - off
  local llpos = lpos - (rpos - lpos)
  local x = lpos
  if right_align then
    x = rpos
  end
  local y = top_y
  local opacity = 1
  
  -- animation stuff for dual-wield
  -- last_weapon created above in draw_weapon
  -- yes, this code is ugly
  if dual_wield then
    if is_secondary then
      if not last_weapon.s_drawn_opac then
        last_weapon.s_drawn_opac = Animation:new()
        last_weapon.s_drawn_posy = Animation:new()
        last_weapon.s_drawn_posx = Animation:new()
        if weapon.secondary.weapon_drawn then
          last_weapon.s_drawn_opac:set(1)
          last_weapon.s_drawn_posy:set(top_y)
          last_weapon.s_drawn_posx:set(lpos)
        else
          last_weapon.s_drawn_opac:set(0)
          last_weapon.s_drawn_posy:set(top_y + img.height)
          last_weapon.s_drawn_posx:set(llpos)
        end
      else
        if weapon.secondary.weapon_drawn then
          last_weapon.s_drawn_opac:target(0, 1, bullet_switch)
          last_weapon.s_drawn_posy:target(top_y + img.height, top_y, bullet_switch)
          last_weapon.s_drawn_posx:target(llpos, lpos, bullet_switch)
        else
          last_weapon.s_drawn_opac:target(1, 0, bullet_switch)
          last_weapon.s_drawn_posy:target(top_y, top_y + img.height, bullet_switch)
          last_weapon.s_drawn_posx:target(lpos, llpos, bullet_switch)
        end
      end
      
--      x = last_weapon.s_drawn_posx:current()
--      y = last_weapon.s_drawn_posy:current()
--      opacity = last_weapon.s_drawn_opac:current()
    end
    
    if not is_secondary then
      if not last_weapon.p_drawn_opac then
        last_weapon.p_drawn_opac = Animation:new()
        last_weapon.p_drawn_posy = Animation:new()
        if weapon.primary.weapon_drawn or (not weapon.secondary.drawn) then
          last_weapon.p_drawn_opac:set(1)
          last_weapon.p_drawn_posy:set(top_y)
        else
          last_weapon.p_drawn_opac:set(0)
          last_weapon.p_drawn_posy:set(top_y + img.height)
        end
      else
        if weapon.primary.weapon_drawn or (not weapon.secondary.drawn) then
          last_weapon.p_drawn_opac:target(0, 1, bullet_switch)
          last_weapon.p_drawn_posy:target(top_y + img.height, top_y, bullet_switch)
        else
          last_weapon.p_drawn_opac:target(1, 0, bullet_switch)
          last_weapon.p_drawn_posy:target(top_y, top_y + img.height, bullet_switch)
        end
      end
      
      if not last_weapon.p_drawn_posx then
        last_weapon.p_drawn_posx = Animation:new()
        if weapon.secondary.weapon_drawn then
          last_weapon.p_drawn_posx:set(rpos)
        else
          last_weapon.p_drawn_posx:set(lpos)
        end
      else
        if weapon.secondary.weapon_drawn then
          last_weapon.p_drawn_posx:target(lpos, rpos, bullet_switch)
        else
          last_weapon.p_drawn_posx:target(rpos, lpos, bullet_switch)
        end
      end
    
      x = last_weapon.p_drawn_posx:current()
--      y = last_weapon.p_drawn_posy:current()
      opacity = last_weapon.p_drawn_opac:current()
    end
  end
  
  img.tint_color = {1,1,1,opacity}
  img2.tint_color = {1,1,1,opacity}
  local row = 0
  while row < rows do
    local min = items_per_row * row
    local max = min + items_per_row
    local rx = x
    
    while min < max do
      if min < rounds then
        img:draw(rx, y)
      else
        img2:draw(rx, y)
      end
      
      min = min + 1
      rx = rx + w
    end
  
    row = row + 1
    y = y + h
    x = x - off
  end  
end


Animation = {start_val = 0, final_val = 0, current_val = 0, start_ticks = 0, final_ticks = 0}
function Animation:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function Animation:adjust_frac(frac)
  return math.sqrt(1 - math.pow(frac - 1.0, 2))
end

function Animation:update()
  if Game.ticks >= self.final_ticks then
    self.current_val = self.final_val
  else
    local pos = self:adjust_frac((Game.ticks - self.start_ticks) / (self.final_ticks - self.start_ticks))
    self.current_val = (pos * (self.final_val - self.start_val)) + self.start_val
  end
end

function Animation:set(to)
  self.start_val = to
  self.final_val = to
  self.current_val = to
  self.start_ticks = Game.ticks
  self.final_ticks = Game.ticks
  return
end

function Animation:target(from, to, when)
  if when <= 0 then
    self:set(to)
    return
  end
  -- otherwise, calculate from current value
  self:update()
  
  -- don't recalculate if we're on the same animation
  if (from == self.start_val) and (to == self.final_val) then
    return
  end
  
  local frac = math.abs(to - self.current_val) / math.abs(to - from)
  if frac < 1 then
    -- finish sooner, based on requested speed
    when = math.ceil(when * self:adjust_frac(frac))
  end
  
  self.start_val = self.current_val
  self.final_val = to
  self.start_ticks = Game.ticks
  self.final_ticks = Game.ticks + when
end

function Animation:current()
  return self.current_val
end
  
function format_time(ticks)
   local secs = math.ceil(ticks / 30)
   return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function net_gamename(gametype)
  if not gamename then
    gamename = { }
    gamename["kill monsters"] = "EMFH"
    gamename["cooperative play"] = "Co-op"
    gamename["capture the flag"] = "CTF"
    gamename["king of the hill"] = "KOTH"
    gamename["kill the man with the ball"] = "KTMWTB"
    gamename["rugby"] = "Rugby"
    gamename["tag"] = "Tag"
    gamename["defense"] = "Defense"
    
    gamename["most points"] = "Netscript"
    gamename["least points"] = "Netscript"
    gamename["most time"] = "Netscript"
    gamename["least time"] = "Netscript"
  end
  
  return gamename[gametype.mnemonic]
end

function net_gamelimit()
  if Game.time_remaining then
    return format_time(Game.time_remaining)
  end
  if Game.kill_limit then
    local max_kills = 0
    for i = 1,#Game.players do
      max_kills = math.max(max_kills, Game.players[i - 1].kills)
    end
    return string.format("%d", Game.kill_limit - max_kills)
  end
  return nil
end

function ranking_text(gametype, ranking)
  if (gametype == "kill monsters") or
     (gametype == "capture the flag") or
     (gametype == "rugby") or
     (gametype == "most points") then
    return string.format("%d", ranking)
  end
  if (gametype == "least points") then
    return string.format("%d", -ranking)
  end
  if (gametype == "cooperative play") then
    return string.format("%d%%", ranking)
  end
  if (gametype == "most time") or
     (gametype == "least time") or
     (gametype == "king of the hill") or
     (gametype == "kill the man with the ball") or
     (gametype == "defense") or
     (gametype == "tag") then
    return format_time(math.abs(ranking))
  end
  
  -- unknown
  return nil
end

function comp_player(a, b)
  if a.ranking > b.ranking then
    return true
  end
  if a.ranking < b.ranking then
    return false
  end
  if a.name < b.name then
    return true
  end
  return false
end

function sorted_players()
  local tbl = {}
  for i = 1,#Game.players do
    table.insert(tbl, Game.players[i - 1])
  end
  table.sort(tbl, comp_player)
  return tbl
end

function top_two()
  local tbl = sorted_players()
  local one = tbl[1]
  local two = tbl[2]
  local i = 2
  while (not one.local_) and two and (not two.local_) do
    i = i + 1
    two = tbl[i]
  end
  return one, two
end

function netrow_header(x, y, w, h, gametype)
  netheader:draw(x, y + 14*scale*scale_netadjust)
  local lt = net_gamename(gametype)
  local rt = net_gamelimit()
  if lt and rt then
    lt = lt .. ":"
  end
  netrow_text(x, y, w, h, lt, rt)
end

function netrow_player(x, y, w, h, gametype, player)
  if not player then return end
  
  local img = netplayers[player.color.mnemonic]
  img:draw(x, y + 8*scale*scale_netadjust)
  netteams[player.team.mnemonic]:draw(x + img.width, y + 8*scale*scale_netadjust)
  netrow_text(x, y, w, h, player.name, ranking_text(gametype, player.ranking))
end

function netrow_text(x, y, w, h, left_text, right_text)
  if left_text then
    local lw, lh = netf:measure_text(left_text)
    local lx = x + 60*scale*scale_netadjust
    local ly = math.floor(y + (h - lh)/2) - 2
    netf:draw_text(left_text, lx, ly, { 1, 1, 1, 1 })
  end
  if right_text then
    local lw, lh = netf:measure_text(right_text)
    local lx = x + (w - lw) - 30*scale*scale_netadjust
    local ly = math.floor(y + (h - lh)/2) - 2
    netf:draw_text(right_text, lx, ly, { 1, 1, 1, 1 })
  end
end

function netrow_local(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not netlocaly then
    netlocaly = target_y
  end
  local y = target_y
  if y > (netlocaly + frac) then
    y = netlocaly + frac
  elseif y < (netlocaly - frac) then
    y = netlocaly - frac
  end
  netlocaly = y
  netrow_player(x, y, w, h, gametype, player)
end

function netrow_nonlocal(x, target_y, w, h, gametype, player)

  -- determine position of box
  local frac = h
  if anim_netswap > 0 then frac = h/anim_netswap end
  if not nonlocaly then
    nonlocaly = target_y
  end
  local y = target_y
  if y > (nonlocaly + frac) then
    y = nonlocaly + frac
  elseif y < (nonlocaly - frac) then
    y = nonlocaly - frac
  end
  nonlocaly = y
  
  -- update player list for animation
  if not nonlocalp then
    nonlocalp = { }
    nonlocalp[1] = { p = player, t = Game.ticks }
  end
  if not (nonlocalp[#nonlocalp].p == player) then
    table.insert(nonlocalp, { p = player, t = Game.ticks })
  else
    nonlocalp[#nonlocalp].t = Game.ticks
  end
  while (Game.ticks - nonlocalp[1].t) >= anim_netscroll do
    table.remove(nonlocalp, 1)
  end

  local sty = 0
  frac = h
  if anim_netscroll > 0 then frac = h/anim_netscroll end
  for i,v in ipairs(nonlocalp) do
    local t = Game.ticks - v.t
    local edy = math.floor(h - t*frac)

    Screen.clip_rect.y = y + sty
    Screen.clip_rect.height = edy - sty

    netrow_player(x, y, w, h, gametype, v.p)
    
    sty = edy
  end

  Screen.clip_rect.y = 0
  Screen.clip_rect.height = Screen.height
end
