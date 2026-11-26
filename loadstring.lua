-- OJB Test Hub — executor entry line.
-- Replace YOUR_GITHUB_USER (and the branch, if not main) after you push the repo.
-- Raw URL must point at the release file, not at src/.

local REPO = "https://raw.githubusercontent.com/YOUR_GITHUB_USER/ojb-test-hub/main/release/ojb-test-hub.lua"

local source = game:HttpGet(REPO)
local chunk = loadstring(source)

if type(chunk) ~= "function" then
	error("OJB Test Hub: release file did not compile — check the raw URL")
end

chunk()
