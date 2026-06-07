ARG MDBOOK_VERSION=0.5.3
ARG MDBOOK_PLANTUML_VERSION=2.0.0
ARG MDBOOK_MERMAID_VERSION=0.17.0
ARG PLANTUML_VERSION=1.2026.5
ARG PLANTUML_SHA256=de65ffc34b5c7fdad4e86309ce2dcceff98778799ae17b93a8f492d7a69080e1

FROM rust:slim-bookworm AS builder
ARG MDBOOK_VERSION
ARG MDBOOK_PLANTUML_VERSION
ARG MDBOOK_MERMAID_VERSION
RUN cargo install mdbook --version ${MDBOOK_VERSION}
RUN cargo install mdbook-plantuml --version ${MDBOOK_PLANTUML_VERSION} --no-default-features
RUN cargo install mdbook-mermaid --version ${MDBOOK_MERMAID_VERSION}

FROM debian:bookworm-slim AS downloader
ARG PLANTUML_VERSION
ARG PLANTUML_SHA256
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q -O /plantuml.jar \
    https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar \
    && echo "${PLANTUML_SHA256}  /plantuml.jar" | sha256sum -c -

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    graphviz \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*
COPY --from=downloader /plantuml.jar /usr/local/lib/plantuml.jar
RUN printf '#!/bin/sh\n\
if [ -n "$PLANTUML_INCLUDE_PATH" ]; then\n\
  exec java "-Dplantuml.include.path=$PLANTUML_INCLUDE_PATH" -jar /usr/local/lib/plantuml.jar -charset UTF-8 "$@"\n\
fi\n\
exec java -jar /usr/local/lib/plantuml.jar -charset UTF-8 "$@"\n' \
    > /usr/local/bin/plantuml \
    && chmod +x /usr/local/bin/plantuml
COPY --from=builder \
    /usr/local/cargo/bin/mdbook \
    /usr/local/cargo/bin/mdbook-plantuml \
    /usr/local/cargo/bin/mdbook-mermaid \
    /usr/local/bin/
RUN useradd -m -u 1000 mdbook
USER mdbook
WORKDIR /book
ENTRYPOINT ["mdbook"]
