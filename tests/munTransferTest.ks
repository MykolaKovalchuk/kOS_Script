copyPath("0:/math", "").
copyPath("0:/basix", "").
copyPath("0:/moonInjection", "").

runOncePath("0:/math").
runOncePath("0:/basix").
runOncePath("0:/moonInjection").

local moonOrbitLevel is 15_000.
local mnv is getInitialMoonInjectionManeuver(Mun).
set mnv to improveInjectionManeuver(Mun, mnv, moonOrbitLevel).

local moonOrbitLevelWithPrecision is moonOrbitLevel + 10.
executeManeuver(mnv, { parameter o. return o:hasNextPatch and o:nextPatch:body = Mun and o:nextPatch:periapsis <= moonOrbitLevelWithPrecision. }).
wait 1.

if ship:orbit:hasNextPatch {
	warpTo(time:seconds + ship:orbit:nextPatchEta - 5).
	wait until ship:body = Mun.
	wait 1.
	circularizeOrbit(ship:periapsis, eta:periapsis).
}

deletePath("math").
deletePath("basix").
deletePath("moonInjection").
