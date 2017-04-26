#!/bin/bash
#
# This script documents how to rebuild the RPM for irclib 0.4.8 for the zipfile provided by the
# project. It also contains a fixed version of the SPEC files - as one provided uses deprecated
# instruction, but also ran into a bug with its changelog.
#
# This script can be easily run into a docker container to avoid installing software or change
# the rpm bases of the workstation:
#
#   $ docker run --workdir "$(pwd)" -v $(pwd):$(pwd) -ti docker.io/fedora /bin/bash
#   # ./build-rpm.sh
#

readonly ZIPFILE_URL=${1:-'https://github.com/jaraco/irc/archive/version_0_4_8.zip'}
readonly ZIPFILE_ROOT_FOLDER=${ZIPFILE_ROOT_FOLDER:-'irc-version_0_4_8'}

readonly TARBALL=${2:-'python-irclib-0.4.8.tar.gz'}


readonly FIXED_SPECFILE_TEMPLATE="$(pwd)/python-irclib.spec"

readonly WORK_DIR=${3:-$(pwd)}

echo "1 - Checking that required packages are installed"
yum install -y python wget unzip zip make tar rpm-build

echo "2 - Retrieve archive from upstream website"
readonly ZIPFILE=${ZIPFILE:-$(mktemp)}
wget "${ZIPFILE_URL}" -O "${ZIPFILE}"

readonly BUILD_DIR=${BUILD_DIR:-$(mktemp -d)}
unzip "${ZIPFILE}" -d "${BUILD_DIR}"

echo "3 - Update SPEC file from upstream"
cp "${FIXED_SPECFILE_TEMPLATE}" "${BUILD_DIR}/${ZIPFILE_ROOT_FOLDER}/python-irclib.spec.in"

echo "4 - Build upstream project"
mkdir -p "${WORK_DIR}/SOURCES"
cd "${BUILD_DIR}/${ZIPFILE_ROOT_FOLDER}"
make dist
if [ ! -e "${TARBALL}" ]; then
  echo "Failed to build the tarball required for RPM generation."
  exit 1
else
  cp "${TARBALL}" "${WORK_DIR}/SOURCES/"
fi
cd -

echo "5 - Generate RPM"
rpmbuild --define "_topdir ${WORK_DIR}" -bb "${BUILD_DIR}/${ZIPFILE_ROOT_FOLDER}/python-irclib.spec"
if [ ! -e ${WORK_DIR}/RPMS/noarch/*.rpm ]; then
  echo "No RPM generated."
  exit 2
else
  cp ${WORK_DIR}/RPMS/noarch/*.rpm .
fi
echo "6 - Clean up - delete both build directory and RPM work directory"
rm -rf "${BUILD_DIR}" "${WORK_DIR}"
