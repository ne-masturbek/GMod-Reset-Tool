
-- Server and client both need this for scoring event logs

-- 2^16 bytes - 4 (header) - 2 (UInt length in TTT_ReportStream) - 1 (terminanting byte)
(SERVER and SCORE or CLSCORE).MaxStreamLength = 65529

function ScoreInit()
   return {
      deaths=0,
      suicides=0,
      innos=0,
      traitors=0,
      was_traitor=false,
      bonus=0 -- non-kill points to add
   };
end

function ScoreEvent(e, scores)
   if e.id == EVENT_KILL then
      local aid = e.att.sid64
      local vid = e.vic.sid64

      -- make sure a score table exists for this person
      -- he might have disconnected by now
      if scores[vid] == nil then
         scores[vid] = ScoreInit()

         -- normally we have the ply:GetTraitor stuff to base this on, but that
         -- won't do for disconnected players
         scores[vid].was_traitor = e.vic.tr
      end
      if scores[aid] == nil then
         scores[aid] = ScoreInit()
         scores[aid].was_traitor = e.att.tr
      end

      scores[vid].deaths = scores[vid].deaths + 1

      if aid == vid then
         scores[vid].suicides = scores[vid].suicides + 1
      elseif aid != -1 then
         if e.vic.tr then
            scores[aid].traitors = scores[aid].traitors + 1
         elseif not e.vic.tr then
            scores[aid].innos = scores[aid].innos + 1
         end
      end
   elseif e.id == EVENT_BODYFOUND then
      local sid64 = e.sid64
      if scores[sid64] == nil or scores[sid64].was_traitor then return end

      local find_bonus = scores[sid64].was_detective and 3 or 1
      scores[sid64].bonus = scores[sid64].bonus + find_bonus
   end
end

-- events should be event log as generated by scoring.lua
-- scores should be table with SteamID64s as keys
-- The method of finding these IDs differs between server and client
function ScoreEventLog(events, scores, traitors, detectives)
   for k, s in pairs(scores) do
      scores[k] = ScoreInit()

      scores[k].was_traitor = table.HasValue(traitors, k)
      scores[k].was_detective = table.HasValue(detectives, k)
   end

   local tmp = nil
   for k, e in pairs(events) do
      ScoreEvent(e, scores)
   end

   return scores
end


function ScoreTeamBonus(scores, wintype)
   local alive = {traitors = 0, innos = 0}
   local dead = {traitors = 0, innos = 0}

   for k, sc in pairs(scores) do
      local state = (sc.deaths == 0) and alive or dead
      if sc.was_traitor then
         state.traitors = state.traitors + 1
      else
         state.innos = state.innos + 1
      end
   end

   local bonus = {}
   bonus.traitors = (alive.traitors * 1) + math.ceil(dead.innos * 0.5)
   bonus.innos = alive.innos * 1

   -- running down the clock must never be beneficial for traitors
   if wintype == WIN_TIMELIMIT then
      bonus.traitors = math.floor(alive.innos * -0.5) + math.ceil(dead.innos * 0.5)
   end

   return bonus
end

-- Scores were initially calculated as points immediately, but not anymore, so
-- we can convert them using this fn
function KillsToPoints(score, was_traitor)
   return ((score.suicides * -1)
           + score.bonus
           + (score.traitors * (was_traitor and -16 or 5))
           + (score.innos * (was_traitor and 1 or -8))
           + (score.deaths == 0 and 1 or 0)) --effectively 2 due to team bonus
                                             --for your own survival
end



---- Weapon AMMO_ enum stuff, used only in score.lua/cl_score.lua these days

-- Not actually ammo identifiers anymore, but still weapon identifiers. Used
-- only in round report (score.lua) to save bandwidth because we can't use
-- pooled strings there. Custom SWEPs are sent as classname string and don't
-- need to bother with these.
AMMO_DEAGLE = 2
AMMO_PISTOL = 3
AMMO_MAC10 = 4
AMMO_RIFLE = 5
AMMO_SHOTGUN = 7
-- Following are custom, intentionally out of ammo enum range
AMMO_CROWBAR = 50
AMMO_SIPISTOL = 51
AMMO_C4 = 52
AMMO_FLARE = 53
AMMO_KNIFE = 54
AMMO_M249 = 55
AMMO_M16 = 56
AMMO_DISCOMB = 57
AMMO_POLTER = 58
AMMO_TELEPORT = 59
AMMO_RADIO = 60
AMMO_DEFUSER = 61
AMMO_WTESTER = 62
AMMO_BEACON = 63
AMMO_HEALTHSTATION = 64
AMMO_MOLOTOV = 65
AMMO_SMOKE = 66
AMMO_BINOCULARS = 67
AMMO_PUSH = 68
AMMO_STUN = 69
AMMO_CSE = 70
AMMO_DECOY = 71
AMMO_GLOCK = 72

local WeaponNames = nil
function GetWeaponClassNames()
   if not WeaponNames then
      local tbl = {}
      for k,v in pairs(weapons.GetList()) do
         if v and v.WeaponID then
            tbl[v.WeaponID] = WEPS.GetClass(v)
         end
      end

      for k,v in pairs(scripted_ents.GetList()) do
         local id = v and (v.WeaponID or (v.t and v.t.WeaponID))
         if id then
            tbl[id] = WEPS.GetClass(v)
         end
      end

      WeaponNames = tbl
   end

   return WeaponNames
end

-- reverse lookup from enum to SWEP table
function EnumToSWEP(ammo)
   local e2w = GetWeaponClassNames() or {}
   if e2w[ammo] then
      return util.WeaponForClass(e2w[ammo])
   else
      return nil
   end
end

function EnumToSWEPKey(ammo, key)
   local swep = EnumToSWEP(ammo)
   return swep and swep[key]
end

-- something the client can display
-- This used to be done with a big table of AMMO_ ids to names, now we just use
-- the weapon PrintNames. This means it is no longer usable from the server (not
-- used there anyway), and means capitalization is slightly less pretty.
function EnumToWep(ammo)
   return EnumToSWEPKey(ammo, "PrintName")
end

-- something cheap to send over the network
function WepToEnum(wep)
   if not IsValid(wep) then return end

   return wep.WeaponID
end
