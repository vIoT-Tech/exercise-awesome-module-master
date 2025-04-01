
# Test Server (Python OpenSSL server)
# Save as tls_server.py
import ssl, socket

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind(('0.0.0.0', 4433))
    s.listen(1)
    with context.wrap_socket(s, server_side=True) as ssock:
        print("🔐 TLS Server running on port 4433")
        conn, addr = ssock.accept()
        data = conn.recv(1024)
        print(f"📥 Received: {data.decode()}")

# BASH:
# openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes   