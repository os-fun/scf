#!/bin/sh
set -e

GIT_ROOT=${GIT_ROOT:-$(git rev-parse --show-toplevel)}

RELEASE=${1}

VERSION_INFO=$("${GIT_ROOT}/bin/get-cf-versions.sh" "${RELEASE}")

CF_RELEASE=$(echo "${VERSION_INFO}" | jq -r .[\"cf-release-commit-sha\"])
DIEGO_RELEASE=v$(echo "${VERSION_INFO}" | jq -r .[\"diego-release-version\"])
CFLINUXFS2_ROOTFS_RELEASE=v$(echo "${VERSION_INFO}" | jq -r .[\"cflinuxfs2-rootfs-release-version\"])
GARDEN_RUNC_RELEASE=v$(echo "${VERSION_INFO}" | jq -r .[\"garden-runc-release-version\"])

update_submodule () {
	release_name=${1}
	commit_id=${2}
	root_dir=${3}
	cd "${GIT_ROOT}/${root_dir}/${release_name}"
	git fetch --all
	cd "${GIT_ROOT}"
	git clone "${root_dir}/${release_name}" "${root_dir}/${release_name}-clone" --recursive
	cd "${root_dir}/${release_name}-clone"
	git fetch --all
	git checkout "${commit_id}"
	git submodule update --init --recursive
}

for release_name in nats-release consul-release loggregator capi-release uaa-release diego-release etcd-release garden-runc-release
do
	clone_dir=${GIT_ROOT}/src/${release_name}-clone
	if test -e "${clone_dir}"
	then
		echo "${clone_dir} already exists from previous upgrade."
		exit 1
	fi
done

BUILDPACK_SUBMODULES="go-buildpack-release \
	              binary-buildpack-release \
                      nodejs-buildpack-release \
                      ruby-buildpack-release \
                      php-buildpack-release \
                      python-buildpack-release \
                      staticfile-buildpack-release \
                      java-buildpack-release"

for release_name in ${BUILDPACK_SUBMODULES}
do
	clone_dir=${GIT_ROOT}/src/buildpacks/${release_name}-clone
	if test -e "${clone_dir}"
	then
		echo "${clone_dir} already exists from previous upgrade."
		exit 1
	fi
done

update_submodule diego-release "${DIEGO_RELEASE}" src
update_submodule cflinuxfs2-rootfs-release "${CFLINUXFS2_ROOTFS_RELEASE}" src
update_submodule garden-runc-release "${GARDEN_RUNC_RELEASE}" src

CF_RELEASE_VERSION_INFO=$(curl --silent "https://api.github.com/repos/cloudfoundry/cf-release/contents/src?ref=${CF_RELEASE}")

GO_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"go-buildpack-release\") | .sha")
BINARY_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"binary-buildpack-release\") | .sha")
NODEJS_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"nodejs-buildpack-release\") | .sha")
RUBY_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"ruby-buildpack-release\") | .sha")
PHP_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"php-buildpack-release\") | .sha")
PYTHON_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"python-buildpack-release\") | .sha")
STATICFILE_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"staticfile-buildpack-release\") | .sha")
JAVA_BUILDPACK_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"java-buildpack-release\") | .sha")

CAPI_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"capi-release\") | .sha")
CONSUL_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"consul-release\") | .sha")
ETCD_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"etcd-release\") | .sha")
LOGGREGATOR=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"loggergator\") | .sha")
NATS_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"nats-release\") | .sha")
UAA_RELEASE=$(echo "${CF_RELEASE_VERSION_INFO}" | jq -r ".[] | select(.name == \"uaa-release\") | .sha")

update_submodule go-buildpack-release "${GO_BUILDPACK_RELEASE}" src/buildpacks
update_submodule binary-buildpack-release "${BINARY_BUILDPACK_RELEASE}" src/buildpacks
update_submodule nodejs-buildpack-release "${NODEJS_BUILDPACK_RELEASE}" src/buildpacks
update_submodule ruby-buildpack-release "${RUBY_BUILDPACK_RELEASE}" src/buildpacks
update_submodule php-buildpack-release "${PHP_BUILDPACK_RELEASE}" src/buildpacks
update_submodule python-buildpack-release "${PYTHON_BUILDPACK_RELEASE}" src/buildpacks
update_submodule staticfile-buildpack-release "${STATICFILE_BUILDPACK_RELEASE}" src/buildpacks
update_submodule java-buildpack-release "${JAVA_BUILDPACK_RELEASE}" src/buildpacks

update_submodule capi-release "${CAPI_RELEASE}" src
update_submodule consul-release "${CONSUL_RELEASE}" src
update_submodule etcd-release "${ETCD_RELEASE}" src
update_submodule loggregator "${LOGGREGATOR}" src
update_submodule nats-release "${NATS_RELEASE}" src
update_submodule uaa-release "${UAA_RELEASE}" src
