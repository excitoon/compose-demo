# compose-demo

## Usage

```sh
time docker compose up --exit-code-from test ; echo $?
```

## Problems

1. Tests abort when any of containers die.

https://github.com/excitoon/compose-demo/commit/6fa8b8cc29735d85fd33fd58676db791df86f9a2

```sh
% time docker compose up --exit-code-from test ; echo $?
[+] Building 2.5s (18/18) FINISHED                                                                                                                                        docker:desktop-linux
[+] Running 6/6
 ✔ app                            Built                                                                                                                                                   0.0s
 ✔ base                           Built                                                                                                                                                   0.0s
 ✔ test                           Built                                                                                                                                                   0.0s
 ✔ Container compose-demo-app-1   Recreated                                                                                                                                               0.2s
 ✔ Container compose-demo-test-1  Recreated                                                                                                                                               0.2s
 ✔ Container compose-demo-base-1  Recreated                                                                                                                                               0.1s
Attaching to app-1, base-1, test-1
base-1 exited with code 0
Aborting on container exit...
[+] Stopping 3/3
 ✔ Container compose-demo-test-1  Stopped                                                                                                                                                10.2s
 ✔ Container compose-demo-app-1   Stopped                                                                                                                                                 0.2s
 ✔ Container compose-demo-base-1  Stopped                                                                                                                                                 0.0s
docker compose up --exit-code-from test  0.21s user 0.20s system 2% cpu 13.824 total
137
```

2. Tests can return exit code from random container (not necessarily non-zero) during that abort.

```sh
% time docker compose up --exit-code-from test ; echo $?
[+] Building 3.5s (18/18) FINISHED                                                                                                                                        docker:desktop-linux
[+] Running 7/7
 ✔ app                                  Built                                                                                                                                             0.0s
 ✔ base                                 Built                                                                                                                                             0.0s
 ✔ test                                 Built                                                                                                                                             0.0s
 ✔ Container compose-demo-app-1         Recreated                                                                                                                                         0.3s
 ✔ Container compose-demo-dependency-1  Recreated                                                                                                                                         0.2s
 ✔ Container compose-demo-base-1        Recreated                                                                                                                                         0.1s
 ✔ Container compose-demo-test-1        Recreated                                                                                                                                         0.2s
Attaching to app-1, base-1, dependency-1, test-1
base-1 exited with code 0
Aborting on container exit...
[+] Stopping 4/4
 ✔ Container compose-demo-test-1        Stopped                                                                                                                                           0.0s
 ✔ Container compose-demo-app-1         Stopped                                                                                                                                           0.0s
 ✔ Container compose-demo-dependency-1  Stopped                                                                                                                                           1.1s
 ✔ Container compose-demo-base-1        Stopped                                                                                                                                           0.0s
Gracefully stopping... (press Ctrl+C again to force)
[+] Stopping 4/4
 ✔ Container compose-demo-test-1        Stopped                                                                                                                                           0.0s
 ✔ Container compose-demo-app-1         Stopped                                                                                                                                           0.0s
 ✔ Container compose-demo-dependency-1  Stopped                                                                                                                                           0.0s
 ✔ Container compose-demo-base-1        Stopped                                                                                                                                           0.0s
dependency failed to start: container compose-demo-dependency-1 exited (137)
docker compose up --exit-code-from test  0.22s user 0.20s system 6% cpu 6.257 total
1
```
