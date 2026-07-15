cmake_minimum_required(VERSION 3.25)
project(Qt6ToolchainSmoke VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
  Core
  Gui
  Widgets
  Qml
  Quick
  QuickControls2
  Quick3D
  Test
  Svg
  Multimedia
  WebSockets
  WebChannel
  WebEngineWidgets
  Pdf
)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(qt6_toolchain_smoke
  src/main.cpp
  src/widget_window.cpp
  src/widget_window.h
)

qt_add_qml_module(qt6_toolchain_smoke
  URI ToolchainSmoke
  VERSION 1.0
  QML_FILES
    qml/Main.qml
    qml/Quick3DScene.qml
)

target_link_libraries(qt6_toolchain_smoke PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::Widgets
  Qt6::Qml
  Qt6::Quick
  Qt6::QuickControls2
  Qt6::Quick3D
  Qt6::Svg
  Qt6::Multimedia
  Qt6::WebSockets
  Qt6::WebChannel
  Qt6::WebEngineWidgets
  Qt6::Pdf
)

qt_add_executable(qt6_toolchain_smoke_test
  src/smoke_test.cpp
)
target_link_libraries(qt6_toolchain_smoke_test PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::Qml
  Qt6::Quick3D
  Qt6::Test
)

enable_testing()
add_test(NAME qt6_toolchain_smoke_test COMMAND qt6_toolchain_smoke_test)
set_tests_properties(qt6_toolchain_smoke_test PROPERTIES
  ENVIRONMENT "QT_QPA_PLATFORM=offscreen;LIBGL_ALWAYS_SOFTWARE=1"
)
