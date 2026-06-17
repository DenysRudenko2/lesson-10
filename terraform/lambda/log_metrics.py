"""Lambda-крок 2: логування метрик навченої моделі."""
import json


def handler(event, context):
    print("Logging metrics...")
    print(f"Received event: {json.dumps(event)}")

    # Умовні метрики тренування (у реальному пайплайні — з MLflow/артефактів)
    metrics = {"accuracy": 0.95, "loss": 0.12}
    print(f"accuracy={metrics['accuracy']} loss={metrics['loss']}")

    result = {
        "statusCode": 200,
        "source": event.get("source", "unknown"),
        "commit": event.get("commit", "n/a"),
        "metrics": metrics,
        "message": "Metrics logged successfully",
    }
    print(f"Log result: {json.dumps(result)}")
    return result
