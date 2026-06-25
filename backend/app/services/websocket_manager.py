"""WebSocket connection manager for real-time dashboard."""

import asyncio
import json
import uuid
from datetime import datetime
from typing import Optional
from fastapi import WebSocket, WebSocketDisconnect
import structlog

logger = structlog.get_logger()


class ConnectionManager:
    """Manages WebSocket connections grouped by tenant."""

    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, tenant_id: str):
        await websocket.accept()
        async with self._lock:
            if tenant_id not in self.active_connections:
                self.active_connections[tenant_id] = []
            self.active_connections[tenant_id].append(websocket)
        logger.info("websocket_connected", tenant_id=tenant_id)

    async def disconnect(self, websocket: WebSocket, tenant_id: str):
        async with self._lock:
            if tenant_id in self.active_connections:
                self.active_connections[tenant_id] = [
                    ws for ws in self.active_connections[tenant_id] if ws != websocket
                ]
                if not self.active_connections[tenant_id]:
                    del self.active_connections[tenant_id]
        logger.info("websocket_disconnected", tenant_id=tenant_id)

    async def send_to_tenant(self, tenant_id: str, message: dict):
        """Send a message to all connections for a tenant."""
        async with self._lock:
            connections = self.active_connections.get(tenant_id, [])

        if not connections:
            return

        dead = []
        for ws in connections:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)

        if dead:
            async with self._lock:
                if tenant_id in self.active_connections:
                    self.active_connections[tenant_id] = [
                        ws for ws in self.active_connections[tenant_id] if ws not in dead
                    ]

    async def broadcast_dashboard_update(self, tenant_id: str, stats: dict):
        """Push dashboard stats update."""
        await self.send_to_tenant(tenant_id, {
            "type": "dashboard_update",
            "data": stats,
            "timestamp": datetime.utcnow().isoformat(),
        })

    async def broadcast_device_status(self, tenant_id: str, device_id: str, status: str):
        """Push device status change."""
        await self.send_to_tenant(tenant_id, {
            "type": "device_status",
            "data": {"device_id": device_id, "status": status},
            "timestamp": datetime.utcnow().isoformat(),
        })

    async def broadcast_punch_event(self, tenant_id: str, punch_data: dict):
        """Push new punch event."""
        await self.send_to_tenant(tenant_id, {
            "type": "punch_event",
            "data": punch_data,
            "timestamp": datetime.utcnow().isoformat(),
        })

    async def broadcast_visitor_event(self, tenant_id: str, event_type: str, data: dict):
        """Push visitor check-in/out event."""
        await self.send_to_tenant(tenant_id, {
            "type": f"visitor_{event_type}",
            "data": data,
            "timestamp": datetime.utcnow().isoformat(),
        })

    def get_connection_count(self, tenant_id: Optional[str] = None) -> int:
        if tenant_id:
            return len(self.active_connections.get(tenant_id, []))
        return sum(len(conns) for conns in self.active_connections.values())


ws_manager = ConnectionManager()
