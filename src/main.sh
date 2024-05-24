#!/bin/bash

source ./frontend.sh
source ./backend.sh
source ./database.sh
source ./full.sh

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

case "$main_option" in
frontend)
	frontend "$sub_option"
	;;
backend)
	backend "$sub_option"
	;;
database)
	database "$sub_option"
	;;
full)
	database "$sub_option"
	;;
*)
	echo "Invalid option. Available options are: frontend, backend, database."
	usage
	;;
esac
