# compose-demo

## Usage

We would like to run specific service along with its dependencies (or all services), observing logs at the same time.

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

2. Tests can return exit code from random (or even non-existent?) container (not necessarily non-zero) during that abort.

https://github.com/excitoon/compose-demo/commit/c9aac5c3462642a0018eef429bbf5d1eb98f8942

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

## Workaround

`--exit-code-from` implementation is incorrect because it implies `--abort-on-container-exit` *somewhy*, yet doing it wrong. *In fact it implies (quite explicitly though) that it allows to specify the container* which exit code to return **but it behaves more like it does not take any arguments**.

Best option would be to use plain `run` but in this case we lose logs in stdout. Thus, let's admit that `--abort-on-container-exit` will not work and think out a workaround. We need a mechanism which would pass exit code of the command somewhere (ideally to `compose up` itself) and shut sibling containers down once it finishes. However, we have to have backend part which will actually stop these containers outside of docker. ¯\_(ツ)_/¯

It may work like:

```sh
gather-code-from test docker compose up
```

At this point I stumbled upon `docker compose events` which does **exactly that**:

```json
{"action":"create","attributes":{"image":"base","name":"bd8c2b47dec4_compose-demo-base-1"},"id":"3a46fc4dfdc0ea3bb2aaa7b9aca0a9d1a465fe9dfef167d171130107b313afc5","service":"base","time":"2025-04-19T04:21:43.082860555+03:00","type":"container"}
{"action":"destroy","attributes":{"image":"base","name":"compose-demo-base-1"},"id":"bd8c2b47dec47e545e2a644eeda69132bb0c1f9ef5eacdebf924daabf37583da","service":"base","time":"2025-04-19T04:21:43.10647893+03:00","type":"container"}
{"action":"rename","attributes":{"image":"base","name":"compose-demo-base-1","oldName":"/bd8c2b47dec4_compose-demo-base-1"},"id":"3a46fc4dfdc0ea3bb2aaa7b9aca0a9d1a465fe9dfef167d171130107b313afc5","service":"base","time":"2025-04-19T04:21:43.11200293+03:00","type":"container"}
{"action":"create","attributes":{"image":"base","name":"dbffc533bf81_compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:43.20826518+03:00","type":"container"}
{"action":"destroy","attributes":{"image":"base","name":"compose-demo-dependency-1"},"id":"dbffc533bf816c84cb0756cc6a5db73a96fdef389c4a0df03e7ff64307a3ddbd","service":"dependency","time":"2025-04-19T04:21:43.241183472+03:00","type":"container"}
{"action":"rename","attributes":{"image":"base","name":"compose-demo-dependency-1","oldName":"/dbffc533bf81_compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:43.256040763+03:00","type":"container"}
{"action":"create","attributes":{"image":"compose-demo-app","name":"4edbd6943ee3_compose-demo-app-1"},"id":"f33eb82543848c3d3c64d509f67455b92ddd802924b0616a6dd925de9578d884","service":"app","time":"2025-04-19T04:21:43.373850763+03:00","type":"container"}
{"action":"destroy","attributes":{"image":"compose-demo-app","name":"compose-demo-app-1"},"id":"4edbd6943ee38ba9d98a30620d4823a2f43f786d09c9785ad3783dd591d869f7","service":"app","time":"2025-04-19T04:21:43.392290555+03:00","type":"container"}
{"action":"rename","attributes":{"image":"compose-demo-app","name":"compose-demo-app-1","oldName":"/4edbd6943ee3_compose-demo-app-1"},"id":"f33eb82543848c3d3c64d509f67455b92ddd802924b0616a6dd925de9578d884","service":"app","time":"2025-04-19T04:21:43.398921097+03:00","type":"container"}
{"action":"create","attributes":{"image":"compose-demo-test","name":"c7618b48fc8e_compose-demo-test-1"},"id":"62096ef99daddf5798320e6c0fd1f8eaaa0cd00180b0292eff2fa431ed828371","service":"test","time":"2025-04-19T04:21:43.451097847+03:00","type":"container"}
{"action":"destroy","attributes":{"image":"compose-demo-test","name":"compose-demo-test-1"},"id":"c7618b48fc8e6bbbf80849c7dcfce18af4793d1cd8d399dae9ff95bd78555c42","service":"test","time":"2025-04-19T04:21:43.47128393+03:00","type":"container"}
{"action":"rename","attributes":{"image":"compose-demo-test","name":"compose-demo-test-1","oldName":"/c7618b48fc8e_compose-demo-test-1"},"id":"62096ef99daddf5798320e6c0fd1f8eaaa0cd00180b0292eff2fa431ed828371","service":"test","time":"2025-04-19T04:21:43.479060347+03:00","type":"container"}
{"action":"attach","attributes":{"image":"compose-demo-app","name":"compose-demo-app-1"},"id":"f33eb82543848c3d3c64d509f67455b92ddd802924b0616a6dd925de9578d884","service":"app","time":"2025-04-19T04:21:43.53192218+03:00","type":"container"}
{"action":"attach","attributes":{"image":"base","name":"compose-demo-base-1"},"id":"3a46fc4dfdc0ea3bb2aaa7b9aca0a9d1a465fe9dfef167d171130107b313afc5","service":"base","time":"2025-04-19T04:21:43.534830847+03:00","type":"container"}
{"action":"attach","attributes":{"image":"base","name":"compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:43.538380972+03:00","type":"container"}
{"action":"attach","attributes":{"image":"compose-demo-test","name":"compose-demo-test-1"},"id":"62096ef99daddf5798320e6c0fd1f8eaaa0cd00180b0292eff2fa431ed828371","service":"test","time":"2025-04-19T04:21:43.542090972+03:00","type":"container"}
{"action":"start","attributes":{"image":"base","name":"compose-demo-base-1"},"id":"3a46fc4dfdc0ea3bb2aaa7b9aca0a9d1a465fe9dfef167d171130107b313afc5","service":"base","time":"2025-04-19T04:21:43.71164768+03:00","type":"container"}
{"action":"die","attributes":{"execDuration":"0","exitCode":"0","image":"base","name":"compose-demo-base-1"},"id":"3a46fc4dfdc0ea3bb2aaa7b9aca0a9d1a465fe9dfef167d171130107b313afc5","service":"base","time":"2025-04-19T04:21:43.806522014+03:00","type":"container"}
{"action":"start","attributes":{"image":"base","name":"compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:43.833411097+03:00","type":"container"}
{"action":"kill","attributes":{"image":"base","name":"compose-demo-dependency-1","signal":"15"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:43.842516764+03:00","type":"container"}
{"action":"kill","attributes":{"image":"base","name":"compose-demo-dependency-1","signal":"9"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:44.85446075+03:00","type":"container"}
{"action":"stop","attributes":{"image":"base","name":"compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:44.923905417+03:00","type":"container"}
{"action":"die","attributes":{"execDuration":"1","exitCode":"137","image":"base","name":"compose-demo-dependency-1"},"id":"388c1521e2b2a7f0111a5d885ef4919a26d64f290506c32124e08e09f5c506a0","service":"dependency","time":"2025-04-19T04:21:44.9271425+03:00","type":"container"}
```

Which means we don't even need to change what's inside the containers and the solution will be just an additional and perfectly separate wrapper for `docker compose`, written in Python.

## Solution

TBD.
