
###install nginx-ingress
helm3 repo add stable https://kubernetes-charts.storage.googleapis.com
helm3 repo  list
kubectl create ns nginx-ingress
helm3 upgrade --install nginx-ingress stable/nginx-ingress --wait  --namespace=nginx-ingress --version=1.39.0

####install cert-manager
helm3 repo add jetstack https://charts.jetstack.io
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager-legacy.crds.yaml
kubectl create ns cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
helm3 upgrade --install cert-manager jetstack/cert-manager --wait  --namespace=cert-manager --version=0.15.1
helm3 install cert-manager jetstack/cert-manager  --namespace cert-manager  --version v0.15.1 
kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-766d5c494b-d9mkq              1/1     Running   0          14s
cert-manager-cainjector-6649bbb695-cpk46   1/1     Running   0          14s
cert-manager-webhook-68d464c8b-9mfpv       1/1     Running   0          14s

kubectl apply -f cluster-issuer-prod.yaml
kubectl apply -f cluster-issuer-stage.yaml

###install chartmuseum
kubectl create ns chartmuseum
helm3 upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.13.0 -f kubernetes-templating/chartmuseum/values.yaml

###install harbor
kubectl create ns harbor
helm3 repo add harbor https://helm.goharbor.io
helm3 repo update
helm3 upgrade --install harbor harbor/harbor --wait --namespace=harbor --version=1.3.2 -f ../harbor/values.yaml

chartmuseum | Задание со ⭐
Научимся работать с chartmuseum и зальем в наш репозиторий - примеру frontend
Добавяем наш репозитарий
helm repo add chartmuseum https://chartmuseum.104.154.141.175.nip.io/
"chartmuseum" has been added to your repositories
Проверяем линтером
helm lint
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
Пакуем
helm package .
Successfully packaged chart and saved it to: /Users/alexey/kovtalex_platform/kubernetes-templating/frontend/frontend-0.1.0.tgz

Заливаем
curl -L --data-binary "@frontend-0.1.0.tgz" https://chartmuseum.35.189.202.237.nip.io/api/charts
{"saved":true}
Обновляем список repo
helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "templating" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
Ищем наш frontend в репозитории
helm search repo -l chartmuseum/
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
chartmuseum/frontend    0.1.0           1.16.0          A Helm chart for Kubernetes
И выкатываем
helm upgrade --install frontend chartmuseum/frontend --namespace hipster-shop
Release "frontend" does not exist. Installing it now.
NAME: frontend
LAST DEPLOYED: Sat May 30 01:59:17 2020
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 1
TEST SUITE: None

Создаем свой helm chart
helm create kubernetes-templating/hipster-shop
**********************************************************
Mы будем создавать chart для приложения с нуля, поэтому
удалите values.yaml и содержимое templates.
После этого перенесите https://github.com/express42/otus-platform-snippets/blob/master/Module-04/05-Templating/manifests/all-hipster-shop.yaml all-hipster-shop.yaml в
директорию templates.
*******************************************
kubectl create ns hipster-shop
helm3 upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop

helm create kubernetes-templating/frontend
**************************************************************************************
Аналогично чарту hipster-shop удалите файл values.yaml и
файлы в директории templates, создаваемые по умолчанию.
Выделим из файла all-hipster-shop.yaml манифесты для
установки микросервиса frontend.
В директории templates чарта frontend создайте файлы:
deployment.yaml - должен содержать соответствующую часть из
файла all-hipster-shop.yaml
service.yaml - должен содержать соответствующую часть из файла
all-hipster-shop.yaml
ingress.yaml - должен разворачивать ingress с доменным именем
shop.<IP-адрес>.nip.io
************************************************************
helm3 upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop

***********************************************************
Как должен выглядеть минимальный итоговый файл
values.yaml:
image:
tag: v0.1.3
replicas: 1
service:
type: NodePort
port: 80
targetPort: 8079
NodePort: 30001
*******************************************************************

Добавьте chart frontend как зависимость
Обновим зависимости:
При указании зависимостей в старом формате, все будет
работать, единственное выдаст предупреждение. Подробнее
dependencies:
- name: frontend
version: 0.1.0
repository: "file://../frontend"

helm dep update kubernetes-templating/hipster-shop


helm-secret :
brew install sops
brew install gnupg2
brew install gnu-getopt
helm3 plugin install https://github.com/futuresimple/helm-secrets --version 2.0.2

Сгенерируем новый PGP ключ:
gpg --full-generate-key
После этого командой gpg -k можно проверить, что ключ появился:
gpg -k
gpg: проверка таблицы доверия
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: глубина: 0  достоверных:   1  подписанных:   0  доверие: 0-, 0q, 0n, 0m, 0f, 1u
/Users/alexey/.gnupg/pubring.kbx
--------------------------------
gpg: /Users/israodin/.gnupg/trustdb.gpg: trustdb created
gpg: key 032144ACBB81B5D1 marked as ultimately trusted
gpg: directory '/Users/israodin/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/Users/israodin/.gnupg/openpgp-revocs.d/40B1EA134466C791D4C2E056032144ACBB81B5D1.rev'
public and secret key created and signed.

pub   rsa2048 2020-06-21 [SC]
      40B1EA134466C791D4C2E056032144ACBB81B5D1
uid                      israodin <israodin@gmail.com>
sub   rsa2048 2020-06-21 [E]

 sops -e -i --pgp 40B1EA134466C791D4C2E056032144ACBB81B5D1 ../frontend/templates/secrets.yaml
###########################################################################################################################
Проверим, что файл secrets.yaml изменился. Сейчас его содержание должно выглядеть примерно так:
apiVersion: ENC[AES256_GCM,data:ZdY=,iv:oS+DntCpb0QMi8O/p3L0lKWguEYkxsq+UFH0wwlQ4vg=,tag:RrXbBxBHTVDEibSq0clF1g==,type:str]
kind: ENC[AES256_GCM,data:H8/7i+eu,iv:qNT/iduXr5T1uzkAgi+NF62x/geHN+ffkaAfnodg1ss=,tag:ylGbbSb86UL57PN8SYtr1w==,type:str]
metadata:
    name: ENC[AES256_GCM,data:AnkEj6xh/cc=,iv:DYUifDLuKfnqhZ+j+oHO1p0sXrMYFjj5dmq/cbCbKmg=,tag:Tp8TzIP9Px0sja2JnVeNFQ==,type:str]
type: ENC[AES256_GCM,data:mz3XdinB,iv:YvvycZnPQtTaPlciQ0trqZHyFqrdKYRJD8+gP2zb2wo=,tag:wEQbaHiZ8DGLt3h9BzmYjg==,type:str]
data:
    username: ENC[AES256_GCM,data:EBTa9a9DR2c=,iv:6weqsjV1UTxHZ7qo27MIUtj+wVbBxKWYsre6nyxPIEs=,tag:bEaC87mks2mZ2uhpjJoRtw==,type:str]
    password: ENC[AES256_GCM,data:Jor0cf5aK15U3D24KTnBSA==,iv:UWa0uw3HxNcu/jmslNSZ8Wd53O5ApssSf6oPvtGLPQs=,tag:+reilK+tYX6nY47KbRb1Yg==,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    lastmodified: '2020-06-21T20:52:49Z'
    mac: ENC[AES256_GCM,data:auOdf02dcYMq+oUkSK9oPvTzIYc2MH1O4t0gd8i/XNOVIu01tsdXP9r5NzEa6oNjy/GUQC+ROaLEZ2E+nlzFEmCZCDcvLcfj7wcthSzaf2x43ZGYiyMtLuzvFodJTDDqmqc1qpU0TLw+Trqgqclic7B63MjVTRVrOoT21lqm3aE=,iv:ezmG0xInvNbQ47IQJXPdr/q/U8triPsxsOX4m88m6Mc=,tag:wqtmFNTFdtfqNnuai5+/eQ==,type:str]
    pgp:
    -   created_at: '2020-06-21T20:52:48Z'
        enc: |
            -----BEGIN PGP MESSAGE-----

            hQEMAxT/S+RMgmM+AQgAsDJLbUWvBPf4ygF99BgmWRmfFSbSUBgdGGLv0wLq+Mg0
            gYD/yFcH+JerAUWwfKbwJxEf+J0/lkY9cg+SsRuMDTVp42Rcwy/YiQg0ecApkDMd
            y9raAcNKn7H+0uFZlqJz3Q0cdewtvMHdioTa1d6ysqodkvkV0uZNS5NKxWMaGe6Z
            HUDnUgCDHsy2QZ0xqcgjZ1FGRNL97/pdJf9/MKam9cBgNH7skCPyCpnZZdotB++2
            /X+1PlRAU6PAikzKOBxIMQEMmCGe3xtlZQ7pZKIGKHN8MJ2kx7NBKzBOMCHEpJzY
            isA3vf0f9tV7AL9NoUMCP7RyO+e2Caj5iLN9ldJsu9JeAQC8mNKkzAIxHFA2jnYe
            V2PXNnXPX4Ql5YUz5tHqJ2eWFbI3jjHUNHDWijSIR3Gs56B5Rw0g1HLFeSfoSvcZ
            apEphJAYb4z5ELOjRQ8tyxJpTaCz2DXdpQ0lBmzHLQ==
            =IKbG
            -----END PGP MESSAGE-----
        fp: 40B1EA134466C791D4C2E056032144ACBB81B5D1
    unencrypted_suffix: _unencrypted
    version: 3.5.0
Создадим новый файл secrets.yaml в директории kubernetestemplating/frontend со следующим содержимым:
visibleKey: hiddenValue


Заметим, что структура файла осталась прежней. Мы видим ключ visibleKey, но его значение зашифровано
В таком виде файл уже можно коммитить в Git, но для начала - научимся расшифровывать его.
Можно использовать любой из инструментов:

helm secrets view secrets.yaml

Можно использовать любой из инструментов:
# helm secrets
helm secrets view secrets.yaml

# sops
sops -d secrets.yaml
helm secrets view kubernetes-templating/frontend/secrets.yaml
visibleKey: hiddenValue
sops -d kubernetes-templating/frontend/secrets.yaml
visibleKey: hiddenValue
Теперь осталось понять, как добавить значение нашего секрета в настоящий секрет kubernetes и устанавливать его вместе с основным helm chart.
Создадим в директории kubernetestemplating/frontend/templates еще один файл secret.yaml.
Несмотря на похожее название его предназначение будет отличаться.

helm secrets upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop \
-f kubernetes-templating/frontend/values.yaml \
-f kubernetes-templating/frontend/secrets.yaml


Поместим все получившиеся helm chart's в наш установленный harbor в публичный проект.
Установим helm-push
helm plugin install https://github.com/chartmuseum/helm-push.git
Создадим файл kubernetes-templating/repo.sh со следующим содержанием:
#!/bin/bash
helm repo add templating https://harbor.35.189.202.237.nip.io/chartrepo/library

helm push --username admin --password Harbor12345  frontend/ templating
helm push --username admin --password Harbor12345  hipster-shop/ templating
./repo.sh
"templating" has been added to your repositories
Pushing frontend-0.1.0.tgz to templating...
Done.
Pushing hipster-shop-0.1.0.tgz to templating...
Done.
Проверим:
Представим, что одна из команд разрабатывающих сразу несколько микросервисов нашего продукта решила, что helm не подходит для ее нужд и попробовала использовать решение на основе jsonnet - kubecfg.
Посмотрим на возможности этой утилиты. Работать будем с сервисами paymentservice и shippingservice. Для начала - вынесем манифесты описывающие service и deployment для этих микросервисов из файла all-hipstershop.yaml в директорию kubernetes-templating/kubecfg
Проверим:
helm search repo -l templating
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
templating/frontend     0.1.0           1.16.0          A Helm chart for Kubernetes
templating/hipster-shop 0.1.0           1.16.0          A Helm chart for Kubernetes
И развернем:
helm upgrade --install hipster-shop templating/hipster-shop --namespace hipster-shop
helm upgrade --install frontend templating/frontend --namespace hipster-shop


Kubecfg
Представим, что одна из команд разрабатывающих сразу несколько микросервисов нашего продукта решила, что helm не подходит для ее нужд и попробовала использовать решение на основе jsonnet - kubecfg.
Посмотрим на возможности этой утилиты. Работать будем с сервисами paymentservice и shippingservice.
Для начала - вынесем манифесты описывающие service и deployment для этих микросервисов из файла all-hipstershop.yaml в директорию kubernetes-templating/kubecfg
В итоге должно получиться четыре файла:
tree -L 1 kubecfg
kubecfg
├── paymentservice-deployment.yaml
├── paymentservice-service.yaml
├── shippingservice-deployment.yaml
└── shippingservice-service.yaml
Можно заметить, что манифесты двух микросервисов очень похожи друг на друга и может иметь смысл генерировать их из какого-то шаблона.


gpg --full-generate-key
sops -e -i --pgp B31B7A4D262506810D1BBB09BD8C87245FC85F07 kubernetes-templating/frontend/secrets.yaml
helm3 secrets view kubernetes-templating/frontend/secrets.yaml