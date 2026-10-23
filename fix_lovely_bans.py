from pathlib import Path
import re
import shutil
import sqlite3
import sys

root = Path.home() / "Lovely"
src = root / "backend" / "main.py"

if not src.exists():
    sys.exit("ERROR: backend/main.py nahi mili. Koi change nahi hua.")

original = src.read_text()

# Make a source backup first.
backup = root / "backend" / "main.py.before_timed_bans"
if not backup.exists():
    shutil.copy2(src, backup)

# Back up the default database if it exists.
db_path = root / "lovely_security.db"
if db_path.exists():
    db_backup = root / "lovely_security.db.before_timed_bans"
    if not db_backup.exists():
        shutil.copy2(db_path, db_backup)

s = original

# Add duration to the existing device-ban request.
old_model = '''class DeviceRequest(BaseModel):
    device_id: str = Field(
        min_length=16,
        max_length=256,
    )'''

new_model = '''class DeviceRequest(BaseModel):
    device_id: str = Field(
        min_length=16,
        max_length=256,
    )
    duration: str = "permanent"'''

if old_model in s:
    s = s.replace(old_model, new_model, 1)
elif 'class DeviceRequest(BaseModel):' not in s:
    sys.exit("ERROR: DeviceRequest nahi mila. Original file unchanged.")
elif 'duration: str = "permanent"' not in s:
    sys.exit("ERROR: DeviceRequest ka format different hai. Original file unchanged.")

# Add ban fields to the existing accounts table after normal DB initialization.
migration = r'''

def ensure_ban_columns():
    with database() as db:
        cols = {
            row["name"]
            for row in db.execute("PRAGMA table_info(accounts)").fetchall()
        }
        additions = {
            "account_ban_until": "TEXT",
            "device_ban_until": "TEXT",
            "account_ban_permanent": "INTEGER NOT NULL DEFAULT 0",
            "device_ban_permanent": "INTEGER NOT NULL DEFAULT 0",
        }
        for name, declaration in additions.items():
            if name not in cols:
                db.execute(
                    f"ALTER TABLE accounts ADD COLUMN {name} {declaration}"
                )

        # Preserve old bans: old code did not distinguish their type.
        db.execute("""
            UPDATE accounts
            SET account_ban_permanent = 1,
                device_ban_permanent = 1
            WHERE banned = 1
              AND account_ban_permanent = 0
              AND device_ban_permanent = 0
              AND account_ban_until IS NULL
              AND device_ban_until IS NULL
        """)


def ban_expiry(duration):
    allowed = {
        "24h": timedelta(hours=24),
        "7d": timedelta(days=7),
        "30d": timedelta(days=30),
    }
    if duration == "permanent":
        return None
    if duration not in allowed:
        raise HTTPException(
            status_code=422,
            detail="duration must be 24h, 7d, 30d, or permanent",
        )
    return (datetime.now(timezone.utc) + allowed[duration]).isoformat()


def refresh_ban_state(db, account):
    username = account["username"]
    now_dt = datetime.now(timezone.utc)

    current = db.execute(
        "SELECT * FROM accounts WHERE username = ?",
        (username,),
    ).fetchone()
    if not current:
        return account

    updates = {}
    active = False

    for field in ("account_ban_until", "device_ban_until"):
        value = current[field]
        if value:
            try:
                expiry = datetime.fromisoformat(value)
                if expiry.tzinfo is None:
                    expiry = expiry.replace(tzinfo=timezone.utc)
                if expiry > now_dt:
                    active = True
                else:
                    updates[field] = None
            except (ValueError, TypeError):
                # Fail closed for malformed expiry values.
                active = True

    if current["account_ban_permanent"] or current["device_ban_permanent"]:
        active = True

    for field, value in updates.items():
        db.execute(
            f"UPDATE accounts SET {field} = ? WHERE username = ?",
            (value, username),
        )

    db.execute(
        "UPDATE accounts SET banned = ? WHERE username = ?",
        (1 if active else 0, username),
    )

    return db.execute(
        "SELECT * FROM accounts WHERE username = ?",
        (username,),
    ).fetchone()


'''

if "def ensure_ban_columns():" not in s:
    marker = "\n\ninit_db()\n"
    if marker not in s:
        sys.exit("ERROR: init_db marker nahi mila. Original file unchanged.")
    s = s.replace(marker, "\n\ninit_db()\n" + migration + "\nensure_ban_columns()\n", 1)

# Update existing authentication checks so expired bans are refreshed.
if 'if row["banned"]:' in s and 'row = refresh_ban_state(db, row)' not in s:
    s = s.replace(
        '        if row["banned"]:',
        '        row = refresh_ban_state(db, row)\n'
        '        if row["banned"]:',
        1,
    )

if 'if account["banned"]:' in s and 'account = refresh_ban_state(db, account)' not in s:
    s = s.replace(
        '        if account["banned"]:',
        '        account = refresh_ban_state(db, account)\n'
        '        if account["banned"]:',
        1,
    )

def replace_section(text, start_marker, end_marker, replacement):
    start = text.find(start_marker)
    if start < 0:
        raise ValueError("Start marker missing: " + start_marker)
    end = text.find(end_marker, start)
    if end < 0:
        raise ValueError("End marker missing: " + end_marker)
    return text[:start] + replacement + "\n\n" + text[end:]

device_handlers = r'''# OWNER: BAN DEVICE
# ==========================================

@app.post("/owner/ban-device")
def ban_device(
    data: DeviceRequest,
    _: bool = Depends(require_owner),
):
    expiry = ban_expiry(data.duration)

    with database() as db:
        rows = db.execute(
            "SELECT username FROM accounts WHERE device_id = ?",
            (data.device_id,),
        ).fetchall()

        if not rows:
            raise HTTPException(status_code=404, detail="Device not found")

        if data.duration == "permanent":
            db.execute("""
                UPDATE accounts
                SET device_ban_permanent = 1, device_ban_until = NULL,
                    banned = 1
                WHERE device_id = ?
            """, (data.device_id,))
        else:
            db.execute("""
                UPDATE accounts
                SET device_ban_permanent = 0, device_ban_until = ?,
                    banned = 1
                WHERE device_id = ?
            """, (expiry, data.device_id))

        db.execute("""
            DELETE FROM sessions
            WHERE account_id IN (
                SELECT id FROM accounts WHERE device_id = ?
            )
        """, (data.device_id,))

        log_event(db, "DEVICE_BANNED", rows[0]["username"], data.device_id)

    return {
        "success": True,
        "device_id": data.device_id,
        "duration": data.duration,
        "expires_at": expiry,
        "status": "banned",
    }


# ==========================================
# OWNER: UNBAN DEVICE
# ==========================================

@app.post("/owner/unban-device")
def unban_device(
    data: DeviceRequest,
    _: bool = Depends(require_owner),
):
    with database() as db:
        rows = db.execute(
            "SELECT username FROM accounts WHERE device_id = ?",
            (data.device_id,),
        ).fetchall()

        if not rows:
            raise HTTPException(status_code=404, detail="Device not found")

        db.execute("""
            UPDATE accounts
            SET device_ban_permanent = 0, device_ban_until = NULL
            WHERE device_id = ?
        """, (data.device_id,))

        for row in rows:
            refresh_ban_state(db, row)

        log_event(db, "DEVICE_UNBANNED", None, data.device_id)

    return {
        "success": True,
        "device_id": data.device_id,
        "status": "unbanned_if_no_account_ban",
    }
'''

try:
    s = replace_section(
        s,
        "# OWNER: BAN DEVICE",
        "# OWNER: SECURITY LOGS",
        device_handlers,
    )
except ValueError as e:
    sys.exit(f"ERROR: {e}. Original file unchanged.")

account_handlers = r'''# OWNER: BAN ACCOUNT
# ==========================================

@app.post("/owner/ban-account/{username}")
def owner_ban_account(
    username: str,
    duration: str = "permanent",
    _: bool = Depends(require_owner),
):
    expiry = ban_expiry(duration)

    with database() as db:
        row = db.execute(
            "SELECT device_id FROM accounts WHERE username = ?",
            (username,),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Account not found")

        if duration == "permanent":
            db.execute("""
                UPDATE accounts
                SET account_ban_permanent = 1, account_ban_until = NULL,
                    banned = 1
                WHERE username = ?
            """, (username,))
        else:
            db.execute("""
                UPDATE accounts
                SET account_ban_permanent = 0, account_ban_until = ?,
                    banned = 1
                WHERE username = ?
            """, (expiry, username))

        db.execute("""
            DELETE FROM sessions
            WHERE account_id = (
                SELECT id FROM accounts WHERE username = ?
            )
        """, (username,))

        log_event(db, "ACCOUNT_BANNED", username, row["device_id"])

    return {
        "success": True,
        "username": username,
        "duration": duration,
        "expires_at": expiry,
        "status": "banned",
    }


# ==========================================
# OWNER: UNBAN ACCOUNT
# ==========================================

@app.post("/owner/unban-account/{username}")
def owner_unban_account(
    username: str,
    _: bool = Depends(require_owner),
):
    with database() as db:
        row = db.execute(
            "SELECT device_id FROM accounts WHERE username = ?",
            (username,),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Account not found")

        db.execute("""
            UPDATE accounts
            SET account_ban_permanent = 0, account_ban_until = NULL
            WHERE username = ?
        """, (username,))

        updated = db.execute(
            "SELECT * FROM accounts WHERE username = ?",
            (username,),
        ).fetchone()
        refresh_ban_state(db, updated)

        log_event(db, "ACCOUNT_UNBANNED", username, row["device_id"])

    return {
        "success": True,
        "username": username,
        "status": "unbanned_if_no_device_ban",
    }
'''

try:
    s = replace_section(
        s,
        "# OWNER: BAN ACCOUNT",
        "# LOVELY_SUPER_ADMIN_API_V1",
        account_handlers,
    )
except ValueError as e:
    sys.exit(f"ERROR: {e}. Original file unchanged.")

# Require ban refresh hooks; don't silently claim timed bans work without them.
if 'if row["banned"]:' in s and 'row = refresh_ban_state(db, row)' not in s:
    sys.exit("ERROR: account session ban check hook missing; file not changed.")
if 'if account["banned"]:' in s and 'account = refresh_ban_state(db, account)' not in s:
    sys.exit("ERROR: login ban check hook missing; file not changed.")

src.write_text(s)
print("PATCH WRITTEN")
print("Source backup:", backup)
if db_path.exists():
    print("Database backup:", db_path.with_name(db_path.name + ".before_timed_bans"))
