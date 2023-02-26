# ficti0ntest_infra
ficti0ntest Infra repository
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

bastion_IP = 130.193.38.80
someinternalhost_IP = 10.128.0.33
