# Base image with just PostGIS/PLV8
FROM postgres:14 AS postgis

# PostGIS installation
# http://trac.osgeo.org/postgis/wiki/UsersWikiPostGIS23UbuntuPGSQL96Apt
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" >> /etc/apt/sources.list' \
  && buildDependencies="wget" \
  && apt-get update && apt-get -y --no-install-recommends install ${buildDependencies} \
  && wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - \
  && apt-get install -y --no-install-recommends postgresql-$PG_MAJOR-postgis-3 postgresql-contrib-$PG_MAJOR postgresql-$PG_MAJOR-postgis-3-scripts \
  && apt-get remove -y wget && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
# COPY ./update-postgis.sh /usr/local/bin

# PLV8 Installation
FROM postgis AS plv8
ENV PLV8_VERSION='2.3.15' \
    PLV8_SHASUM="8a05f9d609bb79e47b91ebc03ea63b3f7826fa421a0ee8221ee21581d68cb5ba"

RUN buildDependencies="build-essential \
    ca-certificates \
    curl \
    git-core \
    python \
    gpp \
    cpp \
    pkg-config \
    apt-transport-https \
    cmake \
    libc++-dev \
    libc++abi-dev \
    postgresql-server-dev-$PG_MAJOR" \
  && runtimeDependencies="libc++1 \
    libtinfo5 \
    libc++abi1" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ${buildDependencies} ${runtimeDependencies} \
  && mkdir -p /tmp/build \
  && curl -o /tmp/build/v$PLV8_VERSION.tar.gz -SL "https://github.com/plv8/plv8/archive/v${PLV8_VERSION}.tar.gz" \
  && cd /tmp/build \
  && echo $PLV8_SHASUM v$PLV8_VERSION.tar.gz | sha256sum -c \
  && tar -xzf /tmp/build/v$PLV8_VERSION.tar.gz -C /tmp/build/ \
  && cd /tmp/build/plv8-$PLV8_VERSION \
  && make static \
  && make install \
  && strip /usr/lib/postgresql/${PG_MAJOR}/lib/plv8-${PLV8_VERSION}.so \
  && rm -rf /root/.vpython_cipd_cache /root/.vpython-roo

# CLEANUP
RUN apt-get clean \
  && apt-get remove -y ${buildDependencies} \
  && apt-get autoremove -y \
  && rm -rf /tmp/build /var/lib/apt/lists/*

# ==============================================================================
# Testing image where we build pg_tap
FROM plv8 as testing

ENV PGTAP_VERSION v1.2.0

RUN buildDependencies="make git-core patch postgresql-server-dev-$PG_MAJOR" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ${buildDependencies} perl \
  && cpan TAP::Parser::SourceHandler::pgTAP \
  && git clone https://github.com/theory/pgtap \
  && cd pgtap \
  && git checkout ${PGTAP_VERSION} \
  && make \
  && make install

# CLEANUP
RUN apt-get clean \
  && apt-get remove -y ${buildDependencies} \
  && apt-get autoremove -y \
  && rm -rf /tmp/build /var/lib/apt/lists/*
