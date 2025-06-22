#!/bin/bash

# Azure Sora Video Download Script
# Usage: ./download-video.sh <job_id> [output_filename]

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
    echo "Usage: $0 <job_id> [output_filename]"
    echo "Example: $0 abc123def456"
    echo "Example: $0 abc123def456 my_video.mp4"
    exit 1
fi

JOB_ID="$1"

# Set output filename (use job ID if not provided)
if [ -z "$2" ]; then
    OUTPUT_FILE="video_${JOB_ID}.mp4"
else
    OUTPUT_FILE="$2"
fi

# Status check endpoint
STATUS_ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/jobs/$JOB_ID?api-version=preview"

echo "Checking job status for ID: $JOB_ID"

# Check job status
STATUS_RESPONSE=$(curl -s -X GET "$STATUS_ENDPOINT" \
  -H "Api-key: $AZURE_API_KEY")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Azure API"
    exit 1
fi

# Extract status
STATUS=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$STATUS" ]; then
    echo "Error: Could not retrieve job status"
    echo "Response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    exit 1
fi

echo "Job status: $STATUS"

# Check if job is completed
if [ "$STATUS" != "completed" ] && [ "$STATUS" != "succeeded" ]; then
    if [ "$STATUS" = "failed" ]; then
        echo "Error: Video generation job failed"
        ERROR=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"error"[[:space:]]*:.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
        if [ -n "$ERROR" ]; then
            echo "Error message: $ERROR"
        fi
    else
        echo "Error: Video is not ready yet (status: $STATUS)"
        echo "Please wait for the job to complete before downloading"
    fi
    exit 1
fi

# Extract generation ID from the response
GENERATION_ID=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"generations"[[:space:]]*:.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$GENERATION_ID" ]; then
    echo "Error: Could not extract generation ID from response"
    echo "Response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
    exit 1
fi

echo "Generation ID: $GENERATION_ID"

# Construct video download URL using generation ID
VIDEO_URL="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/${GENERATION_ID}/content/video?api-version=preview"

# Extract video information
PROMPT=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
DURATION=$(echo "$STATUS_RESPONSE" | sed -n 's/.*"n_seconds"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)

echo ""
echo "Video details:"
echo "Prompt: ${PROMPT:-Unknown}"
echo "Duration: ${DURATION:-Unknown} seconds"
echo "Output file: $OUTPUT_FILE"

echo ""
echo "Downloading video..."

# Download the video with progress bar
curl -# "$VIDEO_URL" -H "Api-key: $AZURE_API_KEY" -o "$OUTPUT_FILE"

if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo "Video downloaded successfully to: $OUTPUT_FILE"
    
    # Get file size
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "File size: $FILE_SIZE"
    
    # Get video information using ffprobe if available
    if command -v ffprobe &> /dev/null; then
        echo ""
        echo "Video information:"
        
        # Get duration
        ACTUAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE" 2>/dev/null)
        if [ -n "$ACTUAL_DURATION" ]; then
            echo "Duration: ${ACTUAL_DURATION}s"
        fi
        
        # Get resolution
        RESOLUTION=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUTPUT_FILE" 2>/dev/null)
        if [ -n "$RESOLUTION" ]; then
            echo "Resolution: $RESOLUTION"
        fi
        
        # Get codec
        CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE" 2>/dev/null)
        if [ -n "$CODEC" ]; then
            echo "Codec: $CODEC"
        fi
    fi
else
    echo ""
    echo "Error: Failed to download video"
    exit 1
fi