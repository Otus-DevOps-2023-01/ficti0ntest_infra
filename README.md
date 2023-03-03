# ficti0ntest_infra
ficti0ntest Infra repository

testapp_IP = 62.84.126.253
testapp_port = 9292

Команда для дополнительного задания:
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=startup.yaml

###############################################
Задание:
~/.ssh/config:
Host bastion
  HostName 130.193.38.80
  User appuser
  IdentityFile ~/.ssh/id_rsa

Host int-vm-01
  User appuser
  IdentityFile  ~/.ssh/id_rsa
  ForwardAgent yes

command:
ssh -A -J appuser@130.193.38.80 appuser@10.128.0.33

Дополнительное задание:
 ~/.ssh/config:
Host bastion
  HostName 130.193.38.80
  User appuser
  IdentityFile ~/.ssh/id_rsa

Host int-vm-01
  User appuser
  Hostname 10.128.0.33
  IdentityFile ~/.ssh/id_rsa
  ForwardAgent yes
  ProxyJump bastion

command:
ssh  int-vm-01

---
VPN

bastion_IP = 84.201.130.10
someinternalhost_IP = 10.128.0.33

