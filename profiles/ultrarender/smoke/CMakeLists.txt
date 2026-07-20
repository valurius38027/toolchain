cmake_minimum_required(VERSION 3.25)
project(UltraRenderSdkSmoke VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui)
find_package(Vulkan REQUIRED)
find_package(GTest CONFIG REQUIRED)
find_package(Freetype REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(HARFBUZZ REQUIRED IMPORTED_TARGET harfbuzz)
find_package(flatbuffers CONFIG REQUIRED)

add_executable(ultrarender_sdk_smoke main.cpp)
target_link_libraries(ultrarender_sdk_smoke PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::GuiPrivate
  Vulkan::Vulkan
  GTest::gtest
  Freetype::Freetype
  PkgConfig::HARFBUZZ
  flatbuffers::flatbuffers
)

enable_testing()
add_test(NAME ultrarender_sdk_smoke COMMAND ultrarender_sdk_smoke)
