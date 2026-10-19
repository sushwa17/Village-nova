from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from datetime import datetime, timezone, timedelta
import uuid

from app.core.database import get_db
from app.models.resident import Village
from app.models.village import VillageUpdate
from app.schemas.resident import VillageOut
from app.schemas.village import (
    VillageUpdateOut,
    VillageUpdateCreate,
    VillageWeatherOut,
    WeatherHourOut,
    MandiPriceOut,
    VillageFeedOut,
)
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

# In-memory bulletin store for mock/demo mode to persist newly created updates
_DEMO_BULLETINS: List[dict] = [
    {
        "id": "bul_001",
        "village_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "title": "⚡ 3-Phase Agricultural Power Schedule Changed",
        "content": "Due to grid maintenance, 3-phase power for borewells will run from 4:00 AM to 11:00 AM and 7:00 PM to 10:00 PM starting Tuesday.",
        "category": "panchayat",
        "is_emergency": True,
        "author_name": "TSSPDCL Vikarabad & Gram Panchayat",
        "author_role": "Assistant Engineer / Panchayat Admin",
        "is_verified": True,
        "created_at": datetime.now(timezone.utc) - timedelta(hours=3),
    },
    {
        "id": "bul_002",
        "village_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "title": "🌾 Subsidized Gypsum & Bio-fertilizer Distribution",
        "content": "Rythu Bharosa Kendra (RBK) Ananthagiri has received 200 bags of agricultural gypsum and Trichoderma. Bring Pattadar Passbook before Friday 5 PM.",
        "category": "agriculture",
        "is_emergency": False,
        "author_name": "Agriculture Extension Officer (AEO)",
        "author_role": "Department of Agriculture",
        "is_verified": True,
        "created_at": datetime.now(timezone.utc) - timedelta(hours=8),
    },
    {
        "id": "bul_003",
        "village_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "title": "🏥 Free Monsoon Health & Eye Checkup Camp",
        "content": "Primary Health Centre (PHC) Ananthagiri is organizing a free health screening camp at Zilla Parishad High School ground this Saturday 9 AM.",
        "category": "health",
        "is_emergency": False,
        "author_name": "Dr. Sunitha Reddy",
        "author_role": "Medical Officer, PHC Ananthagiri",
        "is_verified": True,
        "created_at": datetime.now(timezone.utc) - timedelta(days=1),
    },
]


def _get_demo_weather(village_name: str = "Ananthagiri") -> VillageWeatherOut:
    return VillageWeatherOut(
        village_name=village_name,
        temp_c=29.4,
        condition="Scattered Rain & Thunderstorms",
        humidity_pct=82,
        wind_speed_kmh=14.5,
        rain_prob_pct=85,
        rainfall_mm=14.0,
        expected_rain_time="6:00 PM today",
        advisory="Heavy rain (14mm) expected around 6:00 PM. Conclude pesticide spray and field hoeing by 4:30 PM. Keep drainage channels unobstructed.",
        hourly=[
            WeatherHourOut(time="2:00 PM", temp_c=31.0, rain_prob=20, condition="Partly Cloudy", icon="partly_cloudy"),
            WeatherHourOut(time="4:00 PM", temp_c=29.5, rain_prob=45, condition="Overcast Clouds", icon="cloudy"),
            WeatherHourOut(time="6:00 PM", temp_c=26.0, rain_prob=90, condition="Thunderstorm & Heavy Rain", icon="thunderstorm"),
            WeatherHourOut(time="8:00 PM", temp_c=24.5, rain_prob=70, condition="Light Showers", icon="rain"),
            WeatherHourOut(time="10:00 PM", temp_c=24.0, rain_prob=30, condition="Cloudy", icon="cloudy"),
        ],
    )


def _get_demo_mandi_prices() -> List[MandiPriceOut]:
    today_str = datetime.now(timezone.utc).strftime("%d %b %Y")
    return [
        MandiPriceOut(
            commodity="Soybean (JS-335 / Yellow)",
            market="Vikarabad APMC",
            modal_price=4850.0,
            min_price=4620.0,
            max_price=4980.0,
            unit="Quintal",
            price_change=70.0,
            trend="up",
            reported_date=today_str,
        ),
        MandiPriceOut(
            commodity="Cotton (Medium Staple)",
            market="Tandur APMC",
            modal_price=7200.0,
            min_price=6900.0,
            max_price=7450.0,
            unit="Quintal",
            price_change=120.0,
            trend="up",
            reported_date=today_str,
        ),
        MandiPriceOut(
            commodity="Red Gram / Tur (Desi)",
            market="Vikarabad APMC",
            modal_price=6900.0,
            min_price=6650.0,
            max_price=7150.0,
            unit="Quintal",
            price_change=-40.0,
            trend="down",
            reported_date=today_str,
        ),
        MandiPriceOut(
            commodity="Maize (Hybrid Yellow)",
            market="Sadasivpet APMC",
            modal_price=2150.0,
            min_price=2050.0,
            max_price=2220.0,
            unit="Quintal",
            price_change=0.0,
            trend="stable",
            reported_date=today_str,
        ),
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


@router.get("/{village_id}/feed", response_model=APIResponse[VillageFeedOut])
async def get_village_feed(
    village_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Consolidated Village Feed: Combines Hyperlocal Weather, APMC Mandi commodity rates,
    and official Panchayat/KVK bulletins for a rich community experience.
    """
    v_name = "Ananthagiri"
    mandal = "Vikarabad"
    district = "Vikarabad"

    # Match village name from seeds if present
    for v in DEFAULT_VILLAGES:
        if str(v["id"]) == village_id:
            v_name = v["name"]
            mandal = v["mandal"]
            district = v["district"]
            break

    weather = _get_demo_weather(v_name)
    mandi = _get_demo_mandi_prices()

    # Query DB bulletins if available, else in-memory demo bulletins
    bulletins_out: List[VillageUpdateOut] = []
    if db:
        try:
            stmt = select(VillageUpdate).order_by(VillageUpdate.created_at.desc())
            res = await db.execute(stmt)
            records = res.scalars().all()
            if records:
                bulletins_out = [
                    VillageUpdateOut(
                        id=str(r.id),
                        village_id=str(r.village_id),
                        title=r.title,
                        content=r.content,
                        category=r.category,
                        is_emergency=r.is_emergency,
                        author_name="Panchayat Secretary",
                        author_role="Gram Panchayat Admin",
                        is_verified=r.is_verified,
                        created_at=r.created_at,
                    )
                    for r in records
                ]
        except Exception:
            bulletins_out = []

    if not bulletins_out:
        bulletins_out = [VillageUpdateOut(**b) for b in _DEMO_BULLETINS]

    emergency_count = sum(1 for b in bulletins_out if b.is_emergency)

    feed = VillageFeedOut(
        village_id=village_id,
        village_name=v_name,
        mandal=mandal,
        district=district,
        active_alerts_count=emergency_count,
        weather=weather,
        mandi_prices=mandi,
        bulletins=bulletins_out,
    )

    return APIResponse(
        message="Village feed fetched successfully",
        data=feed,
    )


@router.get("/{village_id}/bulletins", response_model=APIResponse[List[VillageUpdateOut]])
async def get_village_bulletins(
    village_id: str,
    category: Optional[str] = Query(None, description="Filter by category: panchayat, agriculture, health, emergency"),
    is_emergency: Optional[bool] = Query(None, description="Filter for urgent/emergency alerts only"),
    db: AsyncSession = Depends(get_db),
):
    """
    List verified announcements, bulletins, and emergency broadcasts for a village.
    """
    bulletins = [VillageUpdateOut(**b) for b in _DEMO_BULLETINS]

    if category:
        bulletins = [b for b in bulletins if b.category.lower() == category.lower()]
    if is_emergency is not None:
        bulletins = [b for b in bulletins if b.is_emergency == is_emergency]

    return APIResponse(
        message="Bulletins fetched successfully",
        data=bulletins,
    )


@router.post("/{village_id}/bulletins", response_model=APIResponse[VillageUpdateOut], status_code=status.HTTP_201_CREATED)
async def post_village_bulletin(
    village_id: str,
    bulletin_in: VillageUpdateCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Post a verified bulletin, notice, or advisory to the village community board.
    """
    now = datetime.now(timezone.utc)
    new_id = f"bul_{uuid.uuid4().hex[:8]}"

    item_dict = {
        "id": new_id,
        "village_id": village_id,
        "title": bulletin_in.title,
        "content": bulletin_in.content,
        "category": bulletin_in.category,
        "is_emergency": bulletin_in.is_emergency,
        "author_name": bulletin_in.author_name or "Community Contributor",
        "author_role": bulletin_in.author_role or "Resident Contributor",
        "is_verified": True,
        "created_at": now,
    }

    # Prepend to demo in-memory storage so it is immediately reflected
    _DEMO_BULLETINS.insert(0, item_dict)

    if db:
        try:
            rec = VillageUpdate(
                village_id=uuid.UUID(village_id) if len(village_id) == 36 else DEFAULT_VILLAGES[0]["id"],
                title=bulletin_in.title,
                content=bulletin_in.content,
                category=bulletin_in.category,
                is_emergency=bulletin_in.is_emergency,
                is_verified=True,
                created_at=now,
            )
            db.add(rec)
            await db.commit()
            await db.refresh(rec)
            item_dict["id"] = str(rec.id)
        except Exception:
            pass

    return APIResponse(
        message="Bulletin posted successfully",
        data=VillageUpdateOut(**item_dict),
    )


@router.get("/{village_id}/weather", response_model=APIResponse[VillageWeatherOut])
async def get_village_weather(
    village_id: str,
):
    """
    Returns Hyperlocal Weather Intelligence: current conditions, rainfall expectation, and actionable agricultural advisories.
    """
    v_name = "Ananthagiri"
    for v in DEFAULT_VILLAGES:
        if str(v["id"]) == village_id:
            v_name = v["name"]
            break

    weather = _get_demo_weather(v_name)
    return APIResponse(
        message="Weather forecast fetched successfully",
        data=weather,
    )


@router.get("/{village_id}/mandi", response_model=APIResponse[List[MandiPriceOut]])
async def get_village_mandi_prices(
    village_id: str,
    commodity: Optional[str] = Query(None, description="Filter by crop name (e.g. Soybean, Cotton)"),
):
    """
    Returns APMC Mandi commodity rates for agricultural trade in the village's district.
    """
    prices = _get_demo_mandi_prices()
    if commodity:
        prices = [p for p in prices if commodity.lower() in p.commodity.lower()]

    return APIResponse(
        message="Mandi rates fetched successfully",
        data=prices,
    )
