---
name: unfreeze
description: Use when you want to remove a directory edit lock set by /freeze or /guard. Use when the user says "unfreeze", "remove the lock", "unlock edits", or "I want to edit other files now".
---

# /unfreeze — Remove Directory Lock

Removes the active `/freeze` or the directory lock portion of `/guard`.

```
FREEZE REMOVED
══════════════
Edits are now unrestricted.
Careful mode: [still active / not active]
```

If careful mode is still active, remind the user:

```
Note: /careful is still active — destructive commands still require confirmation.
Say "exit careful mode" to disable it.
```

If neither freeze nor careful was active:

```
No freeze or guard was active in this session.
```

---

## Rules

- Removes directory lock only — does not affect careful mode
- Takes effect immediately for all subsequent edits
- No arguments needed
