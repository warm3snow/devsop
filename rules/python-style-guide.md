---
# Do not modify the header of this file; the AI coding agent relies on it to apply this style guide as an always-on rule
type: always
---
You are a professional Python development assistant. All code must strictly follow the coding conventions below.

**Note: unless explicitly stated otherwise, follow PEP 8 and the Google Python Style Guide.**

## Conventions Overview

The requirement level of each convention is defined as:
- **Mandatory**: code must follow this; violating it is considered an error
- **Preferable**: code should follow this, but exceptions are allowed in special cases and are not considered errors
- **Optional**: can be referenced; decide whether to adopt it based on the specific situation

## Code Style Conventions

### 【Mandatory】Formatting
- All code must be formatted with `ruff format` (or `black`); formatting must be enforced in CI, not by hand
- Follow PEP 8's 4-space indentation, never tabs
- A single line should not exceed 88 columns (black default) unless breaking is impossible

### 【Mandatory】Imports
- Import order (enforced by `ruff check --select I` / `isort`): standard library → third-party → first-party, one blank line between groups
- Absolute imports only; wildcard imports (`from x import *`) are forbidden
- Avoid importing unused names; use `import numpy as np` style aliases only for well-known conventions

### 【Mandatory】Naming conventions
- Modules/packages: `snake_case` (short, lowercase)
- Functions/variables: `snake_case`; constants: `UPPER_SNAKE_CASE`; classes: `PascalCase`
- Private members: single leading underscore `_internal`; name mangling (`__double`) only for real collision avoidance
- Boolean variables should read as a question (`is_ready`, `has_token`), never `flag`/`status` alone

### 【Preferable】Code line count limits
- A file must not exceed 600 lines; a function must not exceed 60 lines; a class must not exceed 400 lines
- Nesting depth must not exceed 4; extract functions instead of nesting further

## Type Annotation Conventions

### 【Mandatory】Type annotations
- New code must annotate function signatures (parameters + return types) and public attributes
- Use modern syntax: `list[str]`, `dict[str, int]`, `X | None` (not `Optional[X]`), `from __future__ import annotations` where needed
- `Any` is forbidden in public interfaces; use `Protocol` / generics / `TypeVar` instead
- Prefer `dataclasses.dataclass` or `pydantic` models over raw dicts for structured data

## Error Handling Conventions

### 【Mandatory】Exceptions
- Prefer EAFP (`try/except`) over LBYL (`if key in dict`) for single operations
- Catch the most specific exception; bare `except:` and `except Exception: pass` are forbidden
- Never swallow exceptions silently — re-raise (`raise ... from err`) or log with context and handle
- `assert` must not be used for runtime validation (it disappears under `python -O`); raise `ValueError` instead

### 【Mandatory】Logging
- Use the `logging` module; `print()` is forbidden in library/production code paths
- Log with context: `logger.error("create user failed", extra={"uid": uid, "err": err})`
- Never log secrets (passwords/tokens) — mask before logging

## Comment and Docstring Conventions

### 【Mandatory】Docstrings
- Every public module, class, and function has a docstring (PEP 257); use Google style (Args/Returns/Raises sections)
- Comments explain *why*, not *what*; keep comments in sync with code changes

## Language Feature Conventions

### 【Mandatory】Common pitfalls
- No mutable default arguments (`def f(x, acc=[])`); use `acc=None` + init inside
- Context managers (`with open(...)`) are mandatory for resources; never leave file handles/sockets unclosed
- Prefer comprehensions and generator expressions over `map`/`filter` with lambdas
- `f-string` for string interpolation (not `%` formatting or `"..." + var`)

### 【Preferable】Modern constructs
- `pathlib.Path` over `os.path`; `dataclasses` over manual `__init__` boilerplate
- Enum (`enum.Enum`) for fixed value sets instead of string literals
- Virtual environments mandatory per project (`.venv/`); never install into the system Python

## Unit Test Conventions

### 【Mandatory】Testing
- Use `pytest`; tests live in `tests/` with names `test_*.py`, functions `test_*`
- One assertion theme per test; use `pytest.raises(...)` for exception paths
- Mock at boundaries only (`unittest.mock` / `pytest-mock`); do not mock the unit under test
- Coverage target: ≥60% for the project, ≥80% for core modules (per CI threshold)

## Dependency Management Conventions

### 【Mandatory】Dependencies
- Declare dependencies in `pyproject.toml` (PEP 621); pin with a lockfile (`requirements.lock` / `uv.lock` / `poetry.lock`)
- Adding a third-party dependency requires a documented reason; prefer the standard library when equivalent

## Security Conventions

### 【Mandatory】Security
- SQL must be parameterized (SQLAlchemy parameters / `cursor.execute(sql, params)`); string concatenation is forbidden
- No hardcoded keys, tokens, or passwords; read from env vars or secret management
- External input must be validated at the boundary (pydantic / marshmallow / explicit checks)
- Secrets must never appear in logs, exceptions, or API responses

## Recommended Tools

| Purpose | Tool |
|---------|------|
| Lint + format | `ruff` (lint + format) or `black` + `flake8` |
| Type check | `mypy --strict` |
| Testing | `pytest` + `pytest-cov` |
| Dependency management | `uv` / `poetry` |
| CI gate | `ruff check` + `mypy` + `pytest --cov` (block on failure) |
