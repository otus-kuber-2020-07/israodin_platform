В корне вашего репозитория создайте каталог kubernetes-
volumes.
Все файлы этого ДЗ помещайте в этот каталог.
 Избавляем бизнес от ИТ-зависимости
2
  Установка и запуск kind
kind - инструмент для запуска Kuberenetes при помощи Docker
контейнеров.
Установка
Запуск
В этом ДЗ мы развернем StatefulSet c MinIO - локальным S3 хранилищем
  kind create cluster
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
  Избавляем бизнес от ИТ-зависимости
3

  Применение StatefulSet конфигурация StatefulSet
Закомитьте конфигурацию под именем minio- statefulset.yaml.
kubectl может брать конфигурацию по HTTP:
В результате применения конфигурации должно произойти следующее:
Запуститься под с MinIO
Создаться PVC
Динамически создаться PV на этом PVC с помощью дефолотного StorageClass
  kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform- snippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml
 Избавляем бизнес от ИТ-зависимости
4

  Применение Headless Service
Для того, чтобы наш StatefulSet был доступен изнутри кластера,
создадим Headless Service
Конфигурация StatefulSet
Закомитьте конфигурацию под именем minio-headless- service.yaml.
  kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform- snippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml
 Избавляем бизнес от ИТ-зависимости
5

  Проверка работы MinIO
Проверить работу Minio можно с помощью консольного клиента
mc.
Также для проверки ресурсов k8s помогут команды:
 kubectl get statefulsets
kubectl get pods
kubectl get pvc
kubectl get pv
kubectl describe <resource> <resource_name>
 Избавляем бизнес от ИТ-зависимости
6

  Задание со *
В конфигурации нашего StatefulSet данные указаны в открытом
виде, что не безопасно.
Поместите данные в secrets и настройте конфигурацию на их использование.
К PR поставьте метку Review Required и не мерджите PR самостоятельно
  Избавляем бизнес от ИТ-зависимости
7

  Удаление кластера Удалить кластер можно командой:
 kind delete cluster
 Избавляем бизнес от ИТ-зависимости
8

  Проверка ДЗ
Результаты вашей работы должны быть добавлены в ветку kubernetes-volumes вашего GitHub репозитория <YOUR_LOGIN>_platform
В README.md рекомендуется внести описание того, что сделано Создайте Pull Request к ветке master (описание PR рекомендуется заполнять)
Добавьте метку kubernetes-volumes к вашему PR
 Избавляем бизнес от ИТ-зависимости
 9.1

Проверка ДЗ
После того как автоматизированные тесты проверят корректность выполнения ДЗ, необходимо сделать merge ветки kubernetes-volumes в master и закрыть PR
Если у вас возникли вопросы по ДЗ и необходима консультация преподавателей - после прохождения автотестов добавьте к PR метку Review Required и не мерджите PR самостоятельно