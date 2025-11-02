# OpenAI API Key Setup Guide

> **Purpose:** Configure OpenAI GPT-4o-mini API key for AInstein LLM intelligence (Phase 6/7)
> **Security:** API key is stored locally in `Config.xcconfig` (NOT committed to Git)
> **Last Updated:** October 26, 2025

---

## Step 1: Get Your OpenAI API Key

1. Visit https://platform.openai.com/api-keys
2. Log in or create an OpenAI account
3. Click "Create new secret key"
4. Name it "FastingTracker - Development"
5. Copy the key (starts with `sk-proj-...`)
   - ⚠️ **IMPORTANT:** Save this key somewhere safe - you can only see it once!

---

## Step 2: Add API Key to Config.xcconfig

1. Open `Config.xcconfig` in the project root
2. Find the line: `OPENAI_API_KEY = YOUR_OPENAI_API_KEY_HERE`
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key
4. Save the file

**Example:**
```
// Before:
OPENAI_API_KEY = YOUR_OPENAI_API_KEY_HERE

// After:
OPENAI_API_KEY = sk-proj-abc123xyz789...
```

---

## Step 3: Link Config.xcconfig in Xcode (If Not Already Linked)

**Check if already linked:**
1. Open `FastingTracker.xcodeproj` in Xcode
2. Select project in Navigator (blue icon at top)
3. Select "FastingTracker" under PROJECT
4. Go to "Info" tab
5. Check "Configurations" section

**If NOT linked, follow these steps:**

### Debug Configuration
1. Under "Configurations" → "Debug"
2. Click dropdown under "FastingTracker" target
3. Select "Config"
4. Click "Choose File..."
5. Navigate to project root and select `Config.xcconfig`

### Release Configuration
1. Under "Configurations" → "Release"
2. Click dropdown under "FastingTracker" target
3. Select "Config"
4. Click "Choose File..."
5. Navigate to project root and select `Config.xcconfig`

---

## Step 4: Update Info.plist (If Not Already Added)

**Check if already added:**
1. Open `Info.plist`
2. Look for key: `OpenAI_API_Key`

**If NOT added, follow these steps:**
1. Right-click in `Info.plist`
2. Select "Add Row"
3. Key: `OpenAI_API_Key`
4. Type: `String`
5. Value: `$(OPENAI_API_KEY)`

This tells the app to read the API key from the Config.xcconfig file.

---

## Step 5: Verify Setup

### Build Test
1. Clean build folder: `Cmd+Shift+K`
2. Build project: `Cmd+B`
3. Verify 0 errors

### Runtime Test
1. Run app on device or simulator
2. Navigate to Hub tab
3. Tap AInstein floating button
4. Ask: "What's my weight?"
5. Verify AInstein responds with intelligent answer (not fallback)

**If you get an error:**
- Check Console.app for logs containing "OpenAI"
- Common issues:
  - API key not set in Config.xcconfig
  - Config.xcconfig not linked in Xcode configurations
  - Info.plist missing OpenAI_API_Key entry
  - API key invalid or expired

---

## Step 6: Verify .gitignore

**CRITICAL:** Ensure `Config.xcconfig` is NOT committed to Git

1. Open `.gitignore` in project root
2. Verify it contains: `Config.xcconfig`
3. Run: `git status`
4. Verify `Config.xcconfig` does NOT appear in untracked files

**If Config.xcconfig appears in git status:**
```bash
# Add to .gitignore
echo "Config.xcconfig" >> .gitignore

# Remove from Git if accidentally committed
git rm --cached Config.xcconfig
git commit -m "Remove Config.xcconfig from Git (contains secrets)"
```

---

## API Cost Management

### Expected Costs (Phase 7 LLM-Primary)
- **GPT-4o-mini:** $0.15 per 1M input tokens, $0.60 per 1M output tokens
- **Estimated:** $1-3/month per active user
- **Typical query:** ~500 input tokens, ~100 output tokens = $0.00015 per query

### Cost Control Strategies
1. **Hybrid Routing:** Simple queries use rule-based system (free)
2. **Caching:** 30-second TTL reduces duplicate queries
3. **Response Limits:** Max 2 sentences enforced by ResponseValidator
4. **Offline Fallback:** Graceful degradation when no internet

### Monitor Usage
1. Visit https://platform.openai.com/usage
2. Check daily/monthly usage
3. Set up billing alerts (recommended: $5/month alert)

---

## Security Best Practices

### ✅ DO:
- Store API key in `Config.xcconfig` (local, not in Git)
- Add `Config.xcconfig` to `.gitignore`
- Use environment-specific keys (separate keys for Debug/Release if needed)
- Rotate keys if compromised

### ❌ DON'T:
- Commit API key to Git (ever!)
- Hardcode API key in source code
- Share API key publicly
- Use production key for development (optional: use separate keys)

---

## Migration to Backend Proxy (Future)

**When:** After 1,000+ users

This setup (Xcode Config) is sufficient for initial launch. When scaling, migrate to a backend proxy for maximum security:

**Architecture:**
```
iPhone → api.fastlife.com/chat → OpenAI API
         (Your backend)          (with your key)
```

**Benefits:**
- API key never on device
- Rotate keys anytime (no app update)
- Rate limiting server-side
- Cost monitoring and anomaly detection
- Switch AI providers without app update

**Implementation Options:**
- AWS Lambda + API Gateway ($5-10/month)
- Vercel Serverless Functions (free tier, then $20/month)
- Firebase Cloud Functions ($5-15/month)

**Timeline:** 1 week implementation when scaling justifies infrastructure investment

---

## Troubleshooting

### Error: "OpenAI API key not configured"
- Check `Config.xcconfig` has your actual key (not placeholder)
- Verify Config.xcconfig is linked in Xcode configurations
- Clean build folder and rebuild

### Error: "Invalid API key"
- Key must start with `sk-proj-...`
- Verify key copied correctly (no extra spaces/newlines)
- Check key is active at https://platform.openai.com/api-keys

### AInstein returns generic fallbacks
- Check Console.app logs for OpenAI errors
- Verify internet connectivity
- Check OpenAI API status: https://status.openai.com/
- Verify API key has credits/not expired

### Excessive API costs
- Check usage at https://platform.openai.com/usage
- Verify caching is working (check logs for cache hits)
- Ensure hybrid routing is active (simple queries should use rule-based)
- Set billing alert at https://platform.openai.com/account/billing/overview

---

## Support

**OpenAI API Documentation:**
- API Keys: https://platform.openai.com/api-keys
- Usage Dashboard: https://platform.openai.com/usage
- API Reference: https://platform.openai.com/docs/api-reference
- Status Page: https://status.openai.com/

**FastingTracker Documentation:**
- Phase 6/7 Implementation: `docs/handoffs/PHASE-6-7-LLM-INTEGRATION.md`
- Current Status: `docs/handoffs/HANDOFF.md`
- Lessons Learned: `docs/handoffs/LESSONS-LEARNED.md`

---

**Last Updated:** October 26, 2025
**Phase:** Phase 7.5 Restoration - Config Setup
