#!/bin/bash

# Azure TTS CLI Script
# Usage: ./azure-tts.sh "Your text here" "output_filename.mp3"

# Load environment variables from .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "Loaded environment variables from .env file"
else
    echo "Warning: .env file not found at $ENV_FILE"
fi

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 \"text to convert\" \"output_filename.mp3\" [voice]"
    echo "Available voices: alloy, echo, fable, onyx, nova, shimmer"
    echo "Example: $0 \"Hello world\" \"hello.mp3\" \"alloy\""
    exit 1
fi

# Check if AZURE_API_KEY is set
if [ -z "$AZURE_API_KEY" ]; then
    echo "Error: AZURE_API_KEY environment variable is not set"
    echo "Please set it using: export AZURE_API_KEY='your-api-key-here'"
    exit 1
fi

# Assign arguments to variables
TEXT="$1"
OUTPUT_FILE="$2"
VOICE="${3:-alloy}"  # Default to "alloy" if not specified

# Azure endpoint
ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/deployments/gpt-4o-mini-tts/audio/speech?api-version=2025-03-01-preview"

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "model": "gpt-4o-mini-tts",
  "input": "$TEXT",
  "voice": "$VOICE"
}
EOF
)

# Display what we're doing
echo "Converting text to speech..."
echo "Text: $TEXT"
echo "Voice: $VOICE"
echo "Output: $OUTPUT_FILE"

# Make the API call
HTTP_STATUS=$(curl -s -w "%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "api-key: $AZURE_API_KEY" \
  -o "$OUTPUT_FILE" \
  -d "$JSON_PAYLOAD")

# Check if the request was successful
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Success! Audio saved to: $OUTPUT_FILE"
    
    # Check file size to ensure content was saved
    if [ -s "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
        echo "File size: $FILE_SIZE"
    else
        echo "Warning: Output file is empty"
        exit 1
    fi
else
    echo "Error: HTTP status code $HTTP_STATUS"
    echo "Response saved in: $OUTPUT_FILE"
    
    # Display error message if available
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Error details:"
        cat "$OUTPUT_FILE"
        rm "$OUTPUT_FILE"  # Remove the error file
    fi
    exit 1
fi