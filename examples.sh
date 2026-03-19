#!/bin/bash
#
# examples.sh — Low-level llama.cpp examples for LFM2-Audio-1.5B
#
# Prerequisites:
#   - The LFM2-Audio-1.5B-GGUF model folder must exist in the current directory.
#     Download it from HuggingFace: https://huggingface.co/LiquidAI/LFM2-Audio-1.5B-GGUF
#   - Audio samples must exist under ./audio-samples/.
#     Run `uv run download_audio_samples.py` to fetch them.
#
# Supported platforms: ubuntu-x64, ubuntu-arm64, macos-arm64, android-arm64
#
# Usage:
#   bash examples.sh
#
# Examples covered:
#   1. ASR  — transcribe an audio file to text (output printed to console)
#   2. TTS  — synthesize speech from text (output saved to OUTPUT_WAV)
#   3. TTS with voice instructions — same as TTS but with a custom speaker style

# Function to auto-detect platform and architecture
get_platform_and_architecture() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    # Normalize OS name
    case "$OS" in
        darwin) PLATFORM_OS="macos" ;;
        linux) PLATFORM_OS="ubuntu" ;;
        *) PLATFORM_OS="$OS" ;;
    esac

    # Normalize architecture
    case "$ARCH" in
        x86_64|amd64) PLATFORM_ARCH="x64" ;;
        aarch64|arm64) PLATFORM_ARCH="arm64" ;;
        arm*) PLATFORM_ARCH="arm64" ;;
        *) PLATFORM_ARCH="$ARCH" ;;
    esac

    echo "${PLATFORM_OS}-${PLATFORM_ARCH}"
}

# Save current directory
CURRENT_DIR=$(pwd)

export PLATFORM=$(get_platform_and_architecture)

# Change to the directory containing llama-lfm2-audio
cd "$CURRENT_DIR/LFM2-Audio-1.5B-GGUF/runners/$PLATFORM/lfm2-audio-$PLATFORM"

# Path to the llama-lfm2-audio binary for this platform
export LLAMA_CPP_BINARY="$CURRENT_DIR/LFM2-Audio-1.5B-GGUF/runners/$PLATFORM/lfm2-audio-$PLATFORM/llama-lfm2-audio"
# Root folder of the downloaded GGUF model weights
export CKPT="$CURRENT_DIR/LFM2-Audio-1.5B-GGUF"
# Input audio file for ASR
export INPUT_WAV="$CURRENT_DIR/audio-samples/barackobamafederalplaza.mp3"
# Output file where TTS audio will be written
export OUTPUT_WAV="$CURRENT_DIR/audio-samples/output.mp3"

# -----------------------------------------------------------------------------
# Example 1: Audio-to-Text (ASR)
# Transcribes INPUT_WAV and prints the text to the console.
#
# Flag reference:
#   -m        Main language model weights (GGUF format)
#   --mmproj  Audio encoder multimodal projector — converts audio features
#             into the token space the language model understands
#   -mv       Audio decoder weights — required even for ASR so the model
#             can interpret audio tokens
#   -sys      System prompt that controls the task ("Perform ASR.")
#   --audio   Path to the input audio file
# -----------------------------------------------------------------------------
./llama-lfm2-audio \
    -m $CKPT/LFM2-Audio-1.5B-Q8_0.gguf \
    --mmproj $CKPT/mmproj-audioencoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -mv $CKPT/audiodecoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -sys "Perform ASR." \
    --audio $INPUT_WAV

# -----------------------------------------------------------------------------
# Example 2: Text-to-Speech (TTS)
# Synthesizes the text given with -p and saves the audio to OUTPUT_WAV.
#
# Flag reference:
#   -sys      System prompt set to "Perform TTS." to switch the model to
#             speech synthesis mode
#   -p        The text prompt to be spoken
#   --output  Path where the generated audio file will be saved
# -----------------------------------------------------------------------------
./llama-lfm2-audio \
    -m $CKPT/LFM2-Audio-1.5B-Q8_0.gguf \
    --mmproj $CKPT/mmproj-audioencoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -mv $CKPT/audiodecoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -sys "Perform TTS." \
    -p "My name is Pau Labarta Bajo and I love AI" \
    --output $OUTPUT_WAV

# -----------------------------------------------------------------------------
# Example 3: Text-to-Speech with custom voice style
# Same as Example 2, but the system prompt includes a natural-language
# description of the desired speaker style. The model uses this description
# to shape the prosody, pitch, and tone of the generated audio.
# -----------------------------------------------------------------------------
./llama-lfm2-audio \
    -m $CKPT/LFM2-Audio-1.5B-Q8_0.gguf \
    --mmproj $CKPT/mmproj-audioencoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -mv $CKPT/audiodecoder-LFM2-Audio-1.5B-Q8_0.gguf \
    -sys "Perform TTS.
Use the following voice: A male speaker delivers a very expressive and animated speech, with a low-pitch voice and a slightly close-sounding tone. The recording carries a slight background noise." \
    -p "What is your name man?" \
    --output $OUTPUT_WAV

# Return to original directory
cd "$CURRENT_DIR"