"""Performance Management API endpoints."""

import uuid
from datetime import datetime, timezone, date
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.performance import ReviewCycle, Goal, PerformanceReview, Competency, PerformanceRecommendation

router = APIRouter()


class ReviewSubmit(BaseModel):
    rating: Optional[float] = None
    strengths: Optional[str] = None
    improvements: Optional[str] = None
    comments: Optional[str] = None
    goals_achievement: Optional[str] = None
    competency_scores: Optional[dict] = None


class GoalProgressUpdate(BaseModel):
    progress: Optional[float] = None
    current_value: Optional[float] = None


# ---- Review Cycles ----

class CycleCreate(BaseModel):
    name: str
    description: Optional[str] = None
    cycle_type: str = "quarterly"
    start_date: date
    end_date: date
    self_review_due: Optional[date] = None
    manager_review_due: Optional[date] = None


@router.get("/cycles")
async def list_cycles(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ReviewCycle).where(ReviewCycle.tenant_id == current_user.tenant_id)
    if status:
        stmt = stmt.where(ReviewCycle.status == status)
    stmt = stmt.order_by(ReviewCycle.created_at.desc())
    result = await db.execute(stmt)
    cycles = result.scalars().all()
    return [
        {
            "id": str(c.id), "name": c.name, "description": c.description,
            "cycle_type": c.cycle_type, "start_date": str(c.start_date), "end_date": str(c.end_date),
            "self_review_due": str(c.self_review_due) if c.self_review_due else None,
            "manager_review_due": str(c.manager_review_due) if c.manager_review_due else None,
            "status": c.status, "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in cycles
    ]


@router.post("/cycles")
async def create_cycle(
    data: CycleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    cycle = ReviewCycle(
        tenant_id=current_user.tenant_id,
        created_by=current_user.id,
        **data.model_dump(),
    )
    db.add(cycle)
    await db.commit()
    return {"id": str(cycle.id), "name": cycle.name, "status": cycle.status}


@router.put("/cycles/{cycle_id}")
async def update_cycle(
    cycle_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    cycle = await db.get(ReviewCycle, cycle_id)
    if not cycle or cycle.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Cycle not found")
    for k, v in data.items():
        if hasattr(cycle, k) and k not in ("id", "tenant_id"):
            setattr(cycle, k, v)
    await db.commit()
    return {"id": str(cycle.id), "status": cycle.status}


@router.post("/cycles/{cycle_id}/publish")
async def publish_cycle(
    cycle_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    cycle = await db.get(ReviewCycle, cycle_id)
    if not cycle or cycle.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Cycle not found")
    cycle.status = "published"
    await db.commit()
    return {"id": str(cycle.id), "status": "published"}


# ---- Goals ----

class GoalCreate(BaseModel):
    employee_id: uuid.UUID
    cycle_id: Optional[uuid.UUID] = None
    title: str
    description: Optional[str] = None
    goal_type: str = "individual"
    category: Optional[str] = None
    weightage: float = 0
    target_value: Optional[float] = None
    due_date: Optional[date] = None


@router.get("/goals")
async def list_goals(
    employee_id: Optional[uuid.UUID] = None,
    cycle_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Goal).where(Goal.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(Goal.employee_id == employee_id)
    if cycle_id:
        stmt = stmt.where(Goal.cycle_id == cycle_id)
    if status:
        stmt = stmt.where(Goal.status == status)
    stmt = stmt.order_by(Goal.created_at.desc())
    result = await db.execute(stmt)
    goals = result.scalars().all()
    return [
        {
            "id": str(g.id), "employee_id": str(g.employee_id),
            "cycle_id": str(g.cycle_id) if g.cycle_id else None,
            "title": g.title, "description": g.description,
            "goal_type": g.goal_type, "category": g.category,
            "weightage": g.weightage, "target_value": g.target_value,
            "current_value": g.current_value, "progress": g.progress,
            "due_date": str(g.due_date) if g.due_date else None,
            "status": g.status,
            "created_at": g.created_at.isoformat() if g.created_at else None,
        }
        for g in goals
    ]


@router.post("/goals")
async def create_goal(
    data: GoalCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    goal = Goal(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(goal)
    await db.commit()
    return {"id": str(goal.id), "title": goal.title, "status": goal.status}


@router.put("/goals/{goal_id}")
async def update_goal(
    goal_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    goal = await db.get(Goal, goal_id)
    if not goal or goal.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    for k, v in data.items():
        if hasattr(goal, k) and k not in ("id", "tenant_id"):
            setattr(goal, k, v)
    await db.commit()
    return {"id": str(goal.id), "status": goal.status}


@router.put("/goals/{goal_id}/progress")
async def update_goal_progress(
    goal_id: uuid.UUID,
    data: GoalProgressUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    goal = await db.get(Goal, goal_id)
    if not goal or goal.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    if data.progress is not None:
        goal.progress = data.progress
    if data.current_value is not None:
        goal.current_value = data.current_value
    if goal.progress is not None and goal.progress >= 100:
        goal.status = "completed"
    await db.commit()
    return {"id": str(goal.id), "progress": goal.progress, "status": goal.status}


@router.post("/goals/{goal_id}/approve")
async def approve_goal(
    goal_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    goal = await db.get(Goal, goal_id)
    if not goal or goal.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    goal.status = "approved"
    goal.approved_by = current_user.id
    goal.approved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(goal.id), "status": "approved"}


# ---- Performance Reviews ----

class ReviewCreate(BaseModel):
    cycle_id: uuid.UUID
    employee_id: uuid.UUID
    review_type: str = "self"


@router.get("/reviews")
async def list_reviews(
    cycle_id: Optional[uuid.UUID] = None,
    employee_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(PerformanceReview).where(PerformanceReview.tenant_id == current_user.tenant_id)
    if cycle_id:
        stmt = stmt.where(PerformanceReview.cycle_id == cycle_id)
    if employee_id:
        stmt = stmt.where(PerformanceReview.employee_id == employee_id)
    if status:
        stmt = stmt.where(PerformanceReview.status == status)
    stmt = stmt.order_by(PerformanceReview.created_at.desc())
    result = await db.execute(stmt)
    reviews = result.scalars().all()
    return [
        {
            "id": str(r.id), "cycle_id": str(r.cycle_id), "employee_id": str(r.employee_id),
            "reviewer_id": str(r.reviewer_id) if r.reviewer_id else None,
            "review_type": r.review_type, "status": r.status, "rating": r.rating,
            "strengths": r.strengths, "improvements": r.improvements, "comments": r.comments,
            "goals_achievement": r.goals_achievement,
            "submitted_at": r.submitted_at.isoformat() if r.submitted_at else None,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in reviews
    ]


@router.post("/reviews")
async def create_review(
    data: ReviewCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    review = PerformanceReview(
        tenant_id=current_user.tenant_id,
        reviewer_id=current_user.id,
        **data.model_dump(),
    )
    db.add(review)
    await db.commit()
    return {"id": str(review.id), "status": review.status}


@router.put("/reviews/{review_id}/submit")
async def submit_review(
    review_id: uuid.UUID,
    data: ReviewSubmit,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    review = await db.get(PerformanceReview, review_id)
    if not review or review.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Review not found")
    if data.rating is not None:
        review.rating = data.rating
    if data.strengths is not None:
        review.strengths = data.strengths
    if data.improvements is not None:
        review.improvements = data.improvements
    if data.comments is not None:
        review.comments = data.comments
    if data.goals_achievement is not None:
        review.goals_achievement = data.goals_achievement
    if data.competency_scores is not None:
        review.competency_scores = data.competency_scores
    review.status = "submitted"
    review.submitted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(review.id), "status": "submitted", "rating": review.rating}


# ---- Competencies ----

class CompetencyCreate(BaseModel):
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    sort_order: int = 0


@router.get("/competencies")
async def list_competencies(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Competency).where(Competency.tenant_id == current_user.tenant_id, Competency.is_active == True).order_by(Competency.sort_order)
    result = await db.execute(stmt)
    comps = result.scalars().all()
    return [
        {"id": str(c.id), "name": c.name, "description": c.description, "category": c.category, "sort_order": c.sort_order}
        for c in comps
    ]


@router.post("/competencies")
async def create_competency(
    data: CompetencyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    comp = Competency(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(comp)
    await db.commit()
    return {"id": str(comp.id), "name": comp.name}


# ---- Recommendations ----

class RecommendationCreate(BaseModel):
    review_id: uuid.UUID
    employee_id: uuid.UUID
    recommendation_type: str
    details: Optional[str] = None
    salary_increment: Optional[float] = None
    new_designation_id: Optional[uuid.UUID] = None


@router.get("/recommendations")
async def list_recommendations(
    employee_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(PerformanceRecommendation).where(PerformanceRecommendation.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(PerformanceRecommendation.employee_id == employee_id)
    if status:
        stmt = stmt.where(PerformanceRecommendation.status == status)
    stmt = stmt.order_by(PerformanceRecommendation.created_at.desc())
    result = await db.execute(stmt)
    recs = result.scalars().all()
    return [
        {
            "id": str(r.id), "review_id": str(r.review_id), "employee_id": str(r.employee_id),
            "recommendation_type": r.recommendation_type, "details": r.details,
            "salary_increment": r.salary_increment, "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in recs
    ]


@router.post("/recommendations")
async def create_recommendation(
    data: RecommendationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    rec = PerformanceRecommendation(
        tenant_id=current_user.tenant_id,
        recommended_by=current_user.id,
        **data.model_dump(),
    )
    db.add(rec)
    await db.commit()
    return {"id": str(rec.id), "status": rec.status}


@router.put("/recommendations/{rec_id}/approve")
async def approve_recommendation(
    rec_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    rec = await db.get(PerformanceRecommendation, rec_id)
    if not rec or rec.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    rec.status = "approved"
    rec.approved_by = current_user.id
    rec.approved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(rec.id), "status": "approved"}


# ---- Dashboard Stats ----

@router.get("/stats")
async def performance_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tid = current_user.tenant_id

    active_cycles = (await db.execute(
        select(func.count(ReviewCycle.id)).where(ReviewCycle.tenant_id == tid, ReviewCycle.status.in_(["published", "self_review", "manager_review"]))
    )).scalar() or 0

    total_goals = (await db.execute(
        select(func.count(Goal.id)).where(Goal.tenant_id == tid)
    )).scalar() or 0

    completed_goals = (await db.execute(
        select(func.count(Goal.id)).where(Goal.tenant_id == tid, Goal.status == "completed")
    )).scalar() or 0

    pending_reviews = (await db.execute(
        select(func.count(PerformanceReview.id)).where(PerformanceReview.tenant_id == tid, PerformanceReview.status == "pending")
    )).scalar() or 0

    completed_reviews = (await db.execute(
        select(func.count(PerformanceReview.id)).where(PerformanceReview.tenant_id == tid, PerformanceReview.status == "submitted")
    )).scalar() or 0

    avg_rating = (await db.execute(
        select(func.avg(PerformanceReview.rating)).where(PerformanceReview.tenant_id == tid, PerformanceReview.rating.isnot(None))
    )).scalar()

    return {
        "active_cycles": active_cycles,
        "total_goals": total_goals,
        "completed_goals": completed_goals,
        "pending_reviews": pending_reviews,
        "completed_reviews": completed_reviews,
        "average_rating": round(avg_rating, 1) if avg_rating else 0,
    }
