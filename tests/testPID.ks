lock steering to up.

print "Setting up PID structure:".
set hoverPID to PIDLoop(0.02, 0.0015, 0.02, 0, 1).
set hoverPID:SETPOINT to 100.

set wanted_throttle to 0. // for now.
lock throttle to wanted_throttle.

print "Now starting loop:".
print "Make sure you stage until the engine is active.".
print "You will have to kill it with CTRL-C".
until false {
  set wanted_throttle to hoverPID:UPDATE(time:seconds, alt:radar).
  print "Radar Alt " + round(alt:radar,1) + "m, PID wants throttle=" + round(wanted_throttle,3).
  wait 0.
}
