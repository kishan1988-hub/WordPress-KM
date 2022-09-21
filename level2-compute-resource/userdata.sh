#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo yum install git -y

sudo service httpd start
