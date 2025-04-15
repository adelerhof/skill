# Python Flask Web Server with Health Check

This document describes a simple web server built using the Python Flask framework. The server includes a basic health check endpoint.

## Goal

To create a web server that:
1.  Runs using Python and the Flask library.
2.  Responds to GET requests on the path `/api/health`.
3.  Returns a JSON response `{"status": "ok"}` with an HTTP `200 OK` status code for the health check.

## Prerequisites

Before running the code, you need to have Python installed. You also need to install the Flask library. You can install it using pip:

```bash
pip install Flask

###

Okay, let's modify the Python script and Dockerfile to meet the requirement of using a .env file to configure the port, and then construct the appropriate Podman command.
1. Modify the Python Script (api.py)
The script needs to read the port from an environment variable instead of having it hardcoded. We'll use the os module for this.

Python


from flask import Flask, jsonify
import os # Import the os module

app = Flask(__name__)

# Read the PORT environment variable. Default to 5000 if not set.
# os.getenv returns a string, so convert it to an integer for Flask.
PORT = int(os.getenv('PORT', '5000'))

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify(status="ok")

if __name__ == '__main__':
    print(f" * Starting Flask app on port {PORT}") # Optional: Confirmation log
    app.run(host='0.0.0.0', port=PORT)


Key Changes:
import os: Added to access environment variables.
PORT = int(os.getenv('PORT', '5000')): This line now reads the environment variable named PORT. If PORT is not found in the environment, it defaults to the string '5000'. The result is then converted to an integer using int(), which is required by app.run().
2. Modify the Dockerfile
The EXPOSE instruction in a Dockerfile is primarily documentation and helps tools map ports automatically. It doesn't force the application inside to use that port. Since our application now dynamically reads the PORT environment variable at runtime, the EXPOSE instruction using a build-time variable (${PORT:-5000}) isn't strictly necessary for runtime configuration.
It's often clearer to just EXPOSE the default port the application would use if the environment variable isn't set. The actual port mapping happens in the podman run command.

Dockerfile


# Use the official lightweight Alpine image
# Consider using a specific python base image like python:3.11-alpine for potentially easier setup
FROM alpine:3.21 # Using the specified base image

# Install Python and necessary dependencies
# Combine RUN commands to reduce layers
RUN apk add --no-cache python3 py3-pip && \
    apk update && \
    apk upgrade --no-cache --available && sync # --no-cache for upgrade too

COPY requirements.txt requirements.txt
# Consider creating a virtual environment
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# Set the working directory in the container
WORKDIR /app

# Copy the Python script into the container
COPY api.py .

# Expose the default port for documentation purposes
# The actual port used depends on the PORT env var passed at runtime
EXPOSE 5000

# Run the Python script when the container starts
# The script now reads the PORT env var internally
CMD ["python3", "api.py"]


Key Changes:
Consolidated some RUN commands. Added --no-cache to apk upgrade.
Changed EXPOSE ${PORT:-5000} to EXPOSE 5000. This simply documents the default port. The actual port used will be determined by the PORT environment variable passed during podman run and read by the Python script.
3. Create the .env file
Create a file named .env in the same directory as your Dockerfile and api.py. Define the PORT variable (and any others you might need, like DEBUG flags).

Code snippet


# Configuration for the health check app
PORT=8080
# Example of another variable
FLASK_DEBUG=0


(Change 8080 to your desired port)
4. Create requirements.txt
Make sure you have a requirements.txt file listing the necessary Python packages.

Code snippet


Flask>=2.0


5. Build the Container Image
Navigate to the directory containing your Dockerfile, api.py, .env, and requirements.txt. Build the image using Podman:

Bash


podman build -t my-healthcheck-app .


(Replace my-healthcheck-app with your preferred image tag)
6. Run the Container with Podman using the .env file
Now, run the container using the --env-file option to inject the variables from .env into the container's environment. We also need to map the host port to the container port specified in the .env file.

Bash


# Read the PORT value from .env to use for host port mapping
HOST_PORT=$(grep '^PORT=' .env | cut -d= -f2)

# Run the container
podman run -d --name healthcheck-api \
  --env-file .env \
  -p ${HOST_PORT}:${HOST_PORT} \
  my-healthcheck-app


Explanation of the podman run command:
podman run: Starts a new container.
-d: Runs the container in detached mode (in the background).
--name healthcheck-api: Assigns a name to the container for easier management.
--env-file .env: Reads the .env file and sets the environment variables defined within it (e.g., PORT=8080) inside the container. The Python script will pick this up via os.getenv('PORT').
-p ${HOST_PORT}:${HOST_PORT}: Maps the port on your host machine to the port inside the container.
The first ${HOST_PORT}: The port number on your host machine. We retrieve this value directly from the .env file using grep and cut just before running the command.
The second ${HOST_PORT}: The port number inside the container that the Flask application will listen on (because it reads the PORT variable set by --env-file). Using the same variable ensures the mapping targets the correct dynamic port inside the container.
my-healthcheck-app: The name of the image you built.
Now, your Flask application inside the container will listen on the port specified in the .env file (e.g., 8080), and Podman will map your host's port 8080 to the container's port 8080. You can access the health check at http://localhost:8080/api/health (replace 8080 if you used a different port in .env).


That's great! Setting FLASK_DEBUG=1 in your .env file correctly activates Flask's built-in development server features when the container starts.
Here's how those features work, particularly the debugger:
Auto-Reloader (* Restarting with stat):
Flask monitors your Python code files for changes.
When it detects a saved change (using the stat polling method in this case), it automatically restarts the Flask application inside the container.
Important Note: For this to be useful during development where you edit files on your host machine, you need to mount your local source code directory into the container when you run it (using podman run -v ...). Otherwise, the reloader only sees the files copied during the podman build step and won't react to your local edits.
Interactive Debugger (* Debugger is active!):
This is the most powerful feature of Flask's debug mode.
When it Appears: The interactive debugger doesn't show up immediately. It only activates in your browser when your Flask application encounters an unhandled error (an exception that isn't caught by a try...except block) while processing a request.
What it Does: Instead of showing a generic "Internal Server Error" page, Flask displays a detailed traceback of the error directly in the browser.
Interactive Console: The magic happens here. Within that browser traceback, you can click on a small console icon next to any line in the code stack. This opens an interactive Python console running within the context of that specific point in your code execution when the error occurred. You can inspect variables, run commands, and figure out what went wrong.
Debugger PIN (* Debugger PIN: <number>):
Security: Because the interactive debugger allows executing arbitrary Python code on your server (albeit within the container), it's protected by a PIN.
How to Use: The first time you try to open the interactive console in the browser traceback during a session, Flask will prompt you for this PIN.
Where to Find It: The PIN is printed to the standard output/error logs of the Flask application when it starts up in debug mode. Since you are running your container detached (-d), you need to view the container's logs to get the PIN.
How to Use and Test the Debugger:
View Logs to Get PIN: Find the PIN printed when the container started:
Bash
podman logs healthcheck-api

(Replace healthcheck-api if you used a different container name). Look for the line * Debugger PIN: ...
Trigger an Error (Example): Your /api/health route is too simple to cause an error. Let's temporarily add a route that will cause an error to see the debugger in action.
Modify api.py (on your host machine):
Python
from flask import Flask, jsonify
import os

app = Flask(__name__)
PORT = int(os.getenv('PORT', '5000'))
FLASK_DEBUG = os.getenv('FLASK_DEBUG', '0') == '1' # Read debug flag

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify(status="ok")

# Add a route designed to cause an error
@app.route('/api/error', methods=['GET'])
def cause_error():
    result = 1 / 0 # This will raise a ZeroDivisionError
    return jsonify(message="This won't be reached")

if __name__ == '__main__':
    print(f" * Starting Flask app on port {PORT}")
    # Pass debug flag explicitly if desired, though FLASK_DEBUG=1 usually suffices
    app.run(host='0.0.0.0', port=PORT, debug=FLASK_DEBUG)


(Optional but Recommended for Auto-Reload): Mount Source Code: Stop the current container (podman stop healthcheck-api && podman rm healthcheck-api) and re-run it, mounting your current directory (. which contains api.py) into the container's /app directory.
Bash
# Read the PORT value from .env
HOST_PORT=$(grep '^PORT=' .env | cut -d= -f2)

# Run with volume mount
podman run -d --name healthcheck-api \
  --env-file .env \
  -p ${HOST_PORT}:${HOST_PORT} \
  -v .:/app \
  my-healthcheck-app

(Note: If you didn't modify the Dockerfile to install packages differently, changes to requirements.txt would still need a rebuild. But changes to .py files will now be reflected inside the container and trigger the reloader).
If you didn't mount the code, you'll need to rebuild the image (podman build -t my-healthcheck-app .) and then run it again as before.
Access the Error Route: Open your browser and go to the error-causing URL (using the port from your .env file):
http://localhost:8080/api/error (if PORT=8080)
Use the Debugger:
You should see the Flask traceback page in your browser instead of a simple error.
Hover over lines of code in the traceback; a console icon should appear.
Click the console icon.
Enter the Debugger PIN you got from podman logs.
You can now type Python code in the console (e.g., inspect local variables shown in the traceback) and press Enter to execute it in the context of that error.
Important Security Warning: Never run a Flask application with FLASK_DEBUG=1 (or app.run(debug=True)) in a production environment. The interactive debugger is a major security risk as it allows arbitrary code execution. Ensure FLASK_DEBUG is set to 0 or unset for production deployments.
