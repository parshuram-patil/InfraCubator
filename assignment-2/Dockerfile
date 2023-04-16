FROM golang:alpine
COPY main.go /go/src/app/
WORKDIR /go/src/app/
RUN go mod init
RUN go get -d -v ./...
RUN go install -v ./...
EXPOSE 8080
CMD ["go", "run", "main.go"]