# Use the official lightweight Alpine image
# Consider using a specific python base image like python:3.11-alpine for potentially easier setup
FROM alpine:3.21

# Install Python and necessary dependencies
# Combine RUN commands to reduce layers
RUN apk add --no-cache python3=3.12.10-r0 py3-pip=24.3.1-r0 && \
    apk update && \
    apk upgrade --no-cache --available && sync
WORKDIR /build
# Copy the requirements file into the container
COPY /health_check/requirements.txt /build/requirements.txt
# Consider creating a virtual environment
RUN pip install --no-cache-dir -r /build/requirements.txt --break-system-packages

# Set the working directory in the container
WORKDIR /app

# Copy the Python script into the container
COPY /health_check/api.py .
COPY /health_check/health_check.py .

# Create a group and user
RUN addgroup -S skill_group && adduser -S skill_user -G skill_group

# Switch to the new user
USER skill_user

# Expose the default port for documentation purposes
# The actual port used depends on the PORT env var passed at runtime
EXPOSE 5000

# Add health check for the backend using Python script
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD python3 health_check.py

# Run the Python script when the container starts
# The script now reads the PORT env var internally
CMD ["python3", "api.py"]