--[[
                              $$\           $$\ $$\ $$\                                                               $$\                                                         
                              $$ |          \__|$$ |$$ |                                                              $$ |                                                        
$$$$$$\$$$$\   $$$$$$\   $$$$$$$ | $$$$$$\  $$\ $$ |$$ | $$$$$$\         $$$$$$\   $$$$$$\   $$$$$$$\  $$$$$$\   $$$$$$$ | $$$$$$\         $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  
$$  _$$  _$$\  \____$$\ $$  __$$ |$$  __$$\ $$ |$$ |$$ | \____$$\       $$  __$$\ $$  __$$\ $$  _____|$$  __$$\ $$  __$$ |$$  __$$\       $$  __$$\  \____$$\ $$  __$$\ $$  __$$\ 
$$ / $$ / $$ | $$$$$$$ |$$ /  $$ |$$ |  \__|$$ |$$ |$$ | $$$$$$$ |      $$ |  \__|$$$$$$$$ |$$ /      $$ /  $$ |$$ /  $$ |$$$$$$$$ |      $$ /  $$ | $$$$$$$ |$$ |  $$ |$$ /  $$ |
$$ | $$ | $$ |$$  __$$ |$$ |  $$ |$$ |      $$ |$$ |$$ |$$  __$$ |      $$ |      $$   ____|$$ |      $$ |  $$ |$$ |  $$ |$$   ____|      $$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |
$$ | $$ | $$ |\$$$$$$$ |\$$$$$$$ |$$ |      $$ |$$ |$$ |\$$$$$$$ |      $$ |      \$$$$$$$\ \$$$$$$$\ \$$$$$$  |\$$$$$$$ |\$$$$$$$\       \$$$$$$$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |
\__| \__| \__| \_______| \_______|\__|      \__|\__|\__| \_______|      \__|       \_______| \_______| \______/  \_______| \_______|       \____$$ | \_______|\__|  \__| \____$$ |
                                                                                                                                          $$\   $$ |                    $$\   $$ |
                                                                                                                                          \$$$$$$  |                    \$$$$$$  |
                                                                                                                                           \______/                      \______/ 
]]

local scriptName = "madrilla recode"
local author = "cdazzz & nebel (Recoded by Madrilla)"
local version = "v0.0.1"
local branch = "alpha"

client.exec("clear")
client.color_log(255, 255, 255, scriptName  .. " " .. version .. "(" .. branch .. ")" .. " by " .. author)

local menu    = require("madrilla_recode/menu")
local ragebot_helper = require("madrilla_recode/ragebot_helper")
local visuals = require("madrilla_recode/visuals")
local misc    = require("madrilla_recode/misc")
local antiaim = require("madrilla_recode/antiaim")
local resolver = require("madrilla_recode/resolver")
local precipitation = require("madrilla_recode/precipitation")
local discord = require("madrilla_recode/discord")
local killfeed = require("madrilla_recode/killfeed")
local custom_hud = require("madrilla_recode/custom_hud")

menu.OnInitialize()

client.set_event_callback("paint_ui", function()
      visuals.OnPaintUI()
      killfeed.OnPaintUI()
      custom_hud.OnPaintUI()
      discord.OnPaintUI()
end)

client.set_event_callback("paint", function()
      visuals.OnPaint()
end)

client.set_event_callback("round_start", function()
      misc.OnRoundStart()
      ragebot_helper.OnRoundStart()
      antiaim.OnRoundStart()
      killfeed.OnRoundStart()

      precipitation.OnRoundStart()
end)

client.set_event_callback("aim_fire", function(event)
      visuals.OnAimFire(event)
end)

client.set_event_callback("aim_hit", function(event)
      visuals.OnAimHit(event)
end)

client.set_event_callback("player_say", function(event)
      visuals.OnPlayerChat(event)
end)

client.set_event_callback("aim_miss", function(event)
      visuals.OnAimMiss(event)
end)

client.set_event_callback("setup_command", function(cmd)
      antiaim.OnSetupCommand(cmd)
      misc.OnSetupCommand(cmd)
      ragebot_helper.OnSetupCommand(cmd)
end)

client.set_event_callback("net_update_end", function()
      resolver.OnNetUpdateEnd()
      precipitation.OnNetUpdateEnd()
end)

client.set_event_callback("player_death", function(event)
      misc.killsay.OnPlayerDeath(event)
      killfeed.OnPlayerDeath(event)
end)

client.set_event_callback("shutdown", function()
      visuals.ResetAspectRatioChanger()
      visuals.ResetViewModelChanger()
      visuals.ResetThirdPersonDistance()
      killfeed.OnShutdown()
      custom_hud.OnShutdown()
      discord.OnShutdown()
end)

client.set_event_callback("pre_render", function()
      visuals.OnPreRender()
end)