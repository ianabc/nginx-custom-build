FROM centos:7
MAINTAINER "Ian Allison" <iana@pims.math.ca>

# Configure EPEL for GeoIP-devel
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Install required packages for building
RUN yum install -y \
  gcc \
  git \
  make \
  rpm-build \
  rpmdevtools \
  sudo \
  yum-utils

# Make the build area available
RUN mkdir -p /app/build

# Expose web ports for nginx
EXPOSE 80 443

# 1. Build
# 2. Test
# 3. Copy the RPMs back to the host volume
CMD /app/nginx-build.sh && \
  yum install -y ~/rpmbuild/RPMS/{noarch,x86_64}/nginx-*.rpm && \
  nginx -t && \
  rsync --no-relative -vahu ~/rpmbuild/RPMS ~/rpmbuild/SRPMS /app/build
