from sentence_transformers import SentenceTransformer, InputExample, losses
from torch.utils.data import DataLoader
from training_pairs import compliance_pairs

# Convert to SentenceTransformers format
training_examples = [InputExample(texts=[q, a], label=1.0) for q, a in compliance_pairs]

# Load the base embedding model
model = SentenceTransformer("sentence-transformers/all-mpnet-base-v2")

# Prepare training loop
train_dataloader = DataLoader(
    training_examples, 
    shuffle=True, 
    batch_size=4
    )
train_loss = losses.MultipleNegativesRankingLoss(model)

# Fine-tune
model.fit(
    train_objectives=[(train_dataloader, train_loss)],
    epochs=1,
    warmup_steps=10,
    show_progress_bar=True
)

# Save to a directory
model.save("./scripts/models/mpnet-finetuned")
