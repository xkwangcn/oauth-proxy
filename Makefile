GOFLAGS :=
IMAGE_REPOSITORY_NAME ?= openshift

build:
	go build -mod=vendor $(GOFLAGS) .
.PHONY: build

images:
	imagebuilder -f Dockerfile -t $(IMAGE_REPOSITORY_NAME)/oauth-proxy .
.PHONY: images

clean:
	$(RM) ./oauth-proxy
.PHONY: clean
