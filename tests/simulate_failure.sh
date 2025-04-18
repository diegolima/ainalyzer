#!/usr/bin/env bash

# Source the failwrap so this subshell knows about analyze_on_fail
source ~/.ainalyzer/failwrap.sh

echo "Running simulated failing command..."

analyze_on_fail ls /this/does/not/exist

