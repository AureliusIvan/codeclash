#!/bin/bash

# Migration script for CodeClash Online Judge
# This script handles database migrations and setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if Django is available
check_django() {
    if ! python -c "import django" &> /dev/null; then
        error "Django is not installed. Please run 'make install' first."
    fi
    log "Django is available"
}

# Wait for database to be ready
wait_for_db() {
    log "Waiting for database to be ready..."
    
    if command -v docker-compose &> /dev/null; then
        # Check if PostgreSQL container is running
        if docker-compose ps | grep -q "oj-postgres.*Up"; then
            log "PostgreSQL container is running"
            
            # Wait for PostgreSQL to accept connections
            max_tries=30
            try=0
            while [ $try -lt $max_tries ]; do
                if docker exec oj-postgres pg_isready -U onlinejudge &> /dev/null; then
                    log "Database is ready"
                    return 0
                fi
                try=$((try + 1))
                warn "Database not ready, waiting... (attempt $try/$max_tries)"
                sleep 2
            done
            error "Database did not become ready in time"
        else
            warn "PostgreSQL container is not running. Starting it..."
            docker-compose up -d oj-postgres
            sleep 5
            wait_for_db
        fi
    else
        log "Docker Compose not available, assuming database is ready"
    fi
}

# Create migrations for all apps
create_migrations() {
    log "Creating migrations for all apps..."
    
    apps=("account" "announcement" "conf" "contest" "options" "problem" "submission")
    
    for app in "${apps[@]}"; do
        if [ -d "$app" ]; then
            log "Creating migrations for $app"
            python manage.py makemigrations $app
        else
            warn "App directory $app not found, skipping"
        fi
    done
}

# Run migrations
run_migrations() {
    log "Running database migrations..."
    python manage.py migrate --verbosity=2
    
    if [ $? -eq 0 ]; then
        log "Migrations completed successfully"
    else
        error "Migration failed"
    fi
}

# Check migration status
check_migration_status() {
    log "Checking migration status..."
    python manage.py showmigrations
}

# Rollback migrations (if needed)
rollback_migration() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        error "Usage: $0 rollback <app_name> <migration_name>"
    fi
    
    warn "Rolling back migration $2 for app $1"
    python manage.py migrate $1 $2
}

# Create initial superuser
create_superuser() {
    log "Creating initial superuser..."
    python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print("Superuser 'admin' created with password 'admin123'")
else:
    print("Superuser 'admin' already exists")
EOF
}

# Collect static files
collect_static() {
    log "Collecting static files..."
    python manage.py collectstatic --noinput
}

# Main migration process
main() {
    log "Starting migration process for CodeClash Online Judge"
    
    check_django
    wait_for_db
    
    case "${1:-migrate}" in
        "migrate")
            run_migrations
            ;;
        "makemigrations")
            create_migrations
            ;;
        "status")
            check_migration_status
            ;;
        "rollback")
            rollback_migration $2 $3
            ;;
        "setup")
            create_migrations
            run_migrations
            collect_static
            create_superuser
            ;;
        "reset")
            warn "This will delete all data and recreate the database"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if command -v docker-compose &> /dev/null; then
                    docker-compose down -v
                    docker-compose up -d oj-postgres oj-redis
                    sleep 10
                fi
                run_migrations
                create_superuser
                log "Database reset completed"
            else
                log "Operation cancelled"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND]"
            echo
            echo "Commands:"
            echo "  migrate         Run database migrations (default)"
            echo "  makemigrations  Create new migrations"
            echo "  status          Show migration status"
            echo "  setup           Full setup (migrations + superuser + static)"
            echo "  reset           Reset database (WARNING: destroys data)"
            echo "  rollback <app> <migration>  Rollback to specific migration"
            echo "  help            Show this help message"
            ;;
        *)
            error "Unknown command: $1. Use '$0 help' for usage information."
            ;;
    esac
    
    log "Migration process completed"
}

# Run main function with all arguments
main "$@"