FROM lsiobase/alpine.armhf
MAINTAINER zaggash

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# build prerequisite packages
ENV \
	# set python to use utf-8 rather than ascii.
	PYTHONIOENCODING="UTF-8"
RUN \
	# install base pkgs
	apk add --no-cache \
		python3 \
		ca-certificates \
		eudev-libs \
		curl \
		wget \
		nmap \
		net-tools && \
	
	# install dev deps pkgs
	apk add --no-cache --virtual=build-dependencies \
		git \
		mariadb-dev \
		python3-dev \
		linux-headers \
		libffi-dev \
		openssl-dev \
		eudev-dev \
		glib-dev \
		make \
		gcc \
		g++ && \
	
	# install pip dev pkgs
	pip3 --no-cache-dir install --upgrade \
		docutils \
		cython && \

	# install base pip pkgs
	pip3 --no-cache-dir install --upgrade \
		pip \
		#uvloop \ ## Remove since there is a bug while restart app with the services API
		mysqlclient && \

	# build & install python-openzwave
	mkdir -p /app/openzwave && \
	git -C /tmp/ clone -q  https://github.com/OpenZWave/python-openzwave.git && \
	cd /tmp/python-openzwave && \
	PYTHON_EXEC=`which python3` make build && \
	PYTHON_EXEC=`which python3` make install && \
	cp -Rp ./openzwave/config /app/openzwave/ && \

	# install home assistant
	usermod -G dialout abc && \
        pip3 --no-cache-dir install --upgrade \
                homeassistant && \
	# install deps
	pip3 --no-cache-dir install \
		-r  https://raw.githubusercontent.com/home-assistant/home-assistant/master/requirements_all.txt && \

	# cleanup
        pip3 --no-cache-dir uninstall -y \
                docutils \
                cython && \
        apk del --purge \
                build-dependencies && \
        rm -rf /var/cache/apk/* /tmp/*

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
EXPOSE 8123
