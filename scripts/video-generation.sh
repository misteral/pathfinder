#!/bin/bash

# Azure Sora Video Generation Script
# Usage: ./video-generation.sh "your prompt here" [output_filename] [duration_seconds]

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

# Check if prompt is provided
if [ -z "$1" ]; then
    echo "Error: No prompt provided"
    echo "Usage: $0 \"your prompt here\" [output_filename] [duration_seconds]"
    echo "Example: $0 \"A cat playing with a ball\" cat_video.mp4 5"
    echo "Duration: 5-15 seconds (default: 5)"
    exit 1
fi

# Set variables
PROMPT="$1"
ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/jobs?api-version=preview"

# Set output filename (use timestamp if not provided)
if [ -z "$2" ]; then
    OUTPUT_FILE="sora_$(date +%Y%m%d_%H%M%S).mp4"
else
    OUTPUT_FILE="$2"
fi

# Set duration (default to 5 seconds if not provided)
DURATION="${3:-5}"

# Validate duration (must be between 5 and 15 seconds)
if [ "$DURATION" -lt 5 ] || [ "$DURATION" -gt 15 ]; then
    echo "Error: Duration must be between 5 and 15 seconds"
    exit 1
fi

echo "Generating video with prompt: \"$PROMPT\""
echo "Duration: $DURATION seconds"
echo "Output will be saved to: $OUTPUT_FILE"

# Make API request to start video generation job
RESPONSE=$(curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Api-key: $AZURE_API_KEY" \
  -d "{
     \"model\": \"sora\",
     \"prompt\": \"$PROMPT\",
     \"height\": \"1080\",
     \"width\": \"1080\",
     \"n_seconds\": \"$DURATION\",
     \"n_variants\": \"1\"
    }")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Azure API"
    exit 1
fi

# Extract job ID from response
JOB_ID=$(echo "$RESPONSE" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Check if we got a job ID
if [ -z "$JOB_ID" ]; then
    echo "Error: Failed to start video generation job"
    echo "Response from API:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

echo "Video generation job started successfully!"
echo "Job ID: $JOB_ID"
echo ""
echo "You can check the status manually using:"
echo "./scripts/check-video-status.sh $JOB_ID"
echo ""

# Check job status endpoint
STATUS_ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/jobs/$JOB_ID?api-version=preview"

echo "Checking job status..."

# Poll for job completion
MAX_ATTEMPTS=60  # Maximum wait time: 5 minutes (60 * 5 seconds)
ATTEMPT=0
STATUS="pending"

while [ "$STATUS" != "completed" ] && [ "$STATUS" != "succeeded" ] && [ "$STATUS" != "failed" ] && [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    sleep 5  # Wait 5 seconds between checks
    
    # Check job status
    STATUS_RESPONSE=$(curl -s -X GET "$STATUS_ENDPOINT" \
      -H "Api-key: $AZURE_API_KEY")
    
    # Extract status from response
    STATUS=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    
    if [ -z "$STATUS" ]; then
        echo "Warning: Could not extract status from response"
        echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    else
        echo -ne "\rStatus: $STATUS (Attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS)"
    fi
    
    ((ATTEMPT++))
done

echo # New line after status updates

# Check final status
if [ "$STATUS" = "completed" ] || [ "$STATUS" = "succeeded" ]; then
    echo "Video generation completed!"
    
    # Extract generation ID from the status response
    GENERATION_ID=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"generations"[[:space:]]*:.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    
    if [ -z "$GENERATION_ID" ]; then
        echo "Error: Could not extract generation ID"
        echo "Response:"
        echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
        exit 1
    fi
    
    # Construct video download URL using generation ID
    VIDEO_URL="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/${GENERATION_ID}/content/video?api-version=preview"
    
    echo "Downloading video from: $VIDEO_URL"
    
    # Download the video
    curl -s "$VIDEO_URL" -H "Api-key: $AZURE_API_KEY" -o "$OUTPUT_FILE"
    
    if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
        echo "Video saved successfully to: $OUTPUT_FILE"
        
        # Get file size
        FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
        echo "File size: $FILE_SIZE"
        
        # Get video duration using ffprobe if available
        if command -v ffprobe &> /dev/null; then
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE" 2>/dev/null)
            if [ -n "$DURATION" ]; then
                echo "Video duration: ${DURATION}s"
            fi
        fi
    else
        echo "Error: Failed to download video"
        exit 1
    fi
    
elif [ "$STATUS" = "failed" ]; then
    echo "Error: Video generation failed"
    echo "Response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    exit 1
else
    echo "Error: Video generation timed out after $((MAX_ATTEMPTS * 5)) seconds"
    echo "Last status: $STATUS"
    echo "You can check the job status manually with job ID: $JOB_ID"
    exit 1
fi