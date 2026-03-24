cmake_minimum_required(VERSION 3.21)

project(LexTyp VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Export compile_commands.json for clang-tidy and IDE tooling
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Optional: enable clang-tidy via CMake variable
# Usage: cmake -DENABLE_CLANG_TIDY=ON ..
option(ENABLE_CLANG_TIDY "Run clang-tidy during build" OFF)
if(ENABLE_CLANG_TIDY)
    find_program(CLANG_TIDY_EXE NAMES clang-tidy clang-tidy-18 clang-tidy-17 clang-tidy-16)
    if(CLANG_TIDY_EXE)
        message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
        set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
    else()
        message(WARNING "ENABLE_CLANG_TIDY is ON but clang-tidy not found")
    endif()
endif()

# Compiler warnings
option(ENABLE_WARNINGS "Enable compiler warnings" ON)
if(ENABLE_WARNINGS)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-Wall -Wextra -Wpedantic -Wshadow -Wnon-virtual-dtor)
    elseif(MSVC)
        add_compile_options(/W4 /permissive-)
    endif()
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Quick Widgets Pdf)

qt_add_executable(LexTyp
    src/main.cpp
    src/TypstManager.cpp
    src/DocumentModel.cpp
    src/TypstSerializer.cpp
    src/PdfManager.cpp
    src/bib/BibParser.cpp
    src/bib/ReferenceLibrary.cpp
    src/oscola/OscolaFormatter.cpp
    src/citation/CitationFormatter.cpp
    src/citation/TexTemplateParser.cpp
    src/citation/CitationStyleRegistry.cpp
    src/citation/ApaFormatter.cpp
    src/citation/HarvardFormatter.cpp
    src/citation/ChicagoFormatter.cpp
    src/citation/IeeeFormatter.cpp
    src/citation/PlainFormatter.cpp
)

qt_add_qml_module(LexTyp
    URI LexTyp
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/PdfPreview.qml
        qml/SidePanel.qml
        qml/CitationPanel.qml
        qml/blocks/TitleBlock.qml
        qml/blocks/ParagraphBlock.qml
        qml/blocks/CitationBlock.qml
        qml/blocks/BlockToolbar.qml
        qml/blocks/BlockDelegate.qml
        qml/blocks/BlockListView.qml
)

target_include_directories(LexTyp PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/ast
    ${CMAKE_SOURCE_DIR}/src/bib
    ${CMAKE_SOURCE_DIR}/src/oscola
    ${CMAKE_SOURCE_DIR}/src/citation
)

target_link_libraries(LexTyp PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    Qt6::Pdf
)

# Copy Typst binary next to the built executable
set(TYPST_SOURCE "${CMAKE_SOURCE_DIR}/resources/bin/typst")
if(EXISTS "${TYPST_SOURCE}")
    add_custom_command(TARGET LexTyp POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_FILE_DIR:LexTyp>/resources/bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${TYPST_SOURCE}"
            "$<TARGET_FILE_DIR:LexTyp>/resources/bin/typst"
    )
endif()
