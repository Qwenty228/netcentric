from pydantic  import BaseModel
from typing import List

class CommunicationPacketModel(BaseModel):
    header: str
    body: List[int]
    client: str