/***********************************************************
 * File: dma_to_eth.c
 * A Simplified Example for Zynq UltraScale+ (Linux)
 *
 * Compilation (on target or cross-compile):
 *   gcc dma_to_eth.c -o dma_to_eth
 *
 * Usage:
 *   ./dma_to_eth <server_ip> <server_port> <dma_device>
 *
 * Example:
 *   ./dma_to_eth 192.168.1.100 5001 /dev/xdma0_c2h_0
 ***********************************************************/

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <unistd.h>
 #include <fcntl.h>
 #include <errno.h>
 #include <sys/socket.h>
 #include <sys/types.h>
 #include <arpa/inet.h>
 #include <netinet/in.h>
 
 #define DMA_BUFFER_SIZE 1024  // Example size
 static char dmaBuffer[DMA_BUFFER_SIZE];
 
 int main(int argc, char *argv[])
 {
     if (argc < 4) {
         fprintf(stderr, "Usage: %s <server_ip> <server_port> <dma_device>\n", argv[0]);
         return -1;
     }
 
     const char *server_ip   = argv[1];
     int server_port         = atoi(argv[2]);
     const char *dma_devname = argv[3];
 
     /*********************************************************
      * 1. Open the DMA device
      *********************************************************/
     int dma_fd = open(dma_devname, O_RDONLY);
     if (dma_fd < 0) {
         perror("Error opening DMA device");
         return -1;
     }
     printf("Opened DMA device: %s\n", dma_devname);
 
     /*********************************************************
      * 2. Create a socket and connect to the server
      *********************************************************/
     int sock_fd = socket(AF_INET, SOCK_STREAM, 0);
     if (sock_fd < 0) {
         perror("socket creation failed");
         close(dma_fd);
         return -1;
     }
 
     struct sockaddr_in serv_addr;
     memset(&serv_addr, 0, sizeof(serv_addr));
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_port   = htons(server_port);
 
     if (inet_pton(AF_INET, server_ip, &serv_addr.sin_addr) <= 0) {
         perror("Invalid server IP address");
         close(dma_fd);
         close(sock_fd);
         return -1;
     }
 
     if (connect(sock_fd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
         perror("connect failed");
         close(dma_fd);
         close(sock_fd);
         return -1;
     }
     printf("Connected to %s:%d\n", server_ip, server_port);
 
     /*********************************************************
      * 3. Continuously read from DMA and send data via socket
      *    In real scenarios, you'd do this in a loop, or with
      *    larger buffers, etc.
      *********************************************************/
     ssize_t bytesRead = read(dma_fd, dmaBuffer, DMA_BUFFER_SIZE);
     if (bytesRead < 0) {
         perror("Error reading from DMA device");
     } else {
         printf("Read %ld bytes from DMA device\n", bytesRead);
 
         // Send to the server
         ssize_t bytesSent = send(sock_fd, dmaBuffer, bytesRead, 0);
         if (bytesSent < 0) {
             perror("Error sending data to server");
         } else {
             printf("Sent %ld bytes to server\n", bytesSent);
         }
     }
 
     /*********************************************************
      * 4. Clean up
      *********************************************************/
     close(sock_fd);
     close(dma_fd);
 
     return 0;
 }