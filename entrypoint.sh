#!/bin/bash

set -e

CUDA_ENABLED=${CUDA_ENABLED:-true}
DEVICE=""

if [ "${CUDA_ENABLED}" != "true" ]; then
    DEVICE="--device cpu"
fi

# Download the Fish Speech model if not already present.
if [ ! -d "checkpoints/fish-speech-1.5" ]; then
    mkdir -p checkpoints
    echo "Downloading Fish Speech model..."
    huggingface-cli download fishaudio/fish-speech-1.5 --local-dir checkpoints/fish-speech-1.5
fi

# (Optional) Create a test sound directory if needed:
# mkdir -p references/test
# cp /path/to/your/audio/file.wav references/test/
# echo "Corresponding transcription" > references/test/file.lab

# Start the API service
echo "Starting Fish Speech API service..."
python -m tools.api_server \
    --listen 0.0.0.0:8080 \
    --llama-checkpoint-path "checkpoints/fish-speech-1.5" \
    --decoder-checkpoint-path "checkpoints/fish-speech-1.5/firefly-gan-vq-fsq-8x1024-21hz-generator.pth" \
    --decoder-config-name firefly_gan_vq \
    --compile \
    --half ${DEVICE}

