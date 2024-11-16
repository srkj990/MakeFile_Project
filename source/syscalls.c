#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

// Exit the application
void _exit(int status) {
    while (1) {
        // Infinite loop to halt the system
    }
}

// Memory allocation (stub for _sbrk)
void* _sbrk(int incr) {
    return (void*)-1;  // Returning an error
}

// Write to file (stub for _write)
int _write(int file, char* ptr, int len) {
    return len;  // Pretend to write len bytes
}

// Close file (stub for _close)
int _close(int file) {
    return -1;
}

// File status (stub for _fstat)
int _fstat(int file, struct stat* st) {
    st->st_mode = S_IFCHR;  // Character device
    return 0;
}

// Check if file is a terminal (stub for _isatty)
int _isatty(int file) {
    return 1;  // Yes, it is a terminal
}

// File seek (stub for _lseek)
int _lseek(int file, int ptr, int dir) {
    return 0;
}

// Read from file (stub for _read)
int _read(int file, char* ptr, int len) {
    return 0;  // No data read
}

// Get process ID (stub for _getpid)
int _getpid(void) {
    return 1;  // Dummy PID
}

// Kill process (stub for _kill)
int _kill(int pid, int sig) {
    return -1;
}
