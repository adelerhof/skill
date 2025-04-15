# Use the official lightweight Alpine image
# Consider using a specific python base image like python:3.11-alpine for potentially easier setup
FROM alpine:3.21

# Install Python and necessary dependencies
# Combine RUN commands to reduce layers
RUN apk add --no-cache python3 py3-pip && \
    apk update && \
    apk upgrade --no-cache --available && sync # --no-cache for upgrade too

COPY /health_check/requirements.txt requirements.txt
# Consider creating a virtual environment
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# Set the working directory in the container
WORKDIR /app

# Copy the Python script into the container
COPY /health_check/api.py .

# Expose the default port for documentation purposes
# The actual port used depends on the PORT env var passed at runtime
EXPOSE 5000

# Run the Python script when the container starts
# The script now reads the PORT env var internally
CMD ["python3", "api.py"]