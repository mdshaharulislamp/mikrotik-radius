
# RADIUS Config Manager

This is a Django-based web interface to manage FreeRADIUS users and settings. It installs all required dependencies and configures a working RADIUS server with a database backend.

## 🛠️ Installation Instructions

Download the `radiusconfig.tar` file and follow the steps below:

[Download radiusconfig.tar](https://github.com/mdshaharulislamp/mikrotik-radius/raw/main/releases/radiusconfig.tar)


## 📦 Installation

### 1. Extract the project files

```bash
tar -xf radiusconfig.tar
cd radiusconfig
chmod +x install.sh
./install.sh
````

### 2. Follow the prompts

During the installation, you will be asked for the following inputs:

* MySQL root password (press Enter if none)
* Database name
* Database username
* Database password
* Django admin superuser username
* Django admin superuser email
* Django admin superuser password
* MySQL root password (again, 3 times)
* Database password (again)

🕒 Just wait a little bit for the installation to finish.

---

## 🌐 Access the Web Interface

Once installation is complete, you’ll see a message at the bottom showing the address to access the web application, typically:

```
http://<your-server-ip>:8000/iamtheadmin/
```

Or if running on localhost:

```
http://127.0.0.1:8000/iamtheadmin/
```

---

## 🔧 What it does

* Installs all necessary packages (Django, MySQL, FreeRADIUS, etc.)
* Sets up a virtual environment
* Configures FreeRADIUS with SQL support
* Sets up a Django app with RADIUS user management
* Automatically applies migrations and creates a Django admin user

---

## 📝 Notes

* Make sure port `8000` is open in your firewall (or change it in `manage.py runserver`).
* FreeRADIUS logs can be viewed using:

```bash
tail -f /var/log/freeradius/radius.log
```

---

## ⚠️ Disclaimer

> This script assumes a clean Ubuntu/Debian environment. Use at your own risk on production systems.

---

## 📧 Contact

If you find this project helpful or have any questions, feel free to contact 

Email: shaharulcse@gmail.com

LinkedIn: https://www.linkedin.com/in/md-shaharul-islam-5044b7ba/

Blog: https://itprobd.blogspot.com/
