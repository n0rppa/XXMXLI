#!/usr/bin/env python
import os
import sys
import http.server
import socketserver
from http import HTTPStatus
import mimetypes
import re
import codecs

# Ensure proper MIME types are registered
mimetypes.add_type('text/html', '.html', strict=True)
mimetypes.add_type('text/javascript', '.js', strict=True)
mimetypes.add_type('text/css', '.css', strict=True)
mimetypes.add_type('application/json', '.json', strict=True)
mimetypes.add_type('audio/flac', '.flac', strict=True)

# Add CORS headers for audio files
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
}

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP request handler with MIME type fixes."""
    
    def __init__(self, *args, **kwargs):
        # Set the directory to serve files from
        directory = os.path.abspath(os.getcwd())
        super().__init__(*args, directory=directory, **kwargs)
    
    def guess_type(self, path):
        """
        Override the guess_type method to ensure HTML files
        are always served with text/html MIME type.
        """
        base, ext = os.path.splitext(path)
        
        # Explicitly set MIME types for certain extensions
        if ext in ('.html', '.htm'):
            return 'text/html'
        elif ext == '.js':
            return 'text/javascript'
        elif ext == '.css':
            return 'text/css'
        elif ext == '.json':
            return 'application/json'
        elif ext == '.flac':
            return 'audio/flac'
        
        # For other files, use the parent class method
        return super().guess_type(path)
    
    def end_headers(self):
        """Add extra headers to all responses."""
        # Add CORS headers to allow cross-origin requests
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        # Ensure proper caching behavior
        self.send_header('Cache-Control', 'no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        
        # Add security headers to all responses
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'SAMEORIGIN')
        self.send_header('Referrer-Policy', 'strict-origin-when-cross-origin')
        
        # Call the parent's end_headers method
        super().end_headers()
    
    def do_GET(self):
        full_path = self.translate_path(self.path)
        if os.path.isdir(full_path):
            index_path = os.path.join(full_path, 'index.html')
            if os.path.exists(index_path):
                self.path = self.path.rstrip('/') + '/index.html'
            else:
                self.send_error(404, 'Directory index not found')
                return
        return super().do_GET()

def run_server(port=8080, bind="0.0.0.0"):
    """Run the HTTP server."""
    handler = CustomHTTPRequestHandler
    
    # Set up a TCP server
    with socketserver.TCPServer((bind, port), handler) as httpd:
        print(f"Serving HTTP on {bind} port {port} (http://{bind}:{port}/) ...")
        print(f"Current directory: {os.getcwd()}")
        
        try:
            # Start the server
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nKeyboard interrupt received, exiting.")
            httpd.server_close()
            sys.exit(0)

if __name__ == "__main__":
    # Run the server on port 8080
    run_server(port=8080)
