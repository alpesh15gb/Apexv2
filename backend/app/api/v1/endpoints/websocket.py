"""WebSocket endpoint for real-time dashboard updates."""

import uuid
from datetime import datetime
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.core.security import decode_token
from app.services.websocket_manager import ws_manager
import structlog

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.websocket("/ws/dashboard")
async def dashboard_websocket(
    websocket: WebSocket,
    token: str = Query(...),
):
    """WebSocket endpoint for real-time dashboard. Auth via query param token."""
    # Authenticate
    payload = decode_token(token)
    if not payload:
        await websocket.close(code=4001, reason="Invalid token")
        return

    tenant_id = payload.get("tenant_id")
    user_id = payload.get("sub")
    if not tenant_id:
        await websocket.close(code=4001, reason="No tenant in token")
        return

    await ws_manager.connect(websocket, tenant_id)
    logger.info("ws_client_connected", tenant_id=tenant_id, user_id=user_id)

    try:
        while True:
            # Keep connection alive, handle client messages
            data = await websocket.receive_text()
            # Client can request specific data
            if data == "ping":
                await websocket.send_json({"type": "pong", "timestamp": datetime.utcnow().isoformat()})
    except WebSocketDisconnect:
        await ws_manager.disconnect(websocket, tenant_id)
        logger.info("ws_client_disconnected", tenant_id=tenant_id, user_id=user_id)
    except Exception as e:
        logger.error("ws_error", error=str(e), tenant_id=tenant_id)
        await ws_manager.disconnect(websocket, tenant_id)
