#!/bin/bash
cd "$(dirname "$0")"
echo "Iniciando o sistema da recepção em http://localhost:8000"
( sleep 1 && open "http://localhost:8000" 2>/dev/null || xdg-open "http://localhost:8000" 2>/dev/null ) &
python3 -m http.server 8000
