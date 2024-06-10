parameter newLevel.

copyPath("0:/mathl/math.ks", "/math/math.ks").
copyPath("0:/orbit.ks", "").
copyPath("0:/basix.ks", "").

runOncePath("0:/math").
runOncePath("0:/basix").
runOncePath("0:/orbit").

changeCircOrbit(newLevel).

deletePath("/math/math.ks").
deletePath("basix.ks").
deletePath("orbit.ks").
