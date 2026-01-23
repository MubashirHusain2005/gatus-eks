FROM fluentd:latest

USER root

# Install Debian build/development dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ruby-dev && \
    fluent-gem install \
        fluent-plugin-elasticsearch \
        fluent-plugin-kubernetes_metadata_filter \
        fluent-plugin-multi-format-parser && \
    apt-get purge -y \
        build-essential \
        ruby-dev && \
    rm -rf /var/lib/apt/lists/*

USER fluent