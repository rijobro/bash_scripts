# Want to build from scratch?
# mkdir -p ~/Documents/Code/SIRF-SuperBuild && \
# cd ~/Documents/Code/SIRF-SuperBuild && \
# rm -rf Build && rm -rf Install && \
# mkdir Build && cd Build && \
# mkdir sources && cp -r ~/Desktop/STIR sources && cp -r ~/Desktop/SIRF sources && \
# ../cmake_options.sh && \
# make -j4

# Get matlab executable
if [ "$1" == "" ]; then
	num_matlab_installs=$(ls -d /Applications/MATLAB_R*.app | wc -l | xargs)
	if (( num_matlab_installs != 1 )); then
    	echo Multiple Matlab installations found, please given one as input argument:
    	ls -d -1 /Applications/MATLAB_R*.app
    	exit 1
	fi
	matlab_root=$(ls -d /Applications/MATLAB_*.app)
else
	matlab_root="$1"
fi
echo using matlab root as ${matlab_root}

cmake ../Source \
	\
	-DCMAKE_INSTALL_PREFIX:FILEPATH=$(realpath ../Install) \
	-DCMAKE_BUILD_TYPE:STRING=RELEASE \
	\
	-DDEVEL_BUILD:BOOL=ON \
	\
	-DUSE_SYSTEM_ACE:BOOL=ON \
	-DUSE_SYSTEM_Armadillo:BOOL=ON \
	-DUSE_SYSTEM_Boost:BOOL=ON \
	-DUSE_SYSTEM_GTest:BOOL=ON \
	-DUSE_SYSTEM_HDF5:BOOL=ON \
	-DUSE_SYSTEM_SWIG:BOOL=ON \
	-DUSE_SYSTEM_FFTW3:BOOL=ON \
	\
	-DBUILD_pet_rd_tools:BOOL=ON \
	-DBUILD_siemens_to_ismrmrd:BOOL=ON \
	\
	-DCBLAS_LIBRARY:FILEPATH=$(ls -d /usr/local/Cellar/openblas/*/lib/libopenblasp-r*.dylib) \
	-DCBLAS_INCLUDE_DIR:PATH=$(ls -d /usr/local/Cellar/openblas/*/include) \
	\
	-DGTEST_INCLUDE_DIR:PATH=/Users/rich/Documents/Code/googletest/Install/include/gtest \
	-DGTEST_LIBRARY:FILEPATH=/Users/rich/Documents/Code/googletest/Install/lib/libgtest.a \
	-DGTEST_LIBRARY_DEBUG:FILEPATH=/Users/rich/Documents/Code/googletest/Install/lib/libgtest.a \
	-DGTEST_MAIN_LIBRARY:FILEPATH=/Users/rich/Documents/Code/googletest/Install/lib/libgtest_main.a \
	-DGTEST_MAIN_LIBRARY_DEBUG:FILEPATH=/Users/rich/Documents/Code/googletest/Install/lib/libgtest_main.a \
	\
	-DPYTHON_EXECUTABLE:FILEPATH=$(greadlink -f $(which python3)) \
	\
	-DUSE_ITK:BOOL=ON \
	-DUSE_SYSTEM_ITK:BOOL=ON \
	-DITK_DIR:PATH=/Users/rich/Documents/Code/ITK/Install/lib/cmake/ITK-4.13/ \
	\
	-DMatlab_ROOT_DIR:PATH=${matlab_root} \
	\
	-DUSE_SYSTEM_STIR:BOOL=OFF \
	-DSTIR_BUILD_EXECUTABLES:BOOL=ON \
	-DBUILD_TESTING_STIR:BOOL=ON \
	-DSTIR_ENABLE_EXPERIMENTAL:BOOL=ON \
	\
	-DDISABLE_GIT_CHECKOUT_STIR:BOOL=ON \
	-DDISABLE_GIT_CHECKOUT_SIRF:BOOL=ON \
	\
	-DDISABLE_OpenMP:BOOL=OFF \
	-DSTIR_ENABLE_OPENMP:BOOL=ON \
	-DOpenMP_CXX_LIB_NAMES:STRING="omp" \
	-DOpenMP_C_LIB_NAMES:STRING=libomp \
	-DOpenMP_CXX_LIB_NAMES:STRING=libomp \
	-DNIFTYREG_ENABLE_OPENMP:BOOL=OFF \
	-DGadgetron_ENABLE_OPENMP:BOOL=OFF \
	-DOpenMP_CXX_FLAGS:STRING="-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include" \
	-DOpenMP_C_FLAGS:STRING="-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include" \
	-DOpenMP_libomp_LIBRARY:FILEPATH=/usr/local/opt/libomp/lib/libomp.dylib \
	-DOpenMP_omp_LIBRARY:FILEPATH=/usr/local/opt/libomp/lib/libomp.dylib \

	# MATLAB
	# -DOpenMP_libomp_LIBRARY:FILEPATH=${matlab_root}/toolbox/eml/externalDependency/omp/maci64/lib/libomp.dylib \
	# -DOpenMP_omp_LIBRARY:FILEPATH=${matlab_root}/toolbox/eml/externalDependency/omp/maci64/lib/libomp.dylib \
	# -DOpenMP_CXX_FLAGS:STRING="-Xpreprocessor -fopenmp -I${matlab_root}/toolbox/eml/externalDependency/omp/maci64/include" \
	# -DOpenMP_C_FLAGS:STRING="-Xpreprocessor -fopenmp -I${matlab_root}/toolbox/eml/externalDependency/omp/maci64/include" \

	# CIL
	# -DBUILD_CIL_LITE:BOOL=ON \
	# -DCYTHON_EXECUTABLE:FILEPATH=$(which cython) \
	# -DDISABLE_GIT_CHECKOUT_CCPi-Regularisation-Toolkit:BOOL=ON \
	# \

	## Got everything working with openmp using both Apple Clang and llvm,
	## except matlab. Not sure if this is a boost thing or an libomp.dylib thing.
	## If you're working from Python, all should be fine. The following is for
	## Apple Clang
	# -DDISABLE_OpenMP:BOOL=OFF \
	# -DSTIR_ENABLE_OPENMP:BOOL=ON \
	# -DOpenMP_C_LIB_NAMES:STRING=libomp \
	# -DOpenMP_CXX_LIB_NAMES:STRING=libomp \
	# -DNIFTYREG_ENABLE_OPENMP:BOOL=OFF \
	# -DGadgetron_ENABLE_OPENMP:BOOL=OFF \
	# -DOpenMP_CXX_FLAGS:STRING="-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include" \
	# -DOpenMP_C_FLAGS:STRING="-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include" \
	# -DOpenMP_libomp_LIBRARY:FILEPATH=/usr/local/opt/libomp/lib/libomp.dylib \
	# -DOpenMP_omp_LIBRARY:FILEPATH=/usr/local/opt/libomp/lib/libomp.dylib \

	# If using llvm:
	# -DOpenMP_CXX_FLAGS:STRING="-fopenmp=libiomp5 -I/usr/local/opt/libomp/include" \
	# -DOpenMP_C_FLAGS:STRING="-fopenmp=libiomp5 -I/usr/local/opt/libomp/include" \
	
	# I also tried using the OpenMP libraries that get shipped with Matlab. no luck.
	# -DOpenMP_libomp_LIBRARY:FILEPATH=${matlab_root}/toolbox/eml/externalDependency/omp/maci64/lib/libomp.dylib \
	# -DOpenMP_omp_LIBRARY:FILEPATH=${matlab_root}/toolbox/eml/externalDependency/omp/maci64/lib/libomp.dylib \
	# -DOpenMP_CXX_FLAGS:STRING="-Xpreprocessor -fopenmp -I${matlab_root}/toolbox/eml/externalDependency/omp/maci64/include" \
	# -DOpenMP_C_FLAGS:STRING="-Xpreprocessor -fopenmp -I${matlab_root}/toolbox/eml/externalDependency/omp/maci64/include" \
	