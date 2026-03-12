class BuzzOffError(Exception):
    """Base exception for BuzzOff SDK errors."""

    def __init__(self, message: str, status_code: int | None = None, detail: str | None = None):
        self.status_code = status_code
        self.detail = detail or message
        super().__init__(message)


class AuthenticationError(BuzzOffError):
    """401 — Invalid or missing API key."""


class ForbiddenError(BuzzOffError):
    """403 — API key lacks required scope."""


class NotFoundError(BuzzOffError):
    """404 — Resource not found."""


class ConflictError(BuzzOffError):
    """409 — Resource already exists."""


class ValidationError(BuzzOffError):
    """422 — Invalid request data."""


class RateLimitError(BuzzOffError):
    """429 — Too many requests."""


class ServerError(BuzzOffError):
    """5xx — Server-side error."""
