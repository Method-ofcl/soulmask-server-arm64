# Use the arm64 architecture
# Stage 1: FEX Build
FROM ubuntu:22.04 AS fex_build

# Add necessary architecture and update the package list
RUN dpkg --add-architecture arm64 && \
    apt-get update

# Install required dependencies
RUN DEBIAN_FRONTEND="noninteractive" apt install -y cmake \
    clang-13 llvm-13 nasm ninja-build pkg-config \
    libcap-dev libglfw3-dev libepoxy-dev python3-dev libsdl2-dev \
    qtbase5-dev qtchooser qtquickcontrols2-5-dev qtdeclarative5-dev qt5-qmake qtbase5-dev-tools \
    python3 linux-headers-generic \
    git
    
# Clone the FEX repository
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git /opt/FEX

# Create the build directory
RUN mkdir -p /opt/FEX/build
WORKDIR /opt/FEX/build

# Build FEX
ENV CC=clang-13
ENV CXX=clang++-13
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DENABLE_LTO=True -DBUILD_TESTS=False -G Ninja -DCMAKE_PREFIX_PATH=/usr/lib/qt5 ..
RUN ninja

# Stage 2: Steam Build
FROM ubuntu:22.04 AS steam_build

# Copy FEX binaries from the FEX Build stage
COPY --from=fex_build /opt/FEX/build/Bin/* /usr/bin/

# Install additional dependencies
RUN dpkg --add-architecture arm64
RUN apt-get update && \
    apt-get install -y \
    libcap-dev \
    libglfw3-dev \
    libepoxy-dev \
    sudo \
    nano \
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create steam user
RUN useradd -m -s /bin/bash steam

# Set up FEX root file system
USER steam
WORKDIR /home/steam/.fex-emu/RootFS
RUN curl -sqL "https://github.com/hmes98318/palworld-docker/raw/055f6759d6ced37ee23d4bdffdc30583d8eae751/RootFS/Ubuntu_22_04.tar.gz" -o Ubuntu_22_04.tar.gz && \
    tar -zxvf ./Ubuntu_22_04.tar.gz && \
    rm ./Ubuntu_22_04.tar.gz && \
    echo '{"Config":{"RootFS":"Ubuntu_22_04"}}' > ../Config.json

# Set up SteamCMD
WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    echo './steamcmd.sh +quit' > init_steam.sh && \
    chmod +x init_steam.sh && \
    FEXBash ./init_steam.sh && \
    mkdir -p ~/.steam/sdk64/ && \
    ln -s ~/steamcmd/linux64/steamclient.so ~/.steam/sdk64/steamclient.so && \
    rm init_steam.sh

#####################################
# Final Stage: Set up Soulmask Server
FROM steam_build

USER steam
WORKDIR /home/steam/steamcmd

ARG IMAGE_VERSION="latest"
ARG MAINTAINER="https://github.com/Method-ofcl/soulmask-server-arm64"

ARG CONTAINER_GID=10000
ARG CONTAINER_UID=10000

ENV DEBIAN_FRONTEND="noninteractive"
ENV SOULMASK_PATH="/home/steam/soulmask"
ENV STEAMCMD_PATH="/home/steam/steamcmd"
ENV STEAM_SDK64_PATH="~/.steam/sdk64"
ENV STEAM_APP_ID="3017300"

ENV GAME_PORT="27050"
ENV QUERY_PORT="27015"
ENV SERVER_SLOTS="20"
ENV LISTEN_ADDRESS="0.0.0.0"
ENV SERVER_LEVEL="Level01_Main"
ENV BACKUP=900
ENV SAVING=600
ENV SERVER_PASSWORD="PleaseChangeMe"
ENV ADMIN_PASSWORD="AdminPleaseChangeMe"

COPY entrypoint.sh /home/steam/entrypoint.sh

RUN mkdir -p ${SOULMASK_PATH} \
    && echo "${IMAGE_VERSION}" > /home/steam/image_version \
    && echo "${MAINTAINER}" > /home/steam/image_maintainer \
    && echo "${CONTAINER_UID}:${CONTAINER_GID}" > /home/steam/expected_filesystem_permissions

USER root
RUN chown -R steam:steam /home/steam/ && \
    chown steam:steam /home/steam/entrypoint.sh && \
    chmod +x /home/steam/entrypoint.sh
    
USER steam
 
WORKDIR /home/steam

ENTRYPOINT ["FEXBash", "/home/steam/entrypoint.sh"]