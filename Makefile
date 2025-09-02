.PHONY: help install migrate makemigrations collectstatic test runserver shell createsuperuser backup restore docker-build docker-up docker-down docker-logs clean lint format

# Docker settings
DC = docker compose
SERVICE = oj-backend

# Default target
help:
	@echo "Available commands:"
	@echo "  install          Install dependencies"
	@echo "  migrate          Run database migrations"
	@echo "  makemigrations   Create new migrations"
	@echo "  collectstatic    Collect static files"
	@echo "  test             Run tests"
	@echo "  runserver        Start development server"
	@echo "  shell            Open Django shell"
	@echo "  createsuperuser  Create superuser"
	@echo "  backup           Backup database"
	@echo "  restore          Restore database from backup"
	@echo "  docker-build     Build Docker images"
	@echo "  docker-up        Start Docker containers"
	@echo "  docker-down      Stop Docker containers"
	@echo "  docker-logs      View Docker logs"
	@echo "  clean            Clean temporary files"
	@echo "  lint             Run code linting"
	@echo "  format           Format code"

# Development commands
install:
	$(DC) exec -T $(SERVICE) pip install -r deploy/requirements.txt

migrate:
	$(DC) exec -T $(SERVICE) python manage.py migrate

makemigrations:
	$(DC) exec -T $(SERVICE) python manage.py makemigrations

collectstatic:
	$(DC) exec -T $(SERVICE) python manage.py collectstatic --noinput

test:
	$(DC) exec -T $(SERVICE) python manage.py test

runserver:
	$(DC) exec $(SERVICE) python manage.py runserver 0.0.0.0:8000

shell:
	$(DC) exec -it $(SERVICE) python manage.py shell

createsuperuser:
	$(DC) exec -it $(SERVICE) python manage.py createsuperuser

# Database operations
backup:
	@echo "Creating database backup..."
	docker exec -t oj-postgres pg_dump -U onlinejudge onlinejudge > backup_$(shell date +%Y%m%d_%H%M%S).sql

restore:
	@echo "Restoring database from backup..."
	@read -p "Enter backup file path: " backup_file; \
	docker exec -i oj-postgres psql -U onlinejudge -d onlinejudge < $$backup_file

# Docker operations
docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-restart:
	docker compose restart

# Maintenance
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.log" -delete

lint:
	flake8 .

format:
	black .

# Production deployment
deploy: docker-build docker-up migrate collectstatic
	@echo "Deployment completed"

# Development setup
setup: docker-up install migrate collectstatic
	@echo "Development setup completed"

# Reset development environment
reset:
	$(DC) down -v
	$(DC) up -d oj-postgres oj-redis oj-backend
	sleep 5
	$(DC) exec -T $(SERVICE) python manage.py migrate
	@echo "Development environment reset completed"