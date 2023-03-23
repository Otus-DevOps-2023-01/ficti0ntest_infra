# ficti0ntest_infra
ficti0ntest Infra repository

###############################################
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
