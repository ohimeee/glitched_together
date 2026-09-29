-- Kai, Starfall Castle (mechanics.md §4, World 2). Milestone M3: needs the top-down combat layer
-- (EnemyService state machines, server projectiles, XP). Numbers are already in Tuning.FireMage.
--
-- Plan:
--   useIndex 1  Fireball: server projectile (Heartbeat raycasts old→new pos), speed 80, 10 dmg; reflectable.
--   useIndex 2  Flame Wall: 12-stud line, 4 dmg / 0.5 s for 5 s, blocks enemy pathing; 8 s cooldown.
--   useIndex 3  Ignite (E): Brazier / Burnable within 30 studs.
--   useIndex 4  Meteor when charged (300 dmg dealt), 12-stud radius after a 1.2 s marked cast.
--   Dash is replaced by Blink (10 studs, passes iron bars) on the client.
local Tuning = require(game:GetService("ReplicatedStorage").Shared.Config.Tuning)

local FireMage = {
	BlockedBy = { "Downed", "InCutscene", "Picking" },
	Cooldowns = {
		[1] = Tuning.FireMage.Fireball.Cooldown,
		[2] = Tuning.FireMage.FlameWall.Cooldown,
		[3] = Tuning.FireMage.Ignite.Cooldown,
	},
}

function FireMage.Use(_player: Player, _useIndex: number, _target: Instance?, _aim: any)
	-- TODO(M3): implement with EnemyService + projectile simulation.
end

return FireMage
