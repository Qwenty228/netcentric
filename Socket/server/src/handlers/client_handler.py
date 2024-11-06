import socket
import json
from threading import Thread
from src.models.ship_configuration import ShipConfigurationModel
from src.models.players_info import PlayersInfoModel
from src.handlers.battleship_handler import BattleShipHandler


class ClientHandler(Thread):
    """
    ClientHandler class to manage multiple clients in a Battleship game.

    This class is responsible for handling handlers with individual clients,
    processing their messages, and coordinating the game state.

    Attributes:
        all_clients (list[ClientHandler]): List of all connected client handlers.
        game_round (int): The current round of the game.
        game_started (bool): Flag indicating whether the game has started.
        battle_ship_handler (BattleShipHandler): Handler for game logic and state.
    """

    # Class-level variables to track game state and clients
    all_clients: list['ClientHandler'] = []
    game_round = 1
    game_started = False
    battle_ship_handler: BattleShipHandler = None

    def __init__(self, conn: socket.socket, client_id: str) -> None:
        """
        Initializes a ClientHandler instance.

        Args:
            conn (socket.socket): The socket connection for the client.
            client_id (str): Unique identifier for the client.

        This constructor also appends the instance to the list of all clients.
        """
        super().__init__(daemon=True)
        self.conn = conn
        self.client_id = client_id
        self.ships = []  # Stores ship positions for the client
        self.name = f"Client-{self.client_id}"  # Unique name for the client
        ClientHandler.all_clients.append(self)  # Add this client to the list of clients

    def run(self):
        """
        The main method of the thread that handles handlers with the client.

        It listens for messages from the client, processes them, and responds accordingly.
        It also handles the game initialization and round progression.
        """
        self.notify_clients_connection()
        
        while True:
            try:
                data = self.receive_data()
                if data is None:
                    break
                

                print(f"{self.name} sent: {data}")
                reply = {}

                if data["header"] == "init":
                    self.handle_initialization(data)

                elif data["header"] == "game":
                    reply = self.handle_game(data)
                    if not reply:
                        continue
                
                elif data["header"] == "restart":
                    self.reset_game_state()
                    reply = {
                        "header": "restart",
                        "body": "Game has been restarted. Please reinitialize."
                    }
                    self.broadcast_reply_to_other_clients(reply)
                

                self.conn.sendall(json.dumps(reply).encode("utf-8"))
            except socket.error as e:
                print(f"Error: {e}")
                break
            except (UnicodeDecodeError, json.JSONDecodeError) as e:
                # print(f"Error: {e}")
                continue
 

        print(f"Connection with {self.name} closed")
        self.conn.close()
        
        if len(ClientHandler.all_clients) != 0:
            ClientHandler.all_clients.remove(self)
            self.broadcast_game_over(ClientHandler.all_clients[0].name)

    def notify_clients_connection(self):
        """
        Sends a notification to all connected clients about the current connection status.
        """
        for client in ClientHandler.all_clients:
            if client.conn and isinstance(client.conn, socket.socket):
                try:
                    client.conn.sendall(json.dumps({
                        "header": "connection",
                        "body": len(ClientHandler.all_clients) == 2,  # True if both clients are connected
                        "client": self.client_id
                    }).encode("utf-8"))
                except OSError as e:
                    print(e)

    def receive_data(self):
        """
        Receives data from the client.

        Returns:
            dict: Decoded JSON data from the client.
        """ 
        data = self.conn.recv(2048).decode("utf-8")
        if not data:
            return None
        return json.loads(data)

    def handle_initialization(self, data):
        """
        Handles the initialization phase of the game, including storing ship configurations.

        Args:
            data (dict): The message containing ship configurations.
        """
        # Parse and store the ship configuration
        self.ships = [int(ship) for ship in data["body"]]  # Convert ship positions to integers
        self.name = data['client']  # Set the client name
        
        ready_ship = 0
        for client in ClientHandler.all_clients:
            if client.ships:
                ready_ship += 1

        if len(ClientHandler.all_clients) == 2 and not ClientHandler.game_started and ready_ship == 2:
            # Initialize game with both players' ship configurations
            self.initialize_game()
            self.notify_clients_connection()
            
            

    @staticmethod
    def initialize_game():
        """
        Initializes the game when both players are ready, setting up ship configurations and player info.
        """
        player_ships = {
            ClientHandler.all_clients[0].name: ShipConfigurationModel(state=ClientHandler.all_clients[0].ships),
            ClientHandler.all_clients[1].name: ShipConfigurationModel(state=ClientHandler.all_clients[1].ships)
        }
        players_info = PlayersInfoModel(
            player1_name=ClientHandler.all_clients[0].name,  # Player A
            player2_name=ClientHandler.all_clients[1].name   # Player B
        )
        ClientHandler.battle_ship_handler = BattleShipHandler(players_info, player_ships)  # Initialize game handler
        ClientHandler.game_started = True  # Set game as started
        print("Game initialized")

    def handle_game(self, data):
        """
        Handles the game phase, processing attacks and checking for a winner.

        Args:
            data (dict): The message containing game actions.

        Returns:
            dict: The reply message to be sent back to the client.
        """
        if data.get('body') == "round":  # Return current round
            r = ClientHandler.game_round
            names = {
                "A": ClientHandler.all_clients[0].name,
                "B": ClientHandler.all_clients[1].name
            }
            return {"header": "game", "body": r, "names": names}

        target_pos = int(data["body"][0])  # Convert target position to an integer
        reply = ClientHandler.battle_ship_handler.process_attack(self.name, target_pos)

        # Check if the game is over
        winner = ClientHandler.battle_ship_handler.check_winner()
        if winner is not None:
            self.broadcast_game_over(winner)
            self.end_game()
            return

        else:
            self.broadcast_reply_to_other_clients(reply)

        ClientHandler.game_round += 1  # Increment game round after each move
        return reply

    @staticmethod
    def broadcast_game_over(winner):
        """
        Sends a game over message to all clients when a player wins.

        Args:
            winner (str): The name of the winning player.
        """
        game_over_message = {
            "header": "game_over",
            "body": winner
        }
        for client in ClientHandler.all_clients:
            client.conn.sendall(json.dumps(game_over_message).encode("utf-8"))

    def broadcast_reply_to_other_clients(self, reply):
        """
        Sends the game update (radar screens) to other clients.

        Args:
            reply (dict): The message to be sent to the other clients.
        """
        for client in ClientHandler.all_clients:
            if client.conn != self.conn:  # Avoid sending to self
                client.conn.sendall(json.dumps(reply).encode("utf-8"))

    @staticmethod
    def end_game():
        """
        Ends the game by closing all client connections and resetting the game state.
        """
        print("Game over. Closing connections...")
        # for client in ClientHandler.all_clients:
        #     try:
        #         client.conn.close() # Close each client's connection     
        #     except Exception as e:
        #         print(f"Error closing connection: {e}")

        ClientHandler.all_clients.clear()  # Clear the list of connected clients
        ClientHandler.game_started = False  # Reset game state

    # Add a new method to handle game state reset
    @staticmethod
    def reset_game_state():
        """
        Resets the game state, preparing for a new game round.
        """
        ClientHandler.game_round = 1
        ClientHandler.game_started = False
        ClientHandler.battle_ship_handler = None
        for client in ClientHandler.all_clients:
            client.ships.clear()  # Clear ship positions for all clients
        print("Game state has been reset.")
        
    
    