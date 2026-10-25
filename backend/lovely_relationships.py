import sqlite3
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

CP_INVITE_FEE = 1_000_000
CP_SELF_REMOVE_FEE = 5_000_000

router = APIRouter(prefix="/relationships", tags=["Lovely Relationships"])


def now():
    return datetime.now(timezone.utc).isoformat()


class RespondRequest(BaseModel):
    action: str = Field(pattern="^(accept|reject)$")


def setup_relationships(database, get_current_account):
    with database() as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS lovely_cp (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user1 INTEGER NOT NULL,
            user2 INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS lovely_relationship_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER NOT NULL,
            receiver_id INTEGER NOT NULL,
            kind TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            UNIQUE(sender_id, receiver_id, kind, status)
        );

        CREATE TABLE IF NOT EXISTS lovely_siblings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user1 INTEGER NOT NULL,
            user2 INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_rel_receiver_status
        ON lovely_relationship_requests(receiver_id, status);

        CREATE UNIQUE INDEX IF NOT EXISTS idx_lovely_cp_active_user1
        ON lovely_cp(user1) WHERE status='active';

        CREATE UNIQUE INDEX IF NOT EXISTS idx_lovely_cp_active_user2
        ON lovely_cp(user2) WHERE status='active';

        CREATE UNIQUE INDEX IF NOT EXISTS idx_lovely_siblings_active_pair
        ON lovely_siblings(user1, user2) WHERE status='active';
        """)

    def profile(db, account_id):
        row = db.execute(
            "SELECT id, username, user_code, role FROM accounts WHERE id=?",
            (account_id,),
        ).fetchone()
        if not row:
            return None
        result = dict(row)
        try:
            result["display_name"] = result.get("username")
            result["profile_photo"] = ""
            cols = {r["name"] for r in db.execute("PRAGMA table_info(accounts)")}
            if "display_name" in cols:
                result["display_name"] = db.execute(
                    "SELECT display_name FROM accounts WHERE id=?",
                    (account_id,),
                ).fetchone()["display_name"] or result["username"]
            if "profile_photo" in cols:
                result["profile_photo"] = db.execute(
                    "SELECT profile_photo FROM accounts WHERE id=?",
                    (account_id,),
                ).fetchone()["profile_photo"] or ""
        except (KeyError, TypeError):
            pass
        return result

    @router.get("/search/{user_code}")
    def search_user(user_code: str, account=Depends(get_current_account)):
        with database() as db:
            target = db.execute(
                """SELECT id, username, user_code, role
                   FROM accounts WHERE user_code=?""",
                (user_code.strip(),),
            ).fetchone()
            if not target or target["id"] == account["id"]:
                raise HTTPException(404, "User not found")
            if target["banned"]:
                raise HTTPException(404, "User not found")
            result = profile(db, target["id"])
            return {"success": True, "user": result}

    @router.get("/me")
    def relationships_me(account=Depends(get_current_account)):
        uid = account["id"]
        with database() as db:
            cp = db.execute(
                """SELECT * FROM lovely_cp
                   WHERE status='active' AND (user1=? OR user2=?)""",
                (uid, uid),
            ).fetchone()
            cp_partner = None
            if cp:
                partner_id = cp["user2"] if cp["user1"] == uid else cp["user1"]
                cp_partner = profile(db, partner_id)

            siblings = db.execute(
                """SELECT user1, user2 FROM lovely_siblings
                   WHERE status='active' AND (user1=? OR user2=?)""",
                (uid, uid),
            ).fetchall()
            sibling_profiles = [
                profile(db, r["user2"] if r["user1"] == uid else r["user1"])
                for r in siblings
            ]
            requests = db.execute(
                """SELECT * FROM lovely_relationship_requests
                   WHERE receiver_id=? AND status='pending'
                   ORDER BY id DESC""",
                (uid,),
            ).fetchall()
            incoming = []
            for req in requests:
                item = dict(req)
                item["sender"] = profile(db, req["sender_id"])
                incoming.append(item)

            outgoing = db.execute(
                """SELECT * FROM lovely_relationship_requests
                   WHERE sender_id=? AND status='pending'
                   ORDER BY id DESC""",
                (uid,),
            ).fetchall()
            return {
                "success": True,
                "cp_partner": cp_partner,
                "siblings": sibling_profiles,
                "incoming_requests": incoming,
                "outgoing_requests": [dict(r) for r in outgoing],
                "cp_invite_fee": CP_INVITE_FEE,
                "cp_self_remove_fee": CP_SELF_REMOVE_FEE,
            }

    def create_request(db, sender, receiver, kind):
        if sender == receiver:
            raise HTTPException(400, "You cannot select yourself")
        target = db.execute(
            "SELECT id, banned FROM accounts WHERE id=?", (receiver,)
        ).fetchone()
        if not target or target["banned"]:
            raise HTTPException(404, "User not found")
        exists = db.execute(
            """SELECT id FROM lovely_relationship_requests
               WHERE sender_id=? AND receiver_id=? AND kind=?
                 AND status='pending'""",
            (sender, receiver, kind),
        ).fetchone()
        if exists:
            raise HTTPException(409, "Request already pending")
        db.execute(
            """INSERT INTO lovely_relationship_requests
               (sender_id, receiver_id, kind, status, created_at)
               VALUES (?, ?, ?, 'pending', ?)""",
            (sender, receiver, kind, now()),
        )

    @router.post("/cp/invite/{user_code}")
    def cp_invite(user_code: str, account=Depends(get_current_account)):
        uid = account["id"]
        with database() as db:
            target = db.execute(
                "SELECT id FROM accounts WHERE user_code=? AND banned=0",
                (user_code.strip(),),
            ).fetchone()
            if not target:
                raise HTTPException(404, "User not found")
            receiver = target["id"]
            if receiver == uid:
                raise HTTPException(400, "You cannot invite yourself")
            active = db.execute(
                """SELECT id FROM lovely_cp WHERE status='active'
                   AND (user1 IN (?, ?) OR user2 IN (?, ?))""",
                (uid, receiver, uid, receiver),
            ).fetchone()
            if active:
                raise HTTPException(409, "One of these users already has an active CP")
            pending = db.execute(
                """SELECT id FROM lovely_relationship_requests
                   WHERE kind='cp_invite' AND status='pending'
                   AND ((sender_id=? AND receiver_id=?) OR
                        (sender_id=? AND receiver_id=?))""",
                (uid, receiver, receiver, uid),
            ).fetchone()
            if pending:
                raise HTTPException(409, "A CP invitation is already pending")
            wallet = db.execute(
                "SELECT coins FROM wallets WHERE account_id=?", (uid,)
            ).fetchone()
            if not wallet or wallet["coins"] < CP_INVITE_FEE:
                raise HTTPException(400, "Not enough coins. CP invite costs 1,000,000 coins.")
            db.execute(
                "UPDATE wallets SET coins=coins-?, updated_at=? WHERE account_id=? AND coins>=?",
                (CP_INVITE_FEE, now(), uid, CP_INVITE_FEE),
            )
            if db.execute("SELECT changes()").fetchone()[0] != 1:
                raise HTTPException(400, "Not enough coins")
            db.execute(
                """INSERT INTO wallet_transactions
                   (account_id, amount, transaction_type, description, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (uid, -CP_INVITE_FEE, "cp_invite_fee",
                 "CP invitation fee", now()),
            )
            create_request(db, uid, receiver, "cp_invite")
            return {"success": True, "message": "CP invitation sent", "coins_charged": CP_INVITE_FEE}

    @router.post("/siblings/invite/{user_code}")
    def sibling_invite(user_code: str, account=Depends(get_current_account)):
        with database() as db:
            target = db.execute(
                "SELECT id FROM accounts WHERE user_code=? AND banned=0",
                (user_code.strip(),),
            ).fetchone()
            if not target:
                raise HTTPException(404, "User not found")
            receiver = target["id"]
            if receiver == account["id"]:
                raise HTTPException(400, "You cannot invite yourself")
            a, b = sorted((account["id"], receiver))
            existing = db.execute(
                """SELECT id FROM lovely_siblings
                   WHERE user1=? AND user2=? AND status='active'""",
                (a, b),
            ).fetchone()
            if existing:
                raise HTTPException(409, "Already connected as Brother/Sister")

            uid = account["id"]
            fee = 1_000_000
            wallet = db.execute(
                "SELECT coins FROM wallets WHERE account_id=?", (uid,)
            ).fetchone()
            if not wallet or wallet["coins"] < fee:
                raise HTTPException(
                    400, "Not enough coins. Brother/Sister invite costs 1,000,000 coins."
                )

            db.execute(
                "UPDATE wallets SET coins=coins-?, updated_at=? "
                "WHERE account_id=? AND coins>=?",
                (fee, now(), uid, fee),
            )
            if db.execute("SELECT changes()").fetchone()[0] != 1:
                raise HTTPException(400, "Not enough coins")

            db.execute(
                """INSERT INTO wallet_transactions
                   (account_id, amount, transaction_type, description, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (uid, -fee, "sibling_invite_fee",
                 "Brother/Sister invitation fee", now()),
            )
            create_request(db, uid, receiver, "sibling_invite")
            return {
                "success": True,
                "message": "Brother/Sister invitation sent",
                "coins_charged": fee,
            }

    @router.post("/requests/{request_id}/respond")
    def respond_request(
        request_id: int,
        data: RespondRequest,
        account=Depends(get_current_account),
    ):
        uid = account["id"]
        with database() as db:
            req = db.execute(
                """SELECT * FROM lovely_relationship_requests
                   WHERE id=? AND receiver_id=? AND status='pending'""",
                (request_id, uid),
            ).fetchone()
            if not req:
                raise HTTPException(404, "Pending request not found")

            if data.action == "reject":
                db.execute(
                    "UPDATE lovely_relationship_requests SET status='rejected' WHERE id=?",
                    (request_id,),
                )
                return {"success": True, "message": "Request rejected"}

            sender = req["sender_id"]
            if req["kind"] == "cp_invite":
                active = db.execute(
                    """SELECT id FROM lovely_cp WHERE status='active'
                       AND (user1 IN (?, ?) OR user2 IN (?, ?))""",
                    (uid, sender, uid, sender),
                ).fetchone()
                if active:
                    raise HTTPException(409, "One of these users already has an active CP")
                a, b = sorted((uid, sender))
                db.execute(
                    """INSERT INTO lovely_cp(user1, user2, status, created_at)
                       VALUES (?, ?, 'active', ?)""",
                    (a, b, now()),
                )
            elif req["kind"] == "sibling_invite":
                a, b = sorted((uid, sender))
                db.execute(
                    """INSERT OR IGNORE INTO lovely_siblings
                       (user1, user2, status, created_at)
                       VALUES (?, ?, 'active', ?)""",
                    (a, b, now()),
                )
            elif req["kind"] == "cp_remove":
                db.execute(
                    """UPDATE lovely_cp SET status='removed'
                       WHERE status='active'
                         AND ((user1=? AND user2=?) OR (user1=? AND user2=?))""",
                    (uid, sender, sender, uid),
                )
            elif req["kind"] == "sibling_remove":
                a, b = sorted((uid, sender))
                db.execute(
                    """UPDATE lovely_siblings SET status='removed'
                       WHERE user1=? AND user2=? AND status='active'""",
                    (a, b),
                )
            else:
                raise HTTPException(400, "Unsupported request type")

            db.execute(
                "UPDATE lovely_relationship_requests SET status='accepted' WHERE id=?",
                (request_id,),
            )
            return {"success": True, "message": "Request accepted"}

    @router.post("/cp/removal-request")
    def cp_removal_request(account=Depends(get_current_account)):
        uid = account["id"]
        with database() as db:
            cp = db.execute(
                """SELECT user1, user2 FROM lovely_cp
                   WHERE status='active' AND (user1=? OR user2=?)""",
                (uid, uid),
            ).fetchone()
            if not cp:
                raise HTTPException(404, "No active CP found")
            partner = cp["user2"] if cp["user1"] == uid else cp["user1"]
            create_request(db, uid, partner, "cp_remove")
            return {"success": True, "message": "Removal request sent; partner acceptance removes CP for free"}

    @router.post("/cp/remove")
    def cp_self_remove(account=Depends(get_current_account)):
        uid = account["id"]
        with database() as db:
            cp = db.execute(
                """SELECT user1, user2 FROM lovely_cp
                   WHERE status='active' AND (user1=? OR user2=?)""",
                (uid, uid),
            ).fetchone()
            if not cp:
                raise HTTPException(404, "No active CP found")
            wallet = db.execute(
                "SELECT coins FROM wallets WHERE account_id=?", (uid,)
            ).fetchone()
            if not wallet or wallet["coins"] < CP_SELF_REMOVE_FEE:
                raise HTTPException(400, "Not enough coins. Self-removal costs 5,000,000 coins.")
            db.execute(
                "UPDATE wallets SET coins=coins-?, updated_at=? WHERE account_id=? AND coins>=?",
                (CP_SELF_REMOVE_FEE, now(), uid, CP_SELF_REMOVE_FEE),
            )
            if db.execute("SELECT changes()").fetchone()[0] != 1:
                raise HTTPException(400, "Not enough coins")
            db.execute(
                """INSERT INTO wallet_transactions
                   (account_id, amount, transaction_type, description, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (uid, -CP_SELF_REMOVE_FEE, "cp_self_remove_fee",
                 "CP self-removal fee", now()),
            )
            db.execute(
                "UPDATE lovely_cp SET status='removed' WHERE user1=? AND user2=? AND status='active'",
                (cp["user1"], cp["user2"]),
            )
            return {"success": True, "message": "CP removed", "coins_charged": CP_SELF_REMOVE_FEE}

    @router.post("/siblings/{partner_id}/removal-request")
    def sibling_removal_request(partner_id: int, account=Depends(get_current_account)):
        uid = account["id"]
        if uid == partner_id:
            raise HTTPException(400, "Invalid partner")
        a, b = sorted((uid, partner_id))
        with database() as db:
            existing = db.execute(
                """SELECT id FROM lovely_siblings
                   WHERE user1=? AND user2=? AND status='active'""",
                (a, b),
            ).fetchone()
            if not existing:
                raise HTTPException(404, "Brother/Sister relationship not found")
            create_request(db, uid, partner_id, "sibling_remove")
            return {"success": True, "message": "Removal request sent"}

    return router
