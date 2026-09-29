-- Miko, Starfall Castle (mechanics.md §4, World 2). Milestone M3, alongside FireMage.
--
-- Plan:
--   useIndex 1  Sword combo 8 / 8 / 14 (GetPartBoundsInBox arc in front, Enemy-tagged models).
--   useIndex 2  Shield Block (hold): sets Blocking attribute; server enables a welded ShieldHitbox;
--               projectiles hitting it reflect with newDir = dir - 2 * dir:Dot(n) * n, become friendly, x1.5 damage.
--   useIndex 3  Shield Charge (dash): 16-stud rush, 12 dmg + knockback, breaks CrackedWall.
--   useIndex 4  Rally when charged (250 blocked): 14-stud shockwave, 15 dmg, 2 s stun.
local Tuning = require(game:GetService("ReplicatedStorage").Shared.Config.Tuning)

local ShieldKnight = {
	BlockedBy = { "Downed", "InCutscene", "Picking" },
	Cooldowns = { [3] = Tuning.ShieldKnight.Charge.Cooldown },
}

function ShieldKnight.Use(player: Player, useIndex: number, _target: Instance?, aim: any)
	if useIndex == 2 then
		-- Block state is already useful to EnemyService targeting (Taunt) before combat lands.
		player:SetAttribute("Blocking", aim == true or nil)
	end
	-- TODO(M3): sword, charge, rally, reflect.
end

return ShieldKnight
