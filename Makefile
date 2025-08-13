# -----------------------
# Docker Compose Makefile
# -----------------------

# The .env file will be used by default by docker compose
COMPOSE = docker compose --env-file .env

# Compose files
BASE_FILE = docker-compose.base.yml
NEXTCLOUD_FILE = docker-compose.nextcloud.yml
WG_FILE = docker-compose.wg-easy.yml
VAULTWARDEN_FILE = docker-compose.vault-warden.yml

# ======== TARGETS ========

## Create external network
network:
	docker network create proxy-network || true

## Start only base stack (nginx-proxy-manager, etc.)
up-base: network
	$(COMPOSE) -f $(BASE_FILE) up -d

## Start Nextcloud stack
up-nextcloud: network
	$(COMPOSE) -f $(BASE_FILE) -f $(NEXTCLOUD_FILE) up -d

## Start VPN stack
up-wg: network
	$(COMPOSE) -f $(BASE_FILE) -f $(WG_FILE) up -d

## Start Vaultwarden stack
up-vaultwarden: network
	$(COMPOSE) -f $(BASE_FILE) -f $(VAULTWARDEN_FILE) up -d

## Start everything
up-all: network
	$(COMPOSE) -f $(BASE_FILE) -f $(NEXTCLOUD_FILE) -f $(WG_FILE) -f $(VAULTWARDEN_FILE) up -d

## Stop all containers from all stacks
down:
	$(COMPOSE) -f $(BASE_FILE) -f $(NEXTCLOUD_FILE) -f $(WG_FILE) -f $(VAULTWARDEN_FILE) down

## Restart all stacks
restart: down up-all

## View logs (follow mode)
logs:
	$(COMPOSE) logs -f --tail=100

## Update all images & restart
update:
	docker compose -f $(BASE_FILE) -f $(NEXTCLOUD_FILE) -f $(WG_FILE) -f $(VAULTWARDEN_FILE) pull
	make restart

## Backup all volumes (simple tar.gz)
backup:
	@echo "Creating backups in ./backups..."
	@mkdir -p backups
	docker run --rm \
		-v nextcloud_html:/data \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/nextcloud_html_`date +%F`.tar.gz /data
	docker run --rm \
		-v nextcloud_db_data:/var/lib/mysql \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/nextcloud_db_`date +%F`.tar.gz /var/lib/mysql
	docker run --rm \
		-v npm_data:/data \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/npm_data_`date +%F`.tar.gz /data
	docker run --rm \
		-v npm_letsencrypt:/etc/letsencrypt \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/npm_letsencrypt_`date +%F`.tar.gz /etc/letsencrypt
	docker run --rm \
		-v vaultwarden_data:/data \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/vaultwarden_data_`date +%F`.tar.gz /data

## Remove dangling images/volumes
clean:
	docker system prune -f
	docker volume prune -f

.PHONY: network up-base up-nextcloud up-wg up-vaultwarden up-all down restart logs update backup clean
