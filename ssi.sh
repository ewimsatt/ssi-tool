#!/bin/bash
# To use this script, call the script with the base_URL in lowercase as the first argument
# example use: ./ssi.sh stage.site.com STAGEsitedb
 
# Input testing for URL
if [ $# -eq 0 ]
	then
		echo "
		
		You forgot the base_URL. Correct syntax is: ./ssi.sh base_URL databasename
		
		Example: ./ssi.sh snapshotdev.com ssdevdb
		
		"
		exit 1
fi

# Grab the inputs and create variables and a random password
hostname=$1
database=$2
vhost=$1.conf
PASS=$(cat /dev/urandom | tr -cd "[:alnum:]" | tr Ol o1 | head -c 16)

# Create the file structure
cd /var/www/html
if [ -d "$hostname" ]; then
		echo "Directory: $hostname exists. Exiting."
			exit;
		fi
		sudo mkdir -p "$hostname"/{public_html,logs}
		sudo chmod o+x "$hostname"
		sudo chown -R www-data:www-data "$hostname" 

# Create The Database
		echo "Please enter root user MySQL password!"
		read -r rootpasswd
		mysql -uroot -p"${rootpasswd}" -e "CREATE DATABASE ${2} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
		mysql -uroot -p"${rootpasswd}" -e "GRANT ALL PRIVILEGES ON ${2}.* TO '${2}'@'localhost' IDENTIFIED BY '${PASS}';"
		mysql -uroot -p"${rootpasswd}" -e "FLUSH PRIVILEGES;"

# Print the Database username and passowrd to the screen
		echo "----------------------------------------------------------------
		
		SAVE THIS!!! Username: $database Password: $PASS
		
----------------------------------------------------------------"

# Create the vhost 
sudo cp templates/example.com.conf /etc/apache2/sites-available/
sudo chown root:root /etc/apache2/sites-available/example.com.conf
cd /etc/apache2/sites-available
if [ -f "$vhost" ]; then
		echo "File: $vhost exists. Exiting."
			exit;
		fi
		sudo sed "s/example.com/$hostname/g" example.com.conf | sudo tee -a "$vhost" > /dev/null 

# Pull in dev CMS
echo "Do you want to install drupal, wordpress, or nothing?"
select dwn in "drupal" "wordpress" "nothing"; do
		case $dwn in
		drupal ) echo "This will be a git pull for drupal"; break;;
		wordpress ) wget -qO- https://wordpress.org/latest.tar.gz | sudo tar xvz -C /var/www/html/"$hostname"/
			sudo mv /var/www/html/"$hostname"/wordpress/* /var/www/html/"$hostname"/public_html/
			sudo rm -rf /var/www/html/"$hostname"/wordpress
			sudo sed "s/database_name_here/$2/g" /var/www/html/"$hostname"/public_html/wp-config-sample.php | sudo tee -a /var/www/html/"$hostname"/public_html/wp-config.php > /dev/null
			sudo sed -i -e "s/username_here/$2/g" -e "s/password_here/$PASS/g" /var/www/html/"$hostname"/public_html/wp-config.php
			sudo chown -R www-data:www-data /var/www/html/"$hostname"/public_html ; break;;
		nothing ) echo "Fine, ya bastard." ; break;;
	esac
done
		
# Enable the site
		sudo a2ensite "$vhost"
		sudo service apache2 reload
