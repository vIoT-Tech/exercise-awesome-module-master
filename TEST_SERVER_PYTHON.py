
# Test Server (Python OpenSSL server)
# Save as tls_server.py
import ssl, socket

# Sets up an SSL context for a server using TLS protocol and loads certificate and key files.
# Key Operations:
# Create SSL context for server using TLS protocol
# Load certificate and key files into context
# Inputs:
# certfile: Path to certificate file, string
# keyfile: Path to key file, string
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')

# Sets up a server socket to listen on port 4433 for incoming connections.
# Key Operations:
# Create socket for IPv4 and TCP communication
# Bind socket to all available interfaces on port 4433
# Listen for one incoming connection
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind(('0.0.0.0', 4433))
    s.listen(1)

    # Wraps a socket for secure communication on the server side.
    # Key Operations:
    # Wrap socket for secure server-side communication
    with context.wrap_socket(s, server_side=True) as ssock:
        print("🔐 TLS Server running on port 4433")

        # Accepts a new connection and address from a socket.
        # Key Operations:
        # Accept new connection and address
        # Outputs:
        # conn: Connection object for the new client
        # addr: Address of the new client
        conn, addr = ssock.accept()

        # Receives data from a connection and prints it.
        # Key Operations:
        # Receive data from connection
        # Decode received data
        # Print decoded data
        # Inputs:
        # conn: Connection object for receiving data
        data = conn.recv(1024)
        print(f"📥 Received: {data.decode()}")


# BASH:
# openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes   