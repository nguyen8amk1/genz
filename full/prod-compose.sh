if ! sudo docker compose --file ./prod-docker-compose.yml pull; then
	echo "Error: Failed to pull the latest image"
	exit 0
fi

if ! sudo docker compose --file ./prod-docker-compose.yml up; then
	echo "Error: Something wrong with docker compose"
	exit 0
fi
