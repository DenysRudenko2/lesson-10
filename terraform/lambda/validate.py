"""Lambda-крок 1: валідація вхідних даних перед тренуванням."""
import json


def handler(event, context):
    print("Validating data...")
    print(f"Received event: {json.dumps(event)}")

    # Умовна валідація: вважаємо дані валідними, якщо вказано джерело запуску
    source = event.get("source", "unknown")
    is_valid = bool(source) and source != "unknown"

    result = {
        "statusCode": 200,
        "valid": is_valid,
        "source": source,
        "commit": event.get("commit", "n/a"),
        "message": "Data validated successfully" if is_valid else "Validation failed",
    }
    print(f"Validation result: {json.dumps(result)}")
    return result
