.PHONY: deps clean build

deps:
	go get -u ./...

clean: 
	rm -rf ./hello-world/hello-world
	
build:
	GOOS=linux GOARCH=amd64 go build -o hello-world/hello-world ./hello-world

deploy:
	sam deploy --guided

destroy:
	aws cloudformation delete-stack --stack-name jose-sam-example --region us-east-1
