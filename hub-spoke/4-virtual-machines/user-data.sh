#! /bin/bash
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -y apache2
sudo a2enmod ssl
sudo a2ensite default-ssl.conf
sudo systemctl enable apache2
export hostname=`hostname`
echo "<h1>Demo on $hostname</h1>" | sudo tee /var/www/html/index.html
sudo systemctl restart apache2
