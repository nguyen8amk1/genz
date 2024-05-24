# Function for frontend options
frontend() {
	case "$1" in
	start)
		echo "Starting frontend..."
		# Add your frontend start commands here
		;;
	build)
		echo "Building frontend dev image..."
		# Add your frontend start commands here
		;;
	install)
		echo "Install new dependencies"
		# Add your frontend stop commands here
		;;
	commit)
		echo "Checking frontend status..."
		# Add your frontend status commands here
		;;
	push)
		echo "Push the image to docker hub"
		# Add your frontend status commands here
		;;
	nolink)
		echo "Run but no code directory linking"
		# Add your frontend status commands here
		;;
	production)
		echo "Build the production version"
		# Add your frontend status commands here
		;;
	*)
		echo "Invalid frontend option. Available options are: start, stop, status."
		exit 1
		;;
	esac
}
