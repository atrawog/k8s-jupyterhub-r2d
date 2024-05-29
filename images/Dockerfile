FROM jupyterhub/k8s-hub:latest
WORKDIR /srv/jupyterhub
COPY jupyterhub_config.py .
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
