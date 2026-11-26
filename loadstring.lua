-- OJB Test Hub — executor entry line.
-- Owner: mopontop. Branch: main. Raw URL must point at the release file, not src/.
-- Repo moved? Run scripts/push.py to rewrite this owner.

local REPO = "https://raw.githubusercontent.com/mopontop/ojb-test-hub/main/release/ojb-test-hub.lua"

local source = game:HttpGet(REPO)
local chunk = loadstring(source)

if type(chunk) ~= "function" then
	error("OJB Test Hub: release file did not compile — check the raw URL")
end

chunk()
