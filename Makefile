export GO15VENDOREXPERIMENT := 1

all: build manifests

generate:
	hack/dockerized "hack/glide-checksync.sh && ./hack/generate.sh"

apidocs:
	hack/dockerized "hack/glide-checksync.sh && ./hack/generate.sh && ./hack/gen-swagger-doc/gen-swagger-docs.sh v1 html"

build:
	hack/dockerized "hack/glide-checksync.sh && ./hack/check.sh && ./hack/build-go.sh install ${WHAT}"

goveralls:
	hack/dockerized "hack/glide-checksync.sh && ./hack/check.sh && ./hack/build-go.sh install && TRAVIS_JOB_ID=${TRAVIS_JOB_ID} TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST} TRAVIS_BRANCH=${TRAVIS_BRANCH} ./hack/goveralls.sh"

test:
	hack/dockerized "hack/glide-checksync.sh && ./hack/check.sh && ./hack/build-go.sh install ${WHAT} && ./hack/build-go.sh test ${WHAT}"

functest:
	hack/functests.sh

clean:
	hack/dockerized "./hack/build-go.sh clean ${WHAT} && rm _out/* -rf && rm tools/openapispec/openapispec -rf"
	rm tools/openapispec/openapispec -rf

distclean: clean
	hack/dockerized "rm -rf vendor/ && rm -f .glide.*.hash && glide cc"
	rm -rf vendor/

checksync:
	hack/dockerized	hack/glide-checksync.sh
 
sync:
	hack/dockerized "glide install --strip-vendor && md5sum glide.lock > .glide.lock.hash"

docker: build
	hack/build-docker.sh build ${WHAT}

publish: docker
	hack/build-docker.sh push ${WHAT}

manifests:
	hack/dockerized ./hack/build-manifests.sh

.release-functest:
	make functest > .release-functest 2>&1

release-announce: .release-functest
	./hack/release-announce.sh $(RELREF) $(PREREF)

cluster-up:
	./cluster/up.sh

cluster-down:
	./cluster/down.sh

cluster-build:
	./cluster/build.sh

cluster-deploy:
	./cluster/deploy.sh

cluster-sync: cluster-build cluster-deploy

.PHONY: build test clean distclean checksync sync docker manifests publish functest release-announce cluster-up cluster-down cluster-deploy cluster-sync
