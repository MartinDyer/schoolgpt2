import asyncio
import datetime
import re
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import (
    Column,
    DateTime,
    Integer,
    LargeBinary,
    MetaData,
    NVARCHAR,
    String,
    Table,
    Text,
    Boolean,
    UniqueConstraint,
    create_engine,
    select,
    insert,
    update,
    delete,
    and_,
)
from sqlalchemy.engine import Engine


def _parse_odbc_sql_server_connection_string(conn_str: str) -> Tuple[str, str, str, str, Dict[str, str]]:
    # Example: Server=tcp:example.database.windows.net,1433;Initial Catalog=db;User ID=user;Password=pass;Encrypt=True;TrustServerCertificate=False
    """parts = dict(
        (k.strip().lower(), v.strip())
        for k, v in (
            item.split("=", 1)
            for item in re.split(r";(?=(?:[^"]*"[^"]*")*[^"]*$)", conn_str) if item
    if "=" in item
        )
    )"""

    parts = dict(
        (k.strip().lower(), v.strip())
        for k, v in (
            item.split("=", 1)
            for item in re.split(r';(?=(?:[^"]*"[^"]*")*[^"]*$)', conn_str)
            if item and "=" in item
        )
    )

    server = parts.get("server", "").replace("tcp:", "").strip()
    if "," not in server and ":" in server:
        # some strings include tcp:server,1433
        server = server
    database = parts.get("initial catalog", "")
    user = parts.get("user id", "")
    password = parts.get("password", "")
    return server, database, user, password, parts


class SqlConversationClient:
    def __init__(self, odbc_connection_string: str):
        server, database, user, password, parts = _parse_odbc_sql_server_connection_string(odbc_connection_string)
        encrypt = parts.get("encrypt", "true").lower()
        trust = parts.get("trustservercertificate", "false").lower()
        port = "1433"
        if "," in server:
            host, port = server.split(",", 1)
        else:
            host = server
        query_params = [
            f"encrypt={'yes' if encrypt in ['true', 'yes', '1'] else 'no'}",
            f"trustservercertificate={'no' if trust in ['false', 'no', '0'] else 'yes'}",
        ]
        url = f"mssql+pytds://{user}:{password}@{host}:{port}/{database}?" + "&".join(query_params)
        self._engine: Engine = create_engine(url, pool_pre_ping=True, pool_size=5, max_overflow=5)

        self._metadata = MetaData()
        # Minimal schema matching infra/school_safe_database_schema.sql for required operations
        self._users = Table(
            "Users",
            self._metadata,
            Column("UserId", String(36), primary_key=True),
            Column("EntraIdObjectId", NVARCHAR(50), unique=True, nullable=False),
            Column("UserPrincipalName", NVARCHAR(255), nullable=False),
            Column("DisplayName", NVARCHAR(255), nullable=False),
            Column("UserType", NVARCHAR(20), nullable=False),
            Column("IsActive", Boolean, nullable=False, default=True),
        )
        self._chatsessions = Table(
            "ChatSessions",
            self._metadata,
            Column("SessionId", String(36), primary_key=True),
            Column("UserId", String(36), nullable=False),
            Column("SessionTitle", NVARCHAR(255)),
            Column("StartTime", DateTime, default=datetime.datetime.utcnow),
            Column("EndTime", DateTime),
            Column("MessageCount", Integer, default=0),
            Column("IsActive", Boolean, default=True),
        )
        self._chathistory = Table(
            "ChatHistory",
            self._metadata,
            Column("ChatId", String(36), primary_key=True),
            Column("SessionId", String(36), nullable=False),
            Column("UserId", String(36), nullable=False),
            Column("UserMessage", Text, nullable=False),
            Column("AIResponse", Text, nullable=False),
            Column("ResponseTime", DateTime, default=datetime.datetime.utcnow),
            Column("Feedback", NVARCHAR(50)),
            Column("CreatedAt", DateTime, default=datetime.datetime.utcnow),
        )

    async def ensure(self) -> Tuple[bool, Optional[str]]:
        def _ensure():
            self._metadata.create_all(self._engine, checkfirst=True)
        try:
            await asyncio.to_thread(_ensure)
            return True, None
        except Exception as e:
            return False, str(e)

    async def create_conversation(self, user_id: str, title: str) -> Dict[str, Any]:
        session_id = str(user_id) + "-" + uuid4_str()
        now = datetime.datetime.utcnow()
        def _tx():
            with self._engine.begin() as conn:
                conn.execute(insert(self._chatsessions).values(
                    SessionId=session_id,
                    UserId=user_id,
                    SessionTitle=title,
                    StartTime=now,
                    MessageCount=0,
                    IsActive=True,
                ))
            return {"id": session_id, "createdAt": now.isoformat()}
        return await asyncio.to_thread(_tx)

    async def create_message(self, uuid: str, conversation_id: str, user_id: str, input_message: Dict[str, Any]) -> Any:
        role = input_message.get("role")
        content = input_message.get("content", "")
        def _tx():
            with self._engine.begin() as conn:
                conn.execute(insert(self._chathistory).values(
                    ChatId=uuid,
                    SessionId=conversation_id,
                    UserId=user_id,
                    UserMessage=content if role == "user" else "",
                    AIResponse=content if role == "assistant" else "",
                    ResponseTime=datetime.datetime.utcnow(),
                    CreatedAt=datetime.datetime.utcnow(),
                ))
                conn.execute(update(self._chatsessions).where(self._chatsessions.c.SessionId == conversation_id).values(
                    MessageCount=self._chatsessions.c.MessageCount + 1
                ))
            return uuid
        return await asyncio.to_thread(_tx)

    async def update_message_feedback(self, user_id: str, message_id: str, message_feedback: str) -> bool:
        def _tx():
            with self._engine.begin() as conn:
                res = conn.execute(update(self._chathistory).where(
                    and_(self._chathistory.c.ChatId == message_id, self._chathistory.c.UserId == user_id)
                ).values(Feedback=message_feedback))
                return res.rowcount > 0
        return await asyncio.to_thread(_tx)

    async def delete_messages(self, conversation_id: str, user_id: str) -> int:
        def _tx():
            with self._engine.begin() as conn:
                res = conn.execute(delete(self._chathistory).where(
                    and_(self._chathistory.c.SessionId == conversation_id, self._chathistory.c.UserId == user_id)
                ))
                conn.execute(update(self._chatsessions).where(self._chatsessions.c.SessionId == conversation_id).values(MessageCount=0))
                return res.rowcount or 0
        return await asyncio.to_thread(_tx)

    async def delete_conversation(self, user_id: str, conversation_id: str) -> int:
        def _tx():
            with self._engine.begin() as conn:
                conn.execute(delete(self._chathistory).where(
                    and_(self._chathistory.c.SessionId == conversation_id, self._chathistory.c.UserId == user_id)
                ))
                res = conn.execute(delete(self._chatsessions).where(
                    and_(self._chatsessions.c.SessionId == conversation_id, self._chatsessions.c.UserId == user_id)
                ))
                return res.rowcount or 0
        return await asyncio.to_thread(_tx)

    async def get_conversations(self, user_id: str, offset: int = 0, limit: Optional[int] = 25) -> List[Dict[str, Any]]:
        def _tx():
            with self._engine.begin() as conn:
                q = select(
                    self._chatsessions.c.SessionId.label("id"),
                    self._chatsessions.c.SessionTitle.label("title"),
                    self._chatsessions.c.StartTime.label("createdAt"),
                ).where(self._chatsessions.c.UserId == user_id).order_by(self._chatsessions.c.StartTime.desc())
                if limit:
                    q = q.offset(int(offset)).limit(int(limit))
                rows = conn.execute(q).mappings().all()
                return [dict(r) for r in rows]
        return await asyncio.to_thread(_tx)

    async def get_conversation(self, user_id: str, conversation_id: str) -> Optional[Dict[str, Any]]:
        def _tx():
            with self._engine.begin() as conn:
                row = conn.execute(select(self._chatsessions).where(
                    and_(self._chatsessions.c.SessionId == conversation_id, self._chatsessions.c.UserId == user_id)
                )).mappings().first()
                return dict(row) if row else None
        return await asyncio.to_thread(_tx)

    async def get_messages(self, user_id: str, conversation_id: str) -> List[Dict[str, Any]]:
        def _tx():
            with self._engine.begin() as conn:
                rows = conn.execute(select(
                    self._chathistory.c.ChatId.label("id"),
                    self._chathistory.c.UserId,
                    self._chathistory.c.UserMessage,
                    self._chathistory.c.AIResponse,
                    self._chathistory.c.CreatedAt,
                    self._chathistory.c.Feedback,
                ).where(
                    and_(self._chathistory.c.SessionId == conversation_id, self._chathistory.c.UserId == user_id)
                ).order_by(self._chathistory.c.CreatedAt.asc())).mappings().all()
                messages = []
                for r in rows:
                    if r["UserMessage"]:
                        messages.append({
                            "id": r["id"],
                            "role": "user",
                            "content": r["UserMessage"],
                            "createdAt": r["CreatedAt"].isoformat(),
                            "feedback": r.get("Feedback"),
                        })
                    if r["AIResponse"]:
                        messages.append({
                            "id": r["id"],
                            "role": "assistant",
                            "content": r["AIResponse"],
                            "createdAt": r["CreatedAt"].isoformat(),
                            "feedback": r.get("Feedback"),
                        })
                return messages
        return await asyncio.to_thread(_tx)

    async def upsert_conversation(self, conversation: Dict[str, Any]) -> Dict[str, Any]:
        session_id = conversation.get("id") or conversation.get("SessionId")
        title = conversation.get("title") or conversation.get("SessionTitle")
        def _tx():
            with self._engine.begin() as conn:
                existing = conn.execute(select(self._chatsessions.c.SessionId).where(self._chatsessions.c.SessionId == session_id)).first()
                if existing:
                    conn.execute(update(self._chatsessions).where(self._chatsessions.c.SessionId == session_id).values(SessionTitle=title))
                else:
                    conn.execute(insert(self._chatsessions).values(SessionId=session_id, UserId=conversation.get("UserId"), SessionTitle=title, StartTime=datetime.datetime.utcnow()))
            return {"id": session_id, "title": title}
        return await asyncio.to_thread(_tx)


def uuid4_str() -> str:
    import uuid as _uuid
    return str(_uuid.uuid4()) 