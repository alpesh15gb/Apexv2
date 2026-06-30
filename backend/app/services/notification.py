import uuid
import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db.session import get_db
from app.models.notification import Notification, NotificationType, NotificationStatus
from app.models.user import User

logger = logging.getLogger("NotificationService")

class NotificationService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_notification(
        self,
        tenant_id: uuid.UUID,
        user_id: uuid.UUID,
        title: str,
        message: str,
        notification_type: str,
        channel: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Notification:
        # Check if user exists and belongs to tenant
        stmt_user = select(User).where(User.id == user_id, User.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_user)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        notification = Notification(
            tenant_id=tenant_id,
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            channel=channel,
            status=NotificationStatus.PENDING.value,
            metadata_=metadata
        )
        self.db.add(notification)
        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def send_email(self, to: str, subject: str, body: str) -> None:
        settings = get_settings()
        if not settings.SMTP_HOST or not settings.SMTP_USER:
            logger.warning("smtp_not_configured, skipping email", to=to, subject=subject)
            return
        try:
            import aiosmtplib
            msg = MIMEMultipart()
            msg["From"] = settings.SMTP_FROM_EMAIL or settings.SMTP_USER
            msg["To"] = to
            msg["Subject"] = subject
            msg.attach(MIMEText(body, "html"))
            await aiosmtplib.send(
                msg,
                hostname=settings.SMTP_HOST,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USER,
                password=settings.SMTP_PASSWORD,
                start_tls=True,
            )
            logger.info("email_sent", to=to, subject=subject)
        except Exception as e:
            logger.error("email_send_failed", to=to, subject=subject, error=str(e))
            raise

    async def send_sms(self, phone: str, message: str) -> None:
        settings = get_settings()
        if not settings.SMS_API_URL or not settings.SMS_API_KEY:
            logger.warning("sms_not_configured, skipping sms", phone=phone)
            return
        try:
            import httpx
            async with httpx.AsyncClient() as client:
                await client.post(
                    settings.SMS_API_URL,
                    json={"phone": phone, "message": message, "api_key": settings.SMS_API_KEY},
                    timeout=10,
                )
            logger.info("sms_sent", phone=phone)
        except Exception as e:
            logger.error("sms_send_failed", phone=phone, error=str(e))
            raise

    async def send_notification(self, notification_id: uuid.UUID) -> Notification:
        stmt = select(Notification).where(Notification.id == notification_id).options(selectinload(Notification.user))
        res = await self.db.execute(stmt)
        notification = res.scalar_one_or_none()
        if not notification:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")

        if notification.status == NotificationStatus.READ.value:
            return notification

        user = notification.user
        success = True
        try:
            if notification.notification_type == NotificationType.EMAIL.value:
                if user.email:
                    await self.send_email(user.email, notification.title, notification.message)
                else:
                    raise ValueError(f"User {user.id} has no email configured")
            elif notification.notification_type == NotificationType.SMS.value:
                if user.phone:
                    await self.send_sms(user.phone, notification.message)
                else:
                    raise ValueError(f"User {user.id} has no phone configured")
            elif notification.notification_type == NotificationType.PUSH.value:
                logger.info(f"[PUSH SENDING] User: {user.id} | Title: {notification.title} | Message: {notification.message}")
            elif notification.notification_type == NotificationType.IN_APP.value:
                logger.info(f"[IN_APP SENDING] User: {user.id} | Title: {notification.title} | Message: {notification.message}")
            else:
                raise ValueError(f"Unknown notification type: {notification.notification_type}")

            notification.status = NotificationStatus.SENT.value
            notification.sent_at = datetime.now(timezone.utc)
        except Exception as e:
            logger.error(f"Failed to send notification {notification_id}: {str(e)}")
            notification.status = NotificationStatus.FAILED.value
            success = False

        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def list_notifications(
        self,
        tenant_id: uuid.UUID,
        user_id: uuid.UUID,
        status_val: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Notification], int]:
        count_stmt = select(func.count(Notification.id)).where(
            Notification.tenant_id == tenant_id,
            Notification.user_id == user_id
        )
        stmt = select(Notification).where(
            Notification.tenant_id == tenant_id,
            Notification.user_id == user_id
        ).order_by(Notification.created_at.desc())

        if status_val:
            count_stmt = count_stmt.where(Notification.status == status_val)
            stmt = stmt.where(Notification.status == status_val)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        notifications = list(res.scalars().all())
        return notifications, total

    async def mark_as_read(self, notification_id: uuid.UUID, user_id: uuid.UUID) -> Notification:
        stmt = select(Notification).where(Notification.id == notification_id, Notification.user_id == user_id)
        res = await self.db.execute(stmt)
        notification = res.scalar_one_or_none()
        if not notification:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")

        notification.status = NotificationStatus.READ.value
        notification.read_at = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def get_unread_count(self, user_id: uuid.UUID, tenant_id: uuid.UUID) -> int:
        stmt = select(func.count(Notification.id)).where(
            Notification.user_id == user_id,
            Notification.tenant_id == tenant_id,
            Notification.status != NotificationStatus.READ.value
        )
        res = await self.db.execute(stmt)
        return res.scalar() or 0
