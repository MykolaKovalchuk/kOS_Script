// vel_vec.ks
// Calculates velocity vector at a given true anomaly for arbitrary orbits
// /u/nowadaykid

// -----------------------------------------------------------------------------
// vec_to_an(obt_lan, obt_bdy)
// calculates the vector pointing to the equatorial ascending node for an orbit
//    described by the given parameters
// obt_lan:   longitude of ascending node
// obt_bdy:   orbit body
// -----------------------------------------------------------------------------
function vec_to_an {
	parameter obt_lan is ship:orbit:lan.
	parameter obt_bdy is ship:orbit:body.

	// reference direction
	local lng_offset to obt_bdy:rotationangle.
	local eq_axis to latlng(0, obt_lan-lng_offset):position - obt_bdy:position.
	return eq_axis:normalized.
}

// -----------------------------------------------------------------------------
// orbit_normal(obt_inc, obt_lan, obt_bdy)
// calculates the normal vector of an orbit described by the given paramaters
// obt_inc:   inclination
// obt_lan:   longitude of ascending node
// obt_bdy:   orbit body
// -----------------------------------------------------------------------------
function orbit_normal {
	parameter obt_inc is ship:orbit:inclination.
	parameter obt_lan is ship:orbit:lan.
	parameter obt_bdy is ship:orbit:body.

	// equatorial axis around which to rotate
	local axis to vec_to_an(obt_lan, obt_bdy).

	// rotate south pole vector along equatorial axis
	local south_pole to latlng(-90, 0):position - obt_bdy:position.
	local nrm_vec to angleaxis(-obt_inc, axis) * south_pole.
	return nrm_vec:normalized.
}

// -----------------------------------------------------------------------------
// vec_to_pe(obt_inc, obt_lan, obt_aop, obt_body)
// calculates the vector pointing to the periapsis from the central body for an
//    orbit described by the given parameters
// obt_inc:   inclination
// obt_lan:   longitude of ascending node
// obt_aop:   argument of periapsis
// obt_bdy:   orbit body
// -----------------------------------------------------------------------------
function vec_to_pe {
	parameter obt_inc is ship:orbit:inclination.
	parameter obt_lan is ship:orbit:lan.
	parameter obt_aop is ship:orbit:argumentofperiapsis.
	parameter obt_bdy is ship:orbit:body.

	local nrm_vec to orbit_normal(obt_inc, obt_lan, obt_bdy).
	local eq_axis to vec_to_an(obt_lan, obt_bdy).
	local maj_axis to angleaxis(obt_aop, nrm_vec) * eq_axis.
	return maj_axis:normalized.
}

// -----------------------------------------------------------------------------
// radius_true_anom(t, obt_sma, obt_ecc)
// calculates the radius at a given true anomaly along an orbit
//    described by the given parameters
// t:        true anomaly
// obt_sma:  semimajor axis
// obt_ecc:  eccentricity
// -----------------------------------------------------------------------------
function radius_true_anom {
	parameter t.
	parameter obt_sma is ship:obt:semimajoraxis.
	parameter obt_ecc is ship:obt:eccentricity.

	// radius at true anomaly
	return obt_sma * (1 - obt_ecc^2) / (1 + obt_ecc * cos(t)).
}

// -----------------------------------------------------------------------------
// velocity_vec_at(t, obt_sma, obt_ecc, obt_inc, obt_lan, obt_aop, obt_bdy)
// calculates the velocity vector at a given true anomaly along an orbit
//    described by the given parameters
// t:         true anomaly
// obt_sma:   semimajor axis
// obt_ecc:   eccentricity
// obt_inc:   inclination
// obt_lan:   longitude of ascending node
// obt_aop:   argument of periapsis
// obt_bdy:   body
// -----------------------------------------------------------------------------
function velocity_vec_at {
	parameter t.
	parameter obt_sma is ship:obt:semimajoraxis.
	parameter obt_ecc is ship:obt:eccentricity.
	parameter obt_inc is ship:obt:inclination.
	parameter obt_lan is ship:obt:lan.
	parameter obt_aop is ship:obt:argumentofperiapsis.
	parameter obt_bdy is ship:obt:body.

	// normal vector, major axis
	local nrm_vec to orbit_normal(obt_inc, obt_lan, obt_bdy).
	local maj_axis to vec_to_pe(obt_inc, obt_lan, obt_aop, obt_bdy).

	// radial vector, along-track vector
	// note that these are not the radialout and prograde burn directions
	local rad_vec to angleaxis(t, nrm_vec) * maj_axis.
	local pro_vec to vcrs(nrm_vec, rad_vec).

	// equations from http://orbiter-forum.com/showthread.php?t=24457
	local rta to radius_true_anom(t, obt_sma, obt_ecc).
	local h to sqrt(obt_bdy:mu * obt_sma * (1 - obt_ecc^2)).
	local vr to obt_bdy:mu * obt_ecc * sin(t) / h.
	local vt to h / rta.

	return vr * rad_vec:normalized + vt * pro_vec:normalized.
}