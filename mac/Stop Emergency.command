#!/bin/bash
# Double-click: stops the question page, the library and the AI (saves battery).
pkill -f "Emergency/chat_server.py" && echo "Question page stopped."
pkill -f "Emergency/ask.py"         # old-style question windows, if any are still open
pkill -f "kiwix-serve --address=127.0.0.1 --port=8080" && echo "Library stopped."
pkill -f "ollama serve" && echo "AI stopped."
echo "Done. You can close this window."
