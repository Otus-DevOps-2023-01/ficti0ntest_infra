#!/bin/bash

sudo mv -f /tmp/mongodb.conf /etc/mongodb.conf
sudo systemctl restart mongodb
