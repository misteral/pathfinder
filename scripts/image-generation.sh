#!/bin/bash

# Azure DALL-E 3 Image Generator Script
# Usage: ./generate_image.sh "your prompt here" [output_filename]

# Load environment variables from .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "Loaded environment variables from .env file"
else
    echo "Warning: .env file not found at $ENV_FILE"
fi

# Check if API key is set
if [ -z "$AZURE_SW_API_KEY" ]; then
    echo "Error: AZURE_SW_API_KEY environment variable is not set"
    echo "Please set it using: export AZURE_SW_API_KEY='your-api-key'"
    exit 1
fi

# Check if prompt is provided
if [ -z "$1" ]; then
    echo "Error: No prompt provided"
    echo "Usage: $0 \"your prompt here\" [output_filename]"
    echo "Example: $0 \"A red fox in autumn forest\" fox_image.png"
    exit 1
fi

# Set variables
PROMPT="$1"
ENDPOINT="https://albo-mc6nuw1p-swedencentral.openai.azure.com/openai/deployments/dall-e-3/images/generations?api-version=2024-02-01"

# Set output filename (use timestamp if not provided)
if [ -z "$2" ]; then
    OUTPUT_FILE="dalle3_$(date +%Y%m%d_%H%M%S).png"
else
    OUTPUT_FILE="$2"
fi

echo "Generating image with prompt: \"$PROMPT\""
echo "Output will be saved to: $OUTPUT_FILE"

# Make API request and store response
RESPONSE=$(curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AZURE_SW_API_KEY" \
  -d "{
     \"model\": \"dall-e-3\",
     \"prompt\": \"$PROMPT\",
     \"size\": \"1024x1024\",
     \"style\": \"vivid\",
     \"quality\": \"standard\",
     \"n\": 1
    }")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Azure API"
    exit 1
fi

# Extract image URL from response (macOS compatible)
IMAGE_URL=$(echo "$RESPONSE" | sed -n 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Check if we got an image URL
if [ -z "$IMAGE_URL" ]; then
    echo "Error: Failed to generate image or extract URL from response"
    echo "Response from API:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

echo "Image generated successfully!"
echo "Downloading image from: $IMAGE_URL"

# Download the image
curl -s "$IMAGE_URL" -o "$OUTPUT_FILE"

if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo "Image saved successfully to: $OUTPUT_FILE"
    
    # Get file size
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "File size: $FILE_SIZE"
else
    echo "Error: Failed to download image"
    exit 1
fi