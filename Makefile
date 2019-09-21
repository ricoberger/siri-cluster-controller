BRANCH       ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILDTIME    ?= $(shell date '+%Y-%m-%d@%H:%M:%S')
BUILDUSER    ?= $(shell id -un)
DOCKER_IMAGE ?= siri-cluster-controller
REPO         ?= github.com/ricoberger/siri-cluster-controller
REVISION     ?= $(shell git rev-parse HEAD)
VERSION      ?= 1.0.0#$(shell git describe --tags)

.PHONY: build build-linux-amd64 clean docker-build docker-publish release release-major release-minor release-patch

build:
	go build -ldflags "-X ${REPO}/pkg/version.Version=${VERSION} \
		-X ${REPO}/pkg/version.Revision=${REVISION} \
		-X ${REPO}/pkg/version.Branch=${BRANCH} \
		-X ${REPO}/pkg/version.BuildUser=${BUILDUSER} \
		-X ${REPO}/pkg/version.BuildDate=${BUILDTIME}" \
		-o ./bin/siri-cluster-controller ./cmd/controller

build-linux-amd64:
	CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -a -installsuffix cgo -ldflags "-X ${REPO}/pkg/version.Version=${VERSION} \
		-X ${REPO}/pkg/version.Revision=${REVISION} \
		-X ${REPO}/pkg/version.Branch=${BRANCH} \
		-X ${REPO}/pkg/version.BuildUser=${BUILDUSER} \
		-X ${REPO}/pkg/version.BuildDate=${BUILDTIME}" \
		-o ./bin/siri-cluster-controller-linux-amd64 ./cmd/controller

clean:
	rm -rf ./bin

docker-build: build-linux-amd64
	docker build -f cmd/controller/Dockerfile -t "$(DOCKER_IMAGE):${VERSION}" --build-arg REVISION=${REVISION} --build-arg VERSION=${VERSION} .

docker-publish: docker-build
	docker tag $(DOCKER_IMAGE):${VERSION} ricoberger/$(DOCKER_IMAGE):${VERSION}
	docker tag $(DOCKER_IMAGE):${VERSION} docker.pkg.${REPO}/$(DOCKER_IMAGE):${VERSION}
	docker push ricoberger/$(DOCKER_IMAGE):${VERSION}
	docker push docker.pkg.${REPO}/$(DOCKER_IMAGE):${VERSION}

release: clean docker-publish

release-major:
	$(eval MAJORVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1+1".0.0"}'))
	git checkout master
	git pull
	git tag -a $(MAJORVERSION) -m 'release $(MAJORVERSION)'
	git push origin --tags

release-minor:
	$(eval MINORVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2+1".0"}'))
	git checkout master
	git pull
	git tag -a $(MINORVERSION) -m 'release $(MINORVERSION)'
	git push origin --tags

release-patch:
	$(eval PATCHVERSION=$(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2"."$$3+1}'))
	git checkout master
	git pull
	git tag -a $(PATCHVERSION) -m 'release $(PATCHVERSION)'
	git push origin --tags
