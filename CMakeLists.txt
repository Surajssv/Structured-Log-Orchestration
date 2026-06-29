cmake_minimum_required(VERSION 3.10)
project(app_kernel_syslogng LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. Define the executable target
add_executable(${PROJECT_NAME} src/main.cpp)

# 2. Configure the main syslog-ng file from your template source
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/config/app_kernel_syslogng.conf.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.conf"
    @ONLY
)

# 3. Configure the secondary loglevel control file from your template source
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/config/00-loglevel.conf.in"
    "${CMAKE_CURRENT_BINARY_DIR}/00-loglevel.conf"
    @ONLY
)

# 4. Define installation rules
# Installs the binary executable (usually to /usr/local/bin)
install(TARGETS ${PROJECT_NAME} DESTINATION bin)

# Installs BOTH configurations into the syslog-ng inclusion directory
install(
    FILES 
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.conf"
        "${CMAKE_CURRENT_BINARY_DIR}/00-loglevel.conf"
    DESTINATION /etc/syslog-ng/conf.d
)
