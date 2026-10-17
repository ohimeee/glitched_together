-- The end-credits tip jar (Config/Products.Support): the only developer products in the game. ProcessReceipt may be
-- set once per place, so every product goes through here. A support purchase gives no gameplay advantage: the
-- buyer's screen says thank you ("SupportThanks") and Util/Supporters adds the Robux to their total (Supporter
-- Wall, credits, SUPPORTER tag; looks only). Purchases are logged per player in their own data store key so a retried
-- receipt is never thanked twice.
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Supporters = require(ReplicatedStorage.Shared.Util.Supporters)

local SupportService = {}

local support: { [number]: boolean } = {}
for _, p in Products.Support do
	if p.Id ~= 0 then
		support[p.Id] = true
	end
end

local store: DataStore? = nil
local ok = pcall(function()
	store = DataStoreService:GetDataStore("SupportReceipts")
end)
if not ok then
	store = nil -- Studio without API access: purchases are test purchases anyway
end

local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	if not support[info.ProductId] then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- not ours: never grant what we don't know
	end
	local fresh = true
	if store then
		local saved, err = pcall(function()
			(store :: DataStore):UpdateAsync(info.PurchaseId, function(old)
				fresh = old == nil
				return true
			end)
		end)
		if not saved then
			warn("[Support] receipt not saved, Roblox will retry:", err)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	if fresh then
		Supporters.Record(info.PlayerId, info.CurrencySpent)
	end
	local p = Players:GetPlayerByUserId(info.PlayerId)
	if p and fresh then
		Net.event("SupportThanks"):FireClient(p, info.CurrencySpent)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function SupportService.Init()
	MarketplaceService.ProcessReceipt = processReceipt
	Supporters.Init()
	-- the thank-you panel's "hide my name" toggle
	Net.event("SupporterHide").OnServerEvent:Connect(function(p, hidden)
		Supporters.SetHidden(p, hidden == true)
	end)
end

return SupportService
