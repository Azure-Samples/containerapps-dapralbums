# Walk through the application architecture and show dapr vs. non-dapr apps 
# show a quick local deployment of the app running locally 
# show basic bicep template used for deployment 
# explain I can use bicep, arm, yaml, the CLI or even actions to deploy my apps. I have chosen to do CLI for simplicity.

# explain i used az acr build to get my dockerfiles quickly built as images 
# they have already been pushed to azure container registry, so i can reference them using the cli 


export CAPP_ENVIRONMENT='env-da-3k6biz755xt6a'
export RESOURCE_GROUP='album-app-internal'
export API_NAME='album-api'
export UI_NAME='album-viewer'
export ACR_ADMIN_PASSWORD='Ug/y5kTiziqnLKoWSnfwYk0O6APxnrSc'
export ACR_ADMIN_USERNAME='dapralbumappacr'
export ACR_LOGIN_SERVER='dapralbumappacr.azurecr.io'
export ACR_NAME='dapralbumappacr'

az acr build --image album-api:1.0 --registry $ACR_NAME .
az acr build --image album-viewer:1.0 --registry $ACR_NAME .

az containerapp env dapr-component set \
    --name $CAPP_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name statestore \
    --yaml statestore.yaml

az containerapp create -n $API_NAME -g $RESOURCE_GROUP \
            --image $ACR_NAME.azurecr.io/album-api:1.0 --environment $CAPP_ENVIRONMENT  \
            --registry-password $ACR_ADMIN_PASSWORD --registry-username $ACR_ADMIN_USERNAME \
            --registry-server $ACR_LOGIN_SERVER \
            --ingress external --target-port 80 \
            --enable-dapr --dapr-app-id album-api --dapr-app-port 80 \
            --query properties.configuration.ingress.fqdn


az containerapp create -n $UI_NAME -g $RESOURCE_GROUP \
            --image $ACR_NAME.azurecr.io/album-viewer:1.0 --environment $CAPP_ENVIRONMENT  \
            --registry-password $ACR_ADMIN_PASSWORD --registry-username $ACR_ADMIN_USERNAME \
            --registry-server $ACR_LOGIN_SERVER \
            --ingress external --target-port 3000 \
            --env-vars "BACKGROUND_COLOR=purple" \
            --enable-dapr --dapr-app-id album-viewer \
            --dapr-app-port 3000 \
            --query properties.configuration.ingress.fqdn



