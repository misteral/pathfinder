#!/bin/bash

# Azure Sora Video Generation Status Checker
# Usage: ./check-video-status.sh <job_id>

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
if [ -z "$AZURE_API_KEY" ]; then
    echo "Error: AZURE_API_KEY environment variable is not set"
    echo "Please set it using: export AZURE_API_KEY='your-api-key'"
    exit 1
fi

# Check if job ID is provided
if [ -z "$1" ]; then
    echo "Error: No job ID provided"
    echo "Usage: $0 <job_id>"
    echo "Example: $0 abc123def456"
    exit 1
fi

JOB_ID="$1"

# Status check endpoint
STATUS_ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/jobs/$JOB_ID?api-version=preview"

echo "Checking status for job ID: $JOB_ID"

# Check job status
STATUS_RESPONSE=$(curl -s -X GET "$STATUS_ENDPOINT" \
  -H "Api-key: $AZURE_API_KEY")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Azure API"
    exit 1
fi

# Try to pretty print with jq if available
if command -v jq &> /dev/null; then
    echo "$STATUS_RESPONSE" | jq .
else
    # Fallback to basic formatting
    echo "$STATUS_RESPONSE"
fi

# Extract and display key information
STATUS=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
CREATED_AT=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"created_at"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)
PROMPT=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

echo ""
echo "=== Summary ==="
echo "Status: ${STATUS:-Unknown}"
echo "Prompt: ${PROMPT:-Unknown}"

# Convert timestamp if available
if [ -n "$CREATED_AT" ]; then
    # Convert Unix timestamp to readable date
    if command -v date &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS date command
            READABLE_DATE=$(date -r "$CREATED_AT" 2>/dev/null || echo "Invalid timestamp")
        else
            # Linux date command
            READABLE_DATE=$(date -d "@$CREATED_AT" 2>/dev/null || echo "Invalid timestamp")
        fi
        echo "Created: $READABLE_DATE"
    fi
fi

# If job is completed, show download information
if [ "$STATUS" = "completed" ] || [ "$STATUS" = "succeeded" ]; then
    # Extract generation ID
    GENERATION_ID=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"generations"[[:space:]]*:.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    
    if [ -n "$GENERATION_ID" ]; then
        # Construct the correct download URL using generation ID
        VIDEO_URL="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/${GENERATION_ID}/content/video?api-version=preview"
        
        echo ""
        echo "=== Video Ready ==="
        echo "Generation ID: $GENERATION_ID"
        echo "Download URL: $VIDEO_URL"
        echo ""
        echo "To download the video, run:"
        echo "curl -H \"Api-key: \$AZURE_API_KEY\" -o video_${JOB_ID}.mp4 \"$VIDEO_URL\""
        echo ""
        echo "Or use the download script:"
        echo "./scripts/download-video.sh ${JOB_ID}"
    else
        echo ""
        echo "Warning: Could not extract generation ID from response"
    fi
elif [ "$STATUS" = "failed" ]; then
    ERROR=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"error"[[:space:]]*:.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    if [ -n "$ERROR" ]; then
        echo "Error: $ERROR"
    fi
fi