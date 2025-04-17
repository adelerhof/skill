import os
from flask import Flask, jsonify

app = Flask(__name__)
PORT = int(os.getenv("PORT", "5000"))
FLASK_DEBUG = os.getenv("FLASK_DEBUG", "0") == "1" # Read debug flag

@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify(status="ok")

# Add a route designed to cause an error
@app.route("/api/error", methods=["GET"])
def cause_error():
    result = 1 / 0 # This will raise a ZeroDivisionError
    return jsonify(message="This won't be reached")

if __name__ == "__main__":
    print(f" * Starting Flask app on port {PORT}")
    # Pass debug flag explicitly if desired, though FLASK_DEBUG=1 usually suffices
    app.run(host="0.0.0.0", port=PORT, debug=FLASK_DEBUG)