#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/wait.h>

void pump(int infd, int outfd) {
    char buf[4096];
    ssize_t sz, t;
    for (;;) {
        sz = read(infd, buf, sizeof(buf));
        if (sz <= 0) {
            if (errno == EINTR) continue;
            return;
        }
        while (sz) {
            t = write(outfd, buf, sz);
            if (t <= 0) {
                if (errno == EINTR) continue;
                return;
            }
            sz -= t;
        }
    }
}

int pin[2], pout[2], perr[2];

void *pump_stdin(void *ignore) {
    pump(STDIN_FILENO, pin[1]);
    return NULL;
}

void *pump_stdout(void *ignore) {
    pump(pout[0], STDOUT_FILENO);
    return NULL;
}

void set_fd(int fd) {
    if (fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) & ~FD_CLOEXEC) == -1) {
        err(EXIT_FAILURE, "setfd");
    }
}

void *pump_stderr(void *ignore) {
    pump(perr[0], STDERR_FILENO);
    return NULL;
}

int main(int argc, char **argv) {
    if (pipe(pin) == -1) {
        err(EXIT_FAILURE, "pipe");
    }
    if (pipe(pout) == -1) {
        err(EXIT_FAILURE, "pipe");
    }
    if (pipe(perr) == -1) {
        err(EXIT_FAILURE, "pipe");
    }
    pid_t pid = fork();
    if (pid < 0) {
        err(EXIT_FAILURE, "fork");
    } else if (pid > 0) {
        close(pin[0]);
        close(pout[1]);
        close(perr[1]);
        pthread_t p1;
        pthread_create(&p1, NULL, pump_stdin, NULL);
        pthread_detach(p1);
        pthread_t p2;
        pthread_create(&p2, NULL, pump_stderr, NULL);
        pthread_detach(p2);
        pump_stdout(NULL);
        int status;
        for (;;) {
            if (waitpid(pid, &status, 0) < 0) {
                if (errno == EINTR) continue;
                err(EXIT_FAILURE, "wait");
            }
            if (WIFEXITED(status))
                exit(WEXITSTATUS(status));
            else
                exit(EXIT_FAILURE);
        }

    } else {
        if (dup2(pin[0], STDIN_FILENO) == -1)
            err(EXIT_FAILURE, "dup in");
        close(pin[0]);
        set_fd(STDIN_FILENO);
        if (dup2(pout[1], STDOUT_FILENO) == -1)
            err(EXIT_FAILURE, "dup out");
        close(pout[1]);
        set_fd(STDOUT_FILENO);
        if (dup2(perr[1], STDERR_FILENO) == -1)
            err(EXIT_FAILURE, "dup err");
        close(perr[1]);
        set_fd(STDERR_FILENO);
        execv("/system/bin/cmd", argv);
        err(EXIT_FAILURE, "exec");
    }
}
