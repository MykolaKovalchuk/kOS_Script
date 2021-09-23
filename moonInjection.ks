@LAZYGLOBAL OFF.

runOncePath("math").
runOncePath("basix").

function getInitialMoonInjectionManeuver {
	parameter targetMoon.
	// For moons with circular or close to circular orbits.

	local transferDeltaV is calculateDeltaVToAltitude(targetMoon:obt:semiMajorAxis - targetMoon:body:radius, time:seconds + eta:periapsis).
	local burnTime is getEstimatedBurnTime(transferDeltaV).

	local transferSma is (targetMoon:obt:semiMajorAxis + orbit:semiMajorAxis) / 2.
	local transferTime is getOrbitalPeriod(body, transferSma) / 2.
	local ejectionAngle is getEjectionAngleToMoon(targetMoon, transferTime) + getAngularSize(targetMoon:radius, targetMoon:obt:semiMajorAxis).

	local currentAnge is getOrbitAngleBetweenAt(targetMoon, ship, body, time:seconds).
	if currentAnge < 0 {
		set currentAnge to 360 + currentAnge.
	}
	if currentAnge < ejectionAngle {
		set currentAnge to 360 + currentAnge.
	}

	local deltaAngle is currentAnge - ejectionAngle.
	local ejectionEta is ship:obt:period / 360 * deltaAngle.
	if ejectionEta < burnTime / 2 + 30 {
		set ejectionEta to ship:obt:period + ejectionEta.
	}

	local correctionAngle is 360 / targetMoon:obt:period * ejectionEta.
	local correctionEta is ship:obt:period / 360 * correctionAngle.

	local m_time is time:seconds + ejectionEta + correctionEta.
	local moonAltitudeAtIntersectionTime is targetMoon:body:AltitudeOf(positionAt(targetMoon, m_time + transferTime)).
	set transferDeltaV to calculateDeltaVToAltitude(moonAltitudeAtIntersectionTime, m_time).

	return node(m_time, 0, 0, transferDeltaV).
}

function improveInjectionManeuver {
	parameter targetMoon.
	parameter mnv.
	parameter targetLevel.
	parameter minP.
	parameter maxP.

	addManeuverToFlightPlan(mnv).

	local precision is getManeuverPrecisionMetres().

	if not mnv:orbit:hasNextPatch {
		print "There is no next patch.".
	}
	else if mnv:orbit:nextPatch:body <> targetMoon {
		print "Intersecting with wrong moon.".
	}
	else if abs(mnv:orbit:nextPatch:periapsis - targetLevel) < precision and abs(mnv:orbit:nextPatch:inclination) < 90 {
		// Maneuver is good
	}
	else {
		local minMag is getManeuverPrecisionDeltaV().
		local bigNumber is targetMoon:soiRadius.

		local originalP is mnv:prograde.
		local hiP is originalP.
		local lowP is originalP.

		if mnv:orbit:nextPatch:periapsis > targetLevel {
			set hiP to maxP.
		}
		else {
			set lowP to minP.
		}

		local bestPrograde is mnv:prograde.
		local bestPrecision is bigNumber.

		print "Adjusting maneuver burn (deltaV - moon periapsis):".
		until hiP - lowP < minMag {
			local midP is (hiP + lowP) / 2.
			set mnv:prograde to midP.

			local level is bigNumber.
			if mnv:orbit:hasNextPatch and mnv:orbit:nextPatch:body = targetMoon {
				set level to mnv:orbit:nextPatch:periapsis.
				if abs(mnv:orbit:nextPatch:inclination) > 90 {
					set level to -level - 2 * targetMoon:radius.
				}
			}
			else if midP > originalP {
				// Bigger than original burn - past target moon.
				set level to -bigNumber - 2 * targetMoon:radius.
			}

			print "  " + round(midP, 4) + " - " + round(level, 3).

			local currentPrecision is abs(level - targetLevel).
			if (currentPrecision < bestPrecision)
			{
				set bestPrecision to currentPrecision.
				set bestPrograde to midP.
			}

			if currentPrecision < precision {
				set hiP to midP.
				set lowP to midP.
			}
			else if level > targetLevel {
				set lowP to midP.
			}
			else {
				set hiP to midP.
			}
		}

		set mnv:prograde to bestPrograde.
	}

	removeManeuverFromFlightPlan(mnv).

	return mnv.
}

function waitForMoonOrbitPlaneToLaunch {
	parameter targetMoon.
	parameter bufferTime is 0.

	if abs(targetMoon:obt:inclination) < 0.01 { // Same plane and orbit orientation
		return 0.
	}
	else if abs(targetMoon:obt:inclination - 180) < 0.01 { // Same plane, opposite orientation
		return 180.
	}

	print "Target orbit inclination: " + targetMoon:obt:inclination.

	local inclination is abs(targetMoon:obt:inclination). // We are working with ascending node
	local ascendLongitude is targetMoon:obt:longitudeOfAscendingNode - body:rotationAngle.

	local ascendPeriodAngle is ascendLongitude - ship:longitude.
	until ascendPeriodAngle >= 0 {
		set ascendPeriodAngle to ascendPeriodAngle + 360.
	}
	until ascendPeriodAngle <= 360 {
		set ascendPeriodAngle to ascendPeriodAngle - 360.
	}
	if ascendPeriodAngle > 180 {
		set ascendPeriodAngle to ascendPeriodAngle - 180.
		set inclination to -inclination.
	}

	if ascendPeriodAngle > 0 {
		print "Waiting for target orbit plane".

		local ascendEta is body:rotationPeriod * ascendPeriodAngle / 360 - bufferTime.
		local ascendTime is time:seconds + ascendEta.

		print "Launch Eta: " + ascendEta.
		warpTo(ascendTime - 2).
		wait until time:seconds >= ascendTime.
	}

	print "Target inclination: " + inclination.
	return inclination.
}