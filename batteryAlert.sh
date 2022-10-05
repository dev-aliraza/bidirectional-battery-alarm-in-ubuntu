#!/bin/bash

LEVEL_LOW=20 # Battery low default
LEVEL_HIGH=95 # Battery high default
NOT_CHARGING="discharging"
ICON="/usr/share/icons/ubuntu-mono-dark/status/24/battery-low.svg"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
STOP=0 # 0=Don't stop; 1=Stop due to low batter; 2= Stop due to high battery
WATCH_RANGE=""
SOUND="Massive_War_With_Alarm-Emmanuel_Exiga-1899079650.ogg"
SLEEP_TIME=10
STOP_ROUNDS=18
STOP_ROUND_COUNTER=0
DEACT_FILE="deactivate.txt"
DEBUG=0

echo -n '0' > $DIR/$DEACT_FILE # reset deactivate.txt file

# Validation that battery range is required
if [[ "$1" = "" || ("$1" != "high" && "$1" = "low" && "$1" = "both") ]]; then
	echo "Battery range is either not defined or invalid. Valid battery range are: high, low"
	exit 1
fi

WATCH_RANGE="$1"

# Assign battery LOW and HIGH level value (if provided) to respective variable according to battery range
if [ "$2" != "" ]; then
	if [ $WATCH_RANGE = "both" ]; then
		LEVEL_LOW="$2"
		if [ "$3" != "" ]; then
			LEVEL_HIGH="$3"
		fi
	elif [ $WATCH_RANGE = "high" ]; then
		LEVEL_HIGH="$2"	
	else
		LEVEL_LOW="$2"
	fi
fi

function notify_and_sound()
{
	# get battery level from function argument
	BATTERY_LEVEL="$1"

	# If click on stop than write '0' in `deactivate.txt` so that deactivation turn off and only stop logic retains
	$DIR/notify-send.sh -u critical -i "$ICON" -t 0 "Battery High" "Battery level is ${BATTERY_LEVEL}%!" -o "Stop:pkill play; echo -n '0' > $DIR/$DEACT_FILE" -o "Deactivate:pkill play" # Send notification
	# play alarm sound
	play $DIR/$SOUND &> /dev/null # Play alarm sound
}

# Function to check if battery is low or not
function battery_low()
{
	# get battery level and cable status from function argument
	BATTERY_LEVEL="$1"
	CABLE="$2"
	if [ $DEBUG == 1 ]; then
		echo ""
		echo "${BATTERY_LEVEL} <= ${LEVEL_LOW} | ${CABLE} = ${NOT_CHARGING}"
	fi
	if [[ $BATTERY_LEVEL -le $LEVEL_LOW && $CABLE = $NOT_CHARGING ]]; then
		STOP=1 # Set STOP to 1 so that it resist to generate alarm for certain time till charger plugin
		echo -n '1' > $DIR/$DEACT_FILE #deactive alarm on battery low
		# trigger notify_and_sound function
		notify_and_sound $BATTERY_LEVEL
	fi
}

# Function to check if battery is high or not
function battery_high()
{
	# get battery level and cable status from function argument
	BATTERY_LEVEL="$1"
	CABLE="$2"
	if [ $DEBUG == 1 ]; then
		echo ""
		echo "${BATTERY_LEVEL} >= ${LEVEL_HIGH} | ${CABLE} != ${NOT_CHARGING}"
	fi
	if [[ $BATTERY_LEVEL -ge $LEVEL_HIGH && $CABLE != $NOT_CHARGING ]]; then
		STOP=2 # Set STOP to 2 so that it resist to generate alarm for certain time till charger unplug
		echo -n '2' > $DIR/$DEACT_FILE # deactive alarm on battery high
		# trigger notify_and_sound function
		notify_and_sound $BATTERY_LEVEL
	fi
}

while :
do
	# Get battery and charger status via `upower` utility
	#BATTERY_LEVEL=$(/usr/bin/upower -i $(/usr/bin/upower -e | grep 'BAT')|grep percentage|awk '{ print $2 }'|sed s/'%'/''/g)
	#CABLE=$(/usr/bin/upower -d | grep -n2 battery | grep state | awk '{ print $3 }')

	# Get battery and charger status via `acpi` utility
	BATTERY_LEVEL=$(acpi | awk '{ print $4 }' | sed s/'%,'/''/g)
	CABLE=$(acpi | awk '{ print $3 }' | sed s/','/''/g | tr '[A-Z]' '[a-z]')

	# read deactivate.txt file and store its result in variable
	DEACT=$(<$DIR/$DEACT_FILE)

	# If click on `deactivate` when alarm trigger:
	# Deactivate alarm for battery low until charger plugin
	# Deactivate alarm for battery high until charger unplug
	if [ $DEACT != "0" ]; then
		if [[ $DEACT = "1" && $CABLE != $NOT_CHARGING ]]; then
			echo -n '0' > $DIR/$DEACT_FILE
			DEACT="0"
		elif [[ $DEACT = "2" && $CABLE = $NOT_CHARGING ]]; then
			echo -n '0' > $DIR/$DEACT_FILE
			DEACT="0"
		fi

		if [ $DEACT != "0" ]; then
			sleep $SLEEP_TIME
			continue
		fi
	fi

	# If click on `stop` when alarm trigger:
	# Resist alarm for ~180 seconds
	if [ $STOP != 0 ]; then
		if [ $DEBUG == 1 ]; then
			echo "Stop is not 0, waiting... Round is ${STOP_ROUND_COUNTER}"
		fi
		if [ $STOP_ROUND_COUNTER = $STOP_ROUNDS ]; then
			STOP=0
			STOP_ROUND_COUNTER=0
		fi

		if [[ $STOP = 1 && $CABLE != $NOT_CHARGING ]]; then
			if [ $DEBUG == 1 ]; then
				echo "Cable plugged-in reseting STOP to 0"
			fi
			STOP=0
		elif [[ $STOP = 2 && $CABLE = $NOT_CHARGING ]]; then
			if [ $DEBUG == 1 ]; then
				echo "Cable unplugged reseting STOP to 0"
			fi
			STOP=0
		fi

		if [ $STOP != 0 ]; then
			STOP_ROUND_COUNTER=$((STOP_ROUND_COUNTER + 1))
			sleep $SLEEP_TIME
			continue
		fi
	fi

	# Check battery account to provided range that is low, high or both
	if [ $WATCH_RANGE = "both" ]; then
		if [ $DEBUG == 1 ]; then
			echo "Enter in BOTH"
		fi
		battery_low $BATTERY_LEVEL $CABLE
		battery_high $BATTERY_LEVEL $CABLE
	fi

	if [ $WATCH_RANGE = "low" ]; then
		if [ $DEBUG == 1 ]; then
			echo "Enter in LOW"
		fi
		battery_low $BATTERY_LEVEL $CABLE
	fi

	if [ $WATCH_RANGE = "high" ]; then
		if [ $DEBUG == 1 ]; then
			echo "Enter in HIGH"
		fi
		battery_high $BATTERY_LEVEL $CABLE
	fi

	sleep $SLEEP_TIME
done