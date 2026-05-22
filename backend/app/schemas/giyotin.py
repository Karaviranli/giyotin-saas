from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class GiyotinCalculateRequest(BaseModel):
    project_name: str = Field(..., example="Kavira Merkez Ofis")
    width: float = Field(..., gt=0, example=3000.0)
    height: float = Field(..., gt=0, example=2500.0)
    quantity: int = Field(default=1, gt=0)
    system_type: str = Field(default="3LÜ TEMİZLENİR")
    stock_length: float = Field(default=6500.0)
    kerf: float = Field(default=5.0)

class GiyotinRecordResponse(BaseModel):
    id: int
    project_name: str
    width: float
    height: float
    quantity: int
    created_at: datetime
    
    class Config:
        orm_mode = True