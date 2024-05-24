#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/tool-config.json"
#echo $SCRIPT_DIR $CONFIG_FILE

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

# Extract and print the value of the "name" field
image_tag_name=$(jq -r '.prod__image_tag_name' "$CONFIG_FILE")

if [ "$image_tag_name" = "null" ]; then
	echo "Error: The image-tag-name field is not present in the config file."
	exit 1
fi

if ! sudo docker pull $image_tag_name; then
	echo "Error: Something wrong with docker pull process"
	exit 0
fi

if ! sudo docker run -p 80:80 --rm $image_tag_name; then
	echo "Error: Something wrong with docker run process"
	exit 0
fi
