PACKAGE_NAME=statsd-aggregator
PACKAGE_VERSION=0.0.2
PACKAGE_DESCRIPTION="Local aggregator for statsd metrics"

IMAGE_REVISION?=v0.0

# Skip registry based image naming pattern for local builds
LOCALBUILD?=0
ifeq ($(LOCALBUILD), 1)
	TARGET_TAG?=$(PACKAGE_NAME)
else
	TARGET_TAG?=$(PACKAGE_NAME)
endif

# Check if session is interactive shell, used for dind exec
INTERACTIVE:=$(shell [ -t 0 ] && echo 1 || echo 0)
TTY=
ifeq ($(INTERACTIVE), 1)
	TTY=-t
endif

# By default builds are --no-cahe unless USE_DOCKER_CACHE=1 passed
USE_DOCKER_CACHE?=0
ifeq ($(USE_DOCKER_CACHE), 1)
	DOCKERCACHE=
else
	DOCKERCACHE=--no-cache
endif


# Some actions executed on the copy of the workdir to avoid any
# access issues and to provide ability to edit files safely on the fly
TEMP_DIR:=$(shell mktemp -d /tmp/$(PACKAGE_NAME).XXXXXX)

.PHONY: all test clean

all: bin
bin:
	gcc -Wall -O2 -I/usr/include/libev -o statsd-aggregator statsd-aggregator.c -lev -lpthread -lconfig++

clean:
	rm -rf statsd-aggregator build

pkg: bin
	mkdir build
	cp -r etc build/
	cp -r usr build/
	mkdir build/usr/bin/
	cp statsd-aggregator build/usr/bin/
	cd build && \
	fpm --deb-no-default-config-files --deb-user root --deb-group root -d libev-dev --description $(PKG_DESCRIPTION) -s dir -t deb -v $(PKG_VERSION) -n $(PKG_NAME) `find . -type f` && \
	rm -rf `ls|grep -v deb$$`

test: bin
	cd test && ./run-all-tests.sh

install: bin
	cp statsd-aggregator /usr/bin
	mkdir -p /usr/share/statsd-aggregator && cp usr/share/statsd-aggregator/statsd-aggregator.conf.sample /usr/share/statsd-aggregator
	cp etc/init.d/statsd-aggregator /etc/init.d/

copy-src:
	# Copy ./ contents to a temp dir
	cp -r ./* $(TEMP_DIR)

build-image: copy-src ## Build the image

	docker build $(DOCKERCACHE) --rm --pull $(TTY) $(TARGET_TAG):$(IMAGE_REVISION) \
		$(TEMP_DIR)

	rm -rf $(TEMP_DIR)
