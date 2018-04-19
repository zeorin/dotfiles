#!/usr/bin/env bash

if xinput list-props "SynPS/2 Synaptics TouchPad" | grep -q "Device Enabled [^:]*:[^10]*1"; then
     xinput disable "SynPS/2 Synaptics TouchPad"
else
     xinput enable "SynPS/2 Synaptics TouchPad"
fi
