# GoDaddy API 401 Fix — Root Cause Analysis

## Problem
Calling `https://api.godaddy.com/v1/domains/pmxs.space` returned **401 Unauthorized**.

## Root Cause
**Wrong API secret was used.** The vault (`_config\plain\env.txt`) contains the correct credentials:

| Field | Vault Value | User Provided | Match |
|-------|------------|---------------|-------|
| API Key | `hkdGRhhJWDqJ_6eYnhYxpwjdacN9TXBGUaA` | Same | ✅ |
| API Secret | `UhnbhaLek8siB3eAAJB9c9` | `QsxnNzuYjBEvBHna8nCtUA` | ❌ |

The secret `QsxnNzuYjBEvBHna8nCtUA` is not valid — likely a previous/expired key or a typo.

## Resolution
The correct secret from the vault **works**. Verified 2026-06-30:
```
GET https://api.godaddy.com/v1/domains/pmxs.space → 200 OK
```

## How to Regenerate Keys (if needed in future)

### Via GoDaddy Developer Portal:
1. Go to https://developer.godaddy.com/keys
2. Sign in with your GoDaddy account (topsecretawe@gmail.com)
3. Click **"Create New Key"** or **"Regenerate"** next to existing key
4. Copy the **API Key** and **API Secret**
5. Update `_config\plain\env.txt`:
   - `PMX_GODADDY_API_KEY=<new-key>`
   - `PMX_GODADDY_API_SECRET=<new-secret>`
6. Run `_config\lock.bat` to re-encrypt the vault

### Testing New Credentials:
```powershell
$key = "<new-key>"
$secret = "<new-secret>"
$headers = @{ "Authorization" = "sso-key $key`:$secret" }
Invoke-RestMethod -Uri "https://api.godaddy.com/v1/domains/pmxs.space" -Headers $headers
```
Expected: `200 OK` with domain details

### GoDaddy API Endpoints Used:
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/domains/{domain}` | GET | Domain status & details |
| `/v1/domains/{domain}/records` | GET | List all DNS records |
| `/v1/domains/{domain}/records/{type}/{name}` | PATCH | Update DNS records |

## Notes
- API key was created when domain was registered (~11h ago)
- 401 **did not** mean the key was revoked/expired — it was the wrong secret value
- Both `hkdGRhhJWDqJ_6eYnhYxpwjdacN9TXBGUaA` and `UhnbhaLek8siB3eAAJB9c9` are the valid production credentials
