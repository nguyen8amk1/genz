#!/bin/bash

frontend_init() {
	CURRENT_DIR="$1"
	CONFIG_FILE="$2"
	# SOMETHIGN="$1"
	# ELSE="$2"
}

# Extract and print the value of the "name" field
image_tag_name=$(jq -r '.frontend.dev__image_tag_name' "$CONFIG_FILE")
container_name=$(jq -r '.frontend.dev__container_name' "$CONFIG_FILE")
host_port=$(jq -r '.frontend.dev__host_port' "$CONFIG_FILE")
container_port=$(jq -r '.frontend.dev__container_port' "$CONFIG_FILE")
workdir=$(jq -r '.frontend.dev__workdir' "$CONFIG_FILE")

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

build_docker_image() {
	if ! sudo docker build --tag $image_tag_name --file "$CURRENT_DIR/Dev-Dockerfile" $CURRENT_DIR; then
		echo "Error: Something wrong with docker build process"
		exit 1
	fi
}

run() {
	if $no_link_flag; then
		echo "Dev: Run the New Docker Image"
		run_docker_image
	else
		echo "Dev: Run the New Docker Image"
		echo "Dev: Connect the src volume to the Docker Container"
		run_and_link_docker_image
	fi
}

run_and_link_docker_image() {
	# FIXME: this script is coupled to the app part
	if ! sudo docker run --name $container_name -p $host_port:$container_port --rm \
		-v "$CURRENT_DIR/src":"/$workdir/src" \
		-v "$CURRENT_DIR/public":"/$workdir/public" \
		-v "$CURRENT_DIR/machines":"/$workdir/machines" \
		-v "/app/node_modules" \
		$image_tag_name; then
		echo "Error: Something wrong with docker run process"
		exit 1
	fi
}

run_docker_image() {
	# FIXME: this script is coupled to the app part
	if ! sudo docker run --name $container_name -p $host_port:$container_port --rm \
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
	if [ ! -f "$CURRENT_DIR/$package_json" ]; then
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
	# 3. push the content to this file $CURRENT_DIR/Temp-Install_New_Dependencies-Dockerfile
	generate_install_dependencies_docker_file_content >$CURRENT_DIR/Temp-Install_New_Dependencies-Dockerfile

	if ! sudo docker build --tag $image_tag_name --file $CURRENT_DIR/Temp-Install_New_Dependencies-Dockerfile $CURRENT_DIR; then
		echo "Error: Something wrong with installing new dependencies process"
		rm $CURRENT_DIR/Temp-Install_New_Dependencies-Dockerfile
		exit 0
	fi

	rm $CURRENT_DIR/Temp-Install_New_Dependencies-Dockerfile

	dependency_pairs=$(dependencies_processing)
	echo "Dev: Dependencies:"
	IFS=',' read -ra pairs <<<"$dependency_pairs"
	for pair in "${pairs[@]}"; do
		IFS=':' read -r package version <<<"$pair"
		# echo "Package: $package, Version: $version"
		add_packagejson_dependency "$package" "$version"
	done
}

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

commit() {
	echo "Dev: Commit new code into the new dev image"
	# build_docker_image

	generate_copy_code_docker_file_content >$CURRENT_DIR/Temp-Commit_New_Code-Dockerfile

	if ! sudo docker build --tag $image_tag_name --file $CURRENT_DIR/Temp-Commit_New_Code-Dockerfile $CURRENT_DIR; then
		echo "Error: Something wrong with commiting new code process"
		rm $CURRENT_DIR/Temp-Commit_New_Code-Dockerfile
		exit 0
	fi

	rm $CURRENT_DIR/Temp-Commit_New_Code-Dockerfile

}

install() {
	if container_running "$container_name"; then
		echo "Dev: Docker Kill the old $container_name container"
		sudo docker rm -f $container_name
	fi

	echo "Dev: Install New Dependencies"
	install_new_dependencies

	#run_and_link_docker_image
	run
}

# Function for frontend options
frontend() {
	case "$1" in
	start)
		echo "Starting frontend..."
		run
		# Add your frontend start commands here
		;;
	# nolink)
	# 	echo "Run but no code directory linking"
	# 	# Add your frontend status commands here
	# 	;;
	build)
		echo "Dev: Build the Image"
		build_docker_image
		# Add your frontend start commands here
		;;
	install)
		install

		# Add your frontend stop commands here
		;;
	commit)
		commit
		# Add your frontend status commands here
		;;
	push)
		echo "Dev: Push the image to Docker Hub"
		push_docker_image
		;;
	# production)
	# 	echo "Build the production version"
	# 	# Add your frontend status commands here
	# 	;;
	*)
		echo "Invalid frontend option. Available options are: start, stop, status."
		exit 1
		;;
	esac
}
