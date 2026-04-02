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
    src/ast/DocumentNode.cpp
    src/oscola/OscolaFormatter.cpp
    src/citation/CitationFormatter.cpp
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
        qml/NavigationBar.qml
        qml/PdfPreview.qml
        qml/SidePanel.qml
        qml/CitationPanel.qml
        qml/blocks/TitleBlock.qml
        qml/blocks/ParagraphBlock.qml
        qml/blocks/CitationBlock.qml
        qml/blocks/SectionBlock.qml
        qml/blocks/BlockToolbar.qml
        qml/blocks/BlockDelegate.qml
        qml/blocks/BlockListView.qml
    NO_CACHEGEN
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

# --- Typst Binary Management ---
include(FetchContent)

set(TYPST_VERSION "v0.13.0")
if(APPLE)
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(TYPST_ARCH "aarch64-apple-darwin")
    else()
        set(TYPST_ARCH "x86_64-apple-darwin")
    endif()
    set(TYPST_EXT "tar.xz")
elseif(WIN32)
    set(TYPST_ARCH "x86_64-pc-windows-msvc")
    set(TYPST_EXT "zip")
    set(TYPST_EXE ".exe")
else()
    # Assume Linux
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
        set(TYPST_ARCH "aarch64-unknown-linux-musl")
    else()
        set(TYPST_ARCH "x86_64-unknown-linux-musl")
    endif()
    set(TYPST_EXT "tar.xz")
endif()

set(TYPST_URL "https://github.com/typst/typst/releases/download/${TYPST_VERSION}/typst-${TYPST_ARCH}.${TYPST_EXT}")

FetchContent_Declare(
    typst_bin
    URL ${TYPST_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# This command will only download if the binary is missing or has changed
FetchContent_MakeAvailable(typst_bin)

# The binary is at the root of the extracted source directory
set(TYPST_SOURCE "${typst_bin_SOURCE_DIR}/typst${TYPST_EXE}")

# Copy Typst binary next to the built executable
if(EXISTS "${TYPST_SOURCE}")
    add_custom_command(TARGET LexTyp POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_FILE_DIR:LexTyp>/resources/bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${TYPST_SOURCE}"
            "$<TARGET_FILE_DIR:LexTyp>/resources/bin/typst${TYPST_EXE}"
        COMMENT "Copying Typst binary to output directory"
    )
else()
    message(WARNING "Typst binary not found at ${TYPST_SOURCE} after download.")
endif()
