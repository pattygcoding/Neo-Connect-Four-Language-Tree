from pydantic import BaseModel, Field

from .board import COLUMNS


class Move(BaseModel):
    column: int = Field(ge=1, le=COLUMNS)
