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
until php artisan tinker --execute="DB::connection()->getPdo(); echo 'OK';" 2>/dev/null | grep -q "OK"; do
    echo "MySQL is unavailable - sleeping"
    sleep 2
done

echo "MySQL is ready!"

# Install npm dependencies and build assets
if [ ! -d "node_modules" ]; then
    echo "Installing NPM dependencies..."
    npm install
fi

# Always rebuild assets to ensure they're fresh and properly hashed
echo "Building assets..."
npm run build

# Clear any cached assets to prevent version conflicts
if [ -d "public/build" ]; then
    echo "Clearing asset cache..."
    find public/build -name "*.css" -o -name "*.js" | head -20 | xargs ls -la || true
fi

# Generate application key if not exists
if [ ! -f ".env" ] || ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Check if migrations have been run by checking migration status
MIGRATION_STATUS=$(php artisan migrate:status 2>&1)
if echo "$MIGRATION_STATUS" | grep -q "Migration table not found\|No migrations found"; then
    echo "Running migrations with seed..."
    php artisan migrate:fresh --seed --force
    if [ $? -eq 0 ]; then
        touch database/.migrated
        echo "Migrations completed successfully."
    else
        echo "Migrations failed!"
        exit 1
    fi
elif [ ! -f "database/.migrated" ]; then
    echo "Migration status unclear, running migrations to be safe..."
    php artisan migrate:fresh --seed --force
    if [ $? -eq 0 ]; then
        touch database/.migrated
        echo "Migrations completed successfully."
    else
        echo "Migrations failed!"
        exit 1
    fi
else
    echo "Database already migrated."
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Laravel setup completed!"

# Execute the main command
exec "$@"
