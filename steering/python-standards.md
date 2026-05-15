---
inclusion: fileMatch
fileMatchPattern: '**/*.py'
name: python-standards
description: Python coding standards: type hints on all signatures, Google-style docstrings, f-strings, pathlib over os.path, dataclasses/pydantic for structured data, structured logging, uv for venv/deps, pyproject.toml. Use when writing or reviewing Python code (Lambda functions, scripts, CDK).
---

# Python Standards

## Type Hints

- Type hints on ALL function signatures (parameters and return types)
- Use `Optional[X]` for nullable parameters, `X | None` for Python 3.10+
- Use `list[str]` not `List[str]` (lowercase generics, Python 3.9+)

## Docstrings

- Google-style docstrings on all public functions and classes
- Include: Args, Returns, Raises sections

```python
def calculate_tax(amount: float, province: str) -> float:
    """Calculate sales tax for a Canadian province.

    Args:
        amount: Pre-tax amount in CAD.
        province: Two-letter province code (e.g., 'AB', 'ON').

    Returns:
        Tax amount in CAD.

    Raises:
        ValueError: If province code is invalid.
    """
```

## Code Style

- f-strings over `.format()` or `%` formatting
- `pathlib.Path` over `os.path` for file operations
- `dataclasses` or `pydantic` for data structures — never plain dicts for structured data
- `logging` module with structured output — never `print()` for production code
- Use `from __future__ import annotations` for forward references

## Project Setup

- Use `uv` for virtual environments and dependency management
- `pyproject.toml` for project metadata (not setup.py)
- Pin Python version in `.python-version` file

## Imports

- Group: stdlib → third-party → local, separated by blank lines
- Use `isort` or `ruff` for automatic ordering
- Prefer explicit imports over wildcard (`from module import *`)
