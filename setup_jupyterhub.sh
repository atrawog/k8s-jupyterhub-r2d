#!/bin/bash

# Define directories
CHART_DIR="k8s-jupyterhub-r2d"
TEMPLATES_DIR="$CHART_DIR/templates"
IMAGES_DIR="images"

# Generate secrets
PROXY_SECRET=$(openssl rand -hex 32)
HUB_COOKIE_SECRET=$(openssl rand -hex 32)

# Create directories
mkdir -p $TEMPLATES_DIR $IMAGES_DIR

# Create Chart.yaml
cat <<EOF > $CHART_DIR/Chart.yaml
apiVersion: v2
name: k8s-jupyterhub-r2d
description: A Helm chart for JupyterHub with Traefik ingress
version: 0.1.0
appVersion: 1.0
dependencies:
  - name: jupyterhub
    version: "1.2.0"
    repository: "https://jupyterhub.github.io/helm-chart/"
EOF

# Create values.yaml
cat <<EOF > $CHART_DIR/values.yaml
proxy:
  secretToken: "$PROXY_SECRET"
  service:
    type: ClusterIP

hub:
  cookieSecret: "$HUB_COOKIE_SECRET"
  extraEnv:
    DUMMY_AUTH_PASSWORD: "default_password"

ingress:
  enabled: true
  annotations: {}
  hosts:
    - host: ""
      paths: ["/"]
  tls:
    enabled: false
    secretName: "jupyterhub-tls"

traefik:
  enabled: true
  dashboard:
    enabled: true
    domain: ""
  ssl:
    enabled: false
    domains: []
EOF

# Create ingress.yaml template
cat <<EOF > $TEMPLATES_DIR/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jupyterhub
  annotations:
    {{- range \$key, \$value := .Values.ingress.annotations }}
    {{ \$key }}: {{ \$value | quote }}
    {{- end }}
spec:
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ . }}
            pathType: Prefix
            backend:
              service:
                name: proxy-public
                port:
                  number: 80
          {{- end }}
    {{- end }}
  {{- if .Values.ingress.tls.enabled }}
  tls:
    - hosts:
        {{- range .Values.ingress.hosts }}
        - {{ .host }}
        {{- end }}
      secretName: {{ .Values.ingress.tls.secretName }}
  {{- end }}
EOF

# Create Dockerfile
cat <<EOF > $IMAGES_DIR/Dockerfile
FROM jupyterhub/k8s-hub:latest
WORKDIR /srv/jupyterhub
COPY jupyterhub_config.py .
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
EOF

# Create jupyterhub_config.py
cat <<EOF > $IMAGES_DIR/jupyterhub_config.py
import os
c = get_config()

# Example JupyterHub configuration
c.JupyterHub.bind_url = 'http://:8000'
c.Spawner.default_url = '/lab'

# Use the dummy authenticator for testing purposes
c.JupyterHub.authenticator_class = 'dummyauthenticator.DummyAuthenticator'
c.DummyAuthenticator.password = os.environ.get('DUMMY_AUTH_PASSWORD', 'default_password')

# Use the simple spawner for testing purposes
c.JupyterHub.spawner_class = 'simple'
EOF

# Create chartpress.yaml
cat <<EOF > chartpress.yaml
charts:
  - name: k8s-jupyterhub-r2d
    path: k8s-jupyterhub-r2d
images:
  - name: custom-jupyterhub/k8s-hub
    valuesPath: hub.image
    build:
      contextPath: images
      dockerfilePath: images/Dockerfile
EOF

echo "Project structure created successfully."
echo "Proxy Secret: $PROXY_SECRET"
echo "Hub Cookie Secret: $HUB_COOKIE_SECRET"

# Initialize Git repository and make the initial commit
git init
git add .
git commit -m "Initial commit"

# Verify the directory structure
echo "Verifying directory structure..."
ls -R .

# Run Chartpress
chartpress
