#!/bin/bash

# Fixed configuration file name
CONFIG_FILE="./tool-config.json"

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

if ! sudo docker build --tag $image_tag_name --file ./Prod-Dockerfile .; then
	echo "Error: Something wrong with docker build process"
	exit 1
fi

if ! sudo docker push $image_tag_name; then
	echo "Error: Something wrong with docker push process"
	exit 1
fi
