set core:bootfilename to "". // One time script

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

print "Loading scripts from archive.".
copyPath("0:/math", "").
copyPath("0:/basix", "").
copyPath("0:/launchCirc", "").
copyPath("0:/launchCirc.json", "").

runOncePath("basix").
runOncePath("launchCirc").

waitRCS().
countdown(10, "Lift off!").
launch().

SAS on.

print "Done!".
