NAME = demo
VENDOR = foo
REGISTRY = dev.seagullsailors.com:5000

# one stop

.PHONY: build
build: go.build docker.build

.PHONY: deploy
deploy: docker.push docker.pull

.PHONY: clean
clean:
	- rm -f $(NAME)_amd64.exe
	- rm -f $(NAME)_arm64.exe
	- docker rmi ${REGISTRY}/${VENDOR}/${NAME}:amd64
	- docker rmi ${REGISTRY}/${VENDOR}/${NAME}:arm64
	- docker rmi ${REGISTRY}/${VENDOR}/${NAME}:latest
	- docker rmi $(shell docker images --filter="dangling=true" --format="{{.ID}}")

# go lang

.PHONY: go.build
go.build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $(NAME)_amd64.exe ./src/main.go
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o $(NAME)_arm64.exe ./src/main.go

# docker

.PHONY: docker.build
docker.build:
	docker build -t $(REGISTRY)/$(VENDOR)/$(NAME):amd64 --no-cache --build-arg EXE="$(NAME)_amd64.exe" .
	docker build -t $(REGISTRY)/$(VENDOR)/$(NAME):arm64 --no-cache --build-arg EXE="$(NAME)_arm64.exe" .

.PHONY: docker.push
docker.push:
	@ echo ***** NEEDS SIGNIN TO DOCKER REGISTER IF NEEDED *****
	docker push ${REGISTRY}/${VENDOR}/${NAME}:amd64
	docker push ${REGISTRY}/${VENDOR}/${NAME}:arm64
	docker manifest create \
		${REGISTRY}/${VENDOR}/${NAME}:latest \
		--amend ${REGISTRY}/${VENDOR}/${NAME}:amd64 \
		--amend ${REGISTRY}/${VENDOR}/${NAME}:arm64
	docker manifest annotate ${REGISTRY}/${VENDOR}/${NAME}:latest ${REGISTRY}/${VENDOR}/${NAME}:arm64 --variant v8 --arch arm64
	docker manifest push --purge ${REGISTRY}/${VENDOR}/${NAME}:latest
	docker pull ${REGISTRY}/${VENDOR}/${NAME}:latest

.PHONY: docker.pull
docker.pull:
	docker pull ${REGISTRY}/${VENDOR}/${NAME}

.PHONY: docker.login
docker.login:
	docker login $(REGISTRY)

.PHONY: docker.run
docker.run:
	docker run \
		-p "8080:8080" \
		--name $(NAME) \
		--rm \
		${REGISTRY}/${VENDOR}/${NAME}:latest
