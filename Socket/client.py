# battle ship command line game
from network import Network
import random
import json


def print_ships(ships: list[str], attacked: list) -> None:
    """
    Print the ships on the board
    _________________________
    |0 |  |  |  | 0|  |  |  |
    |0 |  |  |  | 0|  |  |  |
    |0 |  |  |  | 0|  |  |  |
    |0 |  |  |  | 0|  |  |  |
    |  |  |  |  |  |  |  |  |
    |  |  |  |  |  |  |  |  |
    |  | 0| 0| 0| 0|  |  |  |
    |  |  |  |  | 0| 0| 0| 0|
    -------------------------
    """
    letter = {"0": " ", "-1": "M", "1": "X"}
    board = [letter[i] for i in attacked]
    for ship in ships:
        if board[int(ship)] == "X":
            continue
        board[int(ship)] = "0"
    print("____________________________________")
    for i in range(0, 64, 8):
        print("|", " | ".join(board[i:i+8]), "|")
    print("------------------------------------")

def print_my_attack(attack: list):
    if not attack:
        attack = ["0"] * 64
    print("____________________________________")
    for i in range(0, 64, 8):
        print("|", " | ".join(attack[i:i+8]), "|")
    print("------------------------------------")


class Battleship:
    def __init__(self) -> None:
        self.name = input("Enter username: ")
        self.ships = [str(i) for i in random.sample(range(64), 16)]
        # game state init to server
        self.network = Network(
            {"header": "init", "body": self.ships, "client": self.name})
        self.player_index = 1 if self.network.client_id == "A" else 0
        self.my_attack = []
        self.opp_attack = ["0"] * 64

        print("My ships: ")
        print_ships(self.ships, self.opp_attack)

    def game(self):
        # get round from server
        game_round = int(self.network.send(
            {"header": "game", "body": "round"})['body'])

        print("Round:", game_round)
        if game_round % 2 == self.player_index:  # if round is odd, A plays, if round is even, B plays
            self.my_attack = self.network.send(
                {"header": "game", "body": [input("Enter a position: ")]})['body']
        else:
            # wait for opponent to play
            print("Waiting for opponent to play")
            self.opp_attack = json.loads(self.network.receive())['body']

        print(self.name, "attack:")
        print_my_attack(self.my_attack)

        print(self.name, "ships: ")
        print_ships(self.ships, self.opp_attack)  # print game state

    def start(self):
        print("log in as", self.network.client_id)
        while True:
            if self.network.ready:
                self.game()
            else:
                print("Waiting for player to connect")
                self.network.ready = json.loads(self.network.receive())[
                    'body']  # blocking A, wait until B connects
                print("Player connected")


if __name__ == "__main__":
    Battleship().start()
