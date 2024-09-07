import json
from threading import Thread
from typing import Iterable
import socket
import random

CLIENT_IDENTIFIERS = random.choice(("AB", "BA"))

class LogicHandler:
    """
    I cannot find the repository for some reason so I am going to write a shittier version of it
    It probably doesnt even work the same way but ehh
    ***IT WORKS ON MY MACHINE***"""
    gamestate = {}
    def __init__(self, client: 'ClientHandler') -> None:
        self.client = client
        LogicHandler.gamestate[client] = {"ships": [], "rendering_screen": ["0"]*64}


    def game_start(self, ships: Iterable[int]) -> None:
        LogicHandler.gamestate[self.client]["ships"] = ships

    def process_attack(self, attack_positions: list[int]) -> dict:
        gamestate = LogicHandler.gamestate[self.client]["rendering_screen"]
        other_client = next(client for client in LogicHandler.gamestate if client != self.client)
        other_player_ships = LogicHandler.gamestate[other_client]["ships"]
        for pos in attack_positions:
            if pos in other_player_ships:
                gamestate[pos] = "1"
            else:
                gamestate[pos] = "-1"
        return {"header": "game", "body": gamestate}



            
class ClientHandler(Thread):
    """
    ClientHandler class to handle multiple clients
    """
    all_clients: list['ClientHandler'] = []
    game_round = 1
    def __init__(self, conn: socket.socket) -> None:
        super().__init__(daemon=True)
        ClientHandler.all_clients.append(self)
        self.client_id = CLIENT_IDENTIFIERS[len(ClientHandler.all_clients) % 2 - 1]
        self.name = f"Client-{self.client_id}"
        self.conn = conn
        
        self.logic_handler = LogicHandler(self)
 
    def run(self):
        # established connection
        for client in ClientHandler.all_clients:
            client.conn.sendall(json.dumps({"header": "connection", "body": len(ClientHandler.all_clients) == 2,  "client": self.client_id}).encode("utf-8"))

        while True:
            try:
                data = self.conn.recv(2048).decode("utf-8")
                if not data:
                    break

                print(self.name, "Received:",  fr'{data}')
                try:
                    data = json.loads(data)
                except json.JSONDecodeError:
                    continue

                reply = {}
                if (data["header"] == "init"):        # if client is initializing
                    self.logic_handler.game_start(list(map(int, data["body"])))
                    if (username := data.get("client")):
                        self.name = f"Client: {username}"


                elif (data["header"] == "game"):      # gmae loop
                    if data.get('body') == "round":               # start of both round, both clients ask for current round
                        reply = {"header": "game", "body": ClientHandler.game_round}
                    else:
                        # get attack position
                        target_pos = list(map(int, data["body"]))
                        reply = self.logic_handler.process_attack(target_pos)
                        # reply to client with rendering screen (hit or miss list of game state)
                        for client in ClientHandler.all_clients:
                            if client.conn != self.conn:
                                client.conn.sendall(json.dumps(reply).encode("utf-8"))
                        
                        ClientHandler.game_round += 1                         # increment round, current round ended

                print(reply)
                self.conn.sendall(json.dumps(reply).encode("utf-8"))

            except socket.error as e:
                print(e)
                break
        print(f"Connection with {self.name} closed")
        self.conn.close()
        ClientHandler.all_clients.remove(self)

            
class Server:
    """
    Server class to handle multiple clients
    """
    MAX_CLIENTS = 2

    # localhost address is 127.0.0.1, <string localhost is fine for python socket>
    def __init__(self, port: int, host="127.0.0.1") -> None:
        self.socket = socket.socket(
            socket.AF_INET, socket.SOCK_STREAM)  # TCP socket
        self.socket.bind((host, port))
        self.socket.listen(Server.MAX_CLIENTS)
        self.socket.settimeout(1)       # allow for timeout

    def start(self):
        while True:
            try:
                conn, addr = self.socket.accept()
                ClientHandler(conn).start()
                print("Connected to: ", addr)
            except socket.timeout:
                continue


if __name__ == "__main__":
    server = Server(55555)
    server.start()
