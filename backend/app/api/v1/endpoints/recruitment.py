"""Recruitment & ATS API endpoints."""

import uuid
from datetime import datetime, timezone, date
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.recruitment import JobRequisition, JobOpening, Candidate, Interview, Offer

router = APIRouter()


class InterviewFeedbackUpdate(BaseModel):
    feedback: Optional[str] = None
    rating: Optional[int] = None
    recommendation: Optional[str] = None


class CandidateStageUpdate(BaseModel):
    stage: str
    rating: Optional[int] = None
    notes: Optional[str] = None


class OfferReject(BaseModel):
    reason: Optional[str] = None


# ---- Job Requisitions ----

class RequisitionCreate(BaseModel):
    title: str
    department_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    employment_type: str = "permanent"
    openings: int = 1
    experience_min: Optional[int] = None
    experience_max: Optional[int] = None
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    skills: Optional[str] = None
    description: Optional[str] = None


@router.get("/requisitions")
async def list_requisitions(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(JobRequisition).where(JobRequisition.tenant_id == current_user.tenant_id)
    if status:
        stmt = stmt.where(JobRequisition.status == status)
    stmt = stmt.order_by(JobRequisition.created_at.desc())

    count_stmt = select(func.count(JobRequisition.id)).where(JobRequisition.tenant_id == current_user.tenant_id)
    if status:
        count_stmt = count_stmt.where(JobRequisition.status == status)
    total = (await db.execute(count_stmt)).scalar() or 0

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    return {
        "items": [
            {
                "id": str(r.id),
                "title": r.title,
                "department_id": str(r.department_id) if r.department_id else None,
                "branch_id": str(r.branch_id) if r.branch_id else None,
                "employment_type": r.employment_type,
                "openings": r.openings,
                "experience_min": r.experience_min,
                "experience_max": r.experience_max,
                "salary_min": r.salary_min,
                "salary_max": r.salary_max,
                "skills": r.skills,
                "description": r.description,
                "status": r.status,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.post("/requisitions")
async def create_requisition(
    data: RequisitionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    req = JobRequisition(
        tenant_id=current_user.tenant_id,
        hiring_manager_id=current_user.id,
        **data.model_dump(),
    )
    db.add(req)
    await db.commit()
    return {"id": str(req.id), "title": req.title, "status": req.status}


@router.put("/requisitions/{req_id}")
async def update_requisition(
    req_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    req = await db.get(JobRequisition, req_id)
    if not req or req.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Requisition not found")
    for k, v in data.items():
        if hasattr(req, k) and k not in ("id", "tenant_id"):
            setattr(req, k, v)
    await db.commit()
    return {"id": str(req.id), "status": req.status}


@router.post("/requisitions/{req_id}/submit")
async def submit_requisition(
    req_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    req = await db.get(JobRequisition, req_id)
    if not req or req.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Requisition not found")
    req.status = "pending_approval"
    await db.commit()
    return {"id": str(req.id), "status": req.status}


@router.post("/requisitions/{req_id}/approve")
async def approve_requisition(
    req_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    req = await db.get(JobRequisition, req_id)
    if not req or req.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Requisition not found")
    req.status = "approved"
    req.approved_by = current_user.id
    req.approved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(req.id), "status": req.status}


# ---- Job Openings ----

class OpeningCreate(BaseModel):
    title: str
    requisition_id: Optional[uuid.UUID] = None
    department_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    description: Optional[str] = None
    requirements: Optional[str] = None
    employment_type: str = "permanent"
    openings: int = 1
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    location: Optional[str] = None


@router.get("/openings")
async def list_openings(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(JobOpening).where(JobOpening.tenant_id == current_user.tenant_id)
    if status:
        stmt = stmt.where(JobOpening.status == status)
    stmt = stmt.order_by(JobOpening.created_at.desc())

    count_stmt = select(func.count(JobOpening.id)).where(JobOpening.tenant_id == current_user.tenant_id)
    if status:
        count_stmt = count_stmt.where(JobOpening.status == status)
    total = (await db.execute(count_stmt)).scalar() or 0

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    # Get candidate counts per opening
    opening_ids = [r.id for r in items]
    candidate_counts = {}
    if opening_ids:
        count_res = await db.execute(
            select(Candidate.opening_id, func.count(Candidate.id))
            .where(Candidate.opening_id.in_(opening_ids))
            .group_by(Candidate.opening_id)
        )
        candidate_counts = {str(oid): cnt for oid, cnt in count_res.all()}

    return {
        "items": [
            {
                "id": str(r.id),
                "title": r.title,
                "department_id": str(r.department_id) if r.department_id else None,
                "branch_id": str(r.branch_id) if r.branch_id else None,
                "description": r.description,
                "requirements": r.requirements,
                "employment_type": r.employment_type,
                "openings": r.openings,
                "salary_min": r.salary_min,
                "salary_max": r.salary_max,
                "location": r.location,
                "status": r.status,
                "candidates": candidate_counts.get(str(r.id), 0),
                "published_at": r.published_at.isoformat() if r.published_at else None,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.post("/openings")
async def create_opening(
    data: OpeningCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    opening = JobOpening(
        tenant_id=current_user.tenant_id,
        created_by=current_user.id,
        **data.model_dump(),
    )
    db.add(opening)
    await db.commit()
    return {"id": str(opening.id), "title": opening.title, "status": opening.status}


@router.put("/openings/{opening_id}")
async def update_opening(
    opening_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    opening = await db.get(JobOpening, opening_id)
    if not opening or opening.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Opening not found")
    for k, v in data.items():
        if hasattr(opening, k) and k not in ("id", "tenant_id"):
            setattr(opening, k, v)
    await db.commit()
    return {"id": str(opening.id), "status": opening.status}


@router.post("/openings/{opening_id}/publish")
async def publish_opening(
    opening_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    opening = await db.get(JobOpening, opening_id)
    if not opening or opening.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Opening not found")
    opening.status = "published"
    opening.published_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(opening.id), "status": "published"}


@router.post("/openings/{opening_id}/close")
async def close_opening(
    opening_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    opening = await db.get(JobOpening, opening_id)
    if not opening or opening.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Opening not found")
    opening.status = "closed"
    opening.closed_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(opening.id), "status": "closed"}


# ---- Candidates ----

class CandidateCreate(BaseModel):
    opening_id: Optional[uuid.UUID] = None
    first_name: str
    last_name: str
    email: str
    phone: Optional[str] = None
    skills: Optional[str] = None
    experience_years: Optional[int] = None
    education: Optional[str] = None
    current_company: Optional[str] = None
    current_designation: Optional[str] = None
    expected_salary: Optional[float] = None
    notice_period: Optional[int] = None
    source: Optional[str] = None


@router.get("/candidates")
async def list_candidates(
    opening_id: Optional[uuid.UUID] = None,
    stage: Optional[str] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Candidate).where(Candidate.tenant_id == current_user.tenant_id)
    count_stmt = select(func.count(Candidate.id)).where(Candidate.tenant_id == current_user.tenant_id)

    if opening_id:
        stmt = stmt.where(Candidate.opening_id == opening_id)
        count_stmt = count_stmt.where(Candidate.opening_id == opening_id)
    if stage:
        stmt = stmt.where(Candidate.stage == stage)
        count_stmt = count_stmt.where(Candidate.stage == stage)
    if search:
        from sqlalchemy import or_
        escaped = search.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        search_filter = or_(
            Candidate.first_name.ilike(f"%{escaped}%"),
            Candidate.last_name.ilike(f"%{escaped}%"),
            Candidate.email.ilike(f"%{escaped}%"),
        )
        stmt = stmt.where(search_filter)
        count_stmt = count_stmt.where(search_filter)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(Candidate.applied_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    return {
        "items": [
            {
                "id": str(c.id),
                "opening_id": str(c.opening_id) if c.opening_id else None,
                "first_name": c.first_name,
                "last_name": c.last_name,
                "email": c.email,
                "phone": c.phone,
                "skills": c.skills,
                "experience_years": c.experience_years,
                "current_company": c.current_company,
                "expected_salary": c.expected_salary,
                "source": c.source,
                "stage": c.stage,
                "rating": c.rating,
                "applied_at": c.applied_at.isoformat() if c.applied_at else None,
            }
            for c in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.post("/candidates")
async def create_candidate(
    data: CandidateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    candidate = Candidate(
        tenant_id=current_user.tenant_id,
        **data.model_dump(),
    )
    db.add(candidate)
    await db.commit()
    return {"id": str(candidate.id), "stage": candidate.stage}


@router.put("/candidates/{candidate_id}")
async def update_candidate(
    candidate_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    candidate = await db.get(Candidate, candidate_id)
    if not candidate or candidate.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Candidate not found")
    for k, v in data.items():
        if hasattr(candidate, k) and k not in ("id", "tenant_id"):
            setattr(candidate, k, v)
    await db.commit()
    return {"id": str(candidate.id), "stage": candidate.stage}


@router.put("/candidates/{candidate_id}/stage")
async def move_candidate_stage(
    candidate_id: uuid.UUID,
    data: CandidateStageUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    candidate = await db.get(Candidate, candidate_id)
    if not candidate or candidate.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Candidate not found")
    candidate.stage = data.stage
    if data.rating is not None:
        candidate.rating = data.rating
    if data.notes is not None:
        candidate.notes = data.notes
    await db.commit()
    return {"id": str(candidate.id), "stage": candidate.stage}


# ---- Interviews ----

class InterviewCreate(BaseModel):
    candidate_id: uuid.UUID
    opening_id: Optional[uuid.UUID] = None
    interviewer_id: Optional[uuid.UUID] = None
    scheduled_at: datetime
    duration_minutes: int = 60
    location: Optional[str] = None
    meeting_link: Optional[str] = None
    interview_type: str = "hr"


@router.get("/interviews")
async def list_interviews(
    candidate_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Interview).where(Interview.tenant_id == current_user.tenant_id)
    count_stmt = select(func.count(Interview.id)).where(Interview.tenant_id == current_user.tenant_id)

    if candidate_id:
        stmt = stmt.where(Interview.candidate_id == candidate_id)
        count_stmt = count_stmt.where(Interview.candidate_id == candidate_id)
    if status:
        stmt = stmt.where(Interview.status == status)
        count_stmt = count_stmt.where(Interview.status == status)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(Interview.scheduled_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    return {
        "items": [
            {
                "id": str(i.id),
                "candidate_id": str(i.candidate_id),
                "opening_id": str(i.opening_id) if i.opening_id else None,
                "interviewer_id": str(i.interviewer_id) if i.interviewer_id else None,
                "scheduled_at": i.scheduled_at.isoformat() if i.scheduled_at else None,
                "duration_minutes": i.duration_minutes,
                "location": i.location,
                "meeting_link": i.meeting_link,
                "interview_type": i.interview_type,
                "status": i.status,
                "feedback": i.feedback,
                "rating": i.rating,
                "recommendation": i.recommendation,
            }
            for i in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.post("/interviews")
async def create_interview(
    data: InterviewCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    interview = Interview(
        tenant_id=current_user.tenant_id,
        **data.model_dump(),
    )
    db.add(interview)
    await db.commit()
    return {"id": str(interview.id), "status": interview.status}


@router.put("/interviews/{interview_id}/feedback")
async def submit_feedback(
    interview_id: uuid.UUID,
    data: InterviewFeedbackUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    interview = await db.get(Interview, interview_id)
    if not interview or interview.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Interview not found")
    interview.feedback = data.feedback
    interview.rating = data.rating
    interview.recommendation = data.recommendation
    interview.status = "completed"
    interview.conducted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(interview.id), "status": "completed"}


# ---- Offers ----

class OfferCreate(BaseModel):
    candidate_id: uuid.UUID
    opening_id: Optional[uuid.UUID] = None
    offered_salary: float
    offered_designation: Optional[str] = None
    offered_department_id: Optional[uuid.UUID] = None
    joining_date: Optional[date] = None
    expiry_date: Optional[date] = None
    notes: Optional[str] = None


@router.get("/offers")
async def list_offers(
    candidate_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Offer).where(Offer.tenant_id == current_user.tenant_id)
    if candidate_id:
        stmt = stmt.where(Offer.candidate_id == candidate_id)
    if status:
        stmt = stmt.where(Offer.status == status)
    stmt = stmt.order_by(Offer.created_at.desc())

    result = await db.execute(stmt)
    items = result.scalars().all()

    return [
        {
            "id": str(o.id),
            "candidate_id": str(o.candidate_id),
            "opening_id": str(o.opening_id) if o.opening_id else None,
            "offered_salary": o.offered_salary,
            "offered_designation": o.offered_designation,
            "joining_date": str(o.joining_date) if o.joining_date else None,
            "expiry_date": str(o.expiry_date) if o.expiry_date else None,
            "status": o.status,
            "notes": o.notes,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        }
        for o in items
    ]


@router.post("/offers")
async def create_offer(
    data: OfferCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    offer = Offer(
        tenant_id=current_user.tenant_id,
        created_by=current_user.id,
        **data.model_dump(),
    )
    db.add(offer)

    # Update candidate stage
    candidate = await db.get(Candidate, data.candidate_id)
    if candidate:
        candidate.stage = "offer"

    await db.commit()
    return {"id": str(offer.id), "status": offer.status}


@router.put("/offers/{offer_id}/accept")
async def accept_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    offer = await db.get(Offer, offer_id)
    if not offer or offer.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Offer not found")
    offer.status = "accepted"
    offer.accepted_at = datetime.now(timezone.utc)

    candidate = await db.get(Candidate, offer.candidate_id)
    if candidate:
        candidate.stage = "accepted"

    await db.commit()
    return {"id": str(offer.id), "status": "accepted"}


@router.put("/offers/{offer_id}/reject")
async def reject_offer(
    offer_id: uuid.UUID,
    data: OfferReject,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    offer = await db.get(Offer, offer_id)
    if not offer or offer.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Offer not found")
    offer.status = "rejected"
    offer.rejected_at = datetime.now(timezone.utc)
    offer.rejection_reason = data.reason

    candidate = await db.get(Candidate, offer.candidate_id)
    if candidate:
        candidate.stage = "rejected"

    await db.commit()
    return {"id": str(offer.id), "status": "rejected"}


# ---- Dashboard Stats ----

@router.get("/stats")
async def recruitment_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tid = current_user.tenant_id

    open_positions = (await db.execute(
        select(func.count(JobOpening.id)).where(JobOpening.tenant_id == tid, JobOpening.status == "published")
    )).scalar() or 0

    active_candidates = (await db.execute(
        select(func.count(Candidate.id)).where(Candidate.tenant_id == tid, Candidate.stage.notin_(["rejected", "joined"]))
    )).scalar() or 0

    interviews_scheduled = (await db.execute(
        select(func.count(Interview.id)).where(Interview.tenant_id == tid, Interview.status == "scheduled")
    )).scalar() or 0

    offers_released = (await db.execute(
        select(func.count(Offer.id)).where(Offer.tenant_id == tid, Offer.status.in_(["sent", "pending"]))
    )).scalar() or 0

    hired_this_month = (await db.execute(
        select(func.count(Candidate.id)).where(Candidate.tenant_id == tid, Candidate.stage == "joined")
    )).scalar() or 0

    return {
        "open_positions": open_positions,
        "active_candidates": active_candidates,
        "interviews_scheduled": interviews_scheduled,
        "offers_released": offers_released,
        "hired_this_month": hired_this_month,
    }


# ---- Pipeline Stages ----

@router.get("/pipeline")
async def get_pipeline(
    opening_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stages = ["applied", "screening", "hr_interview", "technical_interview", "manager_interview", "final_round", "offer", "accepted", "joined", "rejected"]

    stmt = select(Candidate.stage, func.count(Candidate.id)).where(Candidate.tenant_id == current_user.tenant_id)
    if opening_id:
        stmt = stmt.where(Candidate.opening_id == opening_id)
    stmt = stmt.group_by(Candidate.stage)

    result = await db.execute(stmt)
    counts = {stage: cnt for stage, cnt in result.all()}

    return [
        {"stage": stage, "count": counts.get(stage, 0)}
        for stage in stages
    ]
