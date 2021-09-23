@LAZYGLOBAL OFF.

runOncePath("math").
runOncePath("basix").

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

	if (initialLevel <= body:atm:height) {
		set initialLevel to targetLevel.
	}
	ascendToLevel(initialLevel, targetInclination).

	wait until (eta:apoapsis < 60) or (alt:radar > (body:atm:height + 1_000)).
	PANELS on.
	RADIATORS on.
	wait 1.
	set mapView to true.
	wait 1.

	circularizeOrbit(ship:apoapsis, eta:apoapsis).

	if targetLevel > initialLevel {
		wait 1.
		changeCircOrbit(targetLevel).
	}

	wait 1.
	set mapView to false.
}

function ascendToLevel {
	parameter level, targetInclination.

	doSafeStage().
	autoThrotle().
	autoPitch(level, targetInclination).

	until apoapsis > level {
		autoStage().
		wait 0.
	}

	stopEngine("ascending").
}

function autoThrotle {
	parameter desiredSrfTwr is 1.9.

	lock throttle to 1.
	when (ship:availablethrust / (ship:mass * getGravityAtSurface())) >= desiredSrfTwr then {
		lock throttle to min(1, (ship:mass * getGravityAtSurface() * desiredSrfTwr) / max(0.05, ship:availablethrust)).
		print "Throttling down.".
	}
}

function autoPitch {
	parameter targetLevel, targetInclination.

	local targetDirection is calculateDirectionWithBodyRotation(targetLevel, targetInclination).

	lock targetPitch to 90.
	local koeff is 1.03287 * body:atm:height / Kerbin:atm:height.
	when alt:radar > 1_000 then {
		lock targetPitch to 89.999 - koeff * (alt:radar - 1_000) ^ 0.409511.
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
