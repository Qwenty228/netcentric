from typing import Tuple, Dict

from src.models.ship_configuration import ShipConfigurationModel
from src.models.players_info import PlayersInfoModel
from src.models.game_rendering import GameRenderingModel
from src.models.attackparams import AttackParamsModel

class BattleShip:
    def __init__(self, players_info: PlayersInfoModel, players_ships: Tuple[ShipConfigurationModel, ShipConfigurationModel]):
        self.players_info = players_info

        # Opponent ships are stored in a dictionary with the player name as the key
        # with player1 having player2's ships and vice versa for easy access
        self.opponent_ships: Dict[str, ShipConfigurationModel] = {
            players_info.player1_name: players_ships[1],
            players_info.player2_name: players_ships[0]
        }

        # Radar screens are stored in a dictionary with player name as the key
        # which radar screen will be returned back to Godot for rendering of the radar screen
        # (1 is hit, 0 is unknown, -1 is miss)
        self.radar_screens: Dict[str, GameRenderingModel] = {
            players_info.player1_name: GameRenderingModel(),
            players_info.player2_name: GameRenderingModel()
        }


    def attack(self, player_name: str, position: int):
        # Validate the input using Pydantic
        params = AttackParamsModel(
            player_name=player_name,
            position=position,
            valid_player_names=[self.players_info.player1_name, self.players_info.player2_name]
        )
        
        if params.position in self.opponent_ships[params.player_name].state:
            self.radar_screens[params.player_name].screen[params.position] = 1
        else:
            self.radar_screens[params.player_name].screen[params.position] = -1
    
    def check_game_over(self):
        for player_name, radar_screen in self.radar_screens.items():
            if radar_screen.screen.count(1) == 16:
                return player_name

        return None

