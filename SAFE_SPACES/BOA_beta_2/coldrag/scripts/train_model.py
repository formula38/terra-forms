#!/usr/bin/env python3
"""Fine-tune SentenceTransformer model for compliance context embedding."""

import os
from pathlib import Path
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer, InputExample, losses
from torch.utils.data import DataLoader

# Load environment variables
load_dotenv()

# --- Configurable Paths ---
MODEL_NAME = os.getenv("MODEL_NAME", "sentence-transformers/all-mpnet-base-v2")
MODEL_OUTPUT_DIR = Path(os.getenv("MODEL_OUTPUT_DIR", "./coldrag/scripts/models/mpnet-finetuned"))
RETRAIN_MODEL = os.getenv("RETRAIN_MODEL", "false").lower() == "true"

# Load training pairs
try:
    from training_pairs import compliance_pairs
except ImportError as e:
    print("❌ Could not import training pairs. Ensure 'training_pairs.py' defines 'compliance_pairs'.")
    raise e

# Check if training is necessary
model_config_path = MODEL_OUTPUT_DIR / "config.json"
if model_config_path.exists() and not RETRAIN_MODEL:
    print(f"✅ Fine-tuned model already exists at {MODEL_OUTPUT_DIR}. Skipping training.")
else:
    print("📦 Fine-tuned model not found or retraining forced. Starting training...")

    training_examples = [
        InputExample(texts=[q, a], label=1.0)
        for q, a in compliance_pairs
    ]
    train_dataloader = DataLoader(training_examples, shuffle=True, batch_size=4)

    # Load base model + training loss
    model = SentenceTransformer(MODEL_NAME)
    train_loss = losses.MultipleNegativesRankingLoss(model)

    # Train model
    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        epochs=1,
        warmup_steps=10,
        show_progress_bar=True
    )

    # Save trained model
    MODEL_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    model.save(str(MODEL_OUTPUT_DIR))
    print(f"✅ Fine-tuned model saved to {MODEL_OUTPUT_DIR}")
