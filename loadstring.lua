-- Dolo.Hook — executor entry line.
-- Owner: mopontop. Branch: main. Raw URL must point at the release file, not src/.
-- Repo moved? Run scripts/push.py to rewrite this owner.

local REPO = "https://raw.githubusercontent.com/mopontop/dolo-hook/main/release/dolo-hook.lua"

local source = game:HttpGet(REPO)
local chunk = loadstring(source)

if type(chunk) ~= "function" then
	error("Dolo.Hook: release file did not compile — check the raw URL")
end

chunk()
