Установка программного обеспечения в кластерах Kubernetes с помощью диспетчера пакетов Helm
Kubernetes

By Brian Boucheron

PostedJanuary 24, 2020 2.4kviews
Введение
Helm — это диспетчер пакетов для Kubernetes, который облегчает для разработчиков и операторов настройку и развертывание приложений в кластерах Kubernetes.

В ходе этого руководства мы настроим Helm и будем использовать его для установки, изменения конфигурации, отката изменений и последующего удаления приложения Kubernetes Dashboard. Dashboard — это официальный графический пользовательский веб-интерфейс Kubernetes.

С общим описанием Helm и его экосистемы пакетов можно ознакомиться в статье Знакомство с Helm.

Предварительные требования
В ходе данного обучающего руководства вам потребуется следующее:

Кластер Kubernetes 1.8+ с включенным контролем доступа на основе ролей (RBAC).
Инструмент командной строки kubectl, установленный на локальном компьютере и настроенный для подключения к вашему кластеру. Дополнительную информацию об установке kubectl можно найти в официальной документации.
Вы можете протестировать подключение с помощью следующей команды:

   kubectl cluster-info
Отсутствие ошибок означает, что вы успешно подключились к кластеру. Если у вас есть доступ к нескольким кластерам с kubectl, убедитесь, что вы выбрали правильный контекст кластера:

   kubectl config get-contexts
Output
      CURRENT   NAME                    CLUSTER                      AUTHINFO                      NAMESPACE
   *         do-nyc1-k8s-example     do-nyc1-k8s-example          do-nyc1-k8s-example-admin
             docker-for-desktop      docker-for-desktop-cluster   docker-for-desktop
В этом примере символ звездочки (*) показывает, что мы подключены к кластеру do-nyc1-k8s-example. Чтобы переключаться между запущенными кластерами:

   kubectl config use-context context-name
Когда вы будете подключены к нужному кластеру, перейдите к шагу 1 для начала установки Helm.

Шаг 1 — Установка Helm
Сначала мы установим утилиту командной строки helm на локальном компьютере. Helm предоставляет скрипт, который отвечает за процесс установки на MacOS, Windows или Linux.

Перейдите в директорию с возможностью записи и загрузите скрипт из репозитория Helm на GitHub:

cd /tmp
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh
Сделайте скрипт исполняемым с помощью команды chmod:

chmod u+x install-helm.sh
Сейчас вы можете воспользоваться текстовым редактором, чтобы открыть скрипт и изучить его, чтобы убедиться в его безопасности. Когда вы будете удовлетворены, запустите его:

./install-helm.sh
Возможно, вам придется ввести пароль. Введите пароль и нажмите ENTER.

Output
helm installed into /usr/local/bin/helm
Run 'helm init' to configure helm.
Далее мы закончим процесс установки, добавив некоторые компоненты Helm в наш кластер.

Шаг 2 — Установка Tiller
Tiller — это спутник команды helm, который запускается на вашем кластере, получает команды от helm и связывается непосредственно с API Kubernetes для выполнения задач по созданию и удалению ресурсов. Чтобы предоставить Tiller права доступа, которые ему необходимы для запуска на кластере, мы создадим ресурс Kubernetes serviceaccount.

Примечание: мы привяжем serviceaccount к роли кластера cluster-admin. В результате суперпользователь службы tiller получит доступ к кластеру и позволит ему устанавливать все типы ресурсов в любых пространствах имен. Это допустимо при изучении Helm, но вам может потребоваться более изолированная конфигурацию для рабочего кластера Kubernetes.

См. официальную документацию Helm по управлению доступом на основе ролей для получения дополнительной информации по настройке различных сценариев управления на основе ролей в случае Tiller.

Создадим serviceaccount для tiller:

kubectl -n kube-system create serviceaccount tiller
Затем мы привяжем serviceaccount tiller к роли cluster-admin:

kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
Теперь мы можем запустить helm init для установки Tiller в нашем кластере, а также выполнения ряда локальных задач, таких как загрузка данных репозитория stable:

helm init --service-account tiller
Output
. . .

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
Чтобы убедиться, что Tiller запущен, запросите список подов в пространстве имен kube-system:

kubectl get pods --namespace kube-system
Output
NAME                                    READY     STATUS    RESTARTS   AGE
. . .
kube-dns-64f766c69c-rm9tz               3/3       Running   0          22m
kube-proxy-worker-5884                  1/1       Running   1          21m
kube-proxy-worker-5885                  1/1       Running   1          21m
kubernetes-dashboard-7dd4fc69c8-c4gwk   1/1       Running   0          22m
tiller-deploy-5c688d5f9b-lccsk          1/1       Running   0          40s
Имя пода Tiller начинается с префикса tiller-deploy-​​​.

Теперь, когда мы установили оба компонента Helm, мы готовы к использованию helm для установки первого приложения.

Шаг 3 — Установка чарта Helm
Пакеты программного обеспечения Helm называются чартами. Helm предоставляется вместе с репозиторием рекомендованных чартов с именем stable. Вы можете просматривать доступные чарты в соответствующем репозитории GitHub. Мы будем в качестве примера устанавливать Kubernetes Dashboard​​​.

Используйте helm для установки пакета kubernetes-dashboard из репозитория stable:

helm install stable/kubernetes-dashboard --name dashboard-demo
Output
NAME:   dashboard-demo
LAST DEPLOYED: Wed Aug  8 20:11:07 2018
NAMESPACE: default
STATUS: DEPLOYED

. . .
Обратите внимание на строку NAME, выделенную в примере вывода выше. В этом случае мы задали имя dashboard-demo. Это имя нашего релиза. Релиз Helm — это отдельное развертывание одного чарта с конкретной конфигурацией. Вы можете развернуть несколько релизов одного чарта, и у каждого из них может быть своя конфигурация.

Если вы не укажете собственное имя релиза с помощью --name, Helm создаст для вас случайное имя.

Мы можем попросить Helm представить список релизов в этом кластере:

helm list
Output
NAME            REVISION    UPDATED                     STATUS      CHART                       NAMESPACE
dashboard-demo    1           Wed Aug  8 20:11:11 2018    DEPLOYED    kubernetes-dashboard-0.7.1  default
Теперь мы можем использовать kubectl для проверки того, была ли развернута новая служба в кластере:

kubectl get services
Output
NAME                                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
dashboard-demo-kubernetes-dashboard   ClusterIP   10.32.104.73   <none>        443/TCP   51s
kubernetes                             ClusterIP   10.32.0.1      <none>        443/TCP   34m
Обратите внимание, что по умолчанию имя службы, соответствующее нашему релизу, представляет собой сочетание имени релиза Helm и имени чарта.

Теперь, когда мы развернули приложение, давайте воспользуемся Helm для изменения его конфигурации и обновления развертывания.

Шаг 4 — Обновление релиза
Команда helm upgrade может использоваться для апгрейда релиза с новым или обновленным чартом или обновления параметров конфигурации.

Мы внесем простое изменение в наш релиз dashboard-demo для демонстрации процесса обновления и отката: мы изменим имя службы dashboard просто на dashboard вместо dashboard-demo-kubernetes-dashboard.

Чарт kubernetes-dashboard предоставляет возможность настройки fullnameOverride для контроля имени службы. Давайте запустим команду helm upgrade с данной опцией:

helm upgrade dashboard-demo stable/kubernetes-dashboard --set fullnameOverride="dashboard"
Вы увидите вывод, аналогичный выводу на шаге первоначальной настройки helm.

Проверьте, отражают ли ваши службы Kubernetes обновленные значения:

kubectl get services
Output
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes             ClusterIP   10.32.0.1       <none>        443/TCP   36m
dashboard              ClusterIP   10.32.198.148   <none>        443/TCP   40s
Наше имя службы было обновлено и получило новое значение.

Примечание: на данный момент вы можете загрузить приложение Kubernetes Dashboard в браузере и проверить его работоспособность. Для этого нужно запустить следующую команду:

kubectl proxy
Команда создает прокси, который позволяет вам получить доступ к удаленным ресурсам кластера с локального компьютера. Согласно предыдущим инструкциям ваша служба dashboard имеет имя kubernetes-dashboard и запускается в пространстве имен default. Теперь вы можете получить доступ к панели управления по следующему URL-адресу:

http://localhost:8001/api/v1/namespaces/default/services/https:dashboard:/proxy/
При необходимости задайте ваше имя пользователя и пространство имен для выделенных цветом частей. Инструкции по использованию панели управления выходят за пределы темы данного руководства, но вы можете ознакомиться с официальной документацией по Kubernetes Dashboard для получения дополнительной информации.

Далее мы рассмотрим способность Helm выполнять откат релизов.

Шаг 5 — Откат изменений в релизе
Когда мы обновили наш релиз dashboard-demo на предыдущем шаге, мы создали вторую_ версию_ релиза. Helm сохраняет все данные предыдущих релизов на случай, если вам нужно будет вернуться к предыдущей конфигурации или чарту.

Используйте команду helm list для просмотра релиза:

helm list
Output
NAME            REVISION    UPDATED                     STATUS      CHART                       NAMESPACE
dashboard-demo  2         Wed Aug  8 20:13:15 2018    DEPLOYED    kubernetes-dashboard-0.7.1  default
Столбец REVISION показывает нам, что в настоящий момент это вторая версия.

Используйте команду helm rollback для возврата к первой версии:

helm rollback dashboard-demo 1
Вы должны получить следующий вывод, показывающий, что откат изменений выполнен успешно:

Output
Rollback was a success! Happy Helming!
В данный момент, если вы запустите kubectl get services еще раз, вы заметите, что имя службы изменилось и вернулось к предыдущему значению. Helm выполнил повторное развертывание приложения с конфигурацией 1-й версии.

Далее мы рассмотрим процесс удаления релизов с помощью Helm.

Шаг 6 — Удаление релиза
Релизы Helm можно удалять с помощью команды helm delete:

helm delete dashboard-demo
Output
release "dashboard-demo" deleted
Хотя релиз был удален и приложение dashboard больше не запущено, Helm сохраняет всю информацию о версии на случай, если вы захотите откатить изменения. Если бы вы попытались немедленно установить новое приложение dashboard-demo с помощью helm install, то получили бы ошибку:

Error: a release named dashboard-demo already exists.
Если вы используете флаг --deleted для отображения списка удаленных релизов, то увидите, что релиз до сих пор на месте:

helm list --deleted
Output
NAME            REVISION    UPDATED                     STATUS  CHART                       NAMESPACE
dashboard-demo  3           Wed Aug  8 20:15:21 2018    DELETED kubernetes-dashboard-0.7.1  default
Чтобы действительно удалить релиз и очистить все старые версии, используйте флаг --purge с командой helm delete:

helm delete dashboard-demo --purge
Теперь релиз был действительно удален и вы можете использовать освободившееся имя релиза.

Заключение
С помощью этого руководства мы установили инструмент командной строки helm и его дополнительную службу tiller. Также мы изучили установку, обновление, откат изменений и удаление чартов и релизов Helm.

Дополнительную информацию о Helm и чартах Helm см. в официальной документации по Helm.