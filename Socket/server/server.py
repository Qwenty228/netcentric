import json
from threading import Thread
import socket
from src.models.ship_configuration import ShipConfigurationModel
from src.models.players_info import PlayersInfoModel
from src.core.battleship import BattleShip

CLIENT_IDENTIFIERS = "AB"

class BattleShipHandler:
    """
    Manages the game state and interactions using the BattleShip class.
    """
    def __init__(self, players_info: PlayersInfoModel, player_ships: dict[str, ShipConfigurationModel]) -> None:
        self.battle_ship = BattleShip(players_info, (player_ships[players_info.player1_name], player_ships[players_info.player2_name]))

    def process_attack(self, player_name: str, target_pos: int):
        """
        Processes the attack using the BattleShip class.
        """
        # Call the attack method and pass the player name and position
        self.battle_ship.attack(player_name, target_pos)

        # Get updated radar screens for both players
        radar_screens = {
            "radarA": [str(x) for x in self.battle_ship.radar_screens[self.battle_ship.players_info.player1_name].screen],
            "radarB": [str(x) for x in self.battle_ship.radar_screens[self.battle_ship.players_info.player2_name].screen],
        }
        return {"header": "game", "body": radar_screens}


    def check_winner(self):
        return self.battle_ship.check_game_over()


class ClientHandler(Thread):
    """
    ClientHandler class to handle multiple clients.
    """
    all_clients: list['ClientHandler'] = []
    game_round = 1
    game_started = False
    battle_ship_handler: BattleShipHandler = None

    def __init__(self, conn: socket.socket, client_id: str) -> None:
        super().__init__(daemon=True)
        self.conn = conn
        self.client_id = client_id
        self.ships = []  # Stores ship positions for each player
        self.name = f"Client-{self.client_id}"
        ClientHandler.all_clients.append(self)

    def run(self):
        # Notify all clients of the connection
        for client in ClientHandler.all_clients:
            client.conn.sendall(json.dumps({
                "header": "connection",
                "body": len(ClientHandler.all_clients) == 2,  # True if both clients are connected
                "client": self.client_id
            }).encode("utf-8"))

        while True:
            try:
                data = self.conn.recv(2048).decode("utf-8")
                if not data:
                    break

                print(self.name, "send:", data)
                try:
                    data = json.loads(data)
                except json.JSONDecodeError:
                    continue

                reply = {}

                if data["header"] == "init":  # Initialization phase
                    # Parse and store the ship configuration
                    self.ships = [int(ship) for ship in data["body"]]  # Convert ship positions to integers
                    self.name = f"Client: {data['client']}"  # Set the client name

                    # Check if both clients are ready to start the game
                    if len(ClientHandler.all_clients) == 2 and not ClientHandler.game_started:
                        # Initialize game with both players' ship configurations
                        player_ships = {
                            ClientHandler.all_clients[0].name: ShipConfigurationModel(state=ClientHandler.all_clients[0].ships),
                            ClientHandler.all_clients[1].name: ShipConfigurationModel(state=ClientHandler.all_clients[1].ships)
                        }
                        players_info = PlayersInfoModel(
                            player1_name=ClientHandler.all_clients[0].name,  # Player A
                            player2_name=ClientHandler.all_clients[1].name  # Player B
                        )
                        ClientHandler.battle_ship_handler = BattleShipHandler(players_info, player_ships)
                        ClientHandler.game_started = True
                        print("Game initialized")

                elif data["header"] == "game":  # Game phase
                    if data.get('body') == "round":  # Return current round
                        reply = {"header": "game", "body": ClientHandler.game_round}
                    else:        
                            # Parse attack position from the client
                        target_pos = int(data["body"][0]) # Convert the string input from the client to an integer
                       
       
                        reply = ClientHandler.battle_ship_handler.process_attack(self.name, target_pos)
                        print(reply)
                        # Check if the game is over
                        winner = ClientHandler.battle_ship_handler.check_winner()
                        if winner != None: 
                            game_over_message = {
                                "header": "game_over",
                                "body": winner
                            }
                            for client in ClientHandler.all_clients:
                                client.conn.sendall(json.dumps(game_over_message).encode("utf-8"))

                                # End the game by closing connections
                            self.end_game()
                            break  # Exit the loop, connection close
                            
                        # Send the updated radar screens to other clients
                        for client in ClientHandler.all_clients:
                            if client.conn != self.conn:
                                client.conn.sendall(json.dumps(reply).encode("utf-8"))

                            # Increment the game round after each move
                        ClientHandler.game_round += 1

                self.conn.sendall(json.dumps(reply).encode("utf-8"))

            except socket.error as e:
                print(e)
                break

        print(f"Connection with {self.name} closed")
        self.conn.close()
        ClientHandler.all_clients.remove(self)

    def end_game(self):
        """
        Ends the game by closing all client connections and resetting game state.
        """
        print("Game over. Closing connections...")
        for client in ClientHandler.all_clients:
            try:
                client.conn.close()
            except Exception as e:
                print(f"Error closing connection: {e}")
        ClientHandler.all_clients.clear()  # Clear the list of connected clients
        ClientHandler.game_started = False  # Reset game state


class Server:
    """
    Server class to handle multiple clients.
    """
    MAX_CLIENTS = 2

    def __init__(self, port: int, host="127.0.0.1") -> None:
        self.socket = socket.socket(
            socket.AF_INET, socket.SOCK_STREAM)  # TCP socket
        self.socket.bind((host, port))
        self.socket.listen(Server.MAX_CLIENTS)
        self.socket.settimeout(1)  # allow for timeout

    def start(self):
        """
        Starts the server and assigns the first client "A" and the second client "B".
        """
        client_id = "A"  # First player will always be "A"
        while True:
            try:
                conn, addr = self.socket.accept()
                ClientHandler(conn, client_id).start()
                print(f"Connected to: {addr} as {client_id}")
                # Assign next player as "B"
                client_id = "B"
            except socket.timeout:
                continue


if __name__ == "__main__":
    server = Server(10000)
    server.start()

              