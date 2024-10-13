from pydantic import BaseModel, conlist, field_validator

class ShipConfigurationModel(BaseModel):
    state: conlist(int, min_length=16, max_length=16)

    @field_validator('state')
    def validate_state(cls, v):
        if len(set(v)) != len(v):
            raise ValueError('ship config must contain unique values')
        if any(value < 0 or value > 63 for value in v):
            raise ValueError('ship config values must be in the range 0-63')
        return v