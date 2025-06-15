#!/bin/bash
# Trains the fine-tuned embedding model

python3 coldrag/scripts/train_model.py --bootstrap_path coldrag/models/bootstrap_pairs_200_final.py
