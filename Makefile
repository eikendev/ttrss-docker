IMAGE := ttrss

.PHONY: build
build:
	podman build \
		-t \
		local/${IMAGE} .

.PHONY: run
run:
	podman run \
		-ti \
		-v ./volume/configuration:/volume/configuration \
		-p 9000:8080 \
		--rm \
		--security-opt label=disable \
		--name=${IMAGE} \
		local/${IMAGE}
