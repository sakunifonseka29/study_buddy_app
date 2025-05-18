# Flask Server Setup for StudyBuddy App

This guide explains how to set up and run the Flask server required for AI-powered schedule generation in the StudyBuddy app.

## Requirements

- Python 3.7+ installed on your system
- Flask and other dependencies (installed via pip)

## Starting the Flask Server

### Windows

1. Double-click the `start_server.bat` file in the root directory
2. A command prompt window will open and show the server running
3. Keep this window open while using the StudyBuddy app
4. The server will be available at http://127.0.0.1:5051

### Manual Start (Any Platform)

You can also start the server manually:

```bash
# Navigate to the Py directory
cd "path/to/study_buddy_app/Py"

# Start the server
python app.py
```

## Troubleshooting

If you see "Server unreachable" in the app:

1. Make sure the server is running (command window should be open)
2. Check that the server is running on port 5051
3. Click "Retry" in the app to attempt reconnection
4. If problems persist, restart the server and the app

## API Endpoints

The server provides the following endpoints:

- GET `/` - Health check endpoint
- POST `/generate-schedule` - Generates a study schedule
- GET `/user-schedules/{user_id}` - Retrieves schedules for a specific user

## Automatic Server Startup

To have the server start automatically when you run the app, consider:

1. Creating a shortcut that runs both the server and the app
2. Setting up a service that keeps the server running in the background
