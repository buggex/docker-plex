FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PLEX_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

#Add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# global environment settings
ENV DEBIAN_FRONTEND="noninteractive" \
PLEX_DOWNLOAD="https://downloads.plex.tv/plex-media-server-new" \
PLEX_ARCH="amd64" \
PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/config/Library/Application Support" \
PLEX_MEDIA_SERVER_HOME="/usr/lib/plexmediaserver" \
PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="6" \
PLEX_MEDIA_SERVER_USER="abc" \
PLEX_MEDIA_SERVER_INFO_VENDOR="Docker" \
PLEX_MEDIA_SERVER_INFO_DEVICE="Docker Container (LinuxServer.io)"

RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	udev \
	unrar \
	wget \
	jq && \
 echo "**** Udevadm hack ****" && \
 mv /sbin/udevadm /sbin/udevadm.bak && \
 echo "exit 0" > /sbin/udevadm && \
 chmod +x /sbin/udevadm && \
 echo "**** install plex ****" && \
 if [ -z ${PLEX_RELEASE+x} ]; then \
 	PLEX_RELEASE=$(curl -sX GET 'https://plex.tv/api/downloads/5.json' \
	| jq -r '.computer.Linux.version'); \
 fi && \
 curl -o \
	/tmp/plexmediaserver.deb -L \
	"${PLEX_DOWNLOAD}/${PLEX_RELEASE}/debian/plexmediaserver_${PLEX_RELEASE}_${PLEX_ARCH}.deb" && \
 dpkg -i /tmp/plexmediaserver.deb && \
 mv /sbin/udevadm.bak /sbin/udevadm && \
 echo "**** ensure abc user's home folder is /app ****" && \
 usermod -d /app abc && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
	/etc/default/plexmediaserver \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

# update transdocer
RUN \
 echo "**** updating transdocer ****" && \
 mv "/usr/lib/plexmediaserver/Plex Transcoder" "/usr/lib/plexmediaserver/Plex Transcoder Default" && \
 cp "/plex_files/Plex Transcoder" "/usr/lib/plexmediaserver/" && \
 chmod +x "/usr/lib/plexmediaserver/Plex Transcoder"

# ports and volumes
EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config
