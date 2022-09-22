#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo service httpd start
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
