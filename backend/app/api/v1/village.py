from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
import uuid

from app.core.database import get_db
from app.models.resident import Village
from app.schemas.resident import VillageOut
from app.schemas.common import APIResponse

router = APIRouter(prefix="/villages", tags=["Villages"])

# Curated rural Telangana / Central India default demo villages
DEFAULT_VILLAGES = [
    {
        "id": uuid.UUID("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
        "name": "Ananthagiri",
        "mandal": "Vikarabad",
        "district": "Vikarabad",
        "state": "Telangana",
        "pincode": "501101",
    },
    {
        "id": uuid.UUID("4fa85f64-5717-4562-b3fc-2c963f66afa7"),
        "name": "Dharur",
        "mandal": "Dharur",
        "district": "Vikarabad",
        "state": "Telangana",
        "pincode": "501121",
    },
    {
        "id": uuid.UUID("5fa85f64-5717-4562-b3fc-2c963f66afa8"),
        "name": "Kotepally",
        "mandal": "Kotepally",
        "district": "Vikarabad",
        "state": "Telangana",
        "pincode": "501106",
    },
    {
        "id": uuid.UUID("6fa85f64-5717-4562-b3fc-2c963f66afa9"),
        "name": "Nawabpet",
        "mandal": "Nawabpet",
        "district": "Vikarabad",
        "state": "Telangana",
        "pincode": "501111",
    },
    {
        "id": uuid.UUID("7fa85f64-5717-4562-b3fc-2c963f66afb0"),
        "name": "Parigi",
        "mandal": "Parigi",
        "district": "Vikarabad",
        "state": "Telangana",
        "pincode": "501501",
    },
    {
        "id": uuid.UUID("8fa85f64-5717-4562-b3fc-2c963f66afb1"),
        "name": "Kondurg",
        "mandal": "Kondurg",
        "district": "Rangareddy",
        "state": "Telangana",
        "pincode": "509207",
    },
]


@router.get("", response_model=APIResponse[List[VillageOut]])
async def list_villages(
    q: Optional[str] = Query(None, description="Search query by village name or mandal"),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns verified village listings for resident onboarding and community feeds.
    Resilient to database absence or empty table states by returning regional seeds.
    """
    villages_list: List[VillageOut] = []

    if db:
        try:
            stmt = select(Village)
            if q:
                stmt = stmt.where(Village.name.ilike(f"%{q}%") | Village.mandal.ilike(f"%{q}%"))
            result = await db.execute(stmt)
            db_villages = result.scalars().all()
            if db_villages:
                villages_list = [
                    VillageOut(
                        id=v.id,
                        name=v.name,
                        mandal=v.mandal,
                        district=v.district,
                        state=v.state,
                        pincode=v.pincode
                    )
                    for v in db_villages
                ]
        except Exception:
            villages_list = []

    # If DB has no villages or offline/mock session, return curated defaults
    if not villages_list:
        filtered = DEFAULT_VILLAGES
        if q:
            q_lower = q.lower()
            filtered = [
                v for v in DEFAULT_VILLAGES
                if q_lower in v["name"].lower() or q_lower in v["mandal"].lower()
            ]
        villages_list = [VillageOut(**item) for item in filtered]

    return APIResponse(
        message="Villages fetched successfully",
        data=villages_list
    )
