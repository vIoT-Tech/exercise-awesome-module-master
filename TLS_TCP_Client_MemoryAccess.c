//  Linux C Example: TLS TCP Client + Memory Access
// •	Reads a string from a memory buffer
// •	Establishes a TLS connection to a TCP server (port 4433)
// •	Sends the data over secure TCP
// Using OpenSSL (Simplest TLS Approach)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#define SERVER_IP   "192.168.100.1"
#define SERVER_PORT 4433
#define MEMORY_DATA "Hello from Zynq UltraScale+ Linux with TLS!\n"

int main() {
    // Initializes SSL library and error strings for secure communication.
    // Key Operations:   // Initialize SSL library for secure operations    // Load SSL error strings for debugging
    SSL_library_init();
    SSL_load_error_strings();

    // Sets up SSL context for TLS client communication.
    // Key Operations:   // Define SSL method for TLS client.   // Create SSL context using defined method.
    const SSL_METHOD *method = TLS_client_method();
    SSL_CTX *ctx = SSL_CTX_new(method);

    // Checks if context is null, prints errors, and exits if true.
    // Key Operations:  // Check if context is null   // Print errors to stderr  // Exit program with failure status
    // Inputs:     // ctx: Context variable to check, typically a pointer
    if (!ctx) {
        ERR_print_errors_fp(stderr);
        exit(EXIT_FAILURE);
    }

    // Configures the network connection by creating a socket and setting up the server address.  // Creates a socket for TCP communication.
    // Initialize socket for IPv4 and TCP
    // Outputs:  // sock: Socket file descriptor for TCP communication
    // Sets up server address structure with IP and port for network communication.
    // Key Operations:   // Initialize server address family to IPv4  // Set server port using htons // Assign server IP address using inet_addr
    // Inputs:  // SERVER_PORT: Port number for server, integer type // SERVER_IP: Server IP address, string type
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(SERVER_PORT),
        .sin_addr.s_addr = inet_addr(SERVER_IP)
    };


    // Attempts to connect to a server and handles connection failure.
    // Key Operations:   // Attempt to connect to server   // Handle connection failure   // Close socket on failure   // Return error code
    // Inputs:   // sock: Socket file descriptor for connection   // server_addr: Server address structure
    // Outputs:   // 1: Error code indicating connection failure
    if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("connect");
        close(sock);
        return 1;
    }

    // Wrap with SSL
    // Creates an SSL object and associates it with a socket for secure communication.
    // Key Operations:  // Create SSL object using context   // Associate SSL object with socket
    // Inputs:   // ctx: SSL context for configuration  // sock: Socket file descriptor for communication
    SSL *ssl = SSL_new(ctx);
    SSL_set_fd(ssl, sock);


    // Attempts SSL connection, handles errors, sends data if successful.
    // Key Operations:   // Attempt SSL connection   // Handle connection errors   // Print encryption details   // Send data over SSL   // Print sent data
    // Inputs:   // ssl: SSL connection object
    if (SSL_connect(ssl) <= 0) {
        ERR_print_errors_fp(stderr);
    } else {
        printf("✅ Connected with %s encryption\n", SSL_get_cipher(ssl));
        const char *data = MEMORY_DATA;  // In reality, you'd read from buffer or /dev/mem
        SSL_write(ssl, data, strlen(data));
        printf("📤 Sent data: %s\n", data);
    }

    // Shuts down SSL, frees SSL and context, closes socket.
    // Key Operations:   // Shut down SSL connection   // Free SSL object  // Close socket   // Free SSL context
    SSL_shutdown(ssl);
    SSL_free(ssl);
    close(sock);
    SSL_CTX_free(ctx);

    return 0;
}

