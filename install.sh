#!/bin/bash
set -e

# === User Inputs ===
read -p "Enter MySQL root password: " -s MYSQL_ROOT_PASS
echo
read -p "Enter MySQL DB name (existing or new): " DB_NAME
read -p "Enter MySQL DB user: " DB_USER
read -s -p "Enter MySQL DB password: " DB_PASS
echo
read -p "Enter Django superuser username: " DJ_USER
read -p "Enter Django superuser email: " DJ_EMAIL
read -s -p "Enter Django superuser password: " DJ_PASS
echo

# === Step 1: Install system packages ===
echo "Installing system packages..."
apt update
apt install -y python3 python3-venv python3-pip mysql-server libmysqlclient-dev \
    freeradius freeradius-mysql freeradius-utils default-libmysqlclient-dev build-essential pkg-config

# === Step 2: Extract FreeRADIUS config ===
echo "Extracting FreeRADIUS config..."
tar -xf freeradius-config.tar -C /
chown -R freerad:freerad /etc/freeradius/3.0

# === Step 3: Setup MySQL DB and import schema ===
echo "Setting up MySQL database... Please enter MySql Root Password 3 times"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

echo "Importing database schema... Please Enter DB- "$DB_NAME" Password"
mysql -u root -p"$MYSQL_ROOT_PASS" "$DB_NAME" < radius_schema.sql

# === Step 4: Extract Django project and setup Python env ===
echo "Extracting Django project..."
tar -xf radius.tar

echo "Entering Django project folder..."
cd radius || { echo "Django project folder 'radius' not found!"; exit 1; }

echo "Creating Python virtual environment..."
python3 -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

echo "Upgrading pip and installing dependencies..."
pip install --upgrade pip
pip install -r ../requirements.txt

# === Step 5: Configure Django DB settings ===
echo "Configuring Django database settings in settings.py..."
SETTINGS_FILE="radius/settings.py"
# Overwrite DATABASES block (adjust if your settings.py structure differs)
sed -i '/^DATABASES = {/,/^}/d' "$SETTINGS_FILE"

cat << EOF >> "$SETTINGS_FILE"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '$DB_NAME',
        'USER': '$DB_USER',
        'PASSWORD': '$DB_PASS',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
EOF

# === Step 6: Django migrations and superuser creation ===
echo "Running Django migrations..."
python manage.py makemigrations
python manage.py migrate

echo "Creating Django superuser (if not exists)..."
echo "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$DJ_USER').exists():
    User.objects.create_superuser('$DJ_USER', '$DJ_EMAIL', '$DJ_PASS')
" | python manage.py shell

# === Step 7: Setup Gunicorn systemd service ===
echo "Creating Gunicorn systemd service..."
SERVICE_FILE="/etc/systemd/system/gunicorn.service"

cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=gunicorn daemon for Django project
After=network.target

[Service]
User=$(whoami)
Group=www-data
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/venv/bin/gunicorn radius.wsgi:application --workers 3 --bind 0.0.0.0:8000 --worker-class=gevent

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl restart gunicorn

# === Step 8: Restart FreeRADIUS service ===
echo "Restarting FreeRADIUS service..."
sudo systemctl restart freeradius

IP_ADDR=$(hostname -I | awk '{print $1}')

echo "✅ Setup complete!"
echo "Gunicorn is running and serving the Django app on port 8000."
echo "Access your app at: http://$IP_ADDR:8000"
echo "Configure a reverse proxy (e.g. nginx) for production usage."

deactivate
