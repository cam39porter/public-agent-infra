# Start Here — Class Participant Guide

Welcome. By the end of our session together, you'll have your own agent running — one we design live as a class — that reads tasks from Todoist, drafts work for you to approve, and executes once you give it the go-ahead.

This guide is what you should read **before** class, and it's what we'll follow along with **during** class. Come with the accounts set up (Section 3 below) and we'll be able to skip straight to the interesting parts.

---

## 1. What we're building, and why this pattern

The short version: **agents that work for you, not instead of you.**

Most "AI agent" demos show a computer doing a whole job end-to-end. That's a cool demo, but it's a terrible starting point for real work. In real work, you want an agent that does 80% of the boring setup, drafts the thing, and hands it to you to approve — so that the consequential moments stay with you.

The pattern we're going to use has four parts, each with one job:

1. **A shared folder of markdown files (this repo on GitHub)** — the agent's "DNA." What it does, what it doesn't do, what tools it can use, what it's not allowed to touch.
2. **Tasklet** — the runtime. It's the thing that actually runs the agent on a schedule and when events happen. It's the body around the DNA.
3. **Todoist** — the inbox. Every request to an agent, every draft back to you, every approval — all of it flows through Todoist tasks and comments. You already know how Todoist works, which means you already know how to work with the agent.
4. **Claude Code** — the meta-agent. You run this locally on your laptop, and it's how you create, edit, and improve agents. You don't write code; you have a conversation with Claude Code and it edits the markdown for you.

**Why separate them?** Because each one does what it's good at. GitHub is great at version control but terrible at running things. Tasklet is great at running things but shouldn't store "what an agent believes about the world." Todoist is where humans already live, so putting the approval interface there means there's nothing new to learn. Claude Code is shaped to do exactly the kind of text editing the framework needs.

**A few principles to keep in mind:**

- **Narrow scope first, then widen.** Your first agent should do one thing. Not five. One.
- **Draft-and-ask is the default.** Agents don't send emails, book meetings, or spend money without a human tapping "approve" in Todoist. You earn more autonomy over time.
- **Every preference you express becomes permanent.** When you tell your agent "be shorter in emails," it will update its own instructions in GitHub and push them. The next day, every other agent on your system will also know.
- **If you can't explain why an agent did something, read its SKILL.md.** That's the agent. There's no hidden layer.

That's really it. The rest is details.

---

## 2. What we'll do together in class

Rough plan:

1. **Walk through the architecture** live — so you can see how the pieces talk to each other (~15 min)
2. **Decide as a group what workflow we'll build** — we'll pick one real, annoying task that could use an assistant
3. **Use Claude Code to author the agent** — we'll write its SKILL.md together by having a conversation with Claude Code
4. **Wire up Todoist and Tasklet** — connect the plumbing (this is the fiddliest part; budget ~20 min)
5. **Test it with a real task** — trigger the agent, watch it draft, approve the draft, confirm it executed
6. **Tune it based on what went wrong** — because something will go wrong, and that's the useful part

You do not need to memorize any of the docs in this repo beforehand. We'll open them when we need them. But if you want to skim two things ahead of time:

- [`docs/principles.md`](docs/principles.md) — the opinions behind the architecture
- [`docs/architecture.md`](docs/architecture.md) — diagrams of how the pieces connect

10 minutes total. Don't overdo it.

---

## 3. Accounts to create before class

**Please have all of these set up before we start.** The OAuth and account-creation flows are the most time-consuming part, and doing them live eats into the interesting parts of the session.

### Required

1. **GitHub** — [github.com](https://github.com)
   If you don't already have an account, create one. You'll fork this repo into your account.

2. **An email for your agent** — a dedicated email address your agent will use to sign up for services. A free Gmail works fine (e.g. `yourname-agent@gmail.com`). **Do not use your personal email** — the agent will have its own accounts and needs to own them independently of you.

3. **Todoist** — [todoist.com](https://todoist.com)
   - One account for **you** (your personal or work email).
   - One account for **the agent** (using the dedicated email from step 2).
   - Free tier is fine for the class. You can upgrade later if you like it.

4. **Tasklet** — [tasklet.ai](https://tasklet.ai)
   Create an account using your personal email. Tasklet is the runtime that actually runs the agent.

5. **Claude Code** — [claude.com/product/claude-code](https://claude.com/product/claude-code)
   Install the CLI on your laptop. You'll need a Claude subscription (the Pro plan is sufficient for everything we'll do). You run Claude Code from your terminal.

6. **`gh` (GitHub CLI)** — [cli.github.com](https://cli.github.com)
   The Claude Code meta-agent uses this to interact with GitHub on your behalf.

### Nice to have (not required for class)

- A code editor if you like seeing your files in a UI (VS Code, Cursor, etc.). Not needed — Claude Code can handle everything — but many people prefer having a visual diff.

### Skip for now

- **Supabase**. This is the "persistent memory" layer. We won't use it in class. You can add it later once you have real use cases; instructions are in [`docs/adding-supabase.md`](docs/adding-supabase.md).

### Pre-class checklist

Before we start, please:

- [ ] Created/verified your GitHub account
- [ ] Created a dedicated email for your agent
- [ ] Set up two Todoist accounts (you + agent), and invited the agent as a collaborator to your workspace
- [ ] Created a Tasklet account
- [ ] Installed Claude Code and run `claude --version` to confirm it works
- [ ] Installed `gh` and run `gh auth login --web` to authenticate
- [ ] Forked [this repo](https://github.com/cam39porter/public-agent-infra) into your own GitHub account
- [ ] Cloned your fork locally:
  ```bash
  git clone <your-fork-url>
  cd public-agent-infra
  cp config.example.yaml config.yaml
  ```

If any of these fail, message me before class and we'll sort it.

---

## 4. The workflow we'll build (placeholder)

We'll decide this together as a class. Good candidates are things that:

- You do regularly (at least weekly, ideally more)
- Have an obvious "draft → approve → send" shape
- Are annoying enough that you'd actually use the agent if it worked

Examples (just to get you thinking):

- **Meeting follow-up drafter** — picks up new meetings, extracts action items, drafts a short follow-up email for each attendee.
- **Cold inbound triager** — watches for new cold emails, classifies them (pass / follow-up / interesting), drafts a one-line response for each.
- **Weekly digest composer** — each Friday, pulls notable things from the week and drafts a weekly update.
- **Todoist inbox groomer** — every morning, looks at your Todoist inbox, groups related items, suggests priorities, and asks you to approve the plan.
- **RSS/newsletter summarizer** — monitors a few feeds, drafts a short summary of anything interesting for you to skim.

Come with one idea in mind. It doesn't need to be right — we'll narrow it down together.

---

## 5. During class — what to bring open

Have these tabs ready:

- This repo in your terminal (`cd ~/wherever/public-agent-infra`)
- Claude Code running in that directory (`claude`)
- Todoist (your personal account — the one you'll be assigning tasks from)
- Tasklet (logged in)
- GitHub (logged in)
- A browser window where the agent's Todoist account is logged in (for the OAuth authorization step — this is the one most commonly missed)

---

## 6. After class

- Commit and push whatever we built so you have a record of it.
- Run the agent for a week in real life on real tasks. Notice what it gets wrong.
- When it's wrong, tell it — it should update its own SKILL.md and push the fix. If it doesn't, check [`agents/RULES.md`](agents/RULES.md) Rule 8 ("Adaptive Self-Update").
- Add a second agent for a second narrow job. And a third. Each new agent should take less time than the last.
- When you want persistent memory across agents (an entity graph, shared context), enable Supabase — [`docs/adding-supabase.md`](docs/adding-supabase.md).

If you get stuck later, the two docs that will answer almost every question:

- [`docs/creating-an-agent.md`](docs/creating-an-agent.md) — the full, step-by-step version
- [`docs/principles.md`](docs/principles.md) — the reasoning behind the decisions

See you in class.
