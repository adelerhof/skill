# builder image
FROM docker.io/library/golang:1.24-alpine3.21 AS builder

# Build the main application
WORKDIR /build/app
# Assumes main app source is in the root of the build context
COPY kitty.go .
RUN go mod init kitty # Initialize module for main app
RUN go mod tidy         # Tidy main app module
RUN CGO_ENABLED=0 GOOS=linux GO111MODULE='auto' go build -a -o skill .

# Build the health checker utility
WORKDIR /build/healthchecker
# Copy the healthchecker source code
COPY healthchecker/healthchecker.go .
RUN go mod init healthchecker # Initialize module named 'healthchecker'
RUN go mod tidy             # Download dependencies (if any) and clean up go.mod/go.sum
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o healthchecker . # Build the healthchecker


# generate clean, final image for end users
FROM alpine:3

# Install only necessary certificates, no curl needed now
RUN apk --no-cache add ca-certificates && \
    apk update && \
    apk upgrade --available && sync

# Copy the main application binary from the builder stage
COPY --from=builder /build/app/skill /skill

# Copy the health checker binary from the builder stage
COPY --from=builder /build/healthchecker/healthchecker /healthchecker
WORKDIR /www
# Copy static assets
COPY White_Persian_Cat.jpg /www
COPY index.html /www


# Create a group and user
RUN addgroup -S skill_group && adduser -S skill_user -G skill_group

# Switch to the new user
USER skill_user

# executable - Using absolute path for clarity
ENTRYPOINT [ "/skill" ]

# http server listens on port 4000.
EXPOSE 4000

# Health check instruction using the Go utility
# Note: Using JSON array format for CMD is recommended
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/healthchecker"]