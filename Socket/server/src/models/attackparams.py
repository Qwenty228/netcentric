from pydantic import BaseModel, conint, model_validator
from typing import List

class AttackParamsModel(BaseModel):
    player_name: str
    position: conint(ge=0, le=63)
    valid_player_names: List[str]

    @model_validator(mode="after")
    @classmethod
    def check_player_name_in_valid_names(cls, model_instance):
        # Access fields directly from the model instance
        player_name = model_instance.player_name
        valid_player_names = model_instance.valid_player_names

        if player_name not in valid_player_names:
            raise ValueError(f'Player name {player_name} is not in the list of valid player names.')
        
        return model_instance
