# InfluxDB does not build on ARM architechture 

https://github.com/influxdata/influxdb/issues/24312

You can run `docker build --progress=plain  .` on an ARM machine (apple laptop here) to reproduce this issue. it fails at `make` with:

```
#25 40.20 + env GO111MODULE=on go build -tags sqlite_foreign_keys,sqlite_json,assets -ldflags  -X main.commit=407fa622e9 -X main.version=v2.7.1 -o bin/linux/influxd ./cmd/influxd
#25 40.76 # github.com/influxdata/flux
#25 40.76 /root/go/pkg/mod/github.com/influxdata/flux@v0.193.0/runtime.go:48:27: undefined: libflux.Options
#25 42.44 # github.com/influxdata/influxdb/v2/sqlite
#25 42.44 sqlite/sqlite.go:187:28: destSqliteConn.Backup undefined (type *sqlite3.SQLiteConn has no field or method Backup)
#25 50.83 make: *** [GNUmakefile:84: bin/linux/influxd] Error 1
#25 ERROR: executor failed running [/bin/sh -c export GOOS=linux &&     export GOARCH=amd64 &&     export GOEXPERIMENT=boringcrypto &&     uname -a && make  SHELL='sh -x']: exit code: 2
```