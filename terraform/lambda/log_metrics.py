"""Lambda-крок 2: обчислення та логування метрик навченої моделі."""
import json
from datetime import datetime, timezone


def handler(event, context):
    print("=== LogMetrics ===")
    print(f"Input: {json.dumps(event)}")

    epochs = int(event.get("epochs", 100))
    learning_rate = float(event.get("learning_rate", 0.01))

    # умовні метрики, що залежать від гіперпараметрів
    accuracy = round(min(0.99, 0.80 + epochs / 1000 + learning_rate), 4)
    loss = round(max(0.05, 0.50 - epochs / 1000 - learning_rate), 4)

    metrics = {
        "step": "log_metrics",
        "accuracy": accuracy,
        "loss": loss,
        "f1": round(accuracy - 0.01, 4),
        "epochs": epochs,
        "learning_rate": learning_rate,
        "logged_at": datetime.now(timezone.utc).isoformat(),
    }
    print(f"Metrics: {json.dumps(metrics)}")

    return {
        "status": "succeeded",
        "source": event.get("source", "unknown"),
        "commit": event.get("commit", "n/a"),
        "validate": event.get("validate"),
        "metrics": metrics,
    }
