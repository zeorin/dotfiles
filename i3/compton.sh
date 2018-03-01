#!/usr/bin/env bash

killall compton
compton -f -D 5 -cz --respect-prop-shadow
