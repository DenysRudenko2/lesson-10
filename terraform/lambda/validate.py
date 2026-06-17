"""Lambda-крок 1: валідація вхідного датасету перед тренуванням."""
import json
from datetime import datetime, timezone


def handler(event, context):
    print("=== ValidateData ===")
    print(f"Input: {json.dumps(event)}")

    rows = int(event.get("rows", 1000))
    # умовна перевірка якості даних
    invalid_rows = rows // 500
    valid_ratio = round(1 - invalid_rows / rows, 4) if rows else 0.0
    status = "ok" if valid_ratio >= 0.9 else "warn"

    validate = {
        "step": "validate",
        "status": status,
        "rows_checked": rows,
        "invalid_rows": invalid_rows,
        "valid_ratio": valid_ratio,
        "source": event.get("source", "unknown"),
        "commit": event.get("commit", "n/a"),
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }
    print(f"Validation result: {json.dumps(validate)}")

    # передаємо оригінальний вхід далі + додаємо звіт валідації
    return {**event, "validate": validate}
