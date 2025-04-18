# compose-demo

## Usage

```sh
time docker compose up --exit-code-from test ; echo $?
```

## Problems

1. Tests abort when any of containers die.

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
