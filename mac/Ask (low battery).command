#!/bin/bash
# Same as "Start Emergency" but with the smallest, fastest AI model. Use when the battery is low.
E="${EMERGENCY_HOME:-/Users/Shared/Emergency}"
[ -f "$E/emergency.env" ] && . "$E/emergency.env"
EMERGENCY_MODEL="${EMERGENCY_LOW_BATTERY_MODEL:-qwen3.5:2b-q4_K_M}" exec "$E/Start Emergency.command"
