FROM jenkins/jenkins:lts-jdk17

USER root

ARG DOCKER_VERSION=29.7.1
ARG DOCKER_GID=983

# Install the docker CLI only (no daemon) so pipelines can talk to the
# host's Docker engine via the mounted /var/run/docker.sock.
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    | tar xz -C /tmp \
    && mv /tmp/docker/docker /usr/local/bin/docker \
    && rm -rf /tmp/docker

# Match the host's docker group GID so the jenkins user can access the
# bind-mounted socket without running as root.
RUN if ! getent group docker >/dev/null; then groupadd -g ${DOCKER_GID} docker; fi \
    && usermod -aG docker jenkins

USER jenkins
