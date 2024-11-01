from pydantic import BaseModel


class PlayersInfoModel(BaseModel):
    player1_name: str
    player2_name: str
