#!/bin/bash
sudo apt update
sudo apt install mongodb git -y
sudo systemctl enable mongodb --now
