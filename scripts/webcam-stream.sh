#!/bin/bash
# Script to route webcam stream from Janus to virtual video device

set -e

# Configuration
INPUT_DEVICE="/dev/video0"  # Default webcam device
OUTPUT_DEVICE="/dev/video10"  # Virtual video device
WIDTH=1920
HEIGHT=1200
FPS=30
INPUT_FORMAT="uyvy422"
OUTPUT_FORMAT="yuyv422"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to check if a device exists
device_exists() {
    [ -e "$1" ]
}

# Function to check if FFmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "FFmpeg is not installed. Please install FFmpeg first." >&2
        exit 1
    fi
}

# Function to start the stream
start_stream() {
    echo "Starting webcam stream from $INPUT_DEVICE to $OUTPUT_DEVICE..."
    
    # Check if input device exists
    if ! device_exists "$INPUT_DEVICE"; then
        echo "Input device $INPUT_DEVICE not found" >&2
        exit 1
    fi
    
    # Check if output device exists
    if ! device_exists "$OUTPUT_DEVICE"; then
        echo "Output device $OUTPUT_DEVICE not found. Make sure v4l2loopback is loaded." >&2
        exit 1
    fi
    
    # Load v4l2loopback with explicit format support if not already loaded
    if ! lsmod | grep -q v4l2loopback; then
        modprobe v4l2loopback video_nr=10 card_label="PiKVM UVC" exclusive_caps=1 max_buffers=2
        sleep 1
    fi

    # Set the output format on the v4l2loopback device
    v4l2-ctl -d "$OUTPUT_DEVICE" --set-fmt-video=width=1920,height=1200,pixelformat=YUYV
    
    # Start FFmpeg with explicit format conversion
    ffmpeg -hide_banner -loglevel error -f v4l2 -input_format uyvy422 -video_size 1920x1200 -framerate 30 -i "$INPUT_DEVICE" \
           -f v4l2 -codec:v rawvideo -pix_fmt yuyv422 -s 1920x1200 -r 30 -vf "hflip,vflip" "$OUTPUT_DEVICE" &
    
    echo $! > /var/run/kvmd-webcam-stream.pid
    echo "Webcam stream started (PID: $(cat /var/run/kvmd-webcam-stream.pid))"
}

# Function to stop the stream
stop_stream() {
    if [ -f /var/run/kvmd-webcam-stream.pid ]; then
        echo "Stopping webcam stream..."
        kill -TERM "$(cat /var/run/kvmd-webcam-stream.pid)" 2>/dev/null || true
        rm -f /var/run/kvmd-webcam-stream.pid
        echo "Webcam stream stopped"
    else
        echo "No running webcam stream found"
    fi
}

# Function to check status
status() {
    if [ -f /var/run/kvmd-webcam-stream.pid ]; then
        PID=$(cat /var/run/kvmd-webcam-stream.pid)
        if ps -p "$PID" > /dev/null; then
            echo "Webcam stream is running (PID: $PID)"
            return 0
        else
            echo "Webcam stream PID file exists but process is not running"
            return 1
        fi
    else
        echo "Webcam stream is not running"
        return 1
    fi
}

# Main function
main() {
    check_ffmpeg
    
    case "$1" in
        start)
            start_stream
            ;;
        stop)
            stop_stream
            ;;
        restart)
            stop_stream
            sleep 1
            start_stream
            ;;
        status)
            status
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status}"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"
