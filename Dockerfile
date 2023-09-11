FROM amazonlinux:2

# Set up working directories
RUN mkdir -p /opt/app
RUN mkdir -p /opt/app/build
RUN mkdir -p /opt/app/bin/

# Copy in the lambda source
WORKDIR /opt/app
COPY ./*.py /opt/app/
COPY requirements.txt /opt/app/requirements.txt

# Install packages
RUN yum update -y
RUN yum install -y cpio python3-pip yum-utils zip unzip less
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum install -y amazon-linux-extras
RUN amazon-linux-extras enable python3.8
RUN yum -y install python3.8

# This had --no-cache-dir, tracing through multiple tickets led to a problem in wheel
RUN python3.8 -m pip install -r requirements.txt
RUN rm -rf /root/.cache/pip

# Download libraries we need to run in lambda
WORKDIR /tmp
RUN yumdownloader -x \*i686 --archlist=x86_64,aarch64 \
        clamav clamav-lib clamav-update \
        pcre2 libtool-ltdl libxml2 bzip2-libs \
        xz-libs libprelude gnutls nettle libcurl \
        libnghttp2 libidn2 libssh2 openldap \
        libunistring cyrus-sasl-lib nss pcre

RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv
RUN rpm2cpio libtool-ltdl*.rpm | cpio -idmv
RUN rpm2cpio libxml2*.rpm | cpio -idmv
RUN rpm2cpio bzip2-libs*.rpm | cpio -idmv
RUN rpm2cpio xz-libs*.rpm | cpio -idmv
RUN rpm2cpio libprelude*.rpm | cpio -idmv
RUN rpm2cpio gnutls*.rpm | cpio -idmv
RUN rpm2cpio nettle*.rpm | cpio -idmv
RUN rpm2cpio libcurl*.rpm | cpio -idmv
RUN rpm2cpio libnghttp2*.rpm | cpio -idmv
RUN rpm2cpio libidn2*.rpm | cpio -idmv
RUN rpm2cpio libssh2*.rpm | cpio -idmv
RUN rpm2cpio openldap*.rpm | cpio -idmv
RUN rpm2cpio libunistring*.rpm | cpio -idmv
RUN rpm2cpio cyrus-sasl-lib-2*.rpm | cpio -idmv
RUN rpm2cpio nss*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv

# Copy over the binaries and libraries
RUN cp /tmp/usr/bin/clamscan /tmp/usr/bin/freshclam /tmp/usr/lib64/* /opt/app/bin/

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/bin/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/bin/freshclam.conf

ENV LD_LIBRARY_PATH=/opt/app/bin
RUN ldconfig

# Create the zip file
WORKDIR /opt/app
RUN zip -r9 --exclude="*test*" /opt/app/build/lambda.zip *.py bin

WORKDIR /usr/local/lib/python3.8/site-packages
RUN zip -r9 /opt/app/build/lambda.zip *

WORKDIR /opt/app
