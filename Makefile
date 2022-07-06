NETWORK=localbound
POSTGRES_IMAGE=postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

.PHONY: network
network:
	@ docker network create $(NETWORK) 1> /dev/null 2>&1 || true

.PHONY: postgres
postgres: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(POSTGRES_PORT):$(POSTGRES_PORT) \
	--env POSTGRES_USER=$(POSTGRES_USER) \
	--env POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	--name postgres \
	$(POSTGRES_IMAGE)

.PHONY: psql
psql:
	PGPASSWORD=$(POSTGRES_PASSWORD) psql -h localhost -U $(POSTGRES_USER) -p $(POSTGRES_PORT) -d postgres