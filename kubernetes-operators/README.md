+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
k get jobs
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         3m27s
restore-mysql-instance-job   1/1           44s        114s
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

➜  kubernetes-operators git:(kubernetes-operators) ✗ kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data   |
|  3 | some data-2 |
+----+-------------+

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Избавляем бизнес от ИТ-зависимости
Операторы,
CustomResourceDefiniti
on
1 / 51
Избавляем бизнес от ИТ-зависимости
Что с нами будет?
Ветка для работы: kubernetes-operators
В ходе работы мы:
Напишем CustomResource и CustomResourceDefinition для mysql
оператора
🐍 Напишем часть логики mysql оператора при помощи python
KOPF
Сделаем соберем образ и сделаем деплой оператора.
Если делаете часть с 🐍, нужно поставить label 🐍 на Pull request
В данной работе есть задачи в которых необходимо будет
программировать на python, они небязательные (в заголовке
слайда отражены знаком 🐍).
2 / 51
Избавляем бизнес от ИТ-зависимости
Подготовка
Запустите kubernetes кластер в minikube
Создадим директорию kubernetes-operators/deploy :
🐍 В ходе работы понадобится python и различные зависимости
mkdir -p kubernetes-operators/deploy && cd kubernetes-operators
3 / 51
Избавляем бизнес от ИТ-зависимости
Что должно быть в описании MySQL
Для создания pod с MySQL оператору понадобится знать:
. Какой образ с MySQL использовать
. Какую db создать
. Какой пароль задать для доступа к MySQL
То есть мы бы хотели, чтобы описание MySQL выглядело примерно так:
apiVersion: otus.homework/v1
kind: MySQL
metadata:
 name: mysql-instance
spec:
 image: mysql:5.7
 database: otus-database
 password: otuspassword # Так делать не нужно, следует использовать secret
 storage_size: 1Gi
4 / 51
Избавляем бизнес от ИТ-зависимости
CustomResource
Cоздадим CustomResource deploy/cr.yml со следующим
содержимым:
apiVersion: otus.homework/v1
kind: MySQL
metadata:
 name: mysql-instance
spec:
 image: mysql:5.7
 database: otus-database
 password: otuspassword # Так делать не нужно, следует использовать secret
 storage_size: 1Gi
usless_data: "useless info"
gist
5 / 51
Избавляем бизнес от ИТ-зависимости
CustomResource
Пробуем применить его:
Видим ошибку:
Ошибка связана с отсутсвием объектов типа MySQL в API kubernetes.
Исправим это недоразумение.
kubectl apply -f deploy/cr.yml
error: unable to recognize "deploy/cr.yml": no matches for kind "MySQL" in version
"otus.homework/v1"
6 / 51
Избавляем бизнес от ИТ-зависимости
CustomResourceDefinition
CustomResourceDefinition - это ресурс для определения других
ресурсов (далее CRD)
Создадим CRD deploy/crd.yml gist:
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
 name: mysqls.otus.homework # имя CRD должно иметь формат plural.group
spec:
 scope: Namespaced # Данный CRD будер работать в рамках namespace
 group: otus.homework # Группа, отражается в поле apiVersion CR
 versions: # Список версий
 - name: v1
 served: true # Будет ли обслуживаться API-сервером данная версия
 storage: true # Версия описания, которая будет сохраняться в etcd
 names: # различные форматы имени объекта CR
 kind: MySQL # kind CR
 plural: mysqls
 singular: mysql
 shortNames:
 - ms
7 / 51
Избавляем бизнес от ИТ-зависимости
Создаем CRD и CR
Создадим CRD:
Cоздаем CR:
kubectl apply -f deploy/crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created
kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created
8 / 51
Избавляем бизнес от ИТ-зависимости
Взаимодействие с объектами CR CRD
C созданными объектами можно взаимодействовать через kubectl:
kubectl get crd
kubectl get mysqls.otus.homework
kubectl describe mysqls.otus.homework mysql-instance
...
9 / 51
Избавляем бизнес от ИТ-зависимости
Validation
На данный момент мы никак не описали схему нашего CustomResource.
Объекты типа mysql могут иметь абсолютно произвольные поля, нам бы
хотелось этого избежать, для этого будем использовать validation. Для
начала удалим CR mysql-instance:
Добавим в спецификацию CRD ( spec ) параметры validation
kubectl delete mysqls.otus.homework mysql-instance
gist
10 / 51
Избавляем бизнес от ИТ-зависимости
Validation
 validation:
 openAPIV3Schema:
 type: object
 properties:
 apiVersion:
 type: string # Тип данных поля ApiVersion
 kind:
 type: string # Тип данных поля kind
 metadata:
 type: object # Тип поля metadata
 properties: # Доступные параметры и их тип данных поля metadata (словарь)
 name:
 type: string
 spec:
 type: object
 properties:
 image:
 type: string
 database:
 type: string
 password:
 type: string
 storage_size:
 type: string
11 / 51
Избавляем бизнес от ИТ-зависимости
Пробуем применить CRD и CR
Убираем из cr.yml:
Применяем:
Ошибки больше нет
kubectl apply -f deploy/crd.yml
kubectl apply -f deploy/cr.yml
error: error validating "deploy/cr.yml": error validating data:
ValidationError(MySQL): unknown field "usless_data" in homework.otus.v1.MySQL; if
you choose to ignore these errors, turn validation off with --validate=false
usless_data: "useless info"
kubectl apply -f deploy/cr.yml
12 / 51
Избавляем бизнес от ИТ-зависимости
Задание по CRD:
Если сейчас из описания mysql убрать строчку из спецификации, то
манифест будет принят API сервером. Для того, чтобы этого избежать,
добавьте описание обязательный полей в CustomResourceDefinition
Подсказка. Пример есть в лекции.
13 / 51
Избавляем бизнес от ИТ-зависимости
Операторы
Оператор включает в себя CustomResourceDefinition и сustom
сontroller
CRD содержит описание объектов CR
Контроллер следит за объектами определенного типа, и
осуществляет всю логику работы оператора
CRD мы уже создали далее будем писать свой контроллер (все задания
по написанию контроллера дополнительными)
Далее развернем custom controller:
Если вы делаете задания с 🐍, то ваш
Если нет, то используем готовый контроллер
14 / 51
Избавляем бизнес от ИТ-зависимости
Описание контроллера
Используемый/написанный нами контроллер будет обрабатывать два
типа событий:
1) При создании объекта типа ( kind: mySQL ), он будет:
2) При удалении объекта типа ( kind: mySQL ), он будет:
* Cоздавать PersistentVolume, PersistentVolumeClaim, Deployment, Service для mysql
* Создавать PersistentVolume, PersistentVolumeClaim для бэкапов базы данных, если их
еще нет.
* Пытаться восстановиться из бэкапа
* Удалять все успешно завершенные backup-job и restore-job
* Удалять PersistentVolume, PersistentVolumeClaim, Deployment, Service для mysql
15 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
В папке kubernetes-operators/build создайте файл mysqloperator.py . Для написания контроллера будем использовать kopf.
Добавим в него импорт необходимых библиотек
import kopf
import yaml
import kubernetes
import time
from jinja2 import Environment, FileSystemLoader
16 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
В дирректории kubernetes-operators/build/templates создайте шаблоны:
mysql-deployment.yml.j2
mysql-service.yml.j2
mysql-pv.yml.j2
mysql-pvc.yml.j2
backup-pv.yml.j2
backup-pvc.yml.j2
backup-job.yml.j2
restore-job.yml.j2
gist
gist
gist
gist
gist
gist
gist
gist
17 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Добавим функцию, для обработки Jinja шаблонов и преобразования
YAML в JSON:
def render_template(filename, vars_dict):
 env = Environment(loader=FileSystemLoader('./templates'))
 template = env.get_template(filename)
 yaml_manifest = template.render(vars_dict)
 json_manifest = yaml.load(yaml_manifest)
 return json_manifest
18 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Ниже добавим декоратор:
Функция mysql_on_create будет запускаться при создании объектов типа
MySQL.
@kopf.on.create('otus.homework', 'v1', 'mysqls')
# Функция, которая будет запускаться при создании объектов тип MySQL:
def mysql_on_create(body, spec, **kwargs):
 name = body['metadata']['name']
 image = body['spec']['image'] # cохраняем в переменные содержимое описания
MySQL из CR
 password = body['spec']['password']
 database = body['spec']['database']
 storage_size = body['spec']['storage_size']
19 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Добавим в декоратор рендер шаблонов:
 # Генерируем JSON манифесты для деплоя
 persistent_volume = render_template('mysql-pv.yml.j2',
 {'name': name,
 'storage_size': storage_size})
 persistent_volume_claim = render_template('mysql-pvc.yml.j2',
 {'name': name,
 'storage_size': storage_size})
 service = render_template('mysql-service.yml.j2', {'name': name})
 deployment = render_template('mysql-deployment.yml.j2', {
 'name': name,
 'image': image,
 'password': password,
 'database': database})
20 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Для создания объектов пользуемся библиотекой kubernetes:
 api = kubernetes.client.CoreV1Api()
 # Создаем mysql PV:
 api.create_persistent_volume(persistent_volume)
 # Создаем mysql PVC:
 api.create_namespaced_persistent_volume_claim('default',
persistent_volume_claim)
 # Создаем mysql SVC:
 api.create_namespaced_service('default', service)
 # Создаем mysql Deployment:
 api = kubernetes.client.AppsV1Api()
 api.create_namespaced_deployment('default', deployment)
21 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Сейчас должно получиться, что-то похожее на
С такой конфигурацие уже должны обрабатываться события при
создании cr.yml, проверим, для этого из папки build:
Если cr.yml был до этого применен, то вы увидите:
Вопрос: почему объект создался, хотя мы создали CR, до того, как
запустили контроллер?
gist
kopf run mysql-operator.py
[2019-09-16 22:47:33,662] kopf.objects [INFO ] [default/mysql-instance]
Handler 'mysql_on_create' succeeded.
[2019-09-16 22:47:33,662] kopf.objects [INFO ] [default/mysql-instance]
All handlers succeeded for creation.
22 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Если сделать kubectl delete mysqls.otus.homework mysqlinstance , то CustomResource будет удален, но наш контроллер ничего не
сделает т. к обработки событий на удаление у нас нет.
Удалим все ресурсы, созданные контроллером:
kubectl delete mysqls.otus.homework mysql-instance
kubectl delete deployments.apps mysql-instance
kubectl delete pvc mysql-instance-pvc
kubectl delete pv mysql-instance-pv
kubectl delete svc mysql-instance
23 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Для того, чтобы обработать событие удаления ресурса используется
другой декоратор, в нем можно описать удаление ресурсов, аналогично
тому, как мы их создавали, но есть более удобный метод.
Для удаления ресурсов, сделаем deployment,svc,pv,pvc дочерними
ресурсами к mysql, для этого в тело функции mysql_on_create , после
генерации json манифестов добавим:
 # Определяем, что созданные ресурсы являются дочерними к управляемому
CustomResource:
 kopf.append_owner_reference(persistent_volume, owner=body)
 kopf.append_owner_reference(persistent_volume_claim, owner=body) # addopt
 kopf.append_owner_reference(service, owner=body)
 kopf.append_owner_reference(deployment, owner=body)
 # ^ Таким образом при удалении CR удалятся все, связанные с ним pv,pvc,svc,
deployments
24 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
В конец файла добавим обработку события удаления ресурса mysql:
Перезапустите контроллер, создайте и удалите mysql-instance,
проверьте, что все pv, pvc, svc и deployments удалились.
Актуальное состояние контроллера можно подсмиотреть в
@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body, **kwargs):
 return {'message': "mysql and its children resources deleted"}
gist
25 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Теперь добавим создание pv, pvc для backup и restore job. Для этого
после создания deployment добавим следующий код:
 # Cоздаем PVC и PV для бэкапов:
 try:
 backup_pv = render_template('backup-pv.yml.j2', {'name': name})
 api = kubernetes.client.CoreV1Api()
 api.create_persistent_volume(backup_pv)
 except kubernetes.client.rest.ApiException:
 pass
 try:
 backup_pvc = render_template('backup-pvc.yml.j2', {'name': name})
 api = kubernetes.client.CoreV1Api()
 api.create_namespaced_persistent_volume_claim('default', backup_pvc)
 except kubernetes.client.rest.ApiException:
 pass
26 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Конструкция try, except - это обработка исключений, в данном случае,
нужна, чтобы наш контроллер не пытался бесконечно пересоздать pv и pvc
для бэкапов, т к их жизненный цикл отличен от жизненного цикла mysql.
Далее нам необходимо реализовать создание бэкапов и
восстановление из них. Для этого будут использоваться Job. Поскольку при
запуске Job, повторно ее запустить нельзя, нам нужно реализовать логику
удаления успешно законченных jobs c определенным именем.
...
27 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Для этого выше всех обработчиков событий (под функций
render_template) добавим следующую функцию:
def delete_success_jobs(mysql_instance_name):
 api = kubernetes.client.BatchV1Api()
 jobs = api.list_namespaced_job('default')
 for job in jobs.items:
 jobname = job.metadata.name
 if (jobname == f"backup-{mysql_instance_name}-job"):
 if job.status.succeeded == 1:
 api.delete_namespaced_job(jobname,
 'default',
 propagation_policy='Background')
28 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Также нам понадобится функция, для ожидания пока наша backup job
завершится, чтобы дождаться пока backup выполнится перед удалением
mysql deployment, svc, pv, pvc.
Опишем ее:
def wait_until_job_end(jobname):
 api = kubernetes.client.BatchV1Api()
 job_finished = False
 jobs = api.list_namespaced_job('default')
 while (not job_finished) and \
 any(job.metadata.name == jobname for job in jobs.items):
 time.sleep(1)
 jobs = api.list_namespaced_job('default')
 for job in jobs.items:
 if job.metadata.name == jobname:
 if job.status.succeeded == 1:
 job_finished = True
29 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Добавим запуск backup-job и удаление выполненных jobs в функцию
delete_object_make_backup :
Акутальное состояние контроллера
 name = body['metadata']['name']
 image = body['spec']['image']
 password = body['spec']['password']
 database = body['spec']['database']
 delete_success_jobs(name)
 # Cоздаем backup job:
 api = kubernetes.client.BatchV1Api()
 backup_job = render_template('backup-job.yml.j2', {
 'name': name,
 'image': image,
 'password': password,
 'database': database})
 api.create_namespaced_job('default', backup_job)
 wait_until_job_end(f"backup-{name}-job")
gist
30 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Добавим генерацию json из шаблона для restore-job
Добавим попытку восстановиться из бэкапов после deployment mysql:
 restore_job = render_template('restore-job.yml.j2', {
 'name': name,
 'image': image,
 'password': password,
 'database': database})
 # Пытаемся восстановиться из backup
 try:
 api = kubernetes.client.BatchV1Api()
 api.create_namespaced_job('default', restore_job)
 except kubernetes.client.rest.ApiException:
 pass
31 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Добавим зависимость restore-job от объектов mysql (возле других
owner_reference):
Вот и готово. Запускаем оператор (из директории build):
Создаем CR:
Актуальное состояние контроллера
kopf.append_owner_reference(restore_job, owner=body)
kopf run mysql-operator.py
kubectl apply -f deploy/cr.yml
gist
32 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Проверяем что появились pvc:
kubectl get pvc
NAME STATUS VOLUME
CAPACITY ACCESS MODES STORAGECLASS AGE
backup-mysql-instance-pvc Bound pvc-22eace9a-89e6-4926-8949-cc62cb6489af 1Gi
RWO standard 35s
mysql-instance-pvc Bound pvc-b7d25705-15d7-49a5-97cb-aeccd938e611 1Gi
RWO standard 35s
33 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Проверим, что все работает, для этого заполним базу созданного mysqlinstance:
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (
id smallint unsigned not null auto_increment, name varchar(20) not null, constraint
pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name
) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name )
VALUES ( null, 'some data-2' );" otus-database
34 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Посмотри содержимое таблицы:
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otusdatabase
+----+-------------+
| id | name |
+----+-------------+
| 1 | some data |
| 2 | some data-2 |
+----+-------------+
35 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Удалим mysql-instance:
Теперь kubectl get pv показывает, что PV для mysql больше нет, а
kubectl get jobs.batch показывает:
Если Job не выполнилась или выполнилась с ошибкой, то ее нужно
удалять в ручную, т к иногда полезно посмотреть логи
kubectl delete mysqls.otus.homework mysql-instance
NAME COMPLETIONS DURATION AGE
backup-mysql-instance-job 1/1 2s 2m39s
36 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Создадим заново mysql-instance:
Немного подождем и:
Должны увидеть:
kubectl apply -f deploy/cr.yml
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otusdatabase
+----+-------------+
| id | name |
+----+-------------+
| 1 | some data |
| 2 | some data-2 |
+----+-------------+
37 / 51
Избавляем бизнес от ИТ-зависимости
🐍 MySQL контроллер
Мы убедились, что наш контроллер работает, теперь нужно его
остановить и собрать Docker образ с ним. В директории build создайте
Dockerfile:
Соберите и сделайте push в dockerhub ваш образ с оператором.
FROM python:3.7
COPY templates ./templates
COPY mysql-operator.py ./mysql-operator.py
RUN pip install kopf kubernetes pyyaml jinja2
CMD kopf run /mysql-operator.py
38 / 51
Избавляем бизнес от ИТ-зависимости
Деплой оператора
Создайте в папке kubernetes-operator/deploy:
Если вы делали задачи со 🐍 , то поменяйте используемый в deployoperator.yml образ.
service-account.yml
role.yml
role-binding.yml
deploy-operator.yml
39 / 51
Избавляем бизнес от ИТ-зависимости
Деплой оператора
Примените манифесты:
service-account.yml
role.yml
role-binding.yml
deploy-operator.yml
40 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Создаем CR (если еще не создан):
kubectl apply -f deploy/cr.yml
41 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Проверяем что появились pvc:
kubectl get pvc
NAME STATUS VOLUME
CAPACITY ACCESS MODES STORAGECLASS AGE
backup-mysql-instance-pvc Bound pvc-22eace9a-89e6-4926-8949-cc62cb6489af 1Gi
RWO standard 35s
mysql-instance-pvc Bound pvc-b7d25705-15d7-49a5-97cb-aeccd938e611 1Gi
RWO standard 35s
42 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Заполним базу созданного mysql-instance:
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test (
id smallint unsigned not null auto_increment, name varchar(20) not null, constraint
pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name
) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name )
VALUES ( null, 'some data-2' );" otus-database
43 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Посмотри содержимое таблицы:
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otusdatabase
+----+-------------+
| id | name |
+----+-------------+
| 1 | some data |
| 2 | some data-2 |
+----+-------------+
44 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Удалим mysql-instance:
Теперь kubectl get pv показывает, что PV для mysql больше нет, а
kubectl get jobs.batch показывает:
Если Job не выполнилась или выполнилась с ошибкой, то ее нужно
удалять в ручную, т к иногда полезно посмотреть логи
kubectl delete mysqls.otus.homework mysql-instance
NAME COMPLETIONS DURATION AGE
backup-mysql-instance-job 1/1 2s 2m39s
45 / 51
Избавляем бизнес от ИТ-зависимости
Проверим, что все работает
Создадим заново mysql-instance:
Немного подождем и:
Должны увидеть:
kubectl apply -f deploy/cr.yml
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otusdatabase
+----+-------------+
| id | name |
+----+-------------+
| 1 | some data |
| 2 | some data-2 |
+----+-------------+
46 / 51
Избавляем бизнес от ИТ-зависимости
Проверка | tree
Содержимое папки kubernetes-operators, если вы не делали задачи с 🐍:
└── deploy
 ├── cr.yml
 ├── crd.yml
 ├── deploy-operator.yml
 ├── role-binding.yml
 ├── role.yml
 └── service-account.yml
47 / 51
Избавляем бизнес от ИТ-зависимости
Проверка | tree 🐍
Содержимое папки kubernetes-operators, если вы делали задачи с 🐍:
├── build
│ ├── Dockerfile
│ ├── mysql-operator.py
│ └── templates
│ ├── backup-job.yml.j2
│ ├── backup-pv.yml.j2
│ ├── backup-pvc.yml.j2
│ ├── mysql-deployment.yml.j2
│ ├── mysql-pv.yml.j2
│ ├── mysql-pvc.yml.j2
│ ├── mysql-service.yml.j2
│ └── restore-job.yml.j2
└── deploy
 ├── cr.yml
 ├── crd.yml
 ├── deploy-operator.yml
 ├── role-binding.yml
 ├── role.yml
 └── service-account.yml
48 / 51
Избавляем бизнес от ИТ-зависимости
Проверка
Сделайте PR в ветку kubernetes-operators
Добавьте label с номером домашнего задания
Добавьте label с 🐍, если выполнили задания со 🐍
Добавьте в README вывод комманды kubectl get jobs (там должны
быть успешно выполненные backup и restore job)
Приложетие вывод при запущенном MySQL:
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="
{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otusdatabase
49 / 51
Избавляем бизнес от ИТ-зависимости
🐍 Задание со 🌟 (1)
Исправить контроллер, чтобы он писал в status subresource
Описать изменения в README.md (показать код, объяснить, что он делает)
В README показать, что в status происходит запись
Например, при успешном создании mysql-instance, kubectl describe
mysqls.otus.homework mysql-instance может показывать:
Status:
 Kopf:
 mysql_on_create:
 Message: mysql-instance created without restore-job
50 / 51
Избавляем бизнес от ИТ-зависимости
🐍 Задание со 🌟 (2)
Добавить в контроллер логику обработки изменений CR:
Например, реализовать смену пароля от MySQL, при изменении
этого параметра в описании mysql-instance
В README:
Показать, что код работает
Объяснить, что он делает
51 / 51
