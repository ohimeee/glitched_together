-- Accounts allowed to use the admin chat commands in the published game (/world, /cp, /role, /phase, /ult;
-- lobby: /go; see command.md). The experience owner always counts. Add a user id to let another account test with them.
local Admins = {
	Ids = {
		11657510634, -- buldak0555 (owner)
	},
}

function Admins.Allowed(userId: number): boolean
	if game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId then
		return true
	end
	return table.find(Admins.Ids, userId) ~= nil
end

return Admins
