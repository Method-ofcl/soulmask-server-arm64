#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown when sigterm is recieved
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    kill -2 $soulmask_pid
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat /home/steam/image_version)
MAINTAINER=$(cat /home/steam/image_maintainer)
EXPECTED_FS_PERMS=$(cat /home/steam/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Soulmask Dedicated Server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Validate arguments
echo "$(timestamp) INFO: Validating launch arguments"
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="Soulmask Containerized"
    echo "$(timestamp) WARN: SERVER_NAME not set, using default: Soulmask Containerized"
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "$(timestamp) WARN: ADMIN_PASSWORD not set, using default: AdminPleaseChangeMe"
    ADMIN_PASSWORD="AdminPleaseChangeMe"
fi

if [ -z "$SERVER_PASSWORD" ]; then
    echo "$(timestamp) WARN: SERVER_PASSWORD not set, server will be open to the public"
fi

if [ -z "$GAME_MODE" ]; then
    echo "$(timestamp) ERROR: GAME_MODE not set, must be 'pve' or 'pvp'"
    exit 1
else
    if [ "$GAME_MODE" != "pve" ] && [ "$GAME_MODE" != "pvp" ]; then
        echo "$(timestamp) ERROR: GAME_MODE must be either 'pve' or 'pvp'"
        exit 1
    fi
fi

# Check for proper save permissions
echo "$(timestamp) INFO: Validating data directory filesystem permissions"
if ! touch "${SOULMASK_PATH}/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of ${SOULMASK_PATH} is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'sudo chown -R ${EXPECTED_FS_PERMS} /your/soulmask/data/directory'"
    echo ""
    exit 1
fi

rm "${SOULMASK_PATH}/test"

# Install/Update Soulmask
echo "$(timestamp) INFO: Updating Soulmask Dedicated Server"
echo ""
${STEAMCMD_PATH}/steamcmd.sh +force_install_dir "${SOULMASK_PATH}" +login anonymous +app_update ${STEAM_APP_ID} validate +quit
echo ""

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Soulmask"
    exit 1
else
    echo "$(timestamp) INFO: steamcmd update of Soulmask successful"
fi

# Verify if WSServer.sh exists
if [ ! -f "${SOULMASK_PATH}/WSServer.sh" ]; then
    echo "$(timestamp) ERROR: WSServer.sh not found in ${SOULMASK_PATH} after SteamCMD update"
    exit 1
else
    echo "$(timestamp) INFO: WSServer.sh found, proceeding to launch."
fi

# Build launch arguments
echo "$(timestamp) INFO: Constructing launch arguments"
LAUNCH_ARGS="${SERVER_LEVEL} -server -SILENT -SteamServerName=${SERVER_NAME} -${GAME_MODE} -MaxPlayers=${SERVER_SLOTS} -backup=${BACKUP} -saving=${SAVING} -log -UTF8Output -MULTIHOME=${LISTEN_ADDRESS} -Port=${GAME_PORT} -QueryPort=${QUERY_PORT} -EchoPort=${ECHO_PORT} -online=Steam -forcepassthrough -adminpsw=${ADMIN_PASSWORD}"

if [ -n "${SERVER_PASSWORD}" ]; then
    LAUNCH_ARGS="${LAUNCH_ARGS} -PSW=${SERVER_PASSWORD}"
fi


echo "$(timestamp) INFO: Starting to collect rocks..."
echo ""
echo ""                                                                                                                    
echo "                                                          888"                                                           
echo "                                                        851128"                                                          
echo "                                                      0514628358"                                                        
echo "     09531713599590      000896664554644444454455555551593685663245556444444444666666888000000"                          
echo "   0377160008277740      000000000000000000000000000000088526000000000000000000000000000000000"                          
echo "  01771800   091760                                      08000                                 "                         
echo "  6777750      9580   613665334084377158843736092777390    0631159    0371340    82150     06335533348437712904377390"   
echo "  81777712560   00  81750000917300517400  6300  017100      0553760   4277500   0577360   01720000475006772000435000"    
echo "   82177777771348  037700   86775021740   658   01770        2651390 8107750    5551728   677160   880 57730825800"      
echo "     0652377777776097730     6773051750   628   07710        268375803887750   955027740  0537773258   577291160"        
echo "        0085777777687730     6773053750   658   01710    0   260417654087760  05344277360   0853177750 5777237750"       
echo "  0250      057777403770    84776043750   458   07730   546  260027730087750  55600047760 068  0067710051750937750"      
echo "  07760      6177780037380 847160 92734899380  88777064533008359087780967740095200  8373600158   91720051750 837758"     
echo "  83771665465773400   0852129000   006522600   96696666668086696800000669666925558 6455555055323334009451735800377140"   
echo "  000009654690000                       0000000000000000000 000000000000000000                0000000000000000 000000"
echo "                                          00000000000045000 00550000000000000"                                           
echo "                                                       084555800"                                                        
echo "                                                          0000"                                                          
echo ""
echo ""
echo "$(timestamp) INFO: Launching Soulmask. Good luck out there, Chieftan!"
echo "----------------------------------------------------------------------------------------------------------------------"
echo "Server Name: ${SERVER_NAME}"
echo "Game Mode: ${GAME_MODE}"
echo "Server Level: ${SERVER_LEVEL}"
echo "Server Password: ${SERVER_PASSWORD}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Echo Port: ${ECHO_PORT}"
echo "Server Slots: ${SERVER_SLOTS}"
echo "Listen Address: ${LISTEN_ADDRESS}"
echo "Database Backup (seconds): ${BACKUP}"
echo "World Save (seconds): ${SAVING}"
echo "Container Image Version: ${IMAGE_VERSION} "
echo "----------------------------------------------------------------------------------------------------------------------"
echo ""
echo ""

# Launch Soulmask
${SOULMASK_PATH}/WSServer.sh ${LAUNCH_ARGS} &

# Capture Soulmask server start script pid
init_pid=$!

# Capture Soulmask server binary pid 
timeout=0
while [ $timeout -lt 10 ]; do
    # Try using pgrep with full command or binary name
    soulmask_pid=$(pgrep -f "/home/steam/soulmask/WSServer.sh" | head -n 1)
    if [ -n "$soulmask_pid" ]; then
        echo "$(timestamp) INFO: Soulmask server process found (PID: $soulmask_pid)."
        echo ""
        break
    elif [ $timeout -eq 9 ]; then
        echo "$(timestamp) ERROR: Timed out waiting for WSServer (WSServer.sh) to be running"
        exit 1
    fi
    sleep 7
    ((timeout++))
done

# Hold us open until we recieve a SIGTERM
wait $init_pid

# Handle post SIGTERM from here
# Hold us open until WSServer pid closes, indicating full shutdown, then go home
echo "$(timestamp) INFO: Waiting for Soulmask process (PID: $soulmask_pid) to finish..."
tail --pid=$soulmask_pid -f /dev/null
echo "$(timestamp) INFO: Soulmask process (PID: $soulmask_pid) has exited. Container will stop now."

# o7
echo "$(timestamp) INFO: Shutdown complete. Goodbye, Chieftan."
exit 0