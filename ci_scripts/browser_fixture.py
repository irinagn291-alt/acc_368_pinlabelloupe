from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import socket
retry_ready = False
class Handler(BaseHTTPRequestHandler):
 def send(self, body, status=200, headers=None):
  data=body.encode();self.send_response(status)
  for k,v in (headers or {}).items():self.send_header(k,v)
  self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
 def do_POST(self):
  global retry_ready
  data=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
  assert set(data)=={'bundle','push_token','advertising_id','appsflyer_id'}
  assert data['bundle'] in {'app.labelloupe.journal', 'app.pantryorbit.store', 'games.mossbound.crossing'}
  assert 'Safari' in self.headers['User-Agent']
  target='http://127.0.0.1:18786/redirect?source=registration'
  if self.path=='/register-retry':
   retry_ready=False
   target='http://127.0.0.1:18786/retry-page'
  self.send(json.dumps({'success':True,'app_data':target}),headers={'Content-Type':'application/json','Set-Cookie':'launch_session=restored; Path=/; HttpOnly'})
 def do_GET(self):
  global retry_ready
  if self.path=='/allow-retry':
   retry_ready=True
   return self.send('ready')
  if self.path=='/retry-page':
   if retry_ready:return self.send('<html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><h1>Recovered page</h1></body></html>',headers={'Content-Type':'text/html'})
   self.connection.shutdown(socket.SHUT_RDWR)
   self.connection.close()
   return
  if self.path.startswith('/redirect'):
   return self.send('',302,{'Location':'/home?source=registration'})
  if self.path=='/next':body='<h1>Second page</h1><a href="javascript:history.back()">Return to first page</a>'
  else:
   body='<h1>Launch fixture</h1><a href="/next" target="_blank">Next page</a><button onclick="alert(\'JavaScript works\')">Show alert</button>'
   if 'launch_session=restored' in self.headers.get('Cookie',''):body+='<p>Registration cookie restored</p>'
   if self.path=='/home?source=registration':body+='<p>Registration redirect reached</p>'
  body+='<p id="agent"></p><script>document.getElementById("agent").textContent=navigator.userAgent;</script>'
  self.send('<html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>'+body+'</body></html>',headers={'Content-Type':'text/html; charset=utf-8'})
ThreadingHTTPServer(('127.0.0.1',18786),Handler).serve_forever()
