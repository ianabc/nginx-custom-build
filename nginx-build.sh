#!/bin/bash

# Create directories if not already present
rpmdev-setuptree

# Obtain a location for the patches, either from /app (Docker)
# or cloned from GitHub (if run stand-alone).
if [ -d '/app' ]; then
    patch_dir='/app'
else
    patch_dir=$(mktemp)
    git clone https://github.com/ianabc/nginx-custom-build.git "$patch_dir"
fi
cp "$patch_dir/nginx-centos-7.repo" /etc/yum.repos.d/
cp "$patch_dir/nginx-shibboleth.patch" ~/rpmbuild/SPECS/
# Remove temp directory if not Docker
if ! [ -d '/app' ]; then
    rm -rf "$patch_dir"
fi

# Download specific nginx version or just the latest version
if [ "$_NGINX_VERSION" ]; then
    yumdownloader --source "nginx-$_NGINX_VERSION"
else
    yumdownloader --source nginx
fi
if ! [ $? -eq 0 ]; then
    echo "Couldn't download nginx source RPM. Aborting build."
    exit 1
fi

sudo rpm -ihv nginx*.src.rpm

#Get various add-on modules for nginx
pushd ~/rpmbuild/SOURCES

    #Headers More module
    git clone https://github.com/openresty/headers-more-nginx-module
    pushd headers-more-nginx-module
    git checkout v0.30rc1
    popd

    #Shibboleth module
    git clone https://github.com/nginx-shib/nginx-http-shibboleth.git
    pushd nginx-http-shibboleth
    git checkout development
    popd

popd

#Prep and patch the nginx specfile for the RPMs
pushd ~/rpmbuild/SPECS
    patch -p1 < nginx-shibboleth.patch
    spectool -g -R nginx.spec
    yum-builddep -y nginx.spec
    rpmbuild -ba nginx.spec

    if ! [ $? -eq 0 ]; then
        echo "RPM build failed. See the output above to establish why."
        exit 1
    fi
popd
