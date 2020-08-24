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
RESOURCE_GROUP='ScriptSetup-'
IOT_EDGE_VM_NAME='TestIoTEdge-vm'
IOT_EDGE_VM_ADMIN='adminuser'
IOT_EDGE_VM_PWD="Password@$(shuf -i 1000-9999 -n 1)"
CREDENTIALS_FILE='script-credentials.txt'
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
Cyan="\[\033[4;36m\]"


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
echo -e "${CYAN}*Step(1/9)${NC} Checking ${BLUE}azure-iot${NC} extension.."
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
*${CYAN}Step(2/9)${NC} You will need to use a subscription with permissions for creating service principals (owner role provides this).
${YELLOW}If you want to change to a different subscription, enter the name or id.${NC}
Or just press enter to continue with the current subscription. "
read -p ">> " SUBSCRIPTION_ID

if ! test -z "$SUBSCRIPTION_ID"
then 
    az account set -s "$SUBSCRIPTION_ID"
    echo -e "\n${GREEN}Now using:${NC}"
    az account show --query '[name,id]'
fi 


# select a region for deployment
echo -e "${CYAN}*Step(3/9)${NC} 
${YELLOW}Please select a region to deploy resources from this list: centralus, eastus2, francecentral, japanwest, northcentralus, uksouth, westcentralus, westus2, australiaeast, eastasia, southeastasia, japaneast, eastus, ukwest, westus, canadacentral, koreacentral, southcentralus, australiasoutheast, centralindia, brazilsouth, westeurope, northeurope.${NC}
Or just press enter to use ${DEFAULT_REGION}."
read -p ">> " REGION

if [[ "$REGION" =~ ^(centralus|eastus2|francecentral|japanwest|northcentralus|uksouth|westcentralus|westus2|australiaeast|eastasia|southeastasia|japaneast|eastus|ukwest|westus|canadacentral|koreacentral|southcentralus|australiasoutheast|centralindia|brazilsouth|westeurope|northeurope)$ ]]; then
    echo -e "\n${GREEN}Now using:${NC} $REGION"
else
    echo -e "\n${GREEN}Defaulting to:${NC} ${DEFAULT_REGION}"
    REGION=${DEFAULT_REGION}
fi

# choose a resource group
echo -e "${CYAN}*Step(4/9)${NC} 
${YELLOW}What is the name of the resource group to use?${NC}
This will create a new resource group if one doesn't exist.
Hit enter to use the default (${BLUE}${RESOURCE_GROUP}${NC})."
read -p ">> " tmp
RESOURCE_GROUP=${tmp:-$RESOURCE_GROUP}
#RESOURCE_GROUP=$RESOURCE_GROUP+tmp}

EXISTING=$(az group exists -g ${RESOURCE_GROUP})

if ! $EXISTING; then
    echo -e "\n${GREEN}The resource group does not currently exist.${NC}"
    echo -e "We'll create it in ${BLUE}${REGION}${NC}."
    az group create --name ${RESOURCE_GROUP} --location ${REGION} -o none
    checkForError
fi


# Now, run the script to create the resources.
echo -e "
${CYAN}*Step(5/9)${NC} Now we'll deploy some resources to ${GREEN}${RESOURCE_GROUP}.${NC}
This typically takes about 5-10 minutes.

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
EDGE_DEVICE="script-sample-device"
IOTHUB_CONNECTION_STRING=$(az iot hub show-connection-string --hub-name ${IOTHUB} --query='connectionString')
CONTAINER_REGISTRY=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.ContainerRegistry\/registries$/ {print $1}')
CONTAINER_REGISTRY_USERNAME=$(az acr credential show -n $CONTAINER_REGISTRY --query 'username' | tr -d \")
CONTAINER_REGISTRY_PASSWORD=$(az acr credential show -n $CONTAINER_REGISTRY --query 'passwords[0].value' | tr -d \")


echo -e "
${CYAN}*Step(6/9)${NC} 
Some of the configuration for these resources can't be performed using a template.
So, we'll handle these for you now:
- register an IoT Edge device with the IoT Hub
"

# configure the hub for an edge device
echo "${CYAN}*Step(7/9)${NC} Registering device..."
if test -z "$(az iot hub device-identity list -n $IOTHUB | grep "deviceId" | grep $EDGE_DEVICE)"; then
    az iot hub device-identity create --hub-name $IOTHUB --device-id $EDGE_DEVICE --edge-enabled -o none
    checkForError
fi
DEVICE_CONNECTION_STRING=$(az iot hub device-identity connection-string show --device-id $EDGE_DEVICE --hub-name $IOTHUB --query='connectionString')

# deploy the IoT Edge runtime on a VM
az vm show -n $IOT_EDGE_VM_NAME -g $RESOURCE_GROUP &> /dev/null
if [ $? -ne 0 ]; then

    echo -e "
${CYAN}*Step(8/9)${NC}
Finally, we'll deploy a VM that will act as your IoT Edge device"

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
${CYAN}*Step(9/9)${NC}
To access the VM acting as the IoT Edge device, 
- locate it in the portal 
- click Connect on the toolbar and choose Bastion
- enter the username and password below

The VM is named ${GREEN}$IOT_EDGE_VM_NAME${NC}
Username ${GREEN}$IOT_EDGE_VM_ADMIN${NC}
Password ${GREEN}$IOT_EDGE_VM_PWD${NC}

This information can be found here:
${BLUE}$CREDENTIALS_FILE${NC}"

    echo "Edge device name is: "$EDGE_DEVICE >> $CREDENTIALS_FILE
    echo $IOT_EDGE_VM_NAME >> $CREDENTIALS_FILE
    echo $IOT_EDGE_VM_ADMIN >> $CREDENTIALS_FILE
    echo $IOT_EDGE_VM_PWD >> $CREDENTIALS_FILE
    echo "You can find the resources created under this resource group: "+$RESOURCE_GROUP >> $CREDENTIALS_FILE
    echo "Container registry keys:" >> $CREDENTIALS_FILE
    echo $CONTAINER_REGISTRY >> $CREDENTIALS_FILE
    echo $CONTAINER_REGISTRY_USERNAME >> $CREDENTIALS_FILE
    echo $CONTAINER_REGISTRY_PASSWORD >> $CREDENTIALS_FILE

else
    echo -e "${CYAN}*Step(9/9)${NC}
${YELLOW}NOTE${NC}: A VM named ${YELLOW}$IOT_EDGE_VM_NAME${NC} was found in ${YELLOW}${RESOURCE_GROUP}.${NC}
We will not attempt to redeploy the VM."
fi


