#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Normalise the boolean install questions / settings into TOML booleans
# expected by continuwuity.toml.
#
# $registration and $federation may come from:
#   - install questions (literal "0"/"1" — manifest type = boolean)
#   - app settings      (string "true"/"false" written by us, or "0"/"1")
#   - config panel      ("true"/"false" via bind)
# This helper makes them consistent everywhere.

normalise_bool() {
    case "$1" in
        1|true|True|TRUE|yes|on)  echo "true"  ;;
        0|false|False|FALSE|no|off|"") echo "false" ;;
        *) echo "false" ;;
    esac
}
