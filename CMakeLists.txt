cmake_minimum_required(VERSION 3.21)
project(MTGTrackerDesktop VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2)

qt_add_executable(MTGTrackerDesktop WIN32
    src/main.cpp
    src/DeckStore.cpp
    src/DeckStore.h
)

target_link_libraries(MTGTrackerDesktop PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
)

qt_add_resources(MTGTrackerDesktop "desktop_qml"
    PREFIX "/"
    FILES
        qml/Main.qml
        qml/DeckCard.qml
        qml/CounterChip.qml
        qml/DeckEditor.qml
        qml/DeckLinks.qml
)

set_target_properties(MTGTrackerDesktop PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

if(MSVC)
    target_compile_options(MTGTrackerDesktop PRIVATE /W4 /EHsc)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(MTGTrackerDesktop PRIVATE -Wall -Wextra -Wpedantic)
endif()
