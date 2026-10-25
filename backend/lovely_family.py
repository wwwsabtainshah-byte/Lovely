from fastapi import APIRouter, Depends, HTTPException
import sqlite3
from datetime import datetime, timezone
from pydantic import BaseModel, Field

router = APIRouter(prefix="/family", tags=["Family"])
_db = None
_auth = None


def setup_family(database, get_current_account):
    global _db, _auth
    _db, _auth = database, get_current_account

    with database() as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS lovely_families (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            leader_id INTEGER NOT NULL UNIQUE,
            announcement TEXT NOT NULL DEFAULT '',
            level INTEGER NOT NULL DEFAULT 1,
            points INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(leader_id) REFERENCES accounts(id)
        );

        CREATE TABLE IF NOT EXISTS lovely_family_members (
            account_id INTEGER PRIMARY KEY,
            family_id INTEGER NOT NULL,
            joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(account_id) REFERENCES accounts(id),
            FOREIGN KEY(family_id) REFERENCES lovely_families(id)
        );

        CREATE TABLE IF NOT EXISTS lovely_family_join_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            family_id INTEGER NOT NULL,
            account_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            responded_at TEXT,
            FOREIGN KEY(family_id) REFERENCES lovely_families(id),
            FOREIGN KEY(account_id) REFERENCES accounts(id)
        );
        CREATE UNIQUE INDEX IF NOT EXISTS idx_family_pending_request
        ON lovely_family_join_requests(family_id, account_id)
        WHERE status = 'pending';

        """)


class FamilyName(BaseModel):
    name: str = Field(min_length=3, max_length=30)


class FamilyAnnouncement(BaseModel):
    announcement: str = Field(max_length=300)


def current_family(db, account_id):
    return db.execute("""
        SELECT f.*, a.username AS leader
        FROM lovely_families f
        JOIN lovely_family_members m ON m.family_id = f.id
        JOIN accounts a ON a.id = f.leader_id
        WHERE m.account_id = ?
    """, (account_id,)).fetchone()


@router.post("/create")
def create_family(data: FamilyName, account=Depends(lambda: None)):
    raise HTTPException(status_code=503, detail="Use authenticated family router")


def install_authenticated_routes():
    # Remove the old placeholder and any previously installed create route.
    router.routes[:] = [
        r for r in router.routes
        if not (
            r.path in ("/family/create", "/create")
            and "POST" in getattr(r, "methods", set())
        )
    ]

    @router.post("/create")
    def create(data: FamilyName, account=Depends(_auth)):
        name = data.name.strip()
        if len(name) < 3:
            raise HTTPException(400, "Family name too short")
        with _db() as db:
            uid = account["id"]
            if current_family(db, uid):
                raise HTTPException(409, "Already in a family")
            if db.execute(
                "SELECT 1 FROM lovely_families WHERE name = ?", (name,)
            ).fetchone():
                raise HTTPException(409, "Family name already exists")

            fee = 1_000_000
            wallet = db.execute(
                "SELECT coins FROM wallets WHERE account_id=?", (uid,)
            ).fetchone()
            if not wallet or wallet["coins"] < fee:
                raise HTTPException(
                    400, "Not enough coins. Creating a Family costs 1,000,000 coins."
                )

            db.execute(
                "UPDATE wallets SET coins=coins-?, updated_at=? "
                "WHERE account_id=? AND coins>=?",
                (fee, datetime.now(timezone.utc).isoformat(), uid, fee),
            )
            if db.execute("SELECT changes()").fetchone()[0] != 1:
                raise HTTPException(400, "Not enough coins")

            db.execute(
                """INSERT INTO wallet_transactions
                   (account_id, amount, transaction_type, description, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (uid, -fee, "family_create_fee",
                 "Family creation fee", datetime.now(timezone.utc).isoformat()),
            )

            try:
                cur = db.execute(
                    "INSERT INTO lovely_families(name, leader_id) VALUES (?, ?)",
                    (name, uid)
                )
            except sqlite3.IntegrityError:
                raise HTTPException(409, "Family name already exists")

            db.execute(
                "INSERT INTO lovely_family_members(account_id, family_id) VALUES (?, ?)",
                (uid, cur.lastrowid)
            )
            return {
                "success": True,
                "family_id": cur.lastrowid,
                "coins_charged": fee,
            }

    @router.post("/join/{family_id}")
    def join(family_id: int, account=Depends(_auth)):
        uid = account["id"]
        with _db() as db:
            if current_family(db, uid):
                raise HTTPException(409, "Already in a family")
            if not db.execute(
                "SELECT 1 FROM lovely_families WHERE id = ?", (family_id,)
            ).fetchone():
                raise HTTPException(404, "Family not found")
            pending = db.execute(
                """SELECT id FROM lovely_family_join_requests
                   WHERE family_id=? AND account_id=? AND status='pending'""",
                (family_id, uid)
            ).fetchone()
            if pending:
                return {"success": True, "status": "pending",
                        "message": "Request already pending"}
            db.execute(
                """INSERT INTO lovely_family_join_requests
                   (family_id, account_id, status)
                   VALUES (?, ?, 'pending')""",
                (family_id, uid)
            )
        return {"success": True, "status": "pending",
                "message": "Join request sent; leader approval required",
                "coins_charged": 0}

    class FamilyJoinResponse(BaseModel):
        action: str = Field(pattern="^(accept|reject)$")

    @router.get("/requests")
    def family_requests(account=Depends(_auth)):
        uid = account["id"]
        with _db() as db:
            incoming = db.execute("""
                SELECT r.id AS request_id, r.family_id, r.account_id,
                       a.username, r.created_at
                FROM lovely_family_join_requests r
                JOIN lovely_families f ON f.id = r.family_id
                JOIN accounts a ON a.id = r.account_id
                WHERE f.leader_id=? AND r.status='pending'
                ORDER BY r.created_at
            """, (uid,)).fetchall()
            outgoing = db.execute("""
                SELECT r.id AS request_id, r.family_id, f.name AS family_name,
                       r.status, r.created_at
                FROM lovely_family_join_requests r
                JOIN lovely_families f ON f.id = r.family_id
                WHERE r.account_id=? AND r.status='pending'
                ORDER BY r.created_at DESC
            """, (uid,)).fetchall()
        return {"incoming": [dict(x) for x in incoming],
                "outgoing": [dict(x) for x in outgoing]}

    @router.post("/join-requests/{request_id}/respond")
    def respond_to_join_request(
        request_id: int,
        data: FamilyJoinResponse,
        account=Depends(_auth)
    ):
        uid = account["id"]
        with _db() as db:
            req = db.execute("""
                SELECT r.*, f.leader_id
                FROM lovely_family_join_requests r
                JOIN lovely_families f ON f.id=r.family_id
                WHERE r.id=? AND r.status='pending'
            """, (request_id,)).fetchone()
            if not req:
                raise HTTPException(404, "Pending request not found")
            if req["leader_id"] != uid:
                raise HTTPException(403, "Only the family leader can respond")

            if data.action == "accept":
                if current_family(db, req["account_id"]):
                    raise HTTPException(409, "Applicant is already in a family")
                db.execute(
                    """INSERT INTO lovely_family_members(account_id, family_id)
                       VALUES (?, ?)""",
                    (req["account_id"], req["family_id"])
                )
                status = "accepted"
            else:
                status = "rejected"

            db.execute("""
                UPDATE lovely_family_join_requests
                SET status=?, responded_at=CURRENT_TIMESTAMP
                WHERE id=? AND status='pending'
            """, (status, request_id))
        return {"success": True, "status": status, "coins_charged": 0}

    @router.delete("/members/{member_id}")
    def remove_family_member(member_id: int, account=Depends(_auth)):
        uid = account["id"]
        with _db() as db:
            family = current_family(db, uid)
            if not family:
                raise HTTPException(404, "You are not in a family")
            if family["leader_id"] != uid:
                raise HTTPException(403, "Only the family leader can remove members")
            if member_id == uid:
                raise HTTPException(400, "Leader cannot remove themselves")
            member = db.execute(
                """SELECT 1 FROM lovely_family_members
                   WHERE account_id=? AND family_id=?""",
                (member_id, family["id"])
            ).fetchone()
            if not member:
                raise HTTPException(404, "Member not found in your family")
            db.execute(
                """DELETE FROM lovely_family_members
                   WHERE account_id=? AND family_id=?""",
                (member_id, family["id"])
            )
        return {"success": True, "coins_charged": 0}

    @router.get("/me")
    def my_family(account=Depends(_auth)):
        with _db() as db:
            family = current_family(db, account["id"])
            if not family:
                return {"family": None, "members": []}
            members = db.execute("""
                SELECT a.id, a.username
                FROM lovely_family_members m
                JOIN accounts a ON a.id = m.account_id
                WHERE m.family_id = ?
                ORDER BY m.joined_at
            """, (family["id"],)).fetchall()
            return {
                "family": dict(family),
                "my_account_id": account["id"],
                "members": [dict(m) for m in members]
            }

    @router.post("/leave")
    def leave(account=Depends(_auth)):
        with _db() as db:
            family = current_family(db, account["id"])
            if not family:
                raise HTTPException(404, "Not in a family")
            if family["leader_id"] == account["id"]:
                raise HTTPException(
                    409, "Leader must transfer leadership or disband family"
                )
            db.execute(
                "DELETE FROM lovely_family_members WHERE account_id = ?",
                (account["id"],)
            )
        return {"success": True}

    @router.put("/announcement")
    def announcement(data: FamilyAnnouncement, account=Depends(_auth)):
        with _db() as db:
            family = current_family(db, account["id"])
            if not family or family["leader_id"] != account["id"]:
                raise HTTPException(403, "Family leader only")
            db.execute(
                "UPDATE lovely_families SET announcement = ? WHERE id = ?",
                (data.announcement, family["id"])
            )
        return {"success": True}

    @router.get("/ranking")
    def ranking(account=Depends(_auth)):
        with _db() as db:
            rows = db.execute("""
                SELECT f.id, f.name, f.level, f.points,
                       COUNT(m.account_id) AS members
                FROM lovely_families f
                LEFT JOIN lovely_family_members m ON m.family_id = f.id
                GROUP BY f.id
                ORDER BY f.points DESC, members DESC, f.id ASC
                LIMIT 100
            """).fetchall()
            return {"families": [dict(r) for r in rows]}

    @router.delete("/disband")
    def disband_family(account=Depends(_auth)):
        raise HTTPException(
            status_code=403,
            detail="Family disbanding is disabled. Leaders cannot delete their family."
        )
