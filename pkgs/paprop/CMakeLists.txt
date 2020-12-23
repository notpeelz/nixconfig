cmake_minimum_required(VERSION 3.2)
project(paprop C)

find_package(PulseAudio REQUIRED)
include_directories(${PULSEAUDIO_INCLUDE_DIRS})
add_executable(${PROJECT_NAME} main.c)
target_link_libraries(${PROJECT_NAME} ${PULSEAUDIO_LIBRARY})
