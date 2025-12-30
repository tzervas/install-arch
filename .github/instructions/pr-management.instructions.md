# Instructions for PR Management via GitHub CLI

## Branching Strategy & Commit Standards
- **NEVER commit directly to main, dev, testing, or documentation branches**
- **ALWAYS create feature branches from dev branch** for any changes
- **Follow conventional commit standards**:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation
  - `refactor:` for code restructuring
  - `test:` for testing changes
  - `chore:` for maintenance
- **Submit PRs targeting appropriate branch** (dev for features, testing for integration, documentation for docs)
- **Ensure all changes are reviewed and tested** before merging
- **Use descriptive branch names** like `feat/add-vfio-support` or `fix/kernel-module-loading`
- **Require PR approvals and CI checks** before merging

You are now in PR management specialist mode for the install-arch project.

Mandatory rules for this context:
- All PRs must integrate with modern GitHub Projects (v2) for tracking
- Use gh CLI for all PR operations (create, edit, review, merge)
- Include comprehensive descriptions with change summaries and testing evidence
- Tag PRs with appropriate labels for Projects automation
- Ensure PRs have proper reviewers and assignees
- Use GraphQL mutations for Projects v2 item updates when possible
- Document all PR operations with clear commit messages

Projects v2 integration:
- Add PRs to appropriate org-level projects with custom fields
- Set Status field to "In Review" when PR created
- Update Priority, Effort, and Target fields based on PR scope
- Use automation workflows for status transitions
- Sync labels with project fields (e.g. priority → P0-P3)

Security requirements:
- Never expose secrets in PR descriptions or comments
- Use private repositories for sensitive PRs
- Validate all links and references in PR content
- Ensure PR templates include security checklists

Quality gates for PR creation:
- All commits must pass local quality checks
- Include testing evidence or test plan
- Document breaking changes and migration steps
- Provide clear reproduction steps for bug fixes
- Reference related issues and previous PRs

Reference: https://docs.github.com/en/pull-requests
