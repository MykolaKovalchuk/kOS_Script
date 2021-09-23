@LAZYGLOBAL OFF.

runOncePath("math").

function waitRCS {
	RCS on.
	print "Turn off RCS to proceed.".
	wait until RCS = false.
}

function countdown {
	parameter counter, message.

	until counter <= 0 {
		print counter.
		set counter to counter - 1.
		wait 1.
	}
	print message.
}

function doSafeStage {
	wait until stage:ready.
	stage.
	print "Staged.".
}

function autoStage {
	local needstage is false.
	if stage:ready {
		if maxthrust = 0 {
			set needstage to true.
		} else {
			local engineList is list().
			list engines in enginelist.
			for engine in enginelist {
				if engine:ignition and engine:flameout {
					set needstage to true.
					break.
				}
			}
		}
		if needstage {
			doSafeStage.
		}
	}
	return needstage.
}

function stopEngine {
	parameter message.

	lock throttle to 0.
	lock steering to prograde.

	print "Done: " + message.
}

function addManeuverToFlightPlan {
	parameter mnv.
	add mnv.
}

function removeManeuverFromFlightPlan {
	parameter mnv.
	remove mnv.
}

function getManeuverPrecisionMetres {
	return 10.
}

function getManeuverPrecisionDeltaV {
	return 0.001.
}

function executeManeuver {
	parameter mnv.
	parameter checkObt_func is { parameter o. return false. }.
	parameter autoWarp is true.
	parameter throttelCoeff is 1.5.

	if (not hasNode) or (nextNode <> mnv) {
		addManeuverToFlightPlan(mnv).
	}

	local minMag is getManeuverPrecisionDeltaV().

	if mnv:burnvector:mag < minMag {
		removeManeuverFromFlightPlan(mnv).
		return.
	}

	autoStage().
	local burnTime is getEstimatedBurnTime(mnv:deltaV:mag).

	print "Next maneuver:".
	print "  in:        " + mnv:eta.
	print "  prograde:  " + mnv:prograde.
	print "  radial:    " + mnv:radialout.
	print "  normal:    " + mnv:normal.
	print "  apoapsis:  " + mnv:orbit:apoapsis.
	print "  periapsis: " + mnv:orbit:periapsis.
	print "  burntime:  " + burnTime.

	local startTime is time:seconds + mnv:eta - burnTime / 2.
	if autoWarp and BRAKES = false {
		warpTo(startTime - 60).
	}
	else if (startTime - time:seconds) > 180 {
		print "Warp to next maneuver to continue.".
	}

	wait until time:seconds >= startTime - 57.
	SAS off.
	lock steering to mnv:burnvector.

	wait until time:seconds >= startTime - 30.
	if vang(ship:facing:forevector, mnv:burnvector) > 30 {
		RCS on.
		wait until time:seconds >= startTime - 3.
		RCS off.
	}

	lock acc to ship:availablethrust / ship:mass.

	wait until time:seconds >= startTime.
	lock throttle to choose 1 if acc <= 0 else min(1, throttelCoeff * mnv:deltaV:mag / acc).

	local initialVector is mnv:burnvector.
	until mnv:burnvector:mag < minMag or vang(initialVector, mnv:burnvector) > 90 or checkObt_func:call(ship:obt) {
		autoStage().
		wait 0.
	}

	stopEngine("maneuver").

	removeManeuverFromFlightPlan(mnv).
}

function circularizeOrbit {
	parameter level, levelEta.
	parameter autoWarp is true.

	print "Circularizing.".

	local m_time is time:seconds + levelEta.
	local v0 is velocityat(ship, m_time):orbit:mag.
	local v1 is getCircOrbitV(body, level).
	local deltaV is v1 - v0.

	local mnv is node(m_time, 0, 0, deltaV).
	if hasNode {
		if abs(nextNode:prograde - deltaV) > getManeuverPrecisionDeltaV() or abs(nextNode:eta - levelEta) > 1 {
			removeManeuverFromFlightPlan(nextNode).
		}
		else {
			set mnv to nextNode.
		}
	}

	local precision is getManeuverPrecisionMetres() * 2.
	local checkObt_func is { parameter o. return o:apoapsis > 0 and o:periapsis > 0 and (o:apoapsis - o:periapsis) < precision. }.
	executeManeuver(mnv, checkObt_func, autoWarp).
}

function changeCircOrbit {
	parameter newLevel.

	local oldLevel is ship:altitude.
	local startEta is choose eta:periapsis if newLevel > oldLevel else eta:apoapsis.

	print "Changing orbit level in: " + startEta.

	print "Going to transitional orbit.".
	local m_time is time:seconds + startEta.
	local deltaV1 is calculateDeltaVToAltitude(newLevel, m_time).
	local mnv is node(m_time, 0, 0, deltaV1).

	local precision is getManeuverPrecisionMetres().
	local checkObt_func is choose { parameter o. return o:apoapsis > newLevel - precision. } if newLevel > oldLevel else { parameter o. return o:periapsis < newLevel + precision. }.
	executeManeuver(mnv, checkObt_func).

	wait 1.
	local circLevel is choose ship:apoapsis if newLevel > oldLevel else ship:periapsis.
	local circEta is choose eta:apoapsis if newLevel > oldLevel else eta:periapsis.
	circularizeOrbit(circLevel, circEta).
}
