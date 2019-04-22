## Hello Graal

```java
mkdir -p src/hello classes
cat <<EOF > src/hello/HelloWorld.java
package hello;

public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
EOF
```

### Compile with Graal compiler


```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           javac -sourcepath src -d classes src/hello/HelloWorld.java
```

Write once, run anywhere :)

```bash
$ java -cp classes hello.HelloWorld
Hello World!
```

create a jar file

```bash
cat <<EOF > hello.mf
Main-Class: hello.HelloWorld
EOF

docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           jar -cvmf hello.mf hello.jar -C classes .
```

Write once, run anywhere :)

```bash
$ java -jar hello.jar 
Hello World!
```

### Create a native image from class files


```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           native-image --no-server -cp ./classes hello.HelloWorld
```

Run on a container (can not on Mac)

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ./hello.helloworld
Hello World!
```

This executable binary is dynamically linked

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ldd ./hello.helloworld
	linux-vdso.so.1 =>  (0x00007ffe8dbfa000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fab55832000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fab5562a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fab55261000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fab55a50000)
```

You can create statically linkded binary with `--static` option

```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           native-image --no-server --static -cp ./classes hello.HelloWorld
```

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ./hello.helloworld
Hello World!
```

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ldd ./hello.helloworld
	not a dynamic executable
```
### Create a native image from the jar file


```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           native-image --no-server --static -jar hello.jar
```


```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ./hello
Hello World!
```

### Build a http server

```java
cat <<EOF > src/hello/HelloHttp.java
package hello;

import com.sun.net.httpserver.HttpServer;

import java.io.OutputStream;
import java.net.InetSocketAddress;

public class HelloHttp {
    public static void main(String[] args) throws Exception {
        long start = System.nanoTime();
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", exchange -> {
            String response = "Hello World!";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        });
        server.start();
        long elapsed = System.nanoTime() - start;
        System.out.println("Started in " + elapsed / 1_000_000.0 + " [ms]");
    }
}
EOF
```

```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           javac -sourcepath src -d classes src/hello/HelloHttp.java

docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           native-image --no-server --static -cp ./classes hello.HelloHttp

docker run --rm -p 8080:8080 \
           -v "$PWD":/usr/src \
           -w /usr/src \
           oracle/graalvm-ce:1.0.0-rc15 \
           ./hello.hellohttp
```

```bash
$ curl localhost:8080

Hello World!
```

Stop the application

```bash
docker stop `docker ps | grep 'oracle/graalvm-ce:1.0.0-rc15' | awk '{print $1}'`
```

### Deploy to Cloud Foundry

```bash
mkdir tmp
cp hello.hellohttp tmp/
cf push hello-graal --random-route -m 16m -b binary_buildpack -p ./tmp -c './hello.hellohttp'
```

`cf push` just works!


```
2019-04-21T23:59:38.56+0900 [API/14] OUT Creating build for app with guid 93552394-fdd0-4afa-814b-3206e7522321
2019-04-21T23:59:39.29+0900 [STG/0] OUT Downloading binary_buildpack...
2019-04-21T23:59:39.16+0900 [API/14] OUT Updated app with guid 93552394-fdd0-4afa-814b-3206e7522321 ({"state"=>"STARTED"})
2019-04-21T23:59:39.38+0900 [STG/0] OUT Downloaded binary_buildpack
2019-04-21T23:59:39.38+0900 [STG/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f creating container for instance f42fe38a-2896-47c6-be10-85a0dbc28810
2019-04-21T23:59:39.86+0900 [STG/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f successfully created container for instance f42fe38a-2896-47c6-be10-85a0dbc28810
2019-04-21T23:59:40.08+0900 [STG/0] OUT Downloading app package...
2019-04-21T23:59:40.35+0900 [STG/0] OUT Downloaded app package (3.1M)
2019-04-21T23:59:40.44+0900 [STG/0] OUT -----> Binary Buildpack version 1.0.31
2019-04-21T23:59:41.09+0900 [STG/0] OUT Exit status 0
2019-04-21T23:59:41.09+0900 [STG/0] OUT Uploading droplet, build artifacts cache...
2019-04-21T23:59:41.09+0900 [STG/0] OUT Uploading droplet...
2019-04-21T23:59:41.09+0900 [STG/0] OUT Uploading build artifacts cache...
2019-04-21T23:59:41.18+0900 [STG/0] OUT Uploaded build artifacts cache (215B)
2019-04-21T23:59:41.22+0900 [API/7] OUT Creating droplet for app with guid 93552394-fdd0-4afa-814b-3206e7522321
2019-04-21T23:59:42.29+0900 [STG/0] OUT Uploaded droplet (3.1M)
2019-04-21T23:59:42.29+0900 [STG/0] OUT Uploading complete
2019-04-21T23:59:42.55+0900 [STG/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f stopping instance f42fe38a-2896-47c6-be10-85a0dbc28810
2019-04-21T23:59:42.55+0900 [STG/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f destroying container for instance f42fe38a-2896-47c6-be10-85a0dbc28810
2019-04-21T23:59:42.95+0900 [STG/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f successfully destroyed container for instance f42fe38a-2896-47c6-be10-85a0dbc28810
2019-04-21T23:59:43.00+0900 [CELL/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f creating container for instance d15ab3f4-c453-437f-446f-28a1
2019-04-21T23:59:43.50+0900 [CELL/0] OUT Cell eeecc2c0-519a-4d6c-ad9b-e8239542f23f successfully created container for instance d15ab3f4-c453-437f-446f-28a1
2019-04-21T23:59:44.17+0900 [CELL/0] OUT Starting health monitoring of container
2019-04-21T23:59:44.51+0900 [APP/PROC/WEB/0] OUT Started in 0.420449 [ms]
2019-04-21T23:59:44.81+0900 [CELL/0] OUT Container became healthy
```

