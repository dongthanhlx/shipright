# Registry pack — chatbot-telegram-discord

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

AI chatbot integrated with Telegram and/or Discord.

```
install:
  required:
    - addyosmani/agent-skills
      skills: [incremental-implementation, security-and-hardening, code-review-and-quality]
  stack-telegram:
    nodejs: npm install grammy
    python: pip install python-telegram-bot
  stack-discord:
    nodejs: npm install discord.js
    python: pip install discord.py
  optional:
    - datadog-labs/dd-llmo-eval-bootstrap (if AI chatbot)
    - RAGAS (if RAG-powered chatbot)

tested-with: grammy 1.x, discord.js 14.x, python-telegram-bot 20.x
load: references/stacks/chatbot-platforms.md — PlatformAdapter (the ACL for Telegram/Discord),
      webhook vs polling, per-platform limits. AI-powered bot → also stacks/ai-projects.md

platform-decision:
  polling: development / no SSL / behind NAT
  webhook: production / VPS / Railway / Fly.io
  note: "Discord uses WebSocket Gateway, NOT HTTP webhook for bot messages"

shipright-adds-to-CLAUDE:
  boundary-platform: "Platform code ONLY in adapters/ folder. Never in handlers or services."
  boundary-state: "Conversation state in Redis/DB. Never module-level variables (SW terminates)."
  security:
    - "Bot token in env vars only. Never in code or logs."
    - "Admin commands: whitelist by userId (not username — usernames change)."
    - "Validate webhook signature before processing (Telegram: X-Telegram-Bot-Api-Secret-Token)"
    - "Sanitize user input before system prompt injection"
  rate-limits:
    - "Telegram: 30 msg/sec global, 1 msg/sec per chat"
    - "Discord: 5 req/sec per bot"
    - "Send typing indicator before responses > 0.5s"
  debt-signals:
    - "TODO[deployed]: switch from polling to webhook"
    - "TODO[users>100]: add Redis for conversation state persistence"
    - "TODO[messages>1000/day]: add message queue"
```
