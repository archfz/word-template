#/bin/bash
# Set working directory to the one where this script is.
cd "${0%/*}"

# -D_GLIBCXX_USE_CXX11_ABI=0 Adds compatibility for older ABI versions.
GPP_ARGS="-std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0"
EXE_NAME=owgen;

g++ ${GPP_ARGS} -c main.cpp \
dep/docx-factory/src/WordProcessingCompiler.cpp \
dep/docx-factory/src/WordProcessingMerger.cpp \
-Idep/docx-factory/include

g++ ${GPP_ARGS} -o ${EXE_NAME} main.o \
WordProcessingCompiler.o WordProcessingMerger.o \
-Llib -l:libDocxFactory.so \
-Wl,-rpath,'$ORIGIN/lib' \
-Wl,-rpath-link,'./lib'

rm WordProcessingCompiler.o WordProcessingMerger.o main.o