from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.schemas.common import APIResponse
from app.services.knowledge import (
    knowledge_service,
    KnowledgeSearchResult,
    KnowledgeChunkData
)

router = APIRouter(prefix="/knowledge", tags=["Knowledge Base & pgvector Grounding"])


class KnowledgeSearchRequest(BaseModel):
    query: str = Field(min_length=1, example="whitefly yellow mosaic soybean treatment")
    domain: Optional[str] = Field(default=None, example="agronomy")
    top_k: int = Field(default=3, ge=1, le=10, example=3)
    similarity_threshold: float = Field(default=0.15, ge=0.0, le=1.0, example=0.15)


class KnowledgeChunkCreateRequest(BaseModel):
    document_title: str = Field(..., example="PJTSAU Kharif Red Gram Guidelines")
    authority: str = Field(..., example="PJTSAU Telangana")
    domain: str = Field(..., example="agronomy")
    chunk_text: str = Field(..., example="Spacing for PRG-158 red gram in rainfed black soils...")
    official_url: Optional[str] = Field(default=None, example="https://pjtsau.edu.in/redgram")
    published_date: str = Field(default="2026", example="July 2026")


@router.post("/search", response_model=APIResponse[List[KnowledgeSearchResult]])
async def search_knowledge_base(
    req: KnowledgeSearchRequest,
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Semantic vector search across official agricultural university,
    government scheme gazettes, and mandi standards with similarity ranking.
    """
    results = knowledge_service.search(
        query=req.query,
        top_k=req.top_k,
        domain=req.domain,
        similarity_threshold=req.similarity_threshold
    )
    return APIResponse(data=results)


@router.get("/documents", response_model=APIResponse[List[Dict[str, Any]]])
async def list_knowledge_documents(
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Lists all official verified advisory documents and gazettes
    indexed in the VillageNova Knowledge Base.
    """
    docs = knowledge_service.list_documents()
    return APIResponse(data=docs)


@router.post("/chunks", response_model=APIResponse[KnowledgeChunkData])
async def create_knowledge_chunk(
    chunk_in: KnowledgeChunkCreateRequest,
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Ingests and vector-indexes a new verified advisory chunk into the Knowledge Base.
    """
    new_chunk = knowledge_service.index_chunk(
        document_title=chunk_in.document_title,
        authority=chunk_in.authority,
        domain=chunk_in.domain,
        chunk_text=chunk_in.chunk_text,
        official_url=chunk_in.official_url,
        published_date=chunk_in.published_date
    )
    return APIResponse(data=new_chunk)
