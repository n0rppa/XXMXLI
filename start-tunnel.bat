@echo off
cd /d "%~dp0"
echo Starting Cloudflare Tunnel...
cloudflared tunnel run
pause
