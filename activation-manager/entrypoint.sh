#!/bin/sh

stop() {
    echo 'Deactivating using activation server API'
    curl -k -X GET "https://$ACTIVATION_SERVER/deactivation?key=$LICENSE_KEY&deployment=$DEPLOYMENT"
    exit 0
}
trap stop SIGTERM SIGINT SIGQUIT

until [ -n $DEPLOYMENT ] && [ $DEPLOYMENT != null ]; do
    echo 'Checking...'
    export DEPLOYMENT=$(curl --silent -H "apikey: $APIKEY" "$MDCORE_BASE_URL:$REST_PORT/admin/license" | jq -r ".deployment")
    echo "Deployment ID: $DEPLOYMENT"
    sleep 1
done
echo "Waiting for termination signal..."
while true; do sleep 1; done
echo "MD Core pod finished, exiting"
exit 0