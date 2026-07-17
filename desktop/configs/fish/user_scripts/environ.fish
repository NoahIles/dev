# Environment variables — loaded for all shells (interactive and not)

# Editor
set -gx EDITOR zeditor
set -gx SUDO_EDITOR zeditor

# Prevent podman-compose from emitting messages; see podman-compose(1)
set -gx PODMAN_COMPOSE_WARNING_LOGS false
