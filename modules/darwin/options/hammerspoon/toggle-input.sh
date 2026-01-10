#!/usr/bin/env bash
# toggle monitor input between HDMI and Thunderbolt

HDMI=17
THUNDERBOLT=25

current=$(m1ddc get input)

if [ "$current" -eq "$HDMI" ]; then
	m1ddc set input $THUNDERBOLT
	echo "Switched to Thunderbolt"
else
	m1ddc set input $HDMI
	echo "Switched to HDMI"
fi
