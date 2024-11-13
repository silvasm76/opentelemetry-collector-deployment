#!/bin/bash
# Download and setup the OpenTelemetry Collector
curl -L -o /tmp/otelcol-contrib_0.113.0_linux_amd64.tar.gz https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.113.0/otelcol-contrib_0.113.0_linux_amd64.tar.gz
cd /tmp
tar -xzf otelcol-contrib_0.113.0_linux_amd64.tar.gz
mv otelcol-contrib /usr/bin/otelcol
chmod +x /usr/bin/otelcol
curl https://raw.githubusercontent.com/silvasm76/opentelemetry-collector-deployment/refs/heads/main/datadogconfig.yaml -o /tmp/otelconfig.config
/usr/bin/otelcol --config=/tmp/otelconfig.yaml
