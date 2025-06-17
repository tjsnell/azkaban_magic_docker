FROM openjdk:8-jdk-slim

# Install necessary tools
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt/azkaban

# Clone Azkaban source and build solo server
RUN git clone https://github.com/azkaban/azkaban.git /tmp/azkaban \
    && cd /tmp/azkaban \
    && git checkout 3.81.0 \
    && ./gradlew clean build installDist -x test \
    && cp -r azkaban-solo-server/build/install/azkaban-solo-server/* /opt/azkaban/ \
    && rm -rf /tmp/azkaban

# Create necessary directories
RUN mkdir -p /opt/azkaban/logs /opt/azkaban/extlib

# Copy configuration
COPY azkaban.properties /opt/azkaban/conf/
COPY azkaban-users.xml /opt/azkaban/conf/

# Expose port
EXPOSE 8081

# Start Azkaban solo server
CMD ["./bin/start-solo.sh"]