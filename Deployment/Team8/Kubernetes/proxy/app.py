import os
import requests
from flask import Flask, Response

app = Flask(__name__)

KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://keycloak-service:8180")
REALM = os.environ.get("REALM", "boardgame-platform")
CLIENT_ID = os.environ.get("CLIENT_ID", "platform-service-client")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")
BACKEND_URL = os.environ.get("BACKEND_URL", "http://platform-backend-service:8080")

@app.route("/store/games", methods=["GET"])
def store_games():
    # Return stub data since backend requires custom SecurityConfig changes
    return Response('[{"name":"Tic-Tac-Toe","genre":"Strategy","description":"Classic game","imageUrl":"/images/tictactoe.png","gameUrl":"/play/tictactoe","isPurchasable":false,"price":0.0},{"name":"Chess","genre":"Strategy","description":"Classic chess","imageUrl":"/images/chess.png","gameUrl":"/play/chess","isPurchasable":true,"price":9.99},{"name":"Blokus","genre":"Strategy","description":"Territory game","imageUrl":"/images/blokus.png","gameUrl":"/play/blokus","isPurchasable":true,"price":14.99}]', status=200, content_type="application/json")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
