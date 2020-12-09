SB_ROOT=~/Documents/Code/SIRF-SuperBuild
SB_Source=${SB_ROOT}/Source
SB_Build=${SB_ROOT}/Build
SB_Install=${SB_ROOT}/Install

PY_EXE=$(which python3)

# Get to SB root
mkdir -p "${SB_ROOT}"
cd "${SB_ROOT}"

# If source folder not there, clone it
if [ ! -d "${SB_Source}" ]; then
	git clone https://github.com/CCPPETMR/SIRF-SuperBuild.git "${SB_Source}"
fi

# Install pre-requisites
sudo apt install -y libboost-all-dev \
	libfftw3-dev swig libarmadillo-dev

${PY_EXE} -m pip install -U nose numpy matplotlib scipy \
	coverage docopt deprecation nibabel pillow cython wget h5py

sudo apt install g++-6
export CC=gcc-6
export CXX=g++-6

# Go to build dir
mkdir -p "${SB_Build}"
cd "${SB_Build}"

cmake ${SB_Source}  \
	\
	-DCMAKE_INSTALL_PREFIX:FILEPATH=${SB_Install} \
	-DCMAKE_BUILD_TYPE:STRING=RELEASE \
	\
	-DPYTHON_EXECUTABLE:PATH=${PY_EXE} \
	\
	-DDISABLE_CUDA:BOOL=ON \
	\
	-DUSE_SYSTEM_ACE:BOOL=ON \
	-DUSE_SYSTEM_Armadillo:BOOL=ON \
	-DUSE_SYSTEM_Boost:BOOL=ON \
	-DUSE_SYSTEM_SWIG:BOOL=ON \
	-DUSE_SYSTEM_FFTW3:BOOL=ON \
	-DUSE_ITK:BOOL=ON \
	-DUSE_SYSTEM_ITK:BOOL=OFF \
	-DITK_SHARED_LIBS:BOOL=OFF \
	\
	-DDEVEL_BUILD:BOOL=ON \
	-DBUILD_CIL_LITE:BOOL=ON \
	\
	-DSTIR_BUILD_EXECUTABLES:BOOL=ON \
	-DBUILD_TESTING_STIR:BOOL=ON \
	-DSTIR_ENABLE_EXPERIMENTAL:BOOL=ON \
	\
	-DSIRF_URL:STRING=https://github.com/rijobro/SIRF.git \
	-DSIRF_TAG:STRING=fix_HDF5_matlab
	# \
	# -DDISABLE_GIT_CHECKOUT_STIR:BOOL=ON \
	# -DDISABLE_GIT_CHECKOUT_SIRF:BOOL=ON \
	# -DUSE_SYSTEM_HDF5:BOOL=ON \

num_cores_avail=$(grep -c ^processor /proc/cpuinfo)
num_cores_use=$(expr $num_cores_avail - 1)
make -j $num_cores_use

# Gadgetron xml default
cp ${SB_Install}/share/gadgetron/config/gadgetron.xml.example \
	${SB_Install}/share/gadgetron/config/gadgetron.xml

# Nothing to do if no .bashrc
bashrc=~/.bashrc
if [ ! -f $bashrc ]; then
	echo "Looks like there's no bashrc, exiting..."
	exit 1
fi

# If not already appended
if ! grep -q "env_ccppetmr.sh" $bashrc; then
	echo -e "\n" \
  			"################\n" \
  			"# SIRF         #\n" \
  			"################\n" \
  			"\n" \
			"# SIRF-SB\n" \
			"source ${SB_Install}/bin/env_ccppetmr.sh\n" \
			"\n" \
			"# SIRF-SuperBuild\n" \
			"alias cdSB='cdCode && cd SIRF-SuperBuild'\n" \
			"alias cdSBs='cd ${SB_Source}'\n" \
			"alias cdSBb='cd ${SB_Build}'\n" \
			"alias cdSBi='cd ${SB_Install}'\n" \
			"# SIRF\n" \
			"alias cdSIs='cdSBb && cd sources/SIRF'\n" \
			"alias cdSIb='cdSBb && cd builds/SIRF/build'\n" \
			"# STIR\n" \
			"alias cdSTs='cdSBb && cd sources/STIR'\n" \
			"alias cdSTb='cdSBb && cd builds/STIR/build'\n" \
				>> $bashrc

	echo "You now need to run 'source ~/.bashrc'"
fi