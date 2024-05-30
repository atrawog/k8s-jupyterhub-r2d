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
