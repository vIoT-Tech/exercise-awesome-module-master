// Full Linux C Example: TLS TCP Client + Memory Access
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
    SSL_library_init();
    SSL_load_error_strings();
    const SSL_METHOD *method = TLS_client_method();
    SSL_CTX *ctx = SSL_CTX_new(method);

    if (!ctx) {
        ERR_print_errors_fp(stderr);
        exit(EXIT_FAILURE);
    }

    // Create socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(SERVER_PORT),
        .sin_addr.s_addr = inet_addr(SERVER_IP)
    };

    if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("connect");
        close(sock);
        return 1;
    }

    // Wrap with SSL
    SSL *ssl = SSL_new(ctx);
    SSL_set_fd(ssl, sock);

    if (SSL_connect(ssl) <= 0) {
        ERR_print_errors_fp(stderr);
    } else {
        printf("✅ Connected with %s encryption\n", SSL_get_cipher(ssl));
        const char *data = MEMORY_DATA;  // In reality, you'd read from buffer or /dev/mem
        SSL_write(ssl, data, strlen(data));
        printf("📤 Sent data: %s\n", data);
    }

    SSL_shutdown(ssl);
    SSL_free(ssl);
    close(sock);
    SSL_CTX_free(ctx);

    return 0;
}

