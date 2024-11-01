import socket
from src.core.server import Server

host = socket.gethostbyname(socket.gethostname())
host = "127.0.0.1"
port = 10000
server = Server(port, host=host)

print("Host:", host, "Port:", port)
server.start()
