#/bin/bash
# Set working directory to the one where this script is.
cd "${0%/*}"

GPP_ARGS="-std=c++11"
EXE_NAME=owgen;

mkdir build
cd build

g++ ${GPP_ARGS} -c ../main.cpp \
../dep/docx-factory/src/WordProcessingCompiler.cpp \
../dep/docx-factory/src/WordProcessingMerger.cpp \
-I/opt/DocxFactory/include

g++ ${GPP_ARGS} -o ${EXE_NAME} main.o \
WordProcessingCompiler.o WordProcessingMerger.o \
-L../dep/docx-factory/lib -l:libDocxFactory.so

mv ${EXE_NAME} ../