#!/usr/bin/env bash
# Author: <amar.balutkar@quest-global.com>
##############################################################################
#                               !!! IMPORTANT !!!
# This script showcases how to deploy & configure Azure resources using
# azure-cli. It is primarily meant to be run on https://shell.azure.com and 
# not tested to PowerShell or other types of shell.
#
# You will need an Azure subscription with permissions to create/configure 
# Azure resources for running the script
#
# Before you run this script, ensure you are changing the <name> parameter to 
# ensure the namespace we choose is unique.
#
# As a sound security practice, never run scripts from the internet unless you
# trust the publisher.
##############################################################################
DEFAULT_REGION='eastus'
RESOURCE_GROUP='ScriptSetup-delete'
IOT_EDGE_VM_NAME='TestIoTEdge-vm'
IOT_EDGE_VM_UNAME='admin'
IOT_EDGE_VM_PASSWD="Password@$(shuf -i 1000-9999 -n 1)"
VM_CREDENTIALS_FILE='vm-edge-device-credentials.txt'
BASE_URL='https://raw.githubusercontent.com/amarrmb/azureiot_codelab/master/scripts'
CLOUD_INIT_URL="$BASE_URL/cloud-init.yml"
CLOUD_INIT_FILE='cloud-init.yml'
ARM_TEMPLATE_URL="$BASE_URL/deploy.json"


# Colors for formatting the output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color


# Error checking routine
checkForError() {
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Something went wrong:${NC}
    Please read any error messages carefully.
    After addressing any errors, you can safely run this script again.
    Note:
    - If you rerun the script with the same subscription and resource group,
      it will attempt to continue where it left off.
    - Some problems with Azure Cloud Shell may be restarting from the toolbar:
      https://docs.microsoft.com/azure/cloud-shell/using-the-shell-window#restart-cloud-shell
    "
        exit 1
    fi
}

# First let's check if we have azure-iot extension available
echo -e "Checking ${BLUE}azure-iot${NC} extension."
az extension show -n azure-iot -o none &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${BLUE}azure-iot${NC} extension not found. Installing ${BLUE}azure-iot${NC}."
    az extension add --name azure-iot &> /dev/null
    echo -e "${BLUE}azure-iot${NC} extension is now installed."
else
    az extension update --name azure-iot &> /dev/null
    echo -e "${BLUE}azure-iot${NC} extension is up to date."														  
fi

# Since we are running from cloud shell, we are already logged in. Incase we
# want to login, uncomment following function:

# az account show -o none
# if [ $? -ne 0 ]; then
#     echo -e "\nRunning 'az login' for you."
#     az login -o none
# fi

# query subscriptions
echo -e "\n${GREEN}You have access to the following subscriptions:${NC}"
az account list --query '[].{name:name,"subscription Id":id}' --output table

echo -e "\n${GREEN}Your current subscription is:${NC}"
az account show --query '[name,id]'

echo -e "
You will need to use a subscription with permissions for creating service principals (owner role provides this).
${YELLOW}If you want to change to a different subscription, enter the name or id.${NC}
Or just press enter to continue with the current subscription."
read -p ">> " SUBSCRIPTION_ID

if ! test -z "$SUBSCRIPTION_ID"
then 
    az account set -s "$SUBSCRIPTION_ID"
    echo -e "\n${GREEN}Now using:${NC}"
    az account show --query '[name,id]'
fi 


# select a region for deployment
echo -e "
${YELLOW}Please select a region to deploy resources from this list: centralus, eastus2, francecentral, japanwest, northcentralus, uksouth, westcentralus, westus2, australiaeast, eastasia, southeastasia, japaneast, eastus, ukwest, westus, canadacentral, koreacentral, southcentralus, australiasoutheast, centralindia, brazilsouth, westeurope, northeurope.${NC}
Or just press enter to use ${DEFAULT_REGION}."
read -p ">> " REGION

if [[ "$REGION" =~ ^(centralus|eastus2|francecentral|japanwest|northcentralus|uksouth|westcentralus|westus2|australiaeast|eastasia|southeastasia|japaneast|eastus|ukwest|westus|canadacentral|koreacentral|southcentralus|australiasoutheast|centralindia|brazilsouth|westeurope|northeurope)$ ]]; then
    echo -e "\n${GREEN}Now using:${NC} $REGION"
else
    echo -e "\n${GREEN}Defaulting to:${NC} ${DEFAULT_REGION}"
    REGION=${DEFAULT_REGION}
fi

# Now, run the script to create the resources.
echo -e " Hang on tight! starting to create resources"
echo -e "
Now we'll deploy some resources to ${GREEN}${RESOURCE_GROUP}.${NC}
This typically takes about 6 minutes, but the time may vary.

The resources are defined in a template here:
${BLUE}${ARM_TEMPLATE_URL}${NC}"

ROLE_DEFINITION_NAME=$(az deployment group create --resource-group $RESOURCE_GROUP --template-uri $ARM_TEMPLATE_URL --query properties.outputs.roleName.value | tr -d \")
checkForError

# query the resource group to see what has been deployed
# this includes everything in the resource group, and not just the resources deployed by the template
echo -e "\nResource group now contains these resources:"
RESOURCES=$(az resource list --resource-group $RESOURCE_GROUP --query '[].{name:name,"Resource Type":type}' -o table)
echo "${RESOURCES}"


# capture resource configuration in variables
IOTHUB=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Devices\/IotHubs$/ {print $1}')
VNET=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Network\/virtualNetworks$/ {print $1}')
EDGE_DEVICE="lva-sample-device"
IOTHUB_CONNECTION_STRING=$(az iot hub show-connection-string --hub-name ${IOTHUB} --query='connectionString')
CONTAINER_REGISTRY=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.ContainerRegistry\/registries$/ {print $1}')
CONTAINER_REGISTRY_USERNAME=$(az acr credential show -n $CONTAINER_REGISTRY --query 'username' | tr -d \")
CONTAINER_REGISTRY_PASSWORD=$(az acr credential show -n $CONTAINER_REGISTRY --query 'passwords[0].value' | tr -d \")


echo -e "
Some of the configuration for these resources can't be performed using a template.
So, we'll handle these for you now:
- register an IoT Edge device with the IoT Hub
- set up a service principal (app registration) for the Media Services account
"

# configure the hub for an edge device
echo "registering device..."
if test -z "$(az iot hub device-identity list -n $IOTHUB | grep "deviceId" | grep $EDGE_DEVICE)"; then
    az iot hub device-identity create --hub-name $IOTHUB --device-id $EDGE_DEVICE --edge-enabled -o none
    checkForError
fi
DEVICE_CONNECTION_STRING=$(az iot hub device-identity show-connection-string --device-id $EDGE_DEVICE --hub-name $IOTHUB --query='connectionString')

# deploy the IoT Edge runtime on a VM
az vm show -n $IOT_EDGE_VM_NAME -g $RESOURCE_GROUP &> /dev/null
if [ $? -ne 0 ]; then

    echo -e "
Finally, we'll deploy a VM that will act as your IoT Edge device for using the LVA samples."

    curl -s $CLOUD_INIT_URL > $CLOUD_INIT_FILE

    # here be dragons
    # sometimes a / is present in the connection string and it breaks sed
    # this escapes the /
    DEVICE_CONNECTION_STRING=${DEVICE_CONNECTION_STRING//\//\\/} 
    sed -i "s/xDEVICE_CONNECTION_STRINGx/${DEVICE_CONNECTION_STRING//\"/}/g" $CLOUD_INIT_FILE

    az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $IOT_EDGE_VM_NAME \
    --image Canonical:UbuntuServer:18.04-LTS:latest \
    --admin-username $IOT_EDGE_VM_ADMIN \
    --admin-password $IOT_EDGE_VM_PWD \
    --vnet-name $VNET \
    --subnet 'default' \
    --custom-data $CLOUD_INIT_FILE \
    --public-ip-address "" \
    --size "Standard_DS3_v2" \
    --tags environment=dev \
    --output none

    checkForError

    echo -e "
To access the VM acting as the IoT Edge device, 
- locate it in the portal 
- click Connect on the toolbar and choose Bastion
- enter the username and password below

The VM is named ${GREEN}$IOT_EDGE_VM_NAME${NC}
Username ${GREEN}$IOT_EDGE_VM_ADMIN${NC}
Password ${GREEN}$IOT_EDGE_VM_PWD${NC}

This information can be found here:
${BLUE}$VM_CREDENTIALS_FILE${NC}"

    echo $IOT_EDGE_VM_NAME >> $VM_CREDENTIALS_FILE
    echo $IOT_EDGE_VM_ADMIN >> $VM_CREDENTIALS_FILE
    echo $IOT_EDGE_VM_PWD >> $VM_CREDENTIALS_FILE

else
    echo -e "
${YELLOW}NOTE${NC}: A VM named ${YELLOW}$IOT_EDGE_VM_NAME${NC} was found in ${YELLOW}${RESOURCE_GROUP}.${NC}
We will not attempt to redeploy the VM."
fi


