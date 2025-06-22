#!/bin/bash

# Interactive Video Manager for Azure Sora
# Usage: ./manage-videos.sh

# Load environment variables from .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Warning: .env file not found at $ENV_FILE"
fi

# Check if API key is set
if [ -z "$AZURE_API_KEY" ]; then
    echo "Error: AZURE_API_KEY environment variable is not set"
    echo "Please set it using: export AZURE_API_KEY='your-api-key'"
    exit 1
fi

clear
echo "==================================="
echo "   Azure Sora Video Manager"
echo "==================================="
echo ""

while true; do
    echo "What would you like to do?"
    echo "1. Generate a new video"
    echo "2. List all video jobs"
    echo "3. Check status of a job"
    echo "4. Download a completed video"
    echo "5. Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            echo ""
            read -p "Enter your video prompt: " prompt
            read -p "Enter output filename (or press Enter for auto): " filename
            read -p "Enter duration in seconds (5-15, default 5): " duration
            duration=${duration:-5}
            
            echo ""
            if [ -z "$filename" ]; then
                "$SCRIPT_DIR/video-generation.sh" "$prompt" "" "$duration"
            else
                "$SCRIPT_DIR/video-generation.sh" "$prompt" "$filename" "$duration"
            fi
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
            
        2)
            echo ""
            "$SCRIPT_DIR/list-video-jobs.sh"
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
            
        3)
            echo ""
            read -p "Enter job ID: " job_id
            echo ""
            "$SCRIPT_DIR/check-video-status.sh" "$job_id"
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
            
        4)
            echo ""
            read -p "Enter job ID to download: " job_id
            read -p "Enter output filename (or press Enter for auto): " filename
            echo ""
            if [ -z "$filename" ]; then
                "$SCRIPT_DIR/download-video.sh" "$job_id"
            else
                "$SCRIPT_DIR/download-video.sh" "$job_id" "$filename"
            fi
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
            
        5)
            echo ""
            echo "Goodbye!"
            exit 0
            ;;
            
        *)
            echo ""
            echo "Invalid choice. Please try again."
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
    esac
done