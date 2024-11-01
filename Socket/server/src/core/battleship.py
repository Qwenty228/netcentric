from typing import Tuple, Dict

from src.models.ship_configuration import ShipConfigurationModel
from src.models.players_info import PlayersInfoModel
from src.models.game_rendering import GameRenderingModel
from src.models.attack_params import AttackParamsModel


class BattleShip:
    """
    This class represents the core functionality of a Battleship game. It manages player information,
    ships configuration, radar screens, and allows players to attack opponents by specifying positions.
    The game continues until one player has hit all the opponent's ship positions.

    Attributes:
        players_info (PlayersInfoModel): Information about the players including their names.
        opponent_ships (Dict[str, ShipConfigurationModel]): A dictionary storing opponent ship configurations
            for each player. Player1's key holds Player2's ships and vice versa.
        radar_screens (Dict[str, GameRenderingModel]): A dictionary storing the radar screens for each player.
            The radar screen tracks hit (1), unknown (0), and miss (-1) positions.
    """

    def __init__(self, players_info: PlayersInfoModel, players_ships: Tuple[ShipConfigurationModel, ShipConfigurationModel]):
        """
        Initializes the BattleShip game with player information and ship configurations.

        Args:
            players_info (PlayersInfoModel): Model containing player names and relevant information.
            players_ships (Tuple[ShipConfigurationModel, ShipConfigurationModel]): Tuple of ShipConfigurationModel
                where the first element represents player1's ship setup and the second element represents player2's.

        Attributes:
            players_info (PlayersInfoModel): Information about the players.
            opponent_ships (Dict[str, ShipConfigurationModel]): Maps player names to the opponent's ship configurations.
            radar_screens (Dict[str, GameRenderingModel]): Maps player names to their radar screens for tracking hits and misses.
        """
        self.players_info = players_info

        # Maps player names to their opponent's ship configuration for easy access
        self.opponent_ships: Dict[str, ShipConfigurationModel] = {
            players_info.player1_name: players_ships[1],  # player1 has access to player2's ships
            players_info.player2_name: players_ships[0]   # player2 has access to player1's ships
        }

        # Initializes radar screens for each player. These will be updated based on attacks.
        # The radar uses 1 for hit, 0 for unknown, and -1 for miss.
        self.radar_screens: Dict[str, GameRenderingModel] = {
            players_info.player1_name: GameRenderingModel(),
            players_info.player2_name: GameRenderingModel()
        }

    def attack(self, player_name: str, position: int):
        """
        Processes an attack by a player on the opponent's ship.

        Args:
            player_name (str): The name of the player initiating the attack.
            position (int): The position being attacked on the opponent's grid.

        Behavior:
            - The attack is validated using the `AttackParamsModel` to ensure the player name is valid.
            - If the position corresponds to a ship in the opponent's configuration, it is recorded as a hit (1) on the radar screen.
            - If the position does not correspond to a ship, it is recorded as a miss (-1).
        """
        # Validate the player name and attack position using Pydantic model `AttackParamsModel`
        params = AttackParamsModel(
            player_name=player_name,
            position=position,
            valid_player_names=[self.players_info.player1_name, self.players_info.player2_name]
        )

        # Check if the attack position hits an opponent's ship
        if params.position in self.opponent_ships[params.player_name].state:
            self.radar_screens[params.player_name].screen[params.position] = 1  # Record hit
        else:
            self.radar_screens[params.player_name].screen[params.position] = -1  # Record miss

    def check_game_over(self):
        """
        Checks if the game is over by determining if a player has hit all 16 ship positions.

        Returns:
            str: The name of the winning player if a player has hit all 16 ship positions.
            None: If no player has yet won the game.
        """
        # Iterate over the radar screens to check if any player has hit all 16 ship positions
        for player_name, radar_screen in self.radar_screens.items():
            if radar_screen.screen.count(1) == 16:  # Assuming 16 ship positions for victory
                return player_name  # Return the name of the player who won

        # Return None if the game is not yet over
        return None
    
    
