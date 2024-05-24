generate_install_dependencies_docker_file_content() {
	# 2. Generate the docker file content
	echo "FROM $image_tag_name AS build"
	for dep in "${dependencies[@]}"; do
		echo "RUN npm install $dep"
	done
}

_dependencies_processing() {
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
	if [ ! -f "$SCRIPT_DIR/$package_json" ]; then
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
	# 3. push the content to this file $SCRIPT_DIR/Temp-Install_New_Dependencies-Dockerfile
	generate_install_dependencies_docker_file_content >$SCRIPT_DIR/Temp-Install_New_Dependencies-Dockerfile

	if ! sudo docker build --tag $image_tag_name --file $SCRIPT_DIR/Temp-Install_New_Dependencies-Dockerfile $SCRIPT_DIR; then
		echo "Error: Something wrong with installing new dependencies process"
		rm $SCRIPT_DIR/Temp-Install_New_Dependencies-Dockerfile
		exit 0
	fi

	rm $SCRIPT_DIR/Temp-Install_New_Dependencies-Dockerfile

	dependency_pairs=$(_dependencies_processing)
	echo "Dev: Dependencies:"
	IFS=',' read -ra pairs <<<"$dependency_pairs"
	for pair in "${pairs[@]}"; do
		IFS=':' read -r package version <<<"$pair"
		# echo "Package: $package, Version: $version"
		add_packagejson_dependency "$package" "$version"
	done
}
