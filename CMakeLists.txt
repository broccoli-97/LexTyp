cmake_minimum_required(VERSION 3.16)

project(LexTyp VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Widgets Pdf)

qt_add_executable(LexTyp
    src/main.cpp
    src/TypstManager.cpp
    src/DocumentModel.cpp
    src/TypstSerializer.cpp
    src/PdfManager.cpp
    src/bib/BibParser.cpp
    src/oscola/OscolaFormatter.cpp
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
