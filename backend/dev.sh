#!/bin/bash

# Initialize variables
install_flag=false
install_deps=false

build_flag=false
commit_flag=false
push_flag=false

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo $script_dir
#
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
image_tag_name=$(jq -r '.dev__image_tag_name' "$CONFIG_FILE")
container_name=$(jq -r '.dev__container_name' "$CONFIG_FILE")
host_port=$(jq -r '.dev__host_port' "$CONFIG_FILE")
container_port=$(jq -r '.dev__container_port' "$CONFIG_FILE")
workdir=$(jq -r '.dev__workdir' "$CONFIG_FILE")

if [ "$image_tag_name" = "null" ]; then
	echo "Error: The image-tag-name field is not present in the config file."
	exit 1
fi

if [ "$container_name" = "null" ]; then
	echo "Error: The container-name field is not present in the config file."
	exit 1
fi

# image_tag_name="nguyen8a/dev-nalendar-app:latest"
# container_name="dev_nalendar_app_container" # NOTE: this container name should be generated from the image_tag_name

# Set the script to exit immediately if any command exits with a non-zero status
set -e

# Parse command line options
while [[ $# -gt 0 ]]; do
	case "$1" in
	-i | --install)
		install_flag=true
		install_deps=true
		shift
		;;
	-c | --commit)
		commit_flag=true
		shift
		;;
	-p | --push)
		push_flag=true
		shift
		;;
	-b | --build)
		build_flag=true
		shift
		;;
	*)
		# 1. Input all the dependencies -> ./dev.sh --install express react ...
		if $install_deps; then
			dependencies+=("$1")
		else
			echo "Error: Invalid option: $1"
			exit 1
		fi
		shift
		;;

		# echo "Invalid option: $1"
		# exit 1
		# ;;
	esac
done

build_docker_image() {
	if ! sudo docker build --tag $image_tag_name --file "$script_dir/Dev-Dockerfile" $script_dir; then
		echo "Error: Something wrong with docker build process"
		exit 1
	fi
}

run_and_link_docker_image() {
	# FIXME: this script is coupled to the app part
	if ! sudo docker run --name $container_name -p $host_port:$container_port --rm \
		-v "$script_dir/src":"/$workdir/src" \
		-v "$script_dir/public":"/$workdir/public" \
		-v "/app/node_modules" \
		$image_tag_name; then
		echo "Error: Something wrong with docker run process"
		exit 1
	fi
}

push_docker_image() {
	if ! sudo docker push $image_tag_name; then
		echo "Error: Something wrong with docker push process"
		exit 1
	fi
}

generate_install_dependencies_docker_file_content() {
	# 2. Generate the docker file content
	echo "FROM $image_tag_name AS build"
	for dep in "${dependencies[@]}"; do
		echo "RUN npm install $dep"
	done
}

generate_copy_code_docker_file_content() {
	# NOTE: not working
	echo "FROM $image_tag_name AS build"
	echo "RUN rm -rf ./src/*"
	echo "COPY ./src ./src"
	echo "COPY ./public ./public"
}

dependencies_processing() {
	local output=""
	for dep in "${dependencies[@]}"; do
		local dep_format_regex="^([a-zA-Z0-9._-]+)@([0-9]+(\.[0-9]+)*(\.[0-9]+)*)$"
		if [[ $dep =~ $dep_format_regex ]]; then
			local package="${BASH_REMATCH[1]}"
			local version="${BASH_REMATCH[2]}"
			output+="$package:$version,"
		else
			local version=$(curl -s https://registry.npmjs.org/$dep/latest | grep -oP '(?<="version":")[^"]+')
			output+="$dep:$version,"
		fi
	done
	echo -e "$output"
}

# Function to add a dependency to package.json
add_packagejson_dependency() {
	local package_name="$1"
	local package_version="$2"
	local package_json="package.json"

	# Check if package.json exists
	if [ ! -f "$script_dir/$package_json" ]; then
		echo "Error: package.json not found."
		return 1
	fi

	# Check if jq is installed
	if ! command -v jq &>/dev/null; then
		echo "Error: jq is not installed. Please install jq to run this script."
		return 1
	fi

	# Add the dependency to package.json
	jq --arg package_name "$package_name" --arg package_version "$package_version" \
		'.dependencies += { ($package_name): $package_version }' "$package_json" >temp.json && mv temp.json "$package_json"

	echo "Dev: Dependency $package_name@$package_version added to $package_json."
}

install_new_dependencies() {
	echo "Dev: Installing new dependencies:"
	# 3. push the content to this file $script_dir/Temp-Install_New_Dependencies-Dockerfile
	generate_install_dependencies_docker_file_content >$script_dir/Temp-Install_New_Dependencies-Dockerfile

	if ! sudo docker build --tag $image_tag_name --file $script_dir/Temp-Install_New_Dependencies-Dockerfile $script_dir; then
		echo "Error: Something wrong with installing new dependencies process"
		rm $script_dir/Temp-Install_New_Dependencies-Dockerfile
		exit 0
	fi

	rm $script_dir/Temp-Install_New_Dependencies-Dockerfile

	dependency_pairs=$(dependencies_processing)
	echo "Dev: Dependencies:"
	IFS=',' read -ra pairs <<<"$dependency_pairs"
	for pair in "${pairs[@]}"; do
		IFS=':' read -r package version <<<"$pair"
		# echo "Package: $package, Version: $version"
		add_packagejson_dependency "$package" "$version"
	done
}

# Perform default action if no flags provided
if ! $build_flag && ! $install_flag && ! $commit_flag && ! $push_flag; then
	echo "Dev: Run the client Docker Image"
	echo "Dev: Connect the src volume to the Docker Container"
	run_and_link_docker_image
fi

container_running() {
	local container_name="$1"
	local container_status=$(sudo docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)

	if [ "$container_status" == "true" ]; then
		echo "Dev: Container '$container_name' is running."
		return 0 # Container is running
	else
		echo "Dev: Container '$container_name' is not running."
		return 1 # Container is not running
	fi
}

# Perform actions based on flags
if [ "$build_flag" = true ]; then
	echo "Dev: Build the Image"
	build_docker_image
fi

if [ "$commit_flag" = true ]; then
	echo "Dev: Commit new code into the new dev image"
	# build_docker_image

	generate_copy_code_docker_file_content >$script_dir/Temp-Commit_New_Code-Dockerfile

	if ! sudo docker build --tag $image_tag_name --file $script_dir/Temp-Commit_New_Code-Dockerfile $script_dir; then
		echo "Error: Something wrong with commiting new code process"
		rm $script_dir/Temp-Commit_New_Code-Dockerfile
		exit 0
	fi

	rm $script_dir/Temp-Commit_New_Code-Dockerfile
fi

if [ "$install_flag" = true ]; then
	if container_running "$container_name"; then
		echo "Dev: Docker Kill the old $container_name container"
		sudo docker rm -f $container_name
	fi

	echo "Dev: Install New Dependencies"
	install_new_dependencies

	echo "Dev: Run the New Docker Image"
	echo "Dev: Connect the src volume to the Docker Container"
	run_and_link_docker_image
fi

if [ "$push_flag" = true ]; then
	echo "Dev: Push the image to Docker Hub"
	push_docker_image
fi
