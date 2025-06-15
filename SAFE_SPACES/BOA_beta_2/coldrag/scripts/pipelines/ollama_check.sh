#!/bin/bash
# Ensures Ollama and model availability

if ! command -v ollama &> /dev/null; then
  echo "Ollama not installed."
  exit 1
fi

if ! ollama list | grep -q mistral; then
  echo "Pulling mistral model..."
  ollama pull mistral
fi
