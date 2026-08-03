# Meta entrypoint for the monorepo.
# The full stack is multi-service — use Compose from this directory:
#
#   cp .env.example .env
#   docker compose up -d --build
#
# See DOCKER.md for env, IP/domain examples, and cleanup commands.

FROM alpine:3.20
LABEL org.opencontainers.image.title="kubercode" \
      org.opencontainers.image.description="Use docker compose up -d --build (see DOCKER.md)"
WORKDIR /kubercode
COPY DOCKER.md /kubercode/DOCKER.md
CMD ["sh", "-c", "echo 'KuberCode is a multi-service stack. Run: docker compose up -d --build' && echo 'Docs: DOCKER.md' && cat /kubercode/DOCKER.md | head -n 40"]
