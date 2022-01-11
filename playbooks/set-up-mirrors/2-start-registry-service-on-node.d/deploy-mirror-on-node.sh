#!/bin/bash
# Based on this script from Sally O'Malley
#   https://gist.github.com/sallyom/dc168cfecfd478547cbf5e0a85fb9334
set -euxo pipefail

HOSTNAME=localhost
sudo dnf -y install podman httpd httpd-tools make skopeo golang-github-cloudflare-cfssl avahi

mkdir create-registry-certs
pushd create-registry-certs
cat > ca-config.json << EOF
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "server": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat > ca-csr.json << EOF
{
    "CN": "Test Registry Self Signed CA",
    "hosts": [
        "${HOSTNAME}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "US",
            "ST": "CA",
            "L": "San Francisco"
        }
    ]
}
EOF

cat > server.json << EOF
{
    "CN": "Test Registry Self Signed CA",
    "hosts": [
        "${HOSTNAME}"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "US",
            "ST": "CA",
            "L": "San Francisco"
        }
    ]
}
EOF

# generate ca-key.pem, ca.csr, ca.pem
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# generate server-key.pem, server.csr, server.pem
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server

# enable schema version 1 images
cat > registry-config.yml << EOF
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
compatibility:
  schema1:
    enabled: true
EOF

sudo mkdir -p /opt/registry/{certs,data}

CA=$(sudo tail -n +2 ca.pem | head -n-1 | tr -d '\r\n')
sudo cp registry-config.yml /opt/registry/.
sudo cp server-key.pem /opt/registry/certs/.
sudo cp server.pem /opt/registry/certs/.
sudo cp /opt/registry/certs/server.pem /etc/pki/ca-trust/source/anchors/
sudo cp ca.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust extract

# Now that certs are in place, run the local image registry
sudo podman run --name test-registry -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-v /opt/registry/registry-config.yml:/etc/docker/registry/config.yml:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.pem \
-e REGISTRY_HTTP_TLS_KEY=/certs/server-key.pem \
-d docker.io/library/registry:2

popd
rm -rf create-registry-certs
