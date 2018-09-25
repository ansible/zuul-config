#!/bin/bash -xe
# Copyright (C) 2018 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

[ -z "$SUDO_COMMAND" ] && exec sudo $0

if ! type buildah; then
    yum install -y buildah
fi

ctr=$(buildah from centos)
mnt=$(buildah mount $ctr)

## Install dependencies
buildah run $ctr -- yum update -y
buildah run $ctr -- yum install -y passwd rsync ansible strace make gcc \
    python-jinja2 PyYAML git patch python-devel python-virtualenv \
    curl wget curl-devel nodejs
## Install python3
buildah run $ctr -- yum install -y centos-release-scl-rh
buildah run $ctr -- yum install -y rh-python35-runtime rh-python35-PyYAML \
    rh-python35-python rh-python35-python-devel rh-python35-python-lib \
    rh-git29-git

# Symlink SCL python3 in /usr
pushd $mnt
    for i in opt/rh/rh-python35/root/lib64/libpython3*; do
        ln -s /$i usr/lib64/$(basename $i)
    done
    for i in opt/rh/rh-python35/root/lib/python3*; do
        ln -s /$i usr/lib/$(basename $i)
    done
    for i in opt/rh/rh-python35/root/bin/python3*; do
        ln -s /$i bin/$(basename $i)
    done
popd

# Install AWX test requirements
buildah run $ctr -- yum install -y epel-release
buildah run $ctr -- yum update -y
buildah run $ctr -- yum install -y openssh-server ansible mg vim tmux git \
    python-devel python-psycopg2 make python-psutil libxml2-devel \
    libxslt-devel libstdc++.so.6 gcc cyrus-sasl-devel cyrus-sasl \
    openldap-devel libffi-devel zeromq-devel python-pip xmlsec1-devel swig \
    krb5-devel xmlsec1-openssl xmlsec1 xmlsec1-openssl-devel \
    libtool-ltdl-devel bubblewrap zanata-python-client gettext gcc-c++ \
    libcurl-devel python-pycurl bzip2 postgresql postgresql-devel
buildah run $ctr -- git clone --depth 1 https://github.com/ansible/awx
buildah run $ctr -- make -C awx requirements_dev
buildah run $ctr -- localedef -c -i en_US -f UTF-8 en_US.UTF-8
# Cleanup
buildah run $ctr -- yum clean all
buildah run $ctr -- rm -Rf /root/.cache /awx

# Setup user environment
buildah run $ctr -- useradd -m zuul

## Include some buildtime annotations
buildah config --annotation \
    "io.softwarefactory-project.build.host=$(uname -n)" $ctr
buildah config --author tdecacqu@redhat.com $ctr
buildah config --cmd "/bin/bash" $ctr
buildah config --workingdir /tmp $ctr
buildah config --user zuul $ctr

## Commit this container to an image name
buildah umount $ctr
buildah commit $ctr awx-test-image
buildah delete $ctr

echo "Push running:"
echo "sudo buildah push --creds=tdecacqu awx-test-image \\"
echo "  docker://docker.io/softwarefactoryproject/awx-test-image"
