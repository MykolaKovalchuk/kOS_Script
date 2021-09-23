@LAZYGLOBAL OFF.

function getGravityAtSurface {
	return body:mu / (body:radius ^ 2).
}

function getEstimatedBurnTime {
	parameter deltaV.

	local burnTime is 0.
	local sn is ship:stageNum.
	until sn < 0 or deltaV <= 0 {
		local stageDeltaV is ship:stageDeltaV(sn).
		if (deltaV >= stageDeltaV:current) {
			set burnTime to burnTime + stageDeltaV:duration.
		}
		else {
			set burnTime to burnTime + getEstimatedBurnTimeForStage(deltaV, sn).
		}

		set deltaV to deltaV - stageDeltaV:current.
		set sn to sn - 1.
	}

	return burnTime.
}

function getEstimatedBurnTimeForStage {
	parameter deltaV.
	parameter stageNum.

	local stageDeltaV is ship:stageDeltaV(stageNum).
	if (deltaV >= stageDeltaV:current) {
		return stageDeltaV:duration.
	}

	local isp is 0.
	local stageThrust is 0.
	local engineList is list().
	list engines in engineList.
	for en in engineList {
		if en:stage = stageNum and not en:flameout {
			local enIsp is (choose en:isp if en:ignition else en:visp).
			local enThrust is (choose en:availableThrust if en:ignition else en:possibleThrust).
			set isp to isp + enIsp * enThrust.
			set stageThrust to stageThrust + enThrust.
		}
	}
	if (isp <= 0) {
		return 0.
	}

	if stageNum = ship:stageNum {
		set stageThrust to ship:availableThrust.
	}
	if stageThrust > 0 {
		set isp to isp / stageThrust.
	}

	local isp0 is isp * constant:g0. // Apparently it does not depend on current body

	local stageMass is 0.
	if stageNum = ship:stageNum {
		set stageMass to ship:mass.
	}
	else {
		for p in ship:parts {
			if p:stage <= stageNum {
				set stageMass to stageMass + p:mass.
			}
		}
	}

	local mf is stageMass / (constant:e ^ (deltaV / isp0)).
	local fuelFlow is stageThrust / isp0.
	local t is (stageMass - mf) / fuelFlow.

	return t.
}

function getCircOrbitV {
	parameter parentBody, level.
	return sqrt(parentBody:mu / (parentBody:radius + level)).
}

function calculateDeltaVToAltitude {
	parameter newLevel, m_time.
	parameter startLevel is -1.

	local level is choose startLevel if startLevel >= 0 else body:AltitudeOf(positionAt(ship, m_time)).
	local r1 is orbit:body:radius + level.
	local r2 is orbit:body:radius + newLevel.

	local deltaV1 is sqrt(body:mu / r1) * ((sqrt(2 * r2 / (r1 + r2)) - 1)).

	return deltaV1.
}

function getOrbitalPeriod {
	parameter parentBody, semiMajorAxis.
	return (2 * constant:pi) * sqrt((semiMajorAxis^3) / parentBody:mu).
}

function getAngularSize {
	parameter targetMetricSize, targetDistance.
	return arctan2(targetMetricSize, targetDistance).
}

function getEjectionAngleToMoon {
	parameter targetMoon, transferTime.
	local ejectionAngle is 180 - (360 / targetMoon:obt:period * transferTime).
	if ejectionAngle < 0 {
		set ejectionAngle to 360 + ejectionAngle.
	}
	return ejectionAngle.
}

function getOrbitAngleBetweenAt {
	parameter origin, targ, parentBody, atTime.

	local originPosition is positionAt(origin, atTime) - parentBody:position.
	local targetPosition is positionAt(targ, atTime) - parentBody:position.
	local currentAngle to vang(originPosition, targetPosition).

	local originVelocity is origin:velocity:orbit.
	local originNormal is vcrs(originVelocity, originPosition).
	local originTargetCross is vcrs(originPosition, targetPosition).

	if vdot(originNormal, originTargetCross) < 0 {
		return 0 - currentAngle.
	}

	return currentAngle.
}
