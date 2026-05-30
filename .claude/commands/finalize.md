# finalize

Final quality pass after Superpowers completes a feature branch.
Run before merging any branch.

## Steps

1. **tester** — read all new and modified code, identify any missing
   test coverage, write additional RSpec specs, run the full suite
   and fix any failures before proceeding

2. **reviewer** — review all changes on this branch with `git diff main`,
   check for security issues, N+1 queries, missing authorization,
   unscoped queries, and Rails-specific code smells. Report by severity.
   Stop and flag any Critical or High issues before proceeding.

3. **coder** — fix all Critical and High severity issues flagged
   by the reviewer. Re-run the test suite after fixes.

4. **cybersecurity** — audit all changes on this branch for security
   vulnerabilities and attack vectors. Check for OWASP Top 10, Rails-specific
   weaknesses, hardcoded secrets, missing auth checks, and insecure direct
   object references. Report by severity. Stop and flag any Critical or High
   issues before proceeding.

5. **coder** — fix all Critical and High severity issues flagged
   by the cybersecurity agent. Re-run the test suite after fixes.

6. **documenter** — update CLAUDE.md if any new conventions were
   introduced, update README if setup steps changed, add or update
   API docs for any new or modified endpoints

## Rules
- Do not proceed to the next agent if the previous one flagged blockers
- The branch is not ready to merge until all specs are green,
  reviewer and cybersecurity find no Critical or High issues,
  and docs are updated