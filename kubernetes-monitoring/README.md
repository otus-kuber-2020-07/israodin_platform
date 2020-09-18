Install Prometheus Operator with  helm3
#######################################
helm3 install prometheus stable/prometheus-operator --namespace monitoring
############################################################################
kubectl --namespace monitoring get pods -l "release=prometheus"

