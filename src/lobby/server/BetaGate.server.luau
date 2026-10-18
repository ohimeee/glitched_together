-- Closed beta: only testers with the community's Beta Tester role get in (Config/Beta, Util/BetaGate).
require(game:GetService("ReplicatedStorage").Shared.Util.BetaGate).Init()
require(game:GetService("ReplicatedStorage").Shared.Util.BugReports).InitServer() -- testers' bug reports
