# Derived from https://github.com/swiftlang/swift-docker (Apache License 2.0)
# SPDX-FileCopyrightText: 2025 Exercism and contributors
# SPDX-License-Identifier: Apache-2.0

# Copyright 2025 Exercism
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Exercism Swift Docker Image"
LABEL org.opencontainers.image.description="Docker Container for the Swift Exercism track"
LABEL org.opencontainers.image.source=https://github.com/exercism/swift-docker-base
LABEL org.opencontainers.image.licenses="AGPL-3.0 AND Apache-2.0"

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    binutils \
    git \
    unzip \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libncurses-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    zlib1g-dev \
    ## 
    ## Customization for Exercism Swift Track.
    ##
    && apt-get -y autoremove \
    && apt-get -yq clean \
    ##
    ## End of customization.
    ##
    && rm -r /var/lib/apt/lists/*

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   rsa4096 2024-09-16 [SC] [expires: 2026-09-16]
#      52BB7E3DE28A71BE22EC05FFEF80A866B47A981F
# uid           [ unknown] Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>
ARG SWIFT_SIGNING_KEY=52BB7E3DE28A71BE22EC05FFEF80A866B47A981F
ARG SWIFT_PLATFORM=ubuntu24.04
ARG SWIFT_BRANCH=swift-6.2-release
ARG SWIFT_VERSION=swift-6.2-RELEASE
ARG SWIFT_WEBROOT=https://download.swift.org

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
    SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION \
    SWIFT_WEBROOT=$SWIFT_WEBROOT

RUN set -e; \
    ARCH_NAME="$(dpkg --print-architecture)"; \
    url=; \
    case "${ARCH_NAME##*-}" in \
        'amd64') \
            OS_ARCH_SUFFIX=''; \
            ;; \
        'arm64') \
            OS_ARCH_SUFFIX='-aarch64'; \
            ;; \
        *) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
    esac; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
    && SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
    && SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
    # - Grab curl here so we cache better up above
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update && apt-get -q install -y curl && rm -rf /var/lib/apt/lists/* \
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fsSL "$SWIFT_BIN_URL" -o swift.tar.gz "$SWIFT_SIG_URL" -o swift.tar.gz.sig \
    && gpg --batch --quiet --keyserver keyserver.ubuntu.com --recv-keys "$SWIFT_SIGNING_KEY" \
    && gpg --batch --verify swift.tar.gz.sig swift.tar.gz \
    ## 
    ## Customization for Exercism Swift Track.
    ## Removing unneeded tools and libraries to reduce image size.
    ##
    # - Unpack the toolchain, set libs permissions, and clean up.
    # --touch updates the timestamps to now, so we can later find files modified during this build
    && tar -xzf swift.tar.gz --directory / --strip-components=1 --touch \
    && rm -v \
        /usr/lib/liblldb.so* \
        /usr/lib/libsourcekitdInProc.so \
        /usr/lib/libclang.so.* \
        /usr/lib/libLTO.so.* \
        /usr/lib/libSwiftSourceKitPlugin.so \
        /usr/lib/libSwiftSourceKitClientPlugin.so \
        /usr/lib/libswiftDemangle.so \
        /usr/bin/sourcekit-lsp \
        /usr/bin/lldb-server \
        /usr/bin/lld \
        /usr/bin/clangd \
        /usr/bin/docc \
        /usr/bin/swift-format \
        /usr/bin/swift-build-sdk-interfaces \
        /usr/bin/llvm-objdump \
        /usr/bin/llvm-ar \
        /usr/bin/swift-help \
        /usr/bin/wasmkit \
        /usr/bin/llvm-profdata \
        /usr/bin/llvm-symbolizer \
        /usr/bin/llvm-cov \
        /usr/bin/llvm-objcopy \
        /usr/bin/swift-demangle \
        /usr/bin/swift-build-tool \
        /usr/bin/lldb-dap \
        /usr/bin/lldb \
        /usr/bin/plutil \
        /usr/bin/lldb-argdumper \
        /usr/bin/swift-plugin-server \
        /usr/bin/repl_swift \
    && rm -v \
        /usr/libexec/swift/linux/swift-backtrace-static \
        /usr/libexec/swift/linux/swift-backtrace \
    && rm -r \
        /usr/lib/swift_static \
        /usr/lib/swift/embedded \
        /usr/lib/swift/FrameworkABIBaseline \
    ## Remove files we touched during tar extraction
    && find /usr/share/docc -type f -mmin -10 -exec rm -v {} \; \
    && find /usr/share/pm -type f -mmin -10 -exec rm -v {} \; \
    && find /usr/local -type f -mmin -10 -exec rm -v {} \; \
    ## Strip files we touched during tar extraction
    && find /usr/lib -name "*.so" -mmin -10 \
        -exec sh -c 'printf "Modifying: %s\n" "$1" && strip "$1"' _ {} \; \
    && find /usr/bin -type f -perm /111 ! -name "*.*" -mmin -10 \
        -exec sh -c 'printf "Modifying: %s\n" "$1" && strip "$1"' _ {} \; \
    ##
    ## End of customization.
    ##
    && chmod -R o+r /usr/lib/swift \
    && rm -rf "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz \
    && apt-get purge --auto-remove -y curl

COPY LICENSE LICENSE-APACHE-2.0 ~/

# Print Installed Swift Version
RUN swift --version