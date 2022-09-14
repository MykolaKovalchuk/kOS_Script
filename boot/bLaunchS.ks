set core:bootfilename to "". // One time script

core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

switch to 0. // Use remote files on kOS processors with small memory

runOncePath("basix").
runOncePath("launchCirc").

waitRCS().
countdown(10, "Lift off!").
launch().

SAS on.

print "Done!".
