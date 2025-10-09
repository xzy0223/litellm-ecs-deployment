FROM ghcr.io/berriai/litellm:main-stable

WORKDIR /app

COPY config.yaml .

RUN chmod +x ./docker/entrypoint.sh

EXPOSE 4000/tcp

# WARNING: FOR PROD DO NOT USE `--detailed_debug` it slows down response times, instead use the following CMD
# CMD ["--port", "4000", "--config", "config.yaml"]

CMD ["--port", "4000", "--config", "config.yaml", "--detailed_debug"]