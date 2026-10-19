from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.health import router as health_router
from app.api.v1.resident import router as resident_router
from app.api.v1.home import router as home_router
from app.api.v1.ask import router as ask_router
from app.api.v1.village import router as village_router
from app.api.v1.farm import router as farm_router
from app.api.v1.task import router as task_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Backend API services and AI Orchestration Engine for VillageNova",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url=f"{settings.API_V1_PREFIX}/docs",
    redoc_url=f"{settings.API_V1_PREFIX}/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routers under /v1
app.include_router(health_router, prefix=settings.API_V1_PREFIX)
app.include_router(resident_router, prefix=settings.API_V1_PREFIX)
app.include_router(home_router, prefix=settings.API_V1_PREFIX)
app.include_router(ask_router, prefix=settings.API_V1_PREFIX)
app.include_router(village_router, prefix=settings.API_V1_PREFIX)
app.include_router(farm_router, prefix=settings.API_V1_PREFIX)
app.include_router(task_router, prefix=settings.API_V1_PREFIX)


@app.get("/")
async def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs": f"{settings.API_V1_PREFIX}/docs",
        "status": "online"
    }
