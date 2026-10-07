from fastapi import APIRouter
from app.schemas.common import HealthCheckResponse
from app.core.config import settings

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthCheckResponse)
async def health_check():
    """
    Health check endpoint to verify backend service liveness.
    """
    return HealthCheckResponse(
        status="healthy",
        version=settings.VERSION,
        environment="development" if settings.DEBUG else "production"
    )
