from http.server import HTTPServer, SimpleHTTPRequestHandler

class FrameableHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Remove any default X-Frame-Options and allow all framing
        self.send_header('X-Frame-Options', 'ALLOWALL')
        super().end_headers()

if __name__ == '__main__':
    # cd into your Flutter project’s build/web directory before running:
    #    cd build/web
    server = HTTPServer(('localhost', 8000), FrameableHandler)
    print("Serving on http://localhost:8000 …")
    server.serve_forever()
