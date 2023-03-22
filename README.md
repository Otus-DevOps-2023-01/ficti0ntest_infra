# ficti0ntest_infra
ficti0ntest Infra repository

###############################################
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

