#!/usr/bin/env python3
"""Serve the screening room and MP4s, including HTTP byte-range seeking."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import mimetypes
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


class Handler(BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.serve(send_body=False)

    def do_GET(self):
        self.serve(send_body=True)

    def serve(self, send_body):
        route = unquote(urlsplit(self.path).path)
        relative = Path(route.lstrip('/'))
        if any(part.startswith('.') or part == 'node_modules' for part in relative.parts):
            self.send_error(404)
            return
        file = (ROOT / relative).resolve()
        if not file.is_relative_to(ROOT):
            self.send_error(404)
            return
        if file.is_dir():
            file = file / 'index.html'
        if not file.is_file():
            self.send_error(404)
            return
        size = file.stat().st_size
        start, end, status = 0, size - 1, 200
        requested = self.headers.get('Range')
        if requested:
            try:
                unit, spec = requested.split('=', 1)
                if unit != 'bytes' or ',' in spec:
                    raise ValueError('unsupported range')
                first, last = spec.split('-', 1)
                if not first:
                    suffix = int(last)
                    if suffix <= 0:
                        raise ValueError('empty suffix')
                    start = max(0, size - suffix)
                else:
                    start = int(first)
                    end = min(int(last), size - 1) if last else size - 1
                if start < 0 or start >= size or end < start:
                    raise ValueError('range outside file')
                status = 206
            except ValueError:
                self.send_response(416)
                self.send_header('Content-Range', f'bytes */{size}')
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
        self.send_response(status)
        self.send_header('Content-Type', mimetypes.guess_type(file.name)[0] or 'application/octet-stream')
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Content-Length', str(end - start + 1))
        if status == 206:
            self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
        self.end_headers()
        if not send_body:
            return
        try:
            with file.open('rb') as source:
                source.seek(start)
                left = end - start + 1
                while left:
                    data = source.read(min(1024 * 1024, left))
                    if not data:
                        break
                    self.wfile.write(data)
                    left -= len(data)
        except (BrokenPipeError, ConnectionResetError):
            pass  # Normal when the viewer seeks or closes the player.


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4173)
    parser.add_argument('--bind', default='0.0.0.0')
    args = parser.parse_args()
    print(f'Screening room: http://{args.bind}:{args.port}', flush=True)
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()
