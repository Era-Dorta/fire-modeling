# This instructions have only been tested on Ubuntu 14.04

################################################################################
# Uintah
################################################################################

# Dependencies
sudo apt-get install libhypre-dev petsc-dev libxml2-dev zlib1g-dev liblapack-dev libglew-dev libxmu-dev gfortran libboost-all-dev libxrender-dev libxi-dev

# Download the software from
# http://uintah.utah.edu/

# Deactive git certificates for this session, their server shows as not trusted otherwise
export GIT_SSL_NO_VERIFY=1

mkdir build && cd build

# Edit SpatialOps server location
gedit src/build_scripts/build_wasatch_3p.sh&
# Change line 99
# run "git clone --depth 1 --branch Uintah1.6.0 git://software.crsim.utah.edu/SpatialOps.git SpatialOps"
# To 
# run "git clone --depth 1 https://software.crsim.utah.edu:8443/James_Research_Group/SpatialOps.git"
# Change line 139
# run "git clone --depth 1 --branch Uintah1.6.0 git://software.crsim.utah.edu/ExprLib.git ExprLib"
# To
# run "git clone --depth 1  --branch Uintah1.6.0 https://software.crsim.utah.edu:8443/James_Research_Group/ExprLib.git"

# Change line 177
# run "git clone --depth 1 --branch Uintah1.6.0 git://software.crsim.utah.edu/TabProps.git TabProps"
# To
# run "git clone --depth 1 --branch Uintah1.6.0 https://software.crsim.utah.edu:8443/James_Research_Group/TabProps.git"

# Change line 208
# run "git clone --depth 1 --branch Uintah1.6.0 git://software.crsim.utah.edu/RadProps.git RadProps"
# To
# run "git clone --depth 1 --branch Uintah1.6.0 https://software.crsim.utah.edu:8443/James_Research_Group/RadProps.git"

../src/configure '--enable-optimize=-O3 -mfpmath=sse' --enable-all-components --enable-wasatch_3p --enable-64bit --with-petsc=/usr/lib/petscdir/3.4.2/ --with-hypre=/usr/  --with-boost=/usr/

make -j8

################################################################################
# VisIt
################################################################################

##############
# Precompiled
##############

# Go to compiling if you are on linux and mac, as we need the pluging to visualize
# the uintah data and it is not included in the precompiled version

# Download the install script visit-install from the previous site
# With the .tar.gz and the .sh on the same folder execute
# sudo ./visit-install version platform destination
# In our case: sudo ./visit-install 2.9.2 linux-x86_64-ubuntu14 /usr/local/visit

# Add path to bash_rc
# export PATH=/usr/local/visit/bin:$PATH

##############
# Compiling
##############

# This is needed for the visualization plugin on linux and mac

# Download the build script from
# https://wci.llnl.gov/simulation/computer-codes/visit/executables

# Create a build directory and place script there
mkdir build && cd build

# Create a 3rparty folder
mkdir 3rdparty

export PAR_COMPILER=$(which mpicxx)
export PAR_COMPILER_CXX=$(which mpicxx)
export PAR_INCLUDE="-I/usr/include/mpi/"

# Run the script with
# It will rebuild uintah but it looks like it is necessary for the visualization plugin
# but this uintah version will fail on some examples, so both versions are needed
# if we do not want to waste time fixing it
./build_visit.sh --thirdparty-path ./3rdparty --makeflags -j8 --no-icet --uintah

# Visit should be built in 
./visit2.9.2/src/bin/visit
