.PHONY: clean build deploy

clean:
	rm -rf ./bin

build: clean
	export GO111MODULE=on
	GOOS=linux GOARCH=amd64 go build -o bin/hello-world hello-world/main.go
	zip bin/hello-world.zip bin/hello-world

deploy: build
	terraform apply

destroy:
	terraform destroy
