#!/bin/bash

# Azure Sora Video Generation Jobs Lister
# Usage: ./list-video-jobs.sh

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

# List jobs endpoint
LIST_ENDPOINT="https://ai-albobrovmail5452ai096230973777.openai.azure.com/openai/v1/video/generations/jobs?api-version=preview"

echo "Fetching video generation jobs..."
echo ""

# Get list of jobs
RESPONSE=$(curl -s -X GET "$LIST_ENDPOINT" \
  -H "Api-key: $AZURE_API_KEY")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Azure API"
    exit 1
fi

# Check if jq is available for pretty printing
if command -v jq &> /dev/null; then
    # Use jq to parse and format the jobs
    echo "$RESPONSE" | jq -r '.data[]? | 
        "=================================\n" +
        "Job ID: " + .id + "\n" +
        "Status: " + .status + "\n" +
        "Created: " + (.created_at | todate) + "\n" +
        "Prompt: " + .prompt + "\n" +
        "Duration: " + (.n_seconds | tostring) + " seconds\n" +
        if .status == "completed" and .output.url then
            "Video URL: " + .output.url + "\n"
        else "" end'
    
    # Show total count
    TOTAL=$(echo "$RESPONSE" | jq '.data | length')
    echo "================================="
    echo "Total jobs: $TOTAL"
else
    # Fallback without jq - basic parsing
    echo "$RESPONSE" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | while read -r line; do
        JOB_ID=$(echo "$line" | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        echo "Job ID: $JOB_ID"
        echo "Run './scripts/check-video-status.sh $JOB_ID' for details"
        echo "---"
    done
fi