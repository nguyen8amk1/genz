#!/bin/bash

CURRENT_DIR="$(pwd)"
echo $CURRENT_DIR
CONFIG_FILE="$CURRENT_DIR/genz.json"
echo $CONFIG_FILE

# Check if jq is installed
if ! command -v jq &>/dev/null; then
	echo "Error: jq could not be found, please install jq to use this script."
	exit 1
fi

# Check if the file exists
if [ ! -f "$CONFIG_FILE" ]; then
	echo "Error: File not found: $CONFIG_FILE"
	exit 1
fi

source ~/Documents/GitHub/genz/src/frontend.sh
# source ./backend.sh
# source ./database.sh
# source ./full.sh

# Function to display usage information
usage() {
	echo "Usage: $0 {frontend|backend|database}:{start|stop|status}"
	exit 1
}

# Main script logic
if [ $# -ne 1 ]; then
	usage
fi

# Extract the main option and sub-option
IFS=':' read -r main_option sub_option <<<"$1"
if [ -z "$main_option" ] || [ -z "$sub_option" ]; then
	usage
fi

initialize() {
	# TODO: have a genz.json generation prompt
	echo "i have no idea"
}

case "$main_option" in
init)
	initialize "$sub_option"
	;;
frontend | client)
	frontend_init "$CURRENT_DIR" "$CONFIG_FILE"
	frontend "$sub_option"
	;;
backend | api)
	backend_init "$CURRENT_DIR" "$CONFIG_FILE"
	backend "$sub_option"
	;;
database | db)
	database_init "$CURRENT_DIR" "$CONFIG_FILE"
	database "$sub_option"
	;;
full)
	#database "$sub_option" "$CURRENT_DIR" "$CONFIG_FILE"
	echo "I have no idea"
	;;
*)
	echo "Invalid option. Available options are: frontend, backend, database."
	usage
	;;
esac
