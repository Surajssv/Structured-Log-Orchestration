FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    g++ \
    cmake \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the build configuration and source code
COPY CMakeLists.txt ./
COPY src/ ./src/
COPY config/ ./config/

RUN mkdir build && cd build && \
    cmake .. && \
    cmake --build .

CMD ["./build/app_kernel_syslogng"]
