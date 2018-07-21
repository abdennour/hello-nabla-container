#!/bin/bash
# @author Abdennour TOUMI <http://in.abdennoor.com>
# A Bash script that provision an Ubuntu machine for Nabla container runtime with running a demo at the end
# ###################### Install Dependencies ######################

apt-get -yq update
apt-get -y upgrade
# Install docker community edition
apt-get remove docker docker-engine docker.io -y;

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt-get update -y && apt-get upgrade -y;
apt-get install -y docker-ce;

# Install GO
cd /tmp
curl -O https://storage.googleapis.com/golang/go1.10.3.linux-amd64.tar.gz
tar -xvf go1.10.3.linux-amd64.tar.gz
mv go /usr/local
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go


# ###################### Install NABLA Runtime ######################

# download runnc source code
go get github.com/nabla-containers/runnc
cd ${GOPATH}/src/github.com/nabla-containers/runnc
# build the binary runnc and other binaries needed
make container-build
# Validate the Build
ls -lh build/{nabla-run,runnc,runnc-cont}
# Install runnc
cd ${GOPATH}/src/github.com/nabla-containers/runnc
make container-install
# Validate the Install
ls -lh /usr/local/bin/{nabla-run,runnc,runnc-cont}
ls -lh /opt/runnc/lib/{ld-linux-x86-64.so.2,libc.so.6,libseccomp.so.2}

# Configure NABLA runtime with docker
apt-get install -y genisoimage
mkdir -p /etc/systemd/system/docker.service.d/
cat > /etc/systemd/system/docker.service.d/nabla-containers.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -D --add-runtime nabla-runtime=/usr/local/bin/runnc
EOF
systemctl daemon-reload
systemctl restart docker
docker run hello-world


# ###################### Run Demo with NABLA Runtime ######################

# Download the demo (Node App)
go get github.com/abdennour/nabla-demo-apps
# Build the demo
cd ${GOPATH}/src/github.com/abdennour/nabla-demo-apps/node-express
docker build -t node-express-nabla -f Dockerfile.nabla .
# Validate the build
docker images | grep node-express-nabla
# Run the demo
docker run --rm -t -d --runtime=nabla-runtime -p 9090:8080 node-express-nabla # -t -d run in background
# Validate the Run step
curl -s http://localhost:9090