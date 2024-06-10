set core:bootfilename to "". // One time script

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

print "Loading scripts from archive.".
copyPath("0:/math/math.ks", "/math/math.ks").
copyPath("0:/math/vel_vec.ks", "/math/vel_vec.ks").
copyPath("0:/basix.ks", "").
copyPath("0:/orbit.ks", "").
copyPath("0:/launchCirc.ks", "").
copyPath("0:/launchCirc.json", "").

runOncePath("basix").
runOncePath("launchCirc").

waitRCS().
countdown(10, "Lift off!").
launch().

SAS on.

print "Done!".
