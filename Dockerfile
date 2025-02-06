#
# Build
#

FROM registry.redhat.io/openshift4/ose-tools-rhel9@sha256:f29742d55f6093496718251e2fa03a748bbcb26617fcc6188799190b5bd1e7b5 AS ose-tools
FROM registry.access.redhat.com/ubi9/go-toolset:1.22.9-1736729788 AS builder

USER root
WORKDIR /workdir/rhtap-cli

COPY installer/ ./installer/

COPY cmd/ ./cmd/
COPY pkg/ ./pkg/
COPY vendor/ ./vendor/

COPY go.mod go.sum Makefile ./

RUN make GOFLAGS='-buildvcs=false'

#
# Run
#

FROM registry.access.redhat.com/ubi9-minimal:9.5-1736404155

LABEL \
  name="rhtap-cli" \
  com.redhat.component="rhtap-cli" \
  description="Red Hat Trusted Application Pipeline allows organizations to curate their own trusted, repeatable pipelines \
        that stay compliant with industry requirements. Built on proven, trusted open source technologies, Red Hat \
        Trusted Application Pipeline is part of Red Hat Trusted Software Supply Chain, a set of solutions to protect \ 
        users, customers, and partners from risks and vulnerabilities in their software factory." \
  io.k8s.description="Red Hat Trusted Application Pipeline allows organizations to curate their own trusted, repeatable pipelines \
  that stay compliant with industry requirements. Built on proven, trusted open source technologies, Red Hat \
  Trusted Application Pipeline is part of Red Hat Trusted Software Supply Chain, a set of solutions to protect \ 
  users, customers, and partners from risks and vulnerabilities in their software factory." \
  summary="Provides the binaries for downloading the RHTAP CLI." \
  io.k8s.display-name="Red Hat Trusted Application Pipeline CLI" \
  io.openshift.tags="rhtap-cli tas tpa rhdh ec tap openshift"

WORKDIR /rhtap-cli

COPY --from=ose-tools /usr/bin/kubectl /usr/bin/

COPY --from=builder /workdir/rhtap-cli/installer ./
COPY --from=builder /workdir/rhtap-cli/bin/rhtap-cli /usr/local/bin/rhtap-cli

RUN groupadd --gid 1000 -r rhtap-cli && \
    useradd -r -d /rhtap-cli -g rhtap-cli -s /sbin/nologin --uid 1000 rhtap-cli

USER rhtap-cli

RUN kubectl version --client

ENTRYPOINT ["rhtap-cli"]
