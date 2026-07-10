# Stack Reference: AI Chatbot — Telegram, Discord, and Multi-Platform

## Ubiquitous Language for chatbot domain

Define in CLAUDE.md before writing any chatbot code:
```markdown
## Ubiquitous Language (chatbot)
| Term | Meaning | Not |
|---|---|---|
| NormalizedMessage | Platform-agnostic inbound message | Message, Event, Update |
| BotResponse | Platform-agnostic outbound message | Reply, Output, Result |
| ConversationState | Persisted conversation history | Session, Context, Memory |
| PlatformAdapter | Translates platform ↔ domain | Provider, Integration, Bridge |
| Turn | One exchange (user + bot) in conversation | Message pair, Round |
```

---

## The core architecture insight

Platform-specific code should be minimal and isolated.
Your AI logic, conversation management, and business rules know nothing about Telegram or Discord.
Swap platforms by swapping adapters — zero changes to core logic.

This is Shipright's Boundary Rule 4 applied to bot platforms:
**No raw platform message passes beyond the Platform Adapter layer.**

---

## Architecture: Platform Adapter Pattern

```
User sends message on Telegram/Discord
    ↓
[Platform Adapter]          ← Telegram/Discord specific: auth, parse, format, send
    ↓ NormalizedMessage
[Message Router]            ← route by command, intent, user role
    ↓
[Conversation Manager]      ← load history, manage context window
    ↓ ConversationState
[AI Handler]                ← LLM call with conversation context
    ↓ AIResponse
[Response Formatter]        ← format for platform (markdown, buttons, media)
    ↓
[Platform Adapter]          ← send back to Telegram/Discord
```

**Key principle**: Message Router, Conversation Manager, AI Handler know NOTHING
about Telegram or Discord. They work with NormalizedMessage and ConversationState only.

---

## Decision: Polling vs Webhook (ask at L0)

```
"Do you have a public server with SSL certificate?"

No / Local dev only:
  → Long Polling (getUpdates)
  → Your bot asks Telegram/Discord: "any new messages?"
  → Works behind NAT, no inbound ports needed
  → Fine for development and low-traffic production

Yes (VPS, Railway, Fly.io, Vercel):
  → Webhook mode
  → Platform pushes messages to your HTTPS endpoint
  → Lower latency, more efficient for high traffic
  → Required for > few messages/minute production load

Best practice: polling for dev, webhook for production.
Auto-switch: mode: process.env.DEPLOYED ? 'webhook' : 'polling'
```

---

## Decision: Single platform vs Multi-platform (ask at L0)

```
"Do you need both Telegram AND Discord, or just one?"

Single platform:
  → Simpler architecture, ship faster
  → Add second platform later via adapter (no core changes)

Multi-platform:
  → Build Platform Adapter interface first
  → Implement TelegramAdapter and DiscordAdapter separately
  → Same NormalizedMessage flows to same business logic
  → Add Slack, WhatsApp later: implement adapter only
```

---

## L0 CLAUDE.md additions for chatbot

```markdown
## Chatbot-specific rules

### Platform Adapter boundary (extends Boundary Rule 4)
Platform-specific code lives ONLY in adapters/:
  adapters/telegram.adapter.ts
  adapters/discord.adapter.ts

Banned from any other file:
  import TelegramBot from 'node-telegram-bot-api'  ← BANNED outside adapter
  discord.channels.get(...)                         ← BANNED outside adapter

Business logic receives: NormalizedMessage (platform-agnostic type)
Business logic returns: BotResponse (platform-agnostic type)
Platform adapter translates both directions.

### Conversation state rule
Conversation history NEVER stored in memory (process restart = lost context)
All conversation state persists in: Redis (recommended) or PostgreSQL
Key format: conversation:{platform}:{userId} or conversation:{platform}:{chatId}
TTL: 24 hours (configurable)

### Rate limit awareness
Telegram: 30 messages/second globally, 1 message/second per chat
Discord: 5 requests/second per bot
Never send > 1 message/second per user without queuing
Typing indicators (sendChatAction) for responses > 1 second

### Security rules
Bot tokens: environment variables only, never in code or logs
Webhook secret: always validate X-Telegram-Bot-Api-Secret-Token header
User input: never directly injected into SQL or system prompts
Admin commands: whitelist by userId, not by username (usernames changeable)
Group bots: respond only when @mentioned unless explicitly configured otherwise
```

---

## Domain types (platform-agnostic)

```typescript
// types/bot.ts — platform-agnostic, used everywhere except adapters

interface NormalizedMessage {
  id: string
  platform: 'telegram' | 'discord' | 'slack'
  chatId: string                    // channel/chat identifier
  userId: string                    // who sent it
  username?: string                 // display name (may change — never use as ID)
  text?: string
  mediaType?: 'photo' | 'voice' | 'document' | 'video'
  mediaUrl?: string                 // pre-downloaded URL or extension URL
  replyToMessageId?: string
  isGroupChat: boolean
  isMention: boolean                // was the bot @mentioned?
  timestamp: Date
  rawPlatformData: unknown          // escape hatch — Adapter only reads this
}

interface BotResponse {
  text: string
  parseMode?: 'markdown' | 'html' | 'plain'
  replyToMessageId?: string
  inlineKeyboard?: InlineButton[][]  // platform adapter translates to platform format
  mediaUrl?: string
}

interface ConversationState {
  chatId: string
  platform: string
  history: ConversationTurn[]       // last N turns, managed by ConversationManager
  userPreferences?: Record<string, unknown>
  lastActivity: Date
}

interface ConversationTurn {
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  messageId: string
}
```

---

## Platform Adapter interface

```typescript
// adapters/base.adapter.ts
interface IPlatformAdapter {
  // Receive updates (polling or webhook)
  startPolling(): Promise<void>
  handleWebhook(payload: unknown): Promise<void>

  // Parse platform message → NormalizedMessage
  parseMessage(raw: unknown): NormalizedMessage | null

  // Send response back to platform
  sendMessage(chatId: string, response: BotResponse): Promise<void>
  sendTypingIndicator(chatId: string): Promise<void>

  // Platform metadata
  platform: string
  botId: string
}
```

---

## L1 skeleton prompt (chatbot)

```
Read CLAUDE.md and ARCHITECTURE.md.

Create chatbot skeleton:

src/
  adapters/
    base.adapter.ts         ← IPlatformAdapter interface
    telegram.adapter.ts     ← Telegram-specific: grammy or python-telegram-bot
    discord.adapter.ts      ← Discord-specific: discord.js
  types/
    bot.ts                  ← NormalizedMessage, BotResponse, ConversationState
  handlers/
    message.handler.ts      ← route by command/intent, calls AI handler
    command.handler.ts      ← /start, /help, /reset commands
  conversation/
    manager.ts              ← load/save history, manage context window (max N turns)
    store.ts                ← Redis or PostgreSQL persistence
  ai/
    client.ts               ← LLM wrapper (same as ai-rag.md pattern)
    prompt_builder.ts       ← build system prompt + conversation history
    response.adapter.ts     ← parse LLM output → BotResponse
  config/
    env.ts                  ← zod schema, throw on startup if tokens missing

Telegram setup:
  npm install grammy           (Node.js, recommended 2026)
  pip install python-telegram-bot  (Python)

Discord setup:
  npm install discord.js       (Node.js)
  pip install discord.py       (Python)

Walking skeleton:
  Bot receives /start → replies "Hello! I'm [name]. Send me a message."
  Bot receives any text → echo it back (no LLM yet)
  Gate: bot responds in Telegram AND Discord (if multi-platform)
```

---

## Conversation state management (critical — don't skip)

State management: In-memory dict is fine for prototyping, lost on restart.
For production, always persist:

```typescript
// conversation/store.ts
class ConversationStore {
  private redis: Redis  // or PostgreSQL with JSONB

  async load(platform: string, chatId: string): Promise<ConversationState | null> {
    const key = `conv:${platform}:${chatId}`
    const data = await this.redis.get(key)
    return data ? JSON.parse(data) : null
  }

  async save(state: ConversationState): Promise<void> {
    const key = `conv:${state.platform}:${state.chatId}`
    await this.redis.setex(
      key,
      60 * 60 * 24,           // 24h TTL
      JSON.stringify(state)
    )
  }

  async clear(platform: string, chatId: string): Promise<void> {
    await this.redis.del(`conv:${platform}:${chatId}`)
  }
}

// conversation/manager.ts
class ConversationManager {
  private readonly MAX_TURNS = 20         // keep last 20 exchanges
  private readonly MAX_TOKENS = 4000     // estimated context limit

  async addTurn(
    state: ConversationState,
    role: 'user' | 'assistant',
    content: string,
    messageId: string
  ): Promise<ConversationState> {
    const turn: ConversationTurn = {
      role, content, messageId, timestamp: new Date()
    }
    const history = [...state.history, turn]
    // Trim to max turns (sliding window)
    const trimmed = history.slice(-this.MAX_TURNS)
    return { ...state, history: trimmed, lastActivity: new Date() }
  }
}
```

---

## Prompt builder — conversation context

```typescript
// ai/prompt_builder.ts
class PromptBuilder {
  buildMessages(
    systemPrompt: string,
    state: ConversationState,
    newMessage: NormalizedMessage
  ): ChatMessage[] {
    return [
      { role: 'system', content: systemPrompt },
      // Include conversation history
      ...state.history.map(turn => ({
        role: turn.role,
        content: turn.content
      })),
      // Add new message
      {
        role: 'user' as const,
        content: this.formatUserMessage(newMessage)
      }
    ]
  }

  private formatUserMessage(msg: NormalizedMessage): string {
    if (msg.mediaType === 'voice') {
      return `[Voice message transcription]: ${msg.text}`
    }
    if (msg.mediaType === 'photo' && msg.mediaUrl) {
      return `[User sent a photo: ${msg.mediaUrl}]\n${msg.text ?? ''}`
    }
    return msg.text ?? ''
  }
}
```

---

## Telegram-specific adapter (grammy — Node.js)

```typescript
// adapters/telegram.adapter.ts
import { Bot, Context } from 'grammy'
import { IPlatformAdapter } from './base.adapter'

export class TelegramAdapter implements IPlatformAdapter {
  platform = 'telegram'
  botId: string
  private bot: Bot

  constructor(token: string) {
    this.bot = new Bot(token)
    this.botId = token.split(':')[0]
  }

  parseMessage(ctx: Context): NormalizedMessage | null {
    if (!ctx.message?.text && !ctx.message?.voice && !ctx.message?.photo) {
      return null  // ignore non-content updates
    }
    return {
      id: String(ctx.message.message_id),
      platform: 'telegram',
      chatId: String(ctx.chat?.id),
      userId: String(ctx.from?.id),
      username: ctx.from?.username,
      text: ctx.message.text,
      mediaType: ctx.message.voice ? 'voice' :
                 ctx.message.photo ? 'photo' : undefined,
      isGroupChat: ctx.chat?.type !== 'private',
      isMention: ctx.message.text?.includes(`@${this.bot.botInfo?.username}`) ?? false,
      replyToMessageId: ctx.message.reply_to_message
        ? String(ctx.message.reply_to_message.message_id) : undefined,
      timestamp: new Date(ctx.message.date * 1000),
      rawPlatformData: ctx.message
    }
  }

  async sendMessage(chatId: string, response: BotResponse): Promise<void> {
    await this.bot.api.sendMessage(chatId, response.text, {
      parse_mode: response.parseMode === 'markdown' ? 'MarkdownV2' : undefined,
      reply_parameters: response.replyToMessageId
        ? { message_id: Number(response.replyToMessageId) } : undefined,
      reply_markup: response.inlineKeyboard
        ? { inline_keyboard: response.inlineKeyboard.map(row =>
            row.map(btn => ({ text: btn.text, callback_data: btn.data }))
          )} : undefined
    })
  }

  async sendTypingIndicator(chatId: string): Promise<void> {
    await this.bot.api.sendChatAction(chatId, 'typing')
  }

  async startPolling(): Promise<void> {
    this.bot.on('message', async (ctx) => {
      const msg = this.parseMessage(ctx)
      if (msg) await this.onMessage(msg)
    })
    await this.bot.start()
  }

  // Webhook: called from HTTP handler
  async handleWebhook(payload: unknown): Promise<void> {
    await this.bot.handleUpdate(payload as any)
  }
}
```

---

## Discord-specific adapter (discord.js)

```typescript
// adapters/discord.adapter.ts
import { Client, GatewayIntentBits, Message } from 'discord.js'

export class DiscordAdapter implements IPlatformAdapter {
  platform = 'discord'
  botId: string
  private client: Client

  constructor(token: string) {
    this.client = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,   // requires privileged intent in Discord portal
        GatewayIntentBits.DirectMessages,
      ]
    })
  }

  parseMessage(msg: Message): NormalizedMessage | null {
    if (msg.author.bot) return null         // ignore other bots
    const isMention = msg.mentions.has(this.client.user!)
    // In guild: respond only to mentions unless configured otherwise
    if (msg.guild && !isMention) return null
    return {
      id: msg.id,
      platform: 'discord',
      chatId: msg.channelId,
      userId: msg.author.id,
      username: msg.author.username,
      text: msg.content.replace(/<@\d+>/g, '').trim(), // strip @mention
      isGroupChat: !!msg.guild,
      isMention,
      replyToMessageId: msg.reference?.messageId,
      timestamp: msg.createdAt,
      rawPlatformData: msg
    }
  }

  async sendMessage(chatId: string, response: BotResponse): Promise<void> {
    const channel = await this.client.channels.fetch(chatId)
    if (!channel?.isTextBased()) return
    await channel.send({
      content: response.text,
      // Discord uses different markdown — no MarkdownV2 escaping needed
    })
  }

  async sendTypingIndicator(chatId: string): Promise<void> {
    const channel = await this.client.channels.fetch(chatId)
    if (channel?.isTextBased() && 'sendTyping' in channel) {
      await channel.sendTyping()
    }
  }

  async startPolling(): Promise<void> {
    // Discord doesn't have polling — it's always WebSocket (Gateway)
    this.client.on('messageCreate', async (msg) => {
      const normalized = this.parseMessage(msg)
      if (normalized) await this.onMessage(normalized)
    })
    await this.client.login(process.env.DISCORD_BOT_TOKEN)
  }

  // Discord uses WebSocket Gateway, not HTTP webhooks for bot messages
  // Webhook endpoint is only for Discord Interactions (slash commands)
  async handleWebhook(payload: unknown): Promise<void> {
    throw new Error('Discord uses Gateway (WebSocket), not polling webhooks')
  }
}
```

---

## Security: never skip these

```typescript
// Webhook signature verification (Telegram)
function verifyTelegramWebhook(req: Request): boolean {
  const secretToken = req.headers['x-telegram-bot-api-secret-token']
  return secretToken === process.env.TELEGRAM_WEBHOOK_SECRET
}

// Admin command whitelist (by userId, NOT username)
const ADMIN_USER_IDS = new Set(
  process.env.ADMIN_USER_IDS?.split(',').map(id => id.trim()) ?? []
)
function isAdmin(userId: string): boolean {
  return ADMIN_USER_IDS.has(userId)  // userId is stable; username is not
}

// Length cap + basic hygiene — NOT a prompt-injection defense (see warning below)
function capUserInput(text: string): string {
  return text.slice(0, 4000)
}

// ⚠️ Regex-stripping "ignore previous instructions" is SECURITY THEATER (Simon Willison): attackers
// rephrase infinitely. The real defense is ARCHITECTURAL — see the AI chatbot threat model below.

// Rate limiting per user — MUST be Redis-backed in production.
// (An in-memory Map is lost on restart and invisible across instances — it contradicts this file's
//  own "conversation state in Redis" rule. Use Redis INCR + EXPIRE.)
async function checkRateLimit(redis, userId: string, limit = 10, windowSec = 60): Promise<boolean> {
  const key = `rl:${userId}`
  const n = await redis.incr(key)
  if (n === 1) await redis.expire(key, windowSec)
  return n <= limit
}
```

---

## AI chatbot threat model — beyond platform mechanics (see references/security.md + mcp.md)

Token/webhook security above is necessary but not sufficient. A public LLM chatbot has its own
threat surface. Anchored in OWASP LLM Top 10 + Simon Willison's prompt-injection work.

```
Prompt injection (OWASP LLM01) — architectural, not regex
  ✗ regex-strip "ignore instructions" (theater); trust the model to police itself.
  ✓ user text is DATA: delimit it ("<user_message>…</user_message>"), never let chat content
    trigger privileged actions (admin ops, tool calls, DB writes) on its own.
  ✓ authorize actions by userId (stable, whitelisted) — NEVER because the message "asked" for it.
  ✓ filter OUTPUT too — a jailbroken model must not leak the system prompt, secrets, or other users' data.

Abuse & cost control (an open LLM bot is a cost-attack surface — one spammer = your API bill)
  ✓ per-user rate limit (Redis) + a GLOBAL daily LLM-spend circuit breaker (stop at budget, alert).
  ✓ cap tokens per request; cheap model for cheap intents (routing, ai-agent.md).

Content safety / moderation (public bot = legal/ToS exposure)
  ✓ run a moderation check on input AND output; refuse prohibited content; log refusals.

Conversation isolation & PII (multi-user memory is a leak surface — A01)
  ✓ conversation state is scoped by userId/chatId — one user can NEVER retrieve another's history.
  ✓ don't log full message bodies with PII; redact. Support deletion/retention (GDPR): "forget me".

Least-privilege bot permissions (Saltzer & Schroeder)
  ✓ Discord: request only the intents/permissions you use — not "all intents"/Administrator.
  ✓ Telegram: bot has no admin rights in groups unless a feature needs it. Rotate the token on leak.
```

Add to CLAUDE.md: "User chat text is untrusted data, never a command — actions are authorized by
userId, not by message content. Global LLM-spend circuit breaker + per-user Redis rate limit.
Moderate input+output. Conversation memory scoped per user. Least-privilege bot permissions."

---

## Chatbot-specific observability

```typescript
// Every message handled — log this:
logger.info({
  requestId: RequestContext.get_id(),
  platform: msg.platform,
  chatId: msg.chatId,          // OK to log (not PII)
  userId: hashUserId(msg.userId), // hash before logging
  isGroupChat: msg.isGroupChat,
  hasMedia: !!msg.mediaType,
  messageLength: msg.text?.length,
}, 'Message received')

// Every LLM call — log this (from ai/client.ts):
logger.info({
  requestId: RequestContext.get_id(),
  historyTurns: state.history.length,
  model, inputTokens, outputTokens, latencyMs, costUsd
}, 'LLM call completed')

// Rate limit hit:
logger.warn({
  requestId: RequestContext.get_id(),
  userId: hashUserId(userId),
  platform
}, 'Rate limit hit — message rejected')
```

---

## Polling vs Webhook auto-switch pattern

```typescript
// main.ts
const adapter = new TelegramAdapter(process.env.TELEGRAM_BOT_TOKEN!)

if (process.env.WEBHOOK_URL) {
  // Production: webhook mode
  const app = express()
  app.post(`/webhook/${process.env.TELEGRAM_BOT_TOKEN}`, async (req, res) => {
    if (!verifyTelegramWebhook(req)) {
      return res.status(403).json({ error: 'Forbidden' })
    }
    await adapter.handleWebhook(req.body)
    res.json({ ok: true })
  })
  // Register webhook URL with Telegram
  await adapter.bot.api.setWebhook(
    `${process.env.WEBHOOK_URL}/webhook/${process.env.TELEGRAM_BOT_TOKEN}`,
    { secret_token: process.env.TELEGRAM_WEBHOOK_SECRET }
  )
  app.listen(3000)
} else {
  // Development: polling mode
  await adapter.startPolling()
}
```

---

## Platform-specific limits to know

```
Telegram:
  Message size: 4096 characters (split long responses)
  File size: 50MB bots, 2GB premium
  Rate limit: 30 msg/sec globally, 1 msg/sec per chat
  Groups: bot can't read messages unless @mentioned or given admin rights
  History: bot can't read messages sent BEFORE it joined

Discord:
  Message size: 2000 characters
  Embeds: up to 6000 chars across fields
  Rate limit: 5 req/sec per bot (use queuing for bulk operations)
  Intents: MessageContent requires explicit enable in Discord Developer Portal
  Thread messages: need separate intent (ThreadMembers)
  History: bot CAN read channel history via channel.history()

Both platforms:
  Voice messages: need transcription service (Whisper) before LLM
  Images: need vision model or OCR before text LLM
  Long LLM responses: send typing indicator BEFORE generating
```

---

## Walking skeleton for chatbot MVP

```
1. Bot receives /start → replies with greeting (no LLM)
2. Bot receives any text → sends typing indicator → calls LLM → replies
3. Second message → LLM has conversation history from step 2
4. /reset command → clears conversation history
5. Bot running in Telegram AND Discord (if multi-platform)

Gate: conversation persists across messages AND across bot restarts.
If /reset then send message → bot has no memory of previous exchange.
Only after gate passes: add features (commands, RAG, media handling).
```

---

## Common mistakes

```markdown
## Chatbot anti-patterns (add to CLAUDE.md)

Never:
- Store conversation state in memory only (lost on restart)
- Use username as identity (users change usernames — use userId)
- Respond to all group messages without @mention check
- Log raw user message text (privacy — log length/type only)
- Call LLM synchronously without typing indicator first
- Inject user input directly into system prompt without sanitization
- Hardcode admin userIds (use env vars: ADMIN_USER_IDS)
- Use setTimeout for rate limiting (use Redis with atomic operations)

Always:
- Send typing indicator before any response > 0.5s
- Split messages > platform limit (Telegram: 4096, Discord: 2000)
- Verify webhook signature before processing (Telegram)
- Hash userId before logging (privacy)
- Handle platform adapter errors gracefully (network issues, API down)
- Test /reset command clears history completely
- Add /help command listing available commands
```
