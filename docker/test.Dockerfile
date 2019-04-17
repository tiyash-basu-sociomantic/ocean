# Image for staging files

FROM sociomantictsunami/dlang:xenial-v4 as stage

ARG dmdver=2.078.3*-xenial

RUN apt-get update && \
    apt-get install -y --allow-downgrades \
    dmd-transitional=$dmdver \
    d1to2fix=0.10.* \
    libglib2.0-dev \
    libpcre3-dev \
    libxml2-dev \
    libxslt-dev \
    libebtree6-dev \
    liblzo2-dev \
    libreadline-dev \
    libbz2-dev \
    zlib1g-dev \
    libssl-dev \
    libgcrypt11-dev \
    libgpg-error-dev

WORKDIR /ocean
RUN ["chown", "cachalot", "."]

COPY --chown=cachalot:root . .

USER cachalot

# Image for testing the d1 version

FROM stage as d1tester

CMD make -rkBj4 test; \
    make -rkBj4 test F=production

# Image for testing the d2 version

FROM stage as d2tester

RUN ["make", "-j4", "d2conv"]

CMD make -rkBj4 test DVER=2; \
    make -rkBj4 test F=production DVER=2

# Image for building docs

FROM d2tester as d2docs

RUN ["make", "doc"]

# Apache image for seeing docs in browser

FROM httpd:latest as docserver

WORKDIR /usr/local/apache2/htdocs/

COPY --from=d2docs /ocean/build/doc ./
