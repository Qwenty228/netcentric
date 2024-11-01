import socket
from src.handlers.client_handler import ClientHandler


class Server:
    """
    Server class to handle multiple clients in a Battleship game.

    This class manages the server-side logic for accepting connections from clients,
    creating a new ClientHandler thread for each client, and maintaining a maximum
    number of clients.
    """
    MAX_CLIENTS = 2  # Maximum number of clients that can connect to the server

    def __init__(self, port: int, host="127.0.0.1") -> None:
        """
        Initializes the server with the provided host and port.

        Args:
            port (int): The port number for the server to listen on.
            host (str): The host IP address where the server will bind. Default is "127.0.0.1".

        Attributes:
            socket (socket.socket): The server's TCP socket.
        """
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Create a TCP socket
        self.socket.bind((host, port))  # Bind the server to the given host and port
        self.socket.listen(Server.MAX_CLIENTS)  # Listen for a maximum of MAX_CLIENTS connections
        self.socket.settimeout(1)  # Set a timeout to allow for interruptible listening

    def start(self):
        """
        Starts the server and listens for incoming client connections.

        Each client is assigned a unique ID ("A" for the first client and "B" for the second).
        A ClientHandler is created for each connected client, and the game begins when both clients are connected.
        """
        client_id = "A"  # First player will be assigned "A"
        while True:
            try:
                # Wait for a new client connection
                conn, addr = self.socket.accept()
                # Create and start a new thread to handle the client
                ClientHandler(conn, client_id).start()
                print(f"Connected to: {addr} as {client_id}")
                # After the first client ("A"), assign the next client as "B"
                client_id = "B"
            except socket.timeout:
                # Timeout occurs every second, allowing the server to check for other events
                continue
           