[![Test Actions Status](https://github.com/Otus-DevOps-2023-01/ficti0ntest_infra//workflows/Run%20tests%20for%20OTUS%20homework/badge.svg)](https://github.com/Otus-DevOps-2023-01/ficti0ntest_infra/actions)
# ficti0ntest_infra
ficti0ntest Infra repository

###############################################
## Разработка и тестирование Ansible ролей и плейбуков
1.  Создаем ветку  **ansible-4**
```bash
git checkout -b ansible-3
```
2. Установка vagrant и описание инфраструктуры в Vagrantfile
3. Дорабатываем роли
4. Проверяем сборку в vagrant
5. Устанавливаем pip и virtualenv
6. Устанавливаем все необходимые пакеты pip install -r requirements.txt
7. Создаем заготовку molecule с помощью команды molecule init scenario -r db -d vagrant
8. Добавляем собственнные тесты
9. Собираем и тестируем нашу конфигурацию


### Самостоятельные задания:
Пишем тест для проверки доступности порта 27017:

```bash
# check 27017 port
def test_mongo_port(host):
    socket = host.socket('tcp://0.0.0.0:27017')
    assert socket.is_listening
```

Используем роли db и app
packer_db.yml
```yaml
 "type": "ansible",
 "playbook_file": "ansible/playbooks/packer_db.yml",
 "extra_arguments": ["--tags","install"],
 "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
```
packer_app.yml
```yaml
"type": "ansible",
"playbook_file": "ansible/playbooks/packer_app.yml",
"extra_arguments": ["--tags","ruby"],
"ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
```\
## Ansible роли, управление настройками нескольких окружений и best practices
1.  Создаем ветку  **ansible-3**
```bash
git checkout -b ansible-3
```
2. Создаем роли app и db на основе плейбуков, сделанных в прошлом ДЗ
3. Модифицируем эти роли и проверяем, что все работает.
4. Переносим файлы по разным окружениям (stage и prod)
5. Применяем сделанный ранее динамический инвентори **inventory.json** для стейдж окружения. Я его закоментил и поменял на обычный для прохождения CI
6. Настраиваем group_vars для назначения переменных
7. Добавляем информацию об окружении в вывод плейбука
8. Переносим плейбуки в отдельную папку **playbooks**
9. Проверяем работу ролей на стейдж и прод окружении
10. Добавляем роль **jdauphant.nginx**, модифицируем переменные для использования 80 порта
11. Работая с вольтом секретим наши переменные в файлах (пользователи и пароли)

## Задание *
Динамическое инвентори было настроено и проверено

Добавлен бейдж

## Продолжение знакомства с Ansible: templates, handlers, dynamic inventory, vault, tags
1.  Создаем ветку  **ansible-2**
```bash
git checkout -b ansible-2
```
1. Создаем плейбук reddit_app.yml заполняем его и тестируем
2. Создаем плейбук на несколько сценариев reddit_app2.yml
3. Разбиваем наш плейбук на несколько: app.yml, db.yml, deploy.yml и переименовываем наши старые плейбуки в **reddit_app_multiple_plays.yml** и **reddit_app_one_play.yml**
4. Модифицируем наши провижионеры в packer, меняеем их на ansible и пересобираем образы, указываем новые образы в переменных для окружения терраформа.


## Задание со *
```json
Для задания со свездочкой мы снова модифицируем ansible.cfg
[defaults]
inventory = ./inventory
remote_user = ubuntu
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False

[inventory]
enable_plugins = script
```json

Теперь модифицируем наш inventory.json добавляя переменную db_ip в которую записывается адрес БД и делаем так чтобы наши группы соответсвовали тем что в плейбуках.
```bash
#!/bin/bash

ip1=$(yc compute instances list | awk '{print $10}' | sed '/^[[:space:]]*$/d' |  sed  '1d' | head -1)
host1=$(yc compute instances list | awk '{print $4}' | sed '/^[[:space:]]*$/d' |  sed  '1d' | head -1| tr - _)
ip2=$(yc compute instances list | awk '{print $10}' | sed '/^[[:space:]]*$/d' |  sed  '1d' | tail -1)
host2=$(yc compute instances list | awk '{print $4}' | sed '/^[[:space:]]*$/d' |  sed  '1d' | tail -1| tr - _)

if [ "${host1:7}" == "db" ]; then
  db_ip=$ip1
else
  db_ip=$ip2
fi

if [ "$1" == "--list" ] ; then
cat<<EOF
{
  "${host1:7}": {
  "hosts": ["$ip1"],
  "vars": {
    "db_ip": "$db_ip"
  }
  },
  "${host2:7}": {
    "hosts": ["$ip2"],
    "vars": {
      "db_ip": "$db_ip"
    }
  },
  "_meta": {
  "hostvars": {
    "$ip1": {
    "host_specific_var": "$host1"
    },
    "$ip2": {
    "host_specific_var": "$host2"
    }
  }
  }
}
EOF
elif [ "$1" == "--host" ]; then
  echo '{"_meta": {"hostvars": {}}}'
else
  echo "{ }"
fi
```
Теперь передаем нашу переменную в app.yml
```json
  vars:
   db_host: "{{db_ip}}"
```
Запускаем и проверяем, все работает.

## Знакомство с Ansible

1.  Создаем ветку  **ansible-1**
```bash
git checkout -b ansible-1
```
2. Устанавлием Ansible. У меня уже был установлен, поэтому пропускаю этот шаг.
3.  Создаем каталог  **ansible**  и запускаем **stage** окружение  через terraform:
```bash
terraform plan
terraform apply
```
4.  IP адреса (получаем из **output** переменных) подставляем в **inventory**  файл в каталоге **ansible** и проверяем доступность хостов модулем  **ping**
```bash
ansible appserver -i ./inventory -m ping
```
5.  Создаем файл конфигурации  **ansible.cfg** :
```ini
[defaults]
inventory  = ./inventory.json
remote_user  = ubuntu
private_key_file  = ~/.ssh/id_rsa
host_key_checking  = False
retry_files_enabled  = False
```
6.  Формируем инвентори в yml-формате:  **inventory.yml**
```yaml
app:
	hosts:
		appserver:
			ansible_host:  51.250.80.41
db:
	hosts:
		dbserver:
			ansible_host:  51.250.94.135
```
7.  Пишем простой плейбук  **clone.yml**
```yaml
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```
## Задание со *

1.  Создадим инвентори в формате **json**  **inventory.json**:
```bash
touch inventory.json
```
2.  Берем труд человека  поработовшего до нас (мы же девопсы или как) https://gist.github.com/tuxfight3r/2c027f8fd70333a8288e с инвентори на bash, копируем в наш  **inventory.json** и параметризируем его:

```bash
#!/bin/bash
#Дергаем IP и hostnames
ip1=$(yc compute instances list | awk '{print $10}' | sed '/^[[:space:]]*$/d' | sed '1d' | head -1)
host1=$(yc compute instances list | awk '{print $4}' | sed '/^[[:space:]]*$/d' | sed '1d' | head -1| tr - _)
ip2=$(yc compute instances list | awk '{print $10}' | sed '/^[[:space:]]*$/d' | sed '1d' | tail -1)
host2=$(yc compute instances list | awk '{print $4}' | sed '/^[[:space:]]*$/d' | sed '1d' | tail -1| tr - _)

if [  "$1" == "--list"  ] ; then
cat<<EOF
{
	"$host1":  {
		"hosts":  ["$ip1"]
	},
	"$host2":  {
		"hosts":  ["$ip2"]
	},
	"_meta":  {
		"hostvars":  {
			"$ip1":  {
				"host_specific_var":  "$host1"
			},
			"$ip2":  {
				"host_specific_var":  "$host2"
			}
		}
	}
}
EOF
elif [  "$1" == "--host"  ]; then
echo '{"_meta":  {"hostvars":  {}}}'
else
echo "{ }"
fi
```
3.  Делаем файл исполняемым **inventory.json**:
```bash
chmod +x inventory.json
```

Правим  **ansible.cfg**:
```ini
[defaults]
inventory = ./inventory.json
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False

[inventory]
enable_plugins = script
```

4.  Проверяем, что все работает:
```bash
ansible all -m ping
```
```json
51.250.80.41 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
51.250.94.135 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

## Работа с Terraform, принципы организации инфраструктурного кода и работа над инфраструктурой в команде.
1.  Создаем ветку  **terraform-2**:
```bash
    git checkout -b terraform-2
```
перемещаем файл lb.tf
```bash
git mv terraform/lb.tf terraform/files/
```
2.  Создадим IP для внешнего ресурса с поомщью  **yandex_vpc_network**  и  **yandex_vpc_subnet**, для этого добавляем в  **main.tf**  следующие строки:

```json
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}

```

3.  Добавляем упоминание о созданных сетевых ресурсах в код создания инстанса:

```json
  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
```
4.  Проверяем:
```bash
terraform destroy
terraform plan
terraform apply
```
5.  Создаем 2 новых шаблона для packer  **app.json**  и  **db.json**  используя шаблон  **ubuntu16.json**
```bash
cp packer/ubuntu16.json packer/app.json; cp packer/ubuntu16.json packer/db.json
```

Изменяем новые шаблоны:
  **app.json**:
```json
"image_name":  "reddit-app-base-{{timestamp}}",
"image_family":  "reddit-app-base",
"disk_name":  "reddit-app-base",
...
"provisioners":  [
{
"type":  "shell",
"script":  "scripts/install_ruby.sh",
"execute_command":  "sudo {{.Path}}"
}
]
```
 **db.json**:

 ```json
"image_name":  "reddit-db-base-{{timestamp}}",
"image_family":  "reddit-db-base",
"disk_name":  "reddit-db-base",
...
"provisioners":  [
{
"type":  "shell",
"script":  "scripts/install_mongodb.sh",
"execute_command":  "sudo {{.Path}}"
}
]
```

6.  Создаем образы
 ```bash
packer validate -var-file=./variables.json ./app.json
packer build -var-file=./variables.json ./app.json
packer validate -var-file=./variables.json ./db.json
packer build -var-file=./variables.json ./db.json
```

7.  Разбиваем  **main.tf**  на части создав  **app.tf**  и  **db.tf**, а так же выносим в отдельный файл описание сети  **vpc.tf**
```bash
cp ./terraform/main.tf ./terraform/app.tf
cp ./terraform/main.tf ./terraform/db.tf
cp ./terraform/main.tf ./terraform/vpc.tf
```
определяем новые переменные:
 ```json
variable  app_disk_image  {
description  =  "Disk image for reddit app"
default  =  "reddit-app-base"
}
variable  db_disk_image  {
description  =  "Disk image for reddit db"
default  =  "reddit-db-base"
}
 ```
 Оставляем и редактируем *.tf файлы, чтобы ресурсы соответствовали названиям.
 правим  **outputs.tf**

```json
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}

```
8.  Проверяем работу
```bash
terraform plan
terraform apply
 ```
9.  Создаем модульную инфраструктуру. Создаем папку  **modules**  внутри папки  **terraform**
Создаем папки **modules\app** и **modules\db**, в которых создаем по з файла: **main.tf, variables.tf и outputs.tf**
Переносим в них данные, относящиеся к **db** и **app**:
**app\main.tf:**
```json
resource  "yandex_compute_instance"  "app"  {
...
}
```
**app\variables.tf:**
```json
variable  app_disk_image  {
description  =  "Disk image for reddit app"
default  =  "reddit-app-base"
}
variable  "subnet_id"  {
description  =  "Subnets for modules"
}
variable  "public_key_path"  {
description  =  "Path to the public key used for ssh access"
}
```
**app\outputs.tf:**
```json
output  "external_ip_address_app"  {
value  =  yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
```
Аналогично для **db**.
Далее удаляем из дириктории **app.tf**, **db.tf** и **vpc.tf**
Добавляем в main.tf использование модулей:
```json
module  "app"  {
source  =  "./modules/app"
public_key_path  =  var.public_key_path
app_disk_image  =  var.app_disk_image
subnet_id  =  var.subnet_id
db_ip = module.db.db_internal_ip #Дополнительная переменная для доступа по внутреннему IP к БД
}

module  "db"  {
source  =  "./modules/db"
public_key_path  =  var.public_key_path
db_disk_image  =  var.db_disk_image
subnet_id  =  var.subnet_id
}
```
Корректируем основной файл **outputs.tf**:
```json
output  "external_ip_address_app"  {
value  =  module.app.external_ip_address_app
}
output  "external_ip_address_db"  {
value  =  module.db.external_ip_address_db
}
```
Загружаем модули и запускаем:
```bash
terraform get
terraform plan
terraform apply
```
Удаляем все после проверки, что сайт запустился и приконектился к БД. Были пару опечаток и пропущена 1 переменная, все поправил и все заработало. Удаляем: `terraform destroy`
10.  Переиспользование модулей.
Cоздаем среды  **prod**  и  **stage** в папке **terraform**:
```bash
mkdir prod
mkdir stage
```
копируем в эти каталоги файлы **main.tf,  outputs.tf, terraform.tfvars,  variables.tf**
Исправляем путь у модулям в **main.tf**
Проверяем каждую среду:
```bash
terraform fmt
terraform init
terraform plan
terraform apply
```
#### Задание с  **
Настраиваем внешний backend.
Создаем ключ доступа:
```
yc iam access-key create --service-account-name terraform
```
Заносим в переменные:
```json
variable  access_key  {
description  =  "Key id"
}
variable  secret_key  {
description  =  "Secret key"
}
variable  bucket_name  {
description  =  "Bucket name"
}
```
и заполняем значения в terraform.tfvars

Чтобы создать бакит мы создадим файл в папке **terraform** **storage-backet.tf**:
```json
terraform  {
required_providers  {
yandex  =  {
source  =  "yandex-cloud/yandex"
}
}
required_version  =  ">= 0.13"
}
provider  "yandex"  {
service_account_key_file  =  pathexpand(var.service_account_key)
cloud_id  =  var.cloud_id
folder_id  =  var.folder_id
zone  =  var.zone
}
resource  "yandex_storage_bucket"  "utus_terraform2"  {
bucket  =  var.bucket_name
access_key  =  var.access_key
secret_key  =  var.secret_key
force_destroy  =  "true"
}
```
Запускаем и проверяем:
```bash
terraform apply
```
Теперь настроим использование внешнего хранилища для терраформ состояния в средах **prod**  и **stage**.
Создадим файл **backend.tf** в **stage**:
```json
terraform  {
backend  "s3"  {
endpoint  =  "storage.yandexcloud.net"
bucket  =  "otusterraform"
region  =  "ru-central1"
key  =  "prod/terraform.tfstate"
access_key  =  "your_access_key"
secret_key  =  "your_secret_key"
skip_region_validation  =  true
skip_credentials_validation  =  true
}
}
```
Проверяем:
```bash
terraform init
terraform apply
```
Видим что все работает, блокировки тоже работают, если одновременно запускать создание инстансов.

2.  Настраиваем приложение и БД. В каждом из модулей создать каталог **files**, где будут хранится наши скрипты и шаблоны.
```bash
mkdir modules/app/files
mkdir modules/db/files
```
Создаем шаблон  **puma.service.tmpl**  для нашего приложения, добавив адресс для подключения к базе
```json
[Unit]
Description=Puma HTTP Server
After=network.target
[Service]
Type=simple
User=ubuntu
Environment=DATABASE_URL=${db_ip}
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
[Install]
WantedBy=multi-user.target
```
и копируем используемый ранее **deploy.sh**
Корректируем файл **main.tf**, добавив провижионеры:
```json
connection  {
type  =  "ssh"
host  =  yandex_compute_instance.app.network_interface[0].nat_ip_address
user  =  "ubuntu"
agent  =  false
# путь до приватного ключа
private_key  =  file(var.private_key_path)
}
provisioner  "file"  {
content  =  templatefile("${path.module}/files/puma.service.tmpl",  {  db_ip  =  var.db_ip})
destination  =  "/tmp/puma.service"
}
provisioner  "remote-exec"  {
script  =  "${path.module}/files/deploy.sh"
```
Опишем переменную **db_ip**:
```json
variable db_ip {
  description = "database IP"
}
```
Корректируем  **terraform/main.tf**, чтобы получить значение переменной:
```json
module  "app"  {
source  =  "../modules/app"
public_key_path  =  var.public_key_path
private_key_path  =  var.private_key_path
app_disk_image  =  var.app_disk_image
subnet_id  =  var.subnet_id
db_ip  =  module.db.db_internal_ip
}
```
Добавляем в **modules/db/outputs.ff** вывод внутреннего ip адреса:
```json
output  "db_internal_ip"  {
value  =  yandex_compute_instance.db.network_interface.0.ip_address
}
```
Теперь поправим модуль **db**. Создаем в **modules/db/files/** **mongod.conf.tmpl**:
```json
...
# network interfaces
net:
port: 27017
bindIp: ${db_ip}
...
```
Создаем **nodules/db/files/deploy.sh** для модифицирования конфига и перезапуска монго:
```bash
#!/bin/bash
sudo  mv  -f  /tmp/mongodb.conf  /etc/mongodb.conf
sudo  systemctl  restart  mongodb
```
и добавляем провижионеры в файл **modules/db/main.tf**:
```json
connection  {
type  =  "ssh"
host  =  yandex_compute_instance.db.network_interface[0].nat_ip_address
user  =  "ubuntu"
agent  =  false
private_key  =  file(var.private_key_path)
}
provisioner  "file"  {
content  =  templatefile("${path.module}/files/mongodb.conf.tmpl",  {  db_ip  = yandex_compute_instance.db.network_interface.0.ip_address})
destination  =  "/tmp/mongodb.conf"
}
provisioner  "remote-exec"  {
script  =  "${path.module}/files/deploy.sh"
}
```

Убеждаемся, что все работает как положено:
```bash
terraform plan
terraform apply
```


## Знакомство с Terraform

1. Создаем ветку **terraform-1**

    git checkout -b terraform-1

2. Создаем сервисный аккаунт и ключ

    yc iam key create --service-account-name terraform --output ../terraform_key.json
    yc config set service-account-key ../terraform_key.json

3. Создаем файл **main.tf** (попутно добавляя лайфхаки с яндекса по поводу санкций хашикорпа):
```json
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
provider "yandex" {
  service_account_key_file = pathexpand(var.service_account_key_file)
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}
```
Создаем файлы с описанием переменных
**variables.tf**:
```json
variable "cloud_id" {
  description = "Cloud ID"
  sensitive   = true
}
variable "folder_id" {
  description = "Folder ID"
  sensitive   = true
}
variable "service_account_key_file" {
  description = "Service account key file"
  sensitive   = true
}
```
и указываем значения в файле
**terraform.tfvars**:
```json
cloud_id                 = "my cloud_id"
folder_id                = "my folder_id"
service_account_key_file = "../../terraform_key.json"
```
Выполняем:

    terraform init

Добавляем создание ВМ в **main.tf**

    terraform plan
    terraform apply

и обосрались:

> │ Error: Error while requesting API to create instance:
> server-request-id = a5dfe1f6-eb1f-4681-bdf0-bd14796d0c4b
> server-trace-id = ff4706e2bcabb231:10dc370f70fb48f2:ff4706e2bcabb231:1
> client-request-id = f1980cff-392b-4ebd-b5ca-1ba238c17ce7
> client-trace-id = c2a4d336-fabc-46e4-877b-20ba0d714180 rpc error: code
> = InvalidArgument desc = the specified number of cores is not available on platform "standard-v1"; allowed core number: 2, 4, 6, 8,
> 10, 12, 14, 16, 20, 24, 28, 32

Меняем ядра на 2 ( cores  = 2 )

    terraform apply

Пробуем подключиться по ssh, не получается, вносим изменения для добавления ssh публичного ключа в **main.tf**

    terraform destroy
    terraform apply

Подключаемся по ssh (ssh ubuntu@<внешний_IP>) - все OK

Добавляем провижионеры и скрипт. Запускаем и проверяем доступность http://external_ip_address_app:9292

4. Параметризируем код - опишем наши переменные в **variables.tf**
...
variable cloud_id {
  description = "Cloud"
}
...

Параметры для переменных записываем в **terraform.tfvars**
```json
...
cloud_id  = "abv"
...
```

Далее дестроим и применяем

    terraform destroy
    terraform apply

> я целеноправленно не использую -auto-approve, плохая практика на мой вкус

#### Задание

1. Определяем переменную для приватного ключа
```json
variable private_key_path {
description = "Connection private key file"
}

private_key = file(var.private_key_path)
```
2. Задаем дефолтное значение для "**yandex_compute_instance**" "app" для зоны:
т.е. стираем из **terraform.tfvars**

    zone  = "ru-central1-a"

3. Выполняем команду для форматирования конф файлов: `terraform fmt`

4. Создаем файл с примерами переменных **terraform.tfvars.example**

#### Задание **

1. Создаем **lb.tf** в котором опишем http балансировщик
```json
resource "yandex_lb_network_load_balancer" "lb" {
  name = "loadbalancer"
  type = "external"

  listener {
    name        = "web-listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.loadbalancer.id

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
resource "yandex_lb_target_group" "loadbalancer" {
  name      = "target-group"
  folder_id = var.folder_id
  region_id = var.region_id

  target {
    address = yandex_compute_instance.app.network_interface.0.ip_address
    subnet_id = var.subnet_id
  }
}
```
1.1 Добавляем вывод IP в **outputs.tf** вывод внешнего IP:
```json
output "lb_ip_address" {
  value = yandex_lb_network_load_balancer.lb.*
}
```
1.2 Делаем terraform apply и проверяем доступность приложения через балансировщик: http://lb_ip_address:80

    terraform plan
    terraform apply

1.3 Добавляем еще одну ВМ (просто копируя ресурс существующей ВМ)
```json
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  ...
}
```
1.4 Добавляем его в таргеты балансировщика
```json
  target {
      address = yandex_compute_instance.app2.network_interface.0.ip_address
      subnet_id = var.subnet_id
    }
```
1.5 Добавляем в **outputs.tf**
```json
output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}
```
> Проблемы такой конфигурации в дублирующем коде.

1.6 Исправляем код на использование count

Добавляем переменную
```json
variable instances {
  description = "count instances"
  default     = 1
}
```
Удаляем второй инстанс и редактируем первый
```json
resource "yandex_compute_instance" "app" {
  count = var.instances
  name  = "reddit-app-${count.index}"
  ...
  connection {
  ...
    host  = self.network_interface.0.nat_ip_address
  }
  ...
}
```
Правим таргет группу используя блок dynamic
```json
  dynamic "target" {
      for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
      content {
        subnet_id = var.subnet_id
         address   = target.value
      }
    }
```
Исправляем **output.tf**
```json
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
Проверяем:

    terraform plan
    terraform apply

















## Подготовка образов с помощью packer

1. Создаем новую ветку **packer-base** и переносим скрипты из предыдущего ДЗ в **config-scripts**
2. Устанавливаем packer
3. Создаем сервисный аккаунт в **yc**:
```json
    SVC_ACCT="packeraccess"
    FOLDER_ID="my_folder_id"
    yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```

предоставляем ему права **editor**

       ACCT_ID=$(yc iam service-account get $SVC_ACCT |  grep ^id | awk '{print $2}')
       yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID

создаем IAM ключ

    yc iam key create --service-account-id $ACCT_ID --output ../key.json
4. Создаем шаблон **packer**:

    mkdir -p packer/scripts

    touch packer/ubuntu16.json

    cp config-scripts/install_mongodb.sh ./packer/scripts/

    cp config-scripts/install_ruby.sh ./packer/scripts/

5. Добавляем конфигурацию в файл **ubuntu16.json**:

```json
    {
        "builders": [
            {
                "type": "yandex",
                "service_account_key_file": "../../key.json",
                "folder_id": "my_folder_id",
                "source_image_family": "ubuntu-1604-lts",
                "image_name": "reddit-base-{{timestamp}}",
                "image_family": "reddit-base",
                "ssh_username": "ubuntu",
                "platform_id": "standard-v1"
            }
        ],
        "provisioners": [
            {
                "type": "shell",
                "script": "scripts/install_ruby.sh",
                "execute_command": "sudo {{.Path}}"
            },
            {
                "type": "shell",
                "script": "scripts/install_mongodb.sh",
                "execute_command": "sudo {{.Path}}"
            }
        ]
    }
```
1. Проверяем и собираем образ:

    packer validate ubuntu16.json

    packer build ubuntu16.json

Получаю ошибку:

    ... rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded
Почему: потому что по дефолту можно создать только 2 сети, а у меня в другом фолдере уже была, пришлось ее грохнуть. Можно было сделать запрос на увеличение в [техподдержку](https://cloud.yandex.com/en/docs/vpc/concepts/limits).

и получаю снова ошибку:

  `==> yandex: Failed to find instance ip address: instance has no one IPv4 external address`

лечится добавлением параметра в секцию "builders":
    `"use_ipv4_nat": true`

7. Проверяем работу нашего образа

  Создаем ВМ с созданным ранее загрузочным диском
  Заходим по ssh и устанавливаем **reddit**
  Проверяем доступность по ссылке http://External_IP:9292

8.  Создаем файлы с переменными **variables.json** и **variables.json.example**

!! Не забываем добавить **variables.json** в **.gitignore**

9. Другие параметры билдера:

    `"disk_name": "reddit-base"`
    `"disk_size_gb": "20"`

10.   Делаем bake-образ

  Создаем файл **immutable.json** на основе **ubuntu16.json** (добавляем набор inline команд для установки [https://github.com/express42/reddit.git](https://github.com/express42/reddit.git) с пре-реквизитами)

  Проверяем: `packer validate -var-file=./variables.json ./immutable.json`

  Запускаем создание: `packer build -var-file=./variables.json ./immutable.json`

  Используем созданный образ при создании ВМ, после создания логинимся по ssh т проверяем доступность по ссылке http://Ext_IP:9292

###############################################
## Основные сервисы Yandex Cloud

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
