from src.core.battleship import BattleShip
from src.models.players_info import PlayersInfoModel
from src.models.ship_configuration import ShipConfigurationModel


class BattleShipHandler:
    """
    This class manages the interaction between players and the Battleship game.

    It initializes the game with player information and their respective ship configurations.
    It processes player attacks and checks for winners.

    Attributes:
        battle_ship (BattleShip): An instance of the BattleShip class that handles game logic.
    """

    def __init__(self, players_info: PlayersInfoModel, player_ships: dict[str, ShipConfigurationModel]):
        """
        Initializes the BattleshipHandler with player information and ship configurations.

        Args:
            players_info (PlayersInfoModel): Model containing player names and relevant information.
            player_ships (dict[str, ShipConfigurationModel]): A dictionary mapping player names to their ship configurations.

        Initializes an instance of the BattleShip class with the provided player information and ships.
        """
        self.battle_ship = BattleShip(
            players_info=players_info,
            players_ships=(player_ships[players_info.player1_name], player_ships[players_info.player2_name])
        )

    def process_attack(self, player_name: str, target_pos: int):
        """
        Processes an attack from a player at a specified target position.

        Args:
            player_name (str): The name of the player initiating the attack.
            target_pos (int): The position being attacked on the opponent's grid.

        Returns:
            dict: A dictionary containing the radar screens of both players,
                  with hit, miss, and unknown statuses represented as strings.

        If the target position is -1, no attack is processed. 
        The method updates the radar screens based on the attack results.
        """
        # Only process the attack if the target position is valid (not -1)
        if target_pos != -1:
            self.battle_ship.attack(player_name, target_pos)

        # Prepare radar screens for both players in a structured format for return
        radar_screens = {
            "radarA": [str(x) for x in
                       self.battle_ship.radar_screens[self.battle_ship.players_info.player1_name].screen],
            "radarB": [str(x) for x in
                       self.battle_ship.radar_screens[self.battle_ship.players_info.player2_name].screen],
        }

        return {"header": "game", "body": radar_screens}

    def check_winner(self):
        """
        Checks if there is a winner in the game.

        Returns:
            str or None: The name of the winning player if there is one, or None if the game is still ongoing.

        This method checks the radar screens for each player to determine if one has hit all of the opponent's ships.
        """
        return self.battle_ship.check_game_over()
