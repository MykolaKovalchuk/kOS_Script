@LAZYGLOBAL OFF.

runOncePath("math/math").
runOncePath("math/vel_vec").
runOncePath("basix").

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

function circularizeOrbitWithoutManeuver {
	print "Circularizing manually.".

	local throttelCoeff is 1.5.
	local minMag is 0.01.
	local precision is 100.

	local level is ship:apoapsis.
	local v0 is getOrbitApoapsisV(body, level, ship:orbit:semimajoraxis).
	local v1 is getCircOrbitV(body, level).
	local deltaV is v1 - v0.

	print "ETA to apoapsis: " + eta:apoapsis.
	print "Ship V at apoapsis: " + v0.
	print "Circular Orbit V: " + v1.
	print "DeltaV: " + deltaV.

	local burnTime is getEstimatedBurnTime(deltaV).
	print "Burn time: " + burnTime.

	//local targetVVector is velocity_vec_at(180).
	lock steering to velocity_vec_at(180).

	local startTime is time:seconds + eta:apoapsis - burnTime / 2.

	lock acc to ship:availablethrust / ship:mass.

	wait until time:seconds >= startTime.
	// TODO: Play with throttle accuracy
	lock throttle to choose 1 if acc <= 0 else min(1, throttelCoeff * (v1 - getOrbitApoapsisV(body, level, ship:orbit:semimajoraxis)) / acc).

	// TODO: Play more with end burn conditions and precision
	until (v1 - ship:velocity:orbit:mag) < minMag or ship:periapsis >= level or (obt:apoapsis > 0 and obt:periapsis > 0 and (obt:apoapsis - obt:periapsis) < precision) {
		autoStage().
		wait 0.
	}

	stopEngine("circularizing").
}
