# Connection Error Resolution

## Issue Identified

The Flutter app was failing to connect to the Flask Python server running on port 5051 with the error:

```
Server unreachable: ClientException with SocketException: Connection refused (OS Error: Connection refused, errno = 111), address = 127.0.0.1, port = 5051
```

## Root Cause

The Flask server that provides AI-powered schedule generation needed to be manually started before using the app. The app was attempting to connect to the server, but it wasn't running.

## Solutions Implemented

### 1. Created Startup Scripts

- Added `start_server.bat` - A Windows batch file for easy server startup
- The server can now be started by double-clicking this file

### 2. Enhanced Error Handling in the App

- Added retry functionality to `RemoteAPIService` to attempt reconnection multiple times
- Updated the connection status widget to use the new retry mechanism
- Improved error messages to guide users on how to start the server

### 3. Documentation

- Created `FLASK_SERVER_SETUP.md` with detailed instructions for running the Flask server
- Added console logging with step-by-step server startup instructions when connection fails

## How to Use

1. Start the Flask server by running `start_server.bat` before launching the app
2. Keep the server terminal window open while using the app
3. If you see connection errors in the app, click "Retry" to attempt reconnection
4. Alternatively, the app will fall back to local Python script execution when the server is unavailable

## Technical Notes

- The Flask server runs on `127.0.0.1:5051`
- The server provides AI-powered schedule generation through OpenAI GPT
- When the server is unavailable, the app will still function but with limited AI capabilities
