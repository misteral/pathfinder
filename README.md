# Pathfinder Scripts

This project contains utility scripts for AI-powered content generation.

## Setup

1. Copy the environment template file:
   ```bash
   cp .env.template .env
   ```

2. Edit the `.env` file and add your actual API keys:
   ```bash
   # Azure API key for Speech/TTS services
   AZURE_API_KEY=your_actual_azure_api_key_here
   
   # Azure API key for DALL-E 3 image generation
   AZURE_SW_API_KEY=your_actual_azure_sw_api_key_here
   ```

## Available Scripts

### Image Generation (`scripts/image-generation.sh`)

Generates images using Azure DALL-E 3.

**Usage:**
```bash
./scripts/image-generation.sh "your prompt here" [output_filename]
```

**Examples:**
```bash
# Generate with auto-named file
./scripts/image-generation.sh "A red fox in autumn forest"

# Generate with custom filename
./scripts/image-generation.sh "A red fox in autumn forest" fox_image.png
```

### Text-to-Speech (`scripts/tts.sh`)

Converts text to speech using Azure TTS.

**Usage:**
```bash
./scripts/tts.sh "text to convert" "output_filename.mp3" [voice]
```

**Available voices:** alloy, echo, fable, onyx, nova, shimmer (default: alloy)

**Examples:**
```bash
# Basic usage
./scripts/tts.sh "Hello world" "hello.mp3"

# With custom voice
./scripts/tts.sh "Hello world" "hello.mp3" "nova"
```

### Video Generation (`scripts/video-generation.sh`)

Generates short videos using Azure Sora.

**Usage:**
```bash
./scripts/video-generation.sh "your prompt here" [output_filename] [duration_seconds]
```

**Parameters:**
- `prompt`: Description of the video you want to generate (required)
- `output_filename`: Name for the output video file (optional, defaults to timestamped filename)
- `duration_seconds`: Video duration in seconds, must be between 5-15 (optional, default: 5)

**Examples:**
```bash
# Generate with auto-named file and default duration
./scripts/video-generation.sh "A cat playing with a ball"

# Generate with custom filename
./scripts/video-generation.sh "A cat playing with a ball" cat_video.mp4

# Generate with custom filename and duration
./scripts/video-generation.sh "A cat playing with a ball" cat_video.mp4 10
```

**Note:** Video generation is an asynchronous process. The script will poll the status until completion (up to 5 minutes).

### Check Video Status (`scripts/check-video-status.sh`)

Checks the status of a video generation job using its job ID.

**Usage:**
```bash
./scripts/check-video-status.sh <job_id>
```

**Example:**
```bash
# Check status of a job
./scripts/check-video-status.sh abc123def456
```

This script is useful for:
- Checking on long-running video generation jobs
- Retrieving download URLs for completed videos
- Debugging failed video generation attempts

### List Video Jobs (`scripts/list-video-jobs.sh`)

Lists all video generation jobs associated with your Azure account.

**Usage:**
```bash
./scripts/list-video-jobs.sh
```

This script displays:
- Job IDs for all video generation requests
- Status of each job (pending, processing, completed, failed)
- Creation timestamps
- Video prompts
- Download URLs for completed videos

### Download Video (`scripts/download-video.sh`)

Downloads a video from a completed generation job.

**Usage:**
```bash
./scripts/download-video.sh <job_id> [output_filename]
```

**Examples:**
```bash
# Download with auto-generated filename (video_<job_id>.mp4)
./scripts/download-video.sh abc123def456

# Download with custom filename
./scripts/download-video.sh abc123def456 my_awesome_video.mp4
```

**Features:**
- Verifies job completion before downloading
- Shows download progress
- Displays video information (size, duration, resolution, codec)
- On macOS, offers to open the video after download
- Provides detailed error messages for failed jobs

### Interactive Video Manager (`scripts/manage-videos.sh`)

An interactive menu-driven interface for managing all video operations.

**Usage:**
```bash
./scripts/manage-videos.sh
```

**Features:**
- Generate new videos with guided prompts
- List all video generation jobs
- Check status of specific jobs
- Download completed videos
- User-friendly menu interface

This is the easiest way to work with the video generation system!

## Notes

- The scripts automatically load environment variables from the `.env` file
- The `.env` file is gitignored for security
- Make sure to keep your API keys secure and never commit them to version control
