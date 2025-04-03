# builder image
FROM docker.io/library/golang:1.24-alpine3.21 AS builder
RUN mkdir /build
ADD *.go /build/
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux GO111MODULE='auto' go build -a -o skill .


# generate clean, final image for end users
FROM alpine:3
RUN apk --no-cache add ca-certificates
RUN apk update
RUN apk upgrade --available && sync
COPY --from=builder /build/skill .
COPY White_Persian_Cat.jpg .
COPY index.html .

# executable
ENTRYPOINT [ "./skill" ]

# http server listens on port 80.
EXPOSE 80