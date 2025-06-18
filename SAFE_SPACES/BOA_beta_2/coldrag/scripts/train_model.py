import os
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer, InputExample, losses
from torch.utils.data import DataLoader
from training_pairs import compliance_pairs

load_dotenv()

MODEL_NAME = os.getenv("MODEL_NAME", "sentence-transformers/all-mpnet-base-v2")
MODEL_OUTPUT_DIR = os.getenv("MODEL_OUTPUT_DIR", "./scripts/models/mpnet-finetuned")

training_examples = [InputExample(texts=[q, a], label=1.0) for q, a in compliance_pairs]
train_dataloader = DataLoader(training_examples, shuffle=True, batch_size=4)
train_loss = losses.MultipleNegativesRankingLoss(SentenceTransformer(MODEL_NAME))

model = SentenceTransformer(MODEL_NAME)
model.fit(train_objectives=[(train_dataloader, train_loss)], epochs=1, warmup_steps=10, show_progress_bar=True)
model.save(MODEL_OUTPUT_DIR)
