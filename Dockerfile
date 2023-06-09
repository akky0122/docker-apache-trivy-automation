FROM redhat/ubi8

# Update the system and install necessary packages
RUN dnf -y update && dnf -y install wget tar gcc pcre-devel openssl-devel apr-devel apr-util-devel make redhat-rpm-config

# Download and extract Apache source code
RUN cd /usr/local/src \
    && wget -qO- https://www.apache.org/dist/httpd/httpd-2.4.57.tar.gz | tar xz --strip-components=1 -C /usr/local/src

# Configure, compile, and install Apache
RUN cd /usr/local/src \
    && ./configure \
    && make \
    && make install

# Install Java
RUN dnf -y install java-11-openjdk-devel

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Set ServerName directive
#RUN echo "ServerName localhost" >> /usr/local/apache2/conf/httpd.conf


# Copy configuration file
COPY ./httpd.conf ./httpd.conf

# Expose port 80 for Apache
EXPOSE 80

CMD ["/usr/local/apache2/bin/httpd", "-D", "FOREGROUND", "-DNO_DETACH"]

