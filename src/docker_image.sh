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

build_docker_image() {
	if ! sudo docker build --tag $image_tag_name --file "$SCRIPT_DIR/Dev-Dockerfile" $SCRIPT_DIR; then
		echo "Error: Something wrong with docker build process"
		exit 1
	fi
}

start() {
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
		-v "$SCRIPT_DIR/src":"/$workdir/src" \
		-v "$SCRIPT_DIR/public":"/$workdir/public" \
		-v "$SCRIPT_DIR/machines":"/$workdir/machines" \
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

generate_copy_code_docker_file_content() {
	# NOTE: not working
	echo "FROM $image_tag_name AS build"
	echo "RUN rm -rf ./src/*"
	echo "COPY ./src ./src"
	echo "COPY ./public ./public"
}
