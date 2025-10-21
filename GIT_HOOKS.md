Git hooks (pre-commit)
======================

This repository includes a pre-commit hook at `.githooks/pre-commit` to:

- Block committing Python bytecode and `__pycache__/`
- Warn if you are about to add exact duplicate files (by SHA256)

Enable hooks once per clone:

1) Point Git to the hooks folder

   git config core.hooksPath .githooks

2) Make sure the hook is executable

   chmod +x .githooks/pre-commit

That’s it. Future commits will automatically run the checks.

Notes
-----
- The duplicate detector is best-effort and only warns; it won’t block your commit.
- If you intentionally keep duplicate files for testing or archives, you can ignore the warning.
