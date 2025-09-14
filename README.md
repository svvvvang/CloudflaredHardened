# CloudflaredHardened
Build hardened cloudflared in container using token for authentication instead of web authentication

# Using docker compose to create the container (--build optional required when dockerfile is amended)
docker compose up -d --build

# Troubeshooting, access container logs for troubleshooting
docker logs cloudflared
