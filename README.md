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
           making/graal:1.0.0-rc2 \
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
           making/graal:1.0.0-rc2 \
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
           making/graal:1.0.0-rc2 \
           native-image --no-server -cp ./classes hello.HelloWorld
```

Run on a container (can not on Mac)

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           ./hello.helloworld
Hello World!
```

This executable binary is dynamically linked

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
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
           making/graal:1.0.0-rc2 \
           native-image --no-server --static -cp ./classes hello.HelloWorld
```

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           ./hello.helloworld
Hello World!
```

```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           ldd ./hello.helloworld
	not a dynamic executable
```
### Create a native image from the jar file


```bash
docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           native-image --no-server --static -jar hello.jar
```


```bash
$ docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
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

docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           javac -sourcepath src -d classes src/hello/HelloHttp.java

docker run --rm \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           native-image --no-server --static -cp ./classes hello.HelloHttp

docker run --rm -p 8080:8080 \
           -v "$PWD":/usr/src \
           -w /usr/src \
           making/graal:1.0.0-rc2 \
           ./hello.hellohttp
```

```bash
$ curl localhost:8080

Hello World!
```

Stop the application

```bash
docker stop `docker ps | grep 'making/graal:1.0.0-rc2' | awk '{print $1}'`
```

### Deploy to Cloud Foundry

```bash
mkdir tmp
cp hello.hellohttp tmp/
cf push hello-graal --random-route -m 16m -b binary_buildpack -p ./tmp -c './hello.hellohttp'
```

`cf push` fails with the following error...


```
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] Exception in thread "main" java.lang.reflect.InvocationTargetException
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.Throwable.<init>(Throwable.java:310)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.Exception.<init>(Exception.java:102)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.ReflectiveOperationException.<init>(ReflectiveOperationException.java:89)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.reflect.InvocationTargetException.<init>(InvocationTargetException.java:72)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at com.oracle.svm.reflect.proxies.Proxy_1_HelloHttp_main.invoke(Unknown Source)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.reflect.Method.invoke(Method.java:498)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at com.oracle.svm.core.JavaMainWrapper.run(JavaMainWrapper.java:173)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] Caused by: java.net.SocketException: NioSocketError
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.Throwable.<init>(Throwable.java:265)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.lang.Exception.<init>(Exception.java:66)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.io.IOException.<init>(IOException.java:58)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.net.SocketException.<init>(SocketException.java:47)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at com.oracle.svm.core.posix.PosixJavaNIOSubstitutions$Util_sun_nio_ch_Net.handleSocketError(PosixJavaNIOSubstitutions.java:1284)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at com.oracle.svm.core.posix.PosixJavaNIOSubstitutions$Target_sun_nio_ch_Net.socket0(PosixJavaNIOSubstitutions.java:766)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.nio.ch.Net.serverSocket(Net.java:415)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.nio.ch.ServerSocketChannelImpl.<init>(ServerSocketChannelImpl.java:88)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.nio.ch.SelectorProviderImpl.openServerSocketChannel(SelectorProviderImpl.java:56)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at java.nio.channels.ServerSocketChannel.open(ServerSocketChannel.java:108)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.net.httpserver.ServerImpl.<init>(ServerImpl.java:97)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.net.httpserver.HttpServerImpl.<init>(HttpServerImpl.java:50)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at sun.net.httpserver.DefaultHttpServerProvider.createHttpServer(DefaultHttpServerProvider.java:35)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at com.sun.net.httpserver.HttpServer.create(HttpServer.java:130)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] at hello.HelloHttp.main(HelloHttp.java:11)
2018-06-19T17:21:55.274+09:00 [APP/PROC/WEB/0] [ERR] ... 3 more
2018-06-19T17:21:55.278+09:00 [APP/PROC/WEB/0] [OUT] Exit status 0
```

