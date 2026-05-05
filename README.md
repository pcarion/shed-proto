# shed-proto

Shared protobuf definitions for the `shed` ecosystem.

| Repo | Role |
|------|------|
| [`github.com/pcarion/shed`](https://github.com/pcarion/shed) | CLI client |
| [`github.com/pcarion/shed-sidecar`](https://github.com/pcarion/shed-sidecar) | Daemon running on Hetzner-managed Ubuntu VMs |

The sidecar daemon queries systemd service status via D-Bus. The CLI reaches
sidecar instances through SSH tunnels, so the gRPC transport uses
`insecure.NewCredentials()` — the tunnel provides transport security.

## Consuming this module

```bash
go get github.com/pcarion/shed-proto@latest
```

```go
import (
    sidecarv1 "github.com/pcarion/shed-proto/gen/go/sidecar/v1"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
)

conn, err := grpc.NewClient("localhost:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()),
)
client := sidecarv1.NewSidecarClient(conn)

resp, err := client.ServiceStatus(ctx, &sidecarv1.ServiceStatusRequest{
    Services: []string{"nginx.service", "caddy.service"},
})
```

## Regenerating after proto changes

Install [buf](https://buf.build/docs/installation) then:

```bash
buf generate
go mod tidy
```

The CI workflow (`generate.yml`) fails if the committed generated code does not
match what `buf generate` produces, so always commit the regenerated files
alongside any proto change.

## Repository layout

```
proto/
  sidecar/v1/
    sidecar.proto       # source of truth
gen/
  go/
    sidecar/v1/
      sidecar.pb.go       # generated — do not edit
      sidecar_grpc.pb.go  # generated — do not edit
buf.yaml                # lint + breaking-change config
buf.gen.yaml            # code generation config
```

## Adding new RPCs

1. Edit `proto/sidecar/v1/sidecar.proto` (or add a new `.proto` file under `proto/`).
2. Run `buf generate && go mod tidy`.
3. Commit both the proto change and the regenerated files in one PR.
4. Bump the version tag (`git tag vX.Y.Z && git push --tags`) so consumers can
   update with `go get github.com/pcarion/shed-proto@vX.Y.Z`.
