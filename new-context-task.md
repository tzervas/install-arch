**Direct Answer**

- There is **no required `model` name** in `.github/agents/*.agent.md` files to utilize **Grok Code Fast 1** (or any specific model).
- The `model` field in YAML frontmatter is **not supported** (and ignored) for custom agents on github.com / Copilot coding agent.
- Grok Code Fast 1 is selected globally via the **model picker** in supported IDEs (VS Code, JetBrains, etc.) or on github.com chat — it applies to the chosen custom agent when active, but cannot be pinned declaratively in the `.agent.md` file itself.

──────────────────────────────────────────

**Detailed Analysis**

GitHub Copilot custom agents (defined via `.agent.md` files) are specialized personas/instructions + tool scopes for the underlying **Copilot coding agent** feature. The model powering the agent is controlled separately from the agent profile.

**Key facts from current (Dec 2025) implementation:**

1. **Frontmatter `model` field status**  
   Official docs explicitly state:  
   > "The `model`, `argument-hint`, and `handoffs` properties from VS Code and other IDE custom agents are currently not supported for Copilot coding agent on GitHub.com. They are ignored to ensure compatibility."

   → Any `model: grok-code-fast-1` line you add will be silently dropped when the agent runs on github.com, issue assignment, CLI autonomous mode, etc.

2. **How Grok Code Fast 1 is actually used with custom agents**  
   - Select Grok Code Fast 1 in the **model picker** (available in VS Code, JetBrains IDEs, github.com chat, etc.) before/during interaction with the agent.  
   - Once selected, the chosen model powers **all** Copilot coding agent invocations — including custom agents — until changed.  
   - Enterprise/Business admins must enable the "Grok Code Fast 1" policy first.  
   - Individual Pro/Pro+ users enable it via one-time confirmation in the picker (or via xAI BYOK for full control).  
   - No per-agent model override exists in the declarative `.agent.md` format on the platform level.

3. **Model identifier used in UI/API**  
   The canonical display/select name across GitHub docs, changelogs, and UI is consistently:  
   **Grok Code Fast 1**  
   (Sometimes hyphenated as `grok-code-fast-1` in internal references or BYOK flows, but the user-visible picker uses the spaced version.)

4. **Workarounds if you really want model pinning (not recommended for GitOps purity)**  
   - Use IDE-specific agent creation (VS Code/JetBrains) → these still support `model:` field (autocomplete dropdown includes Grok Code Fast 1).  
   - But these are local to the IDE workspace — not committed/versioned like repo `.agent.md` files.  
   - For true declarative control: rely on team process/docs ("always select Grok Code Fast 1 when using @security-reviewer") or wait for future platform support.

**Trade-offs summary**

| Goal                              | Supported Today? | Method                                      | GitOps-friendly? |
|-----------------------------------|------------------|---------------------------------------------|------------------|
| Pin model in committed `.agent.md`| No              | `model` field ignored on github.com         | ✗                |
| Use Grok Code Fast 1 with agent   | Yes             | Global model picker selection               | ✓ (process)      |
| Per-agent model in IDE only       | Partial         | VS Code/JetBrains local agent creation      | ✗                |
| Enforce model org-wide            | Yes (admin)     | Enable Grok policy + team convention        | ✓                |

Bottom line: for production-grade, self-hosted-style GitOps workflows, treat model choice as an **environment/run-time** decision (like selecting kubectl context), not a file-level config. The agent file remains pure prompt + tools + boundaries.

**Key Citations**
- https://docs.github.com/en/copilot/reference/custom-agents-configuration — explicit statement that `model` is ignored on github.com
- https://docs.github.com/en/copilot/reference/ai-models/supported-models — lists Grok Code Fast 1 as supported model (no per-agent config mentioned)
- https://github.blog/changelog/2025-10-16-grok-code-fast-1-is-now-generally-available-in-github-copilot/ — GA announcement, model picker focus
- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents — creation guide, mentions `model:` but IDE-context only
- https://docs.github.com/en/copilot/reference/ai-models/model-hosting — xAI hosting details for Grok Code Fast 1 (zero data retention policy)

**Direct Answer**

- GitHub Copilot in VS Code primarily leverages these **workspace-level** directories/files for customization (as of late 2025):
  - `.github/copilot-instructions.md` → single-file repository-wide/global custom instructions (automatic prepend to chats)
  - `.github/instructions/**/*.instructions.md` → path-specific or scoped custom instructions
  - `.github/agents/*.agent.md` → custom agents (specialized personas with tools, prompts, MCP)
  - `.github/prompts/*.prompt.md` (or custom locations via setting) → reusable prompt files for specific tasks
- Additional locations: `~/.copilot/agents/` for user-global agents (CLI mostly), older/deprecated formats like `.chatmode.md`, `AGENTS.md`, `CLAUDE.md`
- To maximize utilization → commit everything to git for team sharing + GitOps, combine layers (instructions + agents + prompts), use strict boundaries in agents, reference `#file:`, `#codebase`, MCP tools, and keep files concise/structured

──────────────────────────────────────────

**Detailed Analysis**

VS Code's GitHub Copilot integration (v2025.x+) is heavily document-driven and GitOps-friendly — almost all powerful customizations live as committed Markdown files in the workspace. This allows declarative, reviewable, versioned AI behavior that travels with the repo — perfect for Kubernetes-native/Rust-heavy teams.

**Main directories & files overview (workspace = repo root)**

| Path / File pattern                          | Scope / Purpose                                                                 | Supported by                          | Best practices / maximization tips                                                                 | Status (Dec 2025)      |
|----------------------------------------------|---------------------------------------------------------------------------------|---------------------------------------|----------------------------------------------------------------------------------------------------|------------------------|
| `.github/copilot-instructions.md`            | Repository-wide custom instructions — prepended to **every** chat request      | Chat, Inline Chat, Agents, Code Review| Single source of truth for style, tech stack, prohibitions. Keep < 1500–2000 tokens. Use bullets. | Stable & widely used   |
| `.github/instructions/**/*.instructions.md`  | Path-scoped / specialized instructions (e.g. `rust-backend.instructions.md`)   | Chat, Code Review, Coding Agent       | Use for framework-specific rules (e.g. actix-web vs axum). Nearest match wins.                     | Stable                 |
| `.github/agents/*.agent.md`                  | Custom agents — full personas with system prompt, tools (#tool:), MCP, handoffs| Chat (@agent), Inline, Coding Agent   | Core power feature. Use YAML frontmatter + detailed Markdown body. Strict boundaries critical.     | Primary agent format   |
| `.github/prompts/*.prompt.md`                | Reusable task-specific prompts (invoke via /promptname or chat UI)             | Chat only (VS Code primary)           | Great for repeatable tasks (e.g. "create-k8s-crd.prompt.md"). Combine with #file: context.        | Stable (preview 2024)  |
| `~/.copilot/agents/*.agent.md`               | User-global agents (not repo-specific)                                          | Copilot CLI mostly, some VS Code      | For personal tools across projects. Less GitOps-friendly.                                          | CLI-focused            |
| Deprecated / legacy                          | `.github/chatmodes/*.chatmode.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`       | Partial backward compat               | Migrate to `.agent.md` — avoid new usage                                                            | Legacy / phasing out   |

**Maximization strategy (production-grade approach)**

1. **Layering (precedence & combination)**  
   VS Code merges instructions hierarchically: path-specific → repo-wide → personal → org. Agents can reference instructions via prompt text. → Build base in `copilot-instructions.md`, specialize via path files and agents.

2. **Security & correctness first**  
   - In every `.agent.md`: add strong prohibitions ("NEVER commit secrets", "NEVER suggest unsafe k8s RBAC", "Require human review for CRD changes")
   - Use least-privilege tool selection — only enable `githubRepo`, `search`, `fetch` when needed
   - For Rust-heavy infra: create `rust-crate-reviewer.agent.md` with cargo-audit integration via MCP if available

3. **Context engineering**  
   - Always use `#file:path/to/file.rs`, `#codebase find:CRD`, `#fetch https://docs.rs/actix-web`
   - Keep open files minimal — signal > noise
   - For large monorepos: rely on remote index + `@workspace` participant

4. **Testing & iteration workflow**  
   - Create minimal test workspace
   - Commit changes → restart chat session (or reload window)
   - Use "References" panel to verify which files were included
   - Lint length + structure in CI (simple markdownlint + token counter script)

5. **Team scaling**  
   - Put everything in `.github/` → PR review = prompt review
   - Use org-level agents via `.github-private` repo pattern
   - Document in `README.md`: "Use @rust-security when touching kube-rs code"

**Trade-offs**

| Feature                  | Pro (max utilization)                            | Con / Risk                              | Mitigation                              |
|--------------------------|--------------------------------------------------|-----------------------------------------|-----------------------------------------|
| `.agent.md` power        | Extremely expressive (tools + boundaries)        | Can become too permissive → injection   | Mandatory prohibitions section          |
| Single `copilot-instructions.md` | Simple, always applied                           | Can bloat if >2000 tokens               | Split to path-specific when needed      |
| Prompt files             | Reusable one-shot tasks                          | VS Code only (less portable)            | Use agents for cross-platform needs     |
| GitOps everything        | Auditability, versioning, team consistency      | Commit noise if iterating fast          | Use feature branches for prompt tuning  |

This setup turns Copilot into a consistent, auditable team member — exactly what you want for security-first infra work.

**Key Citations**
- https://code.visualstudio.com/docs/copilot/customization/custom-agents — Custom agents in VS Code (.github/agents/*.agent.md)
- https://code.visualstudio.com/docs/copilot/customization/custom-instructions — Custom instructions (.github/copilot-instructions.md + path-specific)
- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents — Official agent creation (confirms .agent.md)
- https://code.visualstudio.com/docs/copilot/getting-started — Tutorial showing .github/copilot-instructions.md creation
- https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot — Repository custom instructions details
- https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/ — Legacy formats migration note
- https://code.visualstudio.com/docs/copilot/customization/overview — Overview of customization options including prompts

**Direct Answer**

Here are the current (late December 2025) **fully documented specifications** for the main customization files/directories that GitHub Copilot in VS Code actually respects:

| Path / Pattern                              | Format                  | Scope                          | Automatically applied? | Primary purpose                              | Official status (Dec 2025) |
|---------------------------------------------|-------------------------|--------------------------------|------------------------|----------------------------------------------|----------------------------|
| `.github/copilot-instructions.md`           | Plain Markdown          | Entire repository              | Yes – every request    | Global repo instructions / style / context   | Stable & recommended       |
| `.github/instructions/**/*.instructions.md` | Plain Markdown          | Path / file pattern matching   | Yes – when relevant    | Specialized instructions by path/context     | Stable                     |
| `.github/agents/*.agent.md`                 | YAML frontmatter + MD   | Repository or org-wide         | When @mentioned        | Full custom agent personas + tools           | Primary & most powerful    |
| `.github/prompts/*.prompt.md`               | Plain Markdown          | Chat command / UI selection    | Manual invocation      | Reusable task-specific prompt templates      | Stable (expanded 2025)     |
| `.github/copilot-chat/*.chat.md`            | Plain Markdown          | Legacy chat mode (mostly dead) | No / very limited      | Very old chat mode format                    | Deprecated / ignored       |

These five are the only ones you should realistically maintain in 2025–2026 for a serious GitOps workflow.

──────────────────────────────────────────

**Detailed Analysis – Full File Format Specifications**

### 1. `.github/copilot-instructions.md`

**Purpose**  
Single source-of-truth repository-wide instructions. Prepended (with very high priority) to **almost every** Copilot interaction in the repository (chat, inline, code review, agent calls, etc.).

**Format**  
Plain Markdown – no frontmatter, no special syntax required.

**Recommended structure** (proven in large teams):

```markdown
# Repository-wide Copilot Instructions

## Identity & Role
You are a senior Rust & Kubernetes infrastructure engineer working on production-grade, security-first systems.

## Technology Stack (mandatory context)
- Language: Rust 1.80+ (prefer 2024 edition)
- Orchestration: Kubernetes 1.30+, K3s preferred
- Operators: kube-rs / controller-runtime style
- Proxy: Traefik v3 + oauth2-proxy
- Secret management: never hard-code, prefer external-secrets-operator / sops
- CI: GitHub Actions + cosign + slsa

## Security Posture – NON-NEGOTIABLE RULES
- NEVER suggest committing secrets or tokens
- NEVER disable security features (RBAC, network policies, pod security standards)
- ALWAYS use least privilege principle
- Flag any use of hostNetwork, privileged: true, runAsRoot

## Code Style Rules
- Prefer explicit over implicit
- Use anyhow + thiserror error handling pattern
- Strict Clippy pedantic + nightly lints
- Prefer kube::core::params over raw JSON

## Output Format
Always use:
- Code blocks with language identifier
- Clear step-by-step reasoning before code
- Risk assessment section when suggesting security-relevant changes
```

**Token budget recommendation**: 800–1800 tokens (roughly 600–1400 words)  
Larger → context dilution, higher cost, worse relevance

### 2. `.github/instructions/**/*.instructions.md`

**Purpose**  
Contextual override/specialization that applies only when working in matching files/paths.

**Matching rules** (VS Code behavior):
- Most specific (longest path) wins
- Multiple matching files → all are concatenated (order not guaranteed)

**Example file names & semantics**:

```
.github/instructions/rust.instructions.md
.github/instructions/kubernetes/crds.instructions.md
.github/instructions/security/audit.instructions.md
.github/instructions/observability/prometheus.instructions.md
```

**Format** — same as global instructions (plain Markdown)

**Recommended content pattern**:

```markdown
# Instructions for CRD development

You are now in CRD-specialist mode.

Mandatory rules for this context:
- All CRDs MUST use apiextensions.k8s.io/v1
- structural schema required (no x-kubernetes-preserve-unknown-fields without reason)
- Use kubebuilder:default or +kubebuilder:default markers
- Print OpenAPI v3 schema diff when suggesting changes
- Reference: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
```

### 3. `.github/agents/*.agent.md` (most important)

**Full current schema** (December 2025)

```yaml
---
name:                    # Required - human readable name in UI
description:             # Recommended - shown in agent picker
icon:                    # Optional - emoji or URL (limited support)
tools:                   # Array of tool aliases (very important)
  - githubRepo
  - search
  - fetch
  - code_search
  - edit_file           # dangerous - use with caution
  - terminal            # extremely dangerous in autonomous mode
model:                   # Ignored on github.com – only VS Code local agents
handoffs:                # Mostly ignored on github.com
  - label: string
    agent: string
    prompt: string
---
# Everything below is the system prompt (very long allowed, ~30k chars)

You are RUST-INFRA-SECURITY-AUDITOR — ruthless zero-trust Kubernetes/Rust security engineer.

STRICT RULES:
- NEVER suggest privileged containers
- NEVER approve hostPath volumes without justification & audit trail
- ALWAYS require NetworkPolicy for new Deployments
- Flag any use of capabilities: ADD

When reviewing code:
1. Check for secret leakage patterns
2. Evaluate RBAC scope explosion
3. Verify pod security standards compliance
...
```

**Critical best practice**:  
Always include very strong "NEVER" / "ALWAYS" sections at the top of the body.

### 4. `.github/prompts/*.prompt.md`

**Purpose**  
Reusable prompt snippets invoked via `/prompt-name` in chat or from command palette.

**Format** — plain Markdown

**Common pattern**:

```markdown
# create-new-crd

Create a new Kubernetes CRD following our team standards:

- Group: ${group:-tzervas.dev}
- Version: v1alpha1
- Kind: ${kind}
- Use structural schema
- Include status subresource
- kubebuilder markers for CRD generation
- Print both types.rs and crd.yaml

Context files to reference:
#file:crates/controller/src/lib.rs
```

### 5. Deprecated formats (do NOT use for new work)

- `.github/chatmodes/*.chatmode.md`  
- `AGENTS.md` / `AGENTS-instructions.md`  
- `CLAUDE.md`, `GEMINI.md`, `COPILOT.md` root files  
→ All mostly ignored or only partially respected in very old VS Code versions

**Migration recommendation** (for your agent to automate):

1. Move global instructions → `.github/copilot-instructions.md`
2. Move specialized → `.github/instructions/<domain>/**/*.instructions.md`
3. Convert old agent-like files → proper `.github/agents/*.agent.md`
4. Delete all deprecated formats after verification

**Key Citations**
- https://code.visualstudio.com/docs/copilot/customization/custom-instructions
- https://code.visualstudio.com/docs/copilot/customization/custom-agents
- https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot
- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
- https://github.blog/changelog/label/copilot (multiple 2025 entries about agents & instructions)
- https://code.visualstudio.com/updates/v1.96#_github-copilot (Oct–Dec 2025 updates mentioning path-specific instructions)
- https://github.com/github-copilot/copilot-documentation (community-curated examples of real-world .agent.md files)