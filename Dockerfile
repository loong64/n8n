ARG NODE_VERSION=22
FROM ghcr.io/loong64/n8nio-base:${NODE_VERSION}

ARG N8N_VERSION
RUN if [ -z "$N8N_VERSION" ] ; then echo "The N8N_VERSION argument is missing!" ; exit 1; fi

LABEL org.opencontainers.image.title="n8n"
LABEL org.opencontainers.image.description="Workflow Automation Tool"
LABEL org.opencontainers.image.source="https://github.com/loong64/n8n"
LABEL org.opencontainers.image.url="https://n8n.io"
LABEL org.opencontainers.image.version=${N8N_VERSION}

ENV N8N_VERSION=${N8N_VERSION}
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=stable
RUN set -eux; \
	npm install -g --omit=dev n8n@${N8N_VERSION} --ignore-scripts --sqlite3_binary_host=https://github.com/loong64/node-sqlite3/releases/download && \
	npm install --prefix=/usr/local/lib/node_modules/n8n sqlite3 --sqlite3_binary_host=https://github.com/loong64/node-sqlite3/releases/download && \
	rm -rf /usr/local/lib/node_modules/n8n/node_modules/@n8n/chat && \
	rm -rf /usr/local/lib/node_modules/n8n/node_modules/@n8n/design-system && \
	rm -rf /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/node_modules && \
	find /usr/local/lib/node_modules/n8n -type f -name "*.ts" -o -name "*.js.map" -o -name "*.vue" | xargs rm -f && \
	rm -rf /root/.npm

# Setup the Task Runner Launcher
ARG TARGETARCH
ARG LAUNCHER_VERSION=1.1.3
COPY docker/images/n8n/n8n-task-runners.json /etc/n8n-task-runners.json
# Download, verify, then extract the launcher binary
RUN \
	mkdir /launcher-temp && \
	cd /launcher-temp && \
	wget https://github.com/loong64/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${TARGETARCH}.tar.gz && \
	wget https://github.com/loong64/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${TARGETARCH}.tar.gz.sha256 && \
	# The .sha256 does not contain the filename --> Form the correct checksum file
	echo "$(cat task-runner-launcher-${LAUNCHER_VERSION}-linux-${TARGETARCH}.tar.gz.sha256) task-runner-launcher-${LAUNCHER_VERSION}-linux-${TARGETARCH}.tar.gz" > checksum.sha256 && \
	sha256sum -c checksum.sha256 && \
	tar xvf task-runner-launcher-${LAUNCHER_VERSION}-linux-${TARGETARCH}.tar.gz --directory=/usr/local/bin && \
	cd - && \
	rm -r /launcher-temp

COPY docker/images/n8n/docker-entrypoint.sh /

RUN \
	mkdir .n8n && \
	chown node:node .n8n
ENV SHELL /bin/sh
USER node
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]