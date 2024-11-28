# Soulmask docker dedicated server for ARM64

This repository provides a Docker image for running Soulmask server on ARM64 architecture (tested on Raspberry Pi5)
As SteamCMD does not support ARM architecture - This is the Way!

[View on Docker Hub](https://hub.docker.com/r/m3thod/soulmask-server-arm64)  


### Requirements

- A machine or environment with ARM64 architecture support.
- Docker installed on your ARM64 system.

You can install docker on a by refering to these tutorials:

[Install Docker Desktop on Linux](https://docs.docker.com/desktop/install/linux-install)

[Install Docker Desktop on Mac](https://docs.docker.com/desktop/install/mac-install)


#### The first startup will download the Soulmask server file, which may take a while (depends on your network condition)  

## Docker

To run the container in Docker, run the following command:

```bash
docker volume create soulmask-persistent-data
docker run \
  --detach \
  --name Soulserver \
  --restart unless-stopped \
  --mount type=volume,source=soulmask-persistent-data,target=/home/steam/soulmask \
  --publish 27050:27050/udp \
  --publish 27015:27015/udp \
  --publish 18888:18888/tcp \
  --env=SERVER_NAME='Soulmask Containerized Server' \
  --env=GAME_MODE='pve' \
  --env=SERVER_SLOTS=20 \
  --env=SERVER_PASSWORD='PleaseChangeMe' \
  --env=ADMIN_PASSWORD='AdminPleaseChangeMe' \
  --env=GAME_PORT=27050 \
  --env=QUERY_PORT=27015 \
  --env=ECHO_PORT=18888 \
  --env=LISTEN_ADDRESS='0.0.0.0' \
  --stop-timeout 90 \
  m3thod/soulmask-server-arm64:latest
```

## Docker Compose

1. To use Docker Compose clone this repo to your local machine 

```bash
git clone https://github.com/your-username/soulmask-server-arm64.git
```

2. Navigate to the repository's directory:

```bash
cd soulmask-server-arm64
```

3. Edit the `docker-compose.yml` and `default.env` files to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

4. To bring the container down:

```bash
docker-compose down --timeout 90
```

Use this if you want to build your own Docker image and launch the container:
######

```bash
docker-compose up --build -d
```

To see the server logs use:

```bash
docker logs <container ID>
```


docker-compose.yml file:
```yml
services:
  soulmask:
    image: m3thod/soulmask-server-arm64:latest  # Use this name for the built image or pull it if not built
    container_name: Soulserver
    restart: unless-stopped
    build:
      context: .
      dockerfile: Dockerfile  # Path to your Dockerfile for building locally
    ports:
      - "27050:27050/udp"
      - "27015:27015/udp"
      - "18888:18888/tcp"
    env_file:
      - default.env
    volumes:
      - soulmask-persistent-data:/home/steam/soulmask
    stop_grace_period: 90s
    healthcheck:
      test: ["CMD-SHELL", "grep -q \"REGISTER SERVER ERROR\" /home/steam/soulmask/WS/Saved/Logs/WS.log || exit 1"]
      interval: 1m  # Check every 1 minute
      timeout: 10s  # Wait for 10 seconds before considering the health check failed
      retries: 3  # Allow 3 retries before considering the container unhealthy
      start_period: 30s  # Initial delay before starting health checks

volumes:
  soulmask-persistent-data:
```

#### Image 

``image: m3thod/soulmask-server-arm64:latest``

This will define the image which your container will be based on. Here it's my image which contains all the need to start the soulmask dedicated server on arm64.

#### Container Name

``container_name: SoulServer``

This define the container name 

#### Restart

``restart: unless-stopped``

`restart` defines the policy that the platform applies on container termination.

- `no`: The default restart policy. It does not restart the container under any circumstances.
- `always`: The policy always restarts the container until its removal.
- `on-failure`: The policy restarts the container if the exit code indicates an error.
- `unless-stopped`: The policy restarts the container irrespective of the exit code but stops
  restarting when the service is stopped or removed.

```yaml
    restart: "no"
    restart: always
    restart: on-failure
    restart: unless-stopped
```
### Ports

Game ports are arbitrary. You can use which ever values you want above 1000. Make sure that you are port forwarding (DNAT) correctly to your instance and that firewall rules are set correctly.

| Port | Description | Protocol | Default |
| ---- | ----------- | -------- | --------|
| Game Port | Port for client connections, should be value above 1000 | UDP | 27050 |
| Query Port | Port for server browser queries, should be a value above 1000 | UDP | 27015 |
| Echo Port | It is optional. Maintenance port, used for local telnet server maintenance, TCP, does not need to be open. | TCP | 18888 |

#### Echo Port

The maintenance port is a simple way to maintain the server, specified through the command line parameter: -EchoPort. During server operation, use a Telnet tool to connect to the maintenance port as follows:

- Execute the run command: telnet 127.0.0.1 18888
- Upon entering the telnet interface, type help to view the available maintenance commands for the server.
- To shut down the server after 30 seconds, enter: quit 30
- To save, enter: saveworld 1


default.env file:
```properties
SERVER_NAME="Soulserver Containerized"
GAME_MODE="pve"
SERVER_PASSWORD="ChangeMePlease"
ADMIN_PASSWORD="AdminChangeMePlease"
GAME_PORT="27050"
QUERY_PORT="27015"
ECHO_PORT="18888"
SERVER_SLOTS="20"
LISTEN_ADDRESS="0.0.0.0"
BACKUP=900
SAVING=600
```

## Environments

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| SERVER_NAME | Name for the Server | Soulserver | False |
| GAME_MODE | Set server to either 'pve' or 'pvp' | None | True |
| SERVER_PASSWORD | Password for the server | PleaseChangeMe | False |
| ADMIN_PASSWORD | Password for GM admin on server | AdminPleaseChangeMe | False |
| SERVER_LEVEL | Level for server to load. Currently there is only 1 so no need to change | Level01_Main | False |
| GAME_PORT | Port for server connections | 27050 | False |
| QUERY_PORT | Port for steam query of server | 27015 | False |
| ECHO_PORT | Maintenance port, used for local telnet server maintenance, TCP, does not need to be open. | 18888 | False |
| SERVER_SLOTS | Number of slots for connections (Max 70) | 20 | False |
| BACKUP | Specifies the interval for writing the game database to disk (unit: seconds) | 900 | False |
| SAVING | Specifies the interval for writing game objects to the database (unit: seconds) | 600 | False |
| LISTEN_ADDRESS | IP address for server to listen on | 0.0.0.0 | False |

For reference, see <https://soulmask.fandom.com/wiki/Private_Server>

### Volumes

```yaml
 volumes:
      - soulmask-persistent-data:/home/steam/soulmask
```

- Soulmask will be installed to `/home/steam/soulmask`
- Any persistent volumes should be mounted to `/home/steam/soulmask` and be owned by 10000:10000
- Game data and saves location: `/home/steam/soulmask/WS/Saved`

You can list your existing volumes using:

```bash
docker volume ls
```
and inspect the volume to check where it is mounted on the host machine:

```bash
docker volume inspect soulmask-persistent-data
```
This command will output details about the volume, including the Mountpoint on the host machine (something like /var/lib/docker/volumes/soulmask-persistent-data/_data).

> [!NOTE]
> It is best to leave managing volumes to Docker. But if you must use bind instead of volume to mount, you need to make sure that on your container host the directory you are bind mounting is owned by 10000:10000 by default (`chown -R 10000:10000 /path/to/directory`). If the ownership of the directory is not correct the container will not start as the server will be unable to persist the savegame.

### Backup server game data

To avoid data loss, consider setting up regular backups for your Docker volumes

- manual backups

Use the docker run command to copy volume data to a tarball:

```bash
docker run --rm -v soulmask-persistent-data:/data -v $(pwd):/backup busybox tar cvf /backup/soulmask_backup.tar /data
```
### Restore server game data

If you wish to restore game data from a backup file use the following command (the container must be stopped when restoring the data):

```bash
docker run --rm -v soulmask-persistent-data:/data -v $(pwd):/backup busybox tar xvf /backup/soulmask_backup.tar -C /
```
When finished start the container again.

### Server update

When there is a new version of Soulmask released the simplest method to update your server is to stop the container and start it again. It will automaticaly update the game server upon start.

```bash
docker stop <container ID or its name eg. Soulserver>
```

```bash
docker start <container ID or its name eg. Soulserver>
```

### Connectivity

You need to make sure that the ports 27050 UDP and 27015 UDP (or whichever ones you decide to use) are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running.

Credits
=============

Thanks to Hmes98318 (https://github.com/hmes98318/palworld-docker.git) and John Skinner (https://github.com/jsknnr/soulmask-dedicated-server.git) for the inspiration.
