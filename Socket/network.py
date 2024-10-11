import socket
import json


class Network:
    def __init__(self,  connection_message: dict = {}) -> None:
        # AF_INET = IPv4, SOCK_STREAM = TCP
        self.client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.addr = self.server, self.port = 'localhost', 55555
        data = self.connect(connection_message)
        self.client_id = data["client"]
        self.ready = data['body']

    def connect(self, connection_message: dict):
        self.client.connect(self.addr)
        server_reply = json.loads(self.client.recv(2048))
        self.send(connection_message)
        return server_reply

    def send(self, data: dict):
        try:
            self.client.send(json.dumps(data).encode("utf-8"))
            return json.loads(self.client.recv(2048))
        except socket.error as e:
            print(str(e))

    def receive(self):
        try:
            return self.client.recv(2048)
        except socket.error as e:
            print(str(e))
