@LAZYGLOBAL OFF.

runOncePath("math/math").
runOncePath("basix").
runOncePath("orbit").

function launch {
	parameter fileName is "launchCirc.json".

	if exists(fileName) {
		local L is readJson(fileName).
		launchTo(L:targetLevel, L:targetInclination, body:atm:height + L:initialLevelAboveAtm).
	}
}

function launchTo {
	parameter targetLevel is 100_000.
	parameter targetInclination is 0.
	parameter initialLevel is body:atm:height + 15_000.

	if (initialLevel <= body:atm:height or career():canmakenodes = false) {
		set initialLevel to targetLevel.
	}
	ascendToLevel(initialLevel, targetInclination).

	wait until (eta:apoapsis < 60) or (alt:radar > (body:atm:height + 1_000)).
	PANELS on.
	RADIATORS on.
	wait 1.
	set mapView to true.
	wait 1.

	if (career():canmakenodes = false) {
		circularizeOrbitWithoutManeuver().
	}
	else {
		circularizeOrbit(ship:apoapsis, eta:apoapsis).

		if targetLevel > initialLevel {
			wait 1.
			changeCircOrbit(targetLevel).
		}
	}

	wait 1.
	set mapView to false.
}

function ascendToLevel {
	parameter level, targetInclination.

	doSafeStage().
	autoThrotle(1.7).
	autoPitch(level, targetInclination, 85).

	until apoapsis > level {
		autoStage().
		wait 0.
	}

	stopEngine("ascending").
}

function autoThrotle {
	parameter desiredSrfTwr is 1.7.

	lock throttle to 1.
	when (ship:availablethrust / (ship:mass * getGravityAtSurface())) >= desiredSrfTwr then {
		lock throttle to min(1, (ship:mass * getGravityAtSurface() * desiredSrfTwr) / max(0.05, ship:availablethrust)).
		print "Throttling down.".
	}
}

function autoPitch {
	parameter targetLevel, targetInclination.
	parameter initialPitch is 85.

	local targetDirection is calculateDirectionWithBodyRotation(targetLevel, targetInclination).

	lock targetPitch to 90.
	when alt:radar > 1_000 or ship:airspeed > 100 then {
		print "Initiating pitch.".
		lock targetPitch to initialPitch.

		local flatDirectionVector is heading(targetDirection, 0):vector.
		when abs(vang(srfPrograde:vector, flatDirectionVector)) < initialPitch then {
			print "Starting gravity pitch.".
			lock targetPitch to max(min(abs(vang(srfPrograde:vector, flatDirectionVector) + 0.01), initialPitch), 5).
		}
	}

	lock steering to heading(targetDirection, targetPitch).
}

function calculateDirectionWithBodyRotation {
	parameter targetLevel, targetInclination.

	if targetInclination = 0 {
		return 90.
	}
	else if targetInclination = 180 {
		return 270.
	}
	else {
		local equatorialVel is 2 * constant:Pi * body:radius / body:rotationPeriod.
		local targetLevelVel is getCircOrbitV(body, targetLevel).

		local targetDirection is 90 - targetInclination.
		local vxRot is targetLevelVel * sin(targetDirection) - equatorialVel.
		local vyRot is targetLevelVel * cos(targetDirection).

		local azimuth IS mod(arctan2(vxRot, vyRot) + 360, 360).
		if targetInclination < 0 {
			if azimuth <= 90 {
				set azimuth to 180 - azimuth.
			}
			else if azimuth >= 270 {
				set azimuth to 540 - azimuth.
			}
		}

		return azimuth.
	}
}
