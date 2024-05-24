# if ! sudo docker-compose --file ./dev-docker-compose.yml pull; then
# 	echo "Error: Failed to pull the latest image"
# 	exit 0
# fi

if ! sudo docker-compose --file ./dev-docker-compose.yml up --build; then
	echo "Error: Something wrong with docker compose up"
	exit 0
fi
