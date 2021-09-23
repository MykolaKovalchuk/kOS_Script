@LAZYGLOBAL OFF.

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

local stateFilePath is "flightState.json".
local flightState is lexicon().

function checkFlightState {
	local stateRecord is lexicon().

	if exists(stateFilePath) {
		set stateRecord to readJson(stateFilePath).
		if stateRecord:isType("Lexicon") and stateRecord:haskey("state") and stateRecord:haskey("target") {
			print "Restored flight state: " + stateRecord:state.
			set flightState to stateRecord.
			return.
		}
	}

	flightState:add("state", "").
	flightState:add("target", "").
	return stateRecord.
}

function saveFlightState {
	parameter state.
	set flightState:state to state.
	writeJson(flightState, stateFilePath).
	print "Saved flight state: " + state.
}

print("***").
print("< Engage brakes to disable automatic time warp >").
print("***").

checkFlightState().

local targetMoon is 0.
if (flightState:target <> "") {
	set targetMoon to Body(flightState:target).
}

if flightState:state = "" {
	print "Loading scripts from archive.".
	copyPath("0:/math", "").
	copyPath("0:/basix", "").
	copyPath("0:/launchCirc", "").
	copyPath("0:/moonInjection", "").

	saveFlightState("launch").
}

runOncePath("math").
runOncePath("basix").
runOncePath("launchCirc").
runOncePath("moonInjection").

if flightState:state = "launch" {
	wait 1.
	print "Select target moon.".
	set mapView to true.
	set target to Body("Sun"). // Initialize target with something
	wait until target:isType("Body") and target:name <> "Sun" and target:body = ship:body.
	set targetMoon to target.

	local targetInclination is waitForMoonOrbitPlaneToLaunch(targetMoon, 25).
	set mapView to false.
	countdown(10, "Lift off!").

	local launchLevel is body:atm:height + 15_000.
	launchTo(launchLevel, targetInclination, -1).

	set flightState:target to targetMoon:name.
	saveFlightState("inject").
}

local moonOrbitLevel is 15_000.
local precisionMeters is getManeuverPrecisionMetres().

if flightState:state = "inject" or (flightState:state = "injectMnv" and not hasNode) {
	wait 1.
	set mapView to true.

	local mnv is getInitialMoonInjectionManeuver(targetMoon).
	local minP is calculateDeltaVToAltitude(targetMoon:altitude - targetMoon:soiRadius, mnv:time).
	local maxP is calculateDeltaVToAltitude(targetMoon:altitude + targetMoon:radius, mnv:time).
	set mnv to improveInjectionManeuver(targetMoon, mnv, moonOrbitLevel, minP, maxP).

	addManeuverToFlightPlan(mnv).
	saveFlightState("injectMnv").
}
if flightState:state = "injectMnv" {
	wait 1.
	set mapView to true.

	local mnv is nextNode.
	local moonOrbitLevelWithPrecision is moonOrbitLevel + precisionMeters.
	local orbitCheckFunc is { parameter o. return o:hasNextPatch and o:nextPatch:body = targetMoon and o:nextPatch:periapsis <= moonOrbitLevelWithPrecision. }.
	executeManeuver(mnv, orbitCheckFunc, false).

	wait 1.
	print "Level difference: " + abs(ship:orbit:nextPatch:periapsis - moonOrbitLevel).
	if ship:orbit:hasNextPatch and ship:orbit:nextPatch:body = targetMoon and abs(ship:orbit:nextPatch:periapsis - moonOrbitLevel) > 100 {
		if ship:orbit:nextPatch:periapsis < moonOrbitLevel - precisionMeters or abs(ship:orbit:nextPatch:inclination) > 90 {
			set moonOrbitLevelWithPrecision to moonOrbitLevel - precisionMeters.
			set orbitCheckFunc to { parameter o. return o:hasNextPatch and o:nextPatch:body = targetMoon and o:nextPatch:periapsis >= moonOrbitLevelWithPrecision. }.
		}
		print "Preparing correction burn.".
		set mnv to improveInjectionManeuver(targetMoon, node(time:seconds + 600, 0, 0, 0), moonOrbitLevel, -5, +5).
		executeManeuver(mnv, orbitCheckFunc, true, 0.75).
	}

	saveFlightState("incline").
}

if flightState:state = "incline" {
	saveFlightState("inclineMnv").
}
if flightState:state = "inclineMnv" {
	saveFlightState("moonSoi").
}

if flightState:state = "moonSoi" {
	if ship:orbit:hasNextPatch and ship:orbit:nextPatch:body = targetMoon {
		wait 1.
		set mapView to true.

		if ship:orbit:nextPatchEta > 180 {
			print "Warp to target moon SOI to continue.".
		}
		wait until ship:body = targetMoon.
	}
	saveFlightState("moonCirc").
}

if flightState:state = "moonCirc" {
	if ship:body = targetMoon {
		wait 1.
		set mapView to true.

		circularizeOrbit(ship:periapsis, eta:periapsis, false).
	}
}

wait 1.
set mapView to false.

set core:bootfilename to "". // Completed journey
SAS on.

print "Done.".
