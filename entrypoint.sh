#!/bin/bash

echo "Starting Laravel setup..."

# Install composer dependencies first
if [ ! -d "vendor" ]; then
    echo "Installing Composer dependencies..."
    composer install --no-interaction --optimize-autoloader --no-dev
else
    echo "Composer dependencies already installed."
fi

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until php artisan migrate:status 2>/dev/null; do
    echo "MySQL is unavailable - sleeping"
    sleep 2
done

echo "MySQL is ready!"

# Install npm dependencies and build assets
if [ ! -d "node_modules" ]; then
    echo "Installing NPM dependencies..."
    npm install
fi

echo "Building assets..."
npm run build

# Generate application key if not exists
if [ ! -f ".env" ] || ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Check if migrations have been run
MIGRATION_CHECK=$(php artisan migrate:status 2>&1 | grep -c "No migrations found" || true)

if [ "$MIGRATION_CHECK" -gt 0 ] || [ ! -f "database/.migrated" ]; then
    echo "Running migrations with seed..."
    php artisan migrate:fresh --seed --force
    touch database/.migrated
else
    echo "Database already migrated."
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Laravel setup completed!"

# Execute the main command
exec "$@"
