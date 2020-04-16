#!/bin/bash -x
set -e

PROJECT_REPO=github.com/openshift/oauth-proxy
DOCKER_REPO=quay.io/xk96
KUBECONFIG=/root/.kube/config
TEST_NAMESPACE=wxk-project

REV=e2e_test_s390
#REV=$(git rev-parse --short HEAD)
TEST_IMAGE="quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:23341e8550cc066abf1651efadd219264cfb6a39eca2bc8e42dd5bde696a3294"
TEST_DIR=$(pwd)/test
HELLO_PATH=${TEST_DIR}/e2e/hello
HELLO_IAMGE="docker.io/xk96/hello-openshift:s390x"
ORIGIN_BUILD_DIR=/tmp/opbuild
ORIGIN_PATH=${ORIGIN_BUILD_DIR}/src/github.com/openshift/origin

if [ "${1}" == "clusterup" ]; then
	if [ "${2}" != "nobuild" ]; then
		if [ ! -d "${ORIGIN_BUILD_DIR}/src" ]; then
			mkdir -p ${ORIGIN_BUILD_DIR}/src
		fi
		GOPATH=${ORIGIN_BUILD_DIR} go get github.com/openshift/origin
		pushd .
		cd ${ORIGIN_PATH}
		# Stabilize on a known working 3.9 commit just for assurance.
                git checkout release-3.9
		popd
		GOPATH=${ORIGIN_BUILD_DIR} ${ORIGIN_PATH}/hack/build-go.sh
	fi
	export PATH=${ORIGIN_PATH}/_output/local/bin/linux/s390x/:${PATH}
	oc version

	# Run bindmountproxy for a non-localhost OpenShift endpoint
	IP=$(openshift start --print-ip)
	docker run --privileged --net=host -v /var/run/docker.sock:/var/run/docker.sock -d --name=bindmountproxy docker.io/xk96/bindmountproxy:s390x proxy ${IP}:2375 $(which openshift)
	sleep 2
	docker_host=tcp://${IP}:2375
        DOCKER_HOST=${docker_host} 
        oc cluster up --public-hostname=9.152.84.163 --logging=true -e DOCKER_HOST=${docker_host} --image="clefos/origin" --version="v3.9.0" --server-loglevel=0
        sudo cp /var/lib/origin/openshift.local.config/master/admin.kubeconfig ~/
	sudo chmod 777 ${KUBECONFIG}
	oc login -u developer -p pass
	oc project ${TEST_NAMESPACE}
	oc status
fi

# build backend site
#go build -o ${HELLO_PATH}/hello_openshift ${PROJECT_REPO}/test/e2e/hello
#sudo docker build -t ${HELLO_IMAGE} ${HELLO_PATH}
#sudo docker push ${HELLO_IMAGE}

# build oauth-proxy
#go build -o ${TEST_DIR}/oauth-proxy
#sudo docker build -t ${TEST_IMAGE} ${TEST_DIR}/
#sudo docker push ${TEST_IMAGE}

# run test
export TEST_IMAGE TEST_NAMESPACE HELLO_IMAGE KUBECONFIG
go test -v ${PROJECT_REPO}/test/e2e
