from typing import List

from pydantic import BaseModel


class PacketModel(BaseModel):
    header: str
    body: List[int]
    client: str
