id: IoT Edge Setup
summary: This codelab is a template for coming up with a "hello world" IoT edge setup on a new hardware/environment
authors: Amar M. Balutkar <amar.balutkar@quest-global.com>
feedback: amar.balutkar@quest-global.com

# Azure IoT Edge codelab by QuEST Global
<!-- ------------------------ -->
<!-- ------------------------ -->
## Objective
Duration: 5

The objective of this hands on lab is to bringup an Azure IoT Edge solution on a new Azure account. We will use a combination of Azure portal, commandline & Visual Studio Code.

By the end of this lab you would have:
- The necessary Azure resources configured on your Azure account

- An edge device (either a VM or a real device) running IoT Edge

- A visual studio solution from where you can write, compile/build & deploy IoT edge modules which can run on the edge device that you have configured

These tasks are summarized as below:

![Goal](images/goal.png)

### What you need? (Pre-requisites)

- Ensure you have subscription to Azure and are able to access resources via portal.azure.com
- Familiarity with commandline: In this lab for some operations, you can either use <code>az cli</code> extension with your favourite shell terminal or use <code>shell.azure.com</code>
- Ensure you have visual studio code (required for section 6). Download from here if you dont have it already: [Link to download VS Code](https://code.visualstudio.com/download)
- Make sure you have the development pre-requisites for IoT Edge based on your language selection. In this example we will deploy a C# module, but you can develop other language modules as well. Carry out the suitable installation as per this guide:[VS Code develop IoT Edge modules](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-vs-code-develop-module)
- You will also require Docker desktop to be running on your local machine (PC, Laptop). This is required for building IoT edge modules. You can download docker desktop from here: [Link to download docker desktop](https://www.docker.com/products/docker-desktop)

## Preparing the Cloud services
Duration: 10

### Initial setup: Resource group creation (typical one time for a given project)

As a good practice, we want to create a new resource group. A resource group allows to group different Azure resources together belonging to the same solution or deployment.

1. Once you login to Azure portal, search for Resource groups. Click on the "Create" button to create a new resource group.
![Image 1](images/1.png)

2. Next, select the subscription, provide the name (something that is logical for you to  for resource group & select a region (the Azure datacentre where the resource group would be located).
![Image 2](images/2.png)

3. Next, you can provide a "tag" information, which is a key value pair. A tag can carry metadata information, like type of environment:dev/QA/production etc.
![Image 3](images/3.png)

4. Once you have filled up correctly, the validation should pass and you are ready with your resource group!

Now that our resource group is created, we will create other Azure resources to be part of this resource group.

### Initial setup: IoT Hub creation (typical one time for a given project)

5. Go to the resource group that we just created & click add
![Image 4](images/4.png)

6. Next, search for IoT Hub, provide it a name and follow along the steps till the "tags" page. We will use the same tag that we provided earlier to be consistent with our naming. (We will keep the default options for now, but later you can change them as per the requirements)
![Image 4](images/4_1.png)
![Image 4](images/5.png)
![Image 4](images/6.png)
![Image 4](images/7.png)
![Image 4](images/8.png)

7. Now our IoT Hub resource is created. Next, we will create an Azure IoT Edge device. 
![Image 4](images/10.png)
![Image 4](images/11.png)

Negative
: We are just creating a cloud resource and not yet connecting it to an actual device, we will do in in the later section. For now, lets just create an instance with a suitable name for the edge device.

- Optional Step: We want to create an Azure container registry instance if you plan to develop & deploy our own IoT Edge modules.
![Image 38](images/38.png)
![Image 39](images/39.png)
![Image 40](images/40.png)

Negative
: Make sure you save the ACR URL, registry name and the Password (all highlighted in Red). We will use these values to configure Azure IoT Edge modules for custom module development.

- So we have completed our first step towards our goal.In the next section we will move towards getting our edge device ready.
![Image 4](images/goal_1.png)

<!-- ------------------------ -->
## Preparing the Edge Device
Duration: 10

In this exercise, we will create a new VM instance and use it for our development. You can replace the VM with an actual physical device (eg: raspberry PI), which will require the dependencies & Azure IoT Edge package to be installed as per its OS & architecture.

1. First, select the <code>Ubuntu Server 18.04 LTS</code> from the add resource page
![Image 13](images/13.png)

2. Next, provide the VM a name. We will also need to provide a username & password which will allow us to SSH remotely into the VM
![Image 14](images/14.png)

3. We will have to provide a storage account name to keep diagnostic logs & provide the tag name (best practice)
![Image 15](images/15.png)
![Image 14](images/16.png)

4. If we have filled all parameters correctly, we should get a validation pass allowing us to create the resource
![Image 14](images/17.png)

5. Once our VM is ready, lets ssh it via the username & password we had set. You can access the public IP of the VM from the VM details page. We will use the cloud shell to ssh to the VM
![Image 14](images/18.png)

6. Lets install the necessary packages on our edge device to be ready with Azure IoT Edge. Inside our IoT Edge device, lets follow the below steps
``` bash
$ curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list
```
``` bash
$ sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/
```
``` bash
$ curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
```
``` bash
$ sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/
```
``` bash
$ sudo apt-get update
```
``` bash
$ sudo apt-get install moby-engine
$ sudo apt-get install moby-cli
$ sudo apt-get install iotedge
```

7. Now that IoT Edge is installed, we will connect it to the cloud resource we had created in the previous step. Let's go back to <code>portal.azure.com</code> and navigate to our IoT Edge device:
![Image 19](images/19.png)

8. Copy the primary connection string by clicking the copy button (highlighted in red)
![Image 19](images/20.png)

9. Now going back to the <code>code terminal</code>, lets open the iotedge config file:
   ``` bash
   nano /etc/iotedge/config.yaml
   #Find the below snippet:
   ```
   ``` bash
   # Manual provisioning configuration
   provisioning:
     source: "manual"
     device_connection_string: "<ADD DEVICE CONNECTION STRING HERE>"
   # Paste the copied connection string in the above line
   ```

10. Lets restart iotedge daemon so that it picks the newly added connection string

    ``` bash
    $ sudo systemctl restart iotedge
    ```
    ``` bash
    $ sudo iotedge list
    ```
It should showcase data as below:
![Image 21](images/21.png)


Positive
: If you are able to see the default module running, Congrats! You have successfully connected your edge device to IoT Hub! Next we will assign modules to our IoT Edge device

![Goal](images/goal_2.png)

<!-- ------------------------ -->
## Assigning modules to IoT Edge device
Duration: 5

- Lets go back to <code>portal.azure.com</code>, specifically to our IoT Edge device. We will follow along the screenshots to assign a module from marketplace to our device.
![Image 21](images/22.png)
![Image 21](images/23.png)
![Image 21](images/24.png)
![Image 21](images/25.png)
- On performing <code>iotedge list</code>, you should see modules running as below. The download of modules might require some time, so you can try running the command after a while if at first you dont see any modules.
![Image 21](images/26.png)

Positive
: Congrats! You have now successfully assigned a module to our IoT Edge device! Next we will look at monitoring the device.

<!-- ------------------------ -->

## Monitoring Edge device & modules
Duration: 5

- Monitoring modules on edge: We used <code>iotedge logs</code> to monitor the logs coming from our IoT Edge modules.

- Device twin & module twins can be used to monitor the health of the device.

- We will look at using built in device endpoints from Visual Studio when we go towards the custom module section.


![Goal](images/goal_3.png)

<!-- ------------------------ -->

## Writing your own custom module
Duration: 20

In this section, we are going to use Visual Studio Code to create a new IoT Edge module & deploy it to the IoT Edge device.

Negative
: Ensure you have VS Code installed.

1. Make sure you have IoT tools installed <code>File->Preferences->Extensions->Search for "IoT tools"</code>. Alternately, you can use hotkey Ctrl+Shift+X to open extension panel
![Image 27](images/27.png)


2. Once the extension is installed, we will create a New IoT Edge solution. First, open the command pallet via shortcut <code>Ctrl+Shift+P</code> or <code>View->Command Palette</code>.
![Image 28](images/28.png)


3. Search for "Azure IoT Edge" and select "New IoT Edge Solution"
![Image 29](images/29.png)

4. Create a new folder, this is where our code will reside
![Image 30](images/30.png)

5. Next, provide a solution name, module name and edit the docker image repository with the Azure container registry name that we created in our previous section.
![Image 31](images/31.png)

6. Once you are done with this step, you will be prompted to update the .env file
``` bash
CONTAINER_REGISTRY_USERNAME_testiotcr=
CONTAINER_REGISTRY_PASSWORD_testiotcr=
```
``` bash
# Update these parameters with the username & password you had copied earlier
```

7. The module has its own bootstrapping code. You can review the Program.cs file, specifically the PipeMessage:
``` c#
        /// <summary>
        /// This method is called whenever the module is sent a message from the EdgeHub. 
        /// It just pipe the messages without any change.
        /// It prints all the incoming messages.
        /// </summary>
        static async Task<MessageResponse> PipeMessage(Message message, object userContext)
        {
            int counterValue = Interlocked.Increment(ref counter);

            var moduleClient = userContext as ModuleClient;
            if (moduleClient == null)
            {
                throw new InvalidOperationException("UserContext doesn't contain " + "expected values");
            }

            byte[] messageBytes = message.GetBytes();
            string messageString = Encoding.UTF8.GetString(messageBytes);
            Console.WriteLine($"Received message: {counterValue}, Body: [{messageString}]");
            
            if (!string.IsNullOrEmpty(messageString))
            {
                using (var pipeMessage = new Message(messageBytes))
                {
                    foreach (var prop in message.Properties)
                    {
                        pipeMessage.Properties.Add(prop.Key, prop.Value);
                    }
                    await moduleClient.SendEventAsync("output1", pipeMessage);
                
                    Console.WriteLine("Received message sent");
                }
            }
            return MessageResponse.Completed;
        }
```
``` bash
# If you are using a different language binding, you will find similar function in your code
```

8. Next, we will review the <code>deployment.template.json</code> file. At this stage, you should see the module & route information as per below. The SimulatedTemperatureSensor is a default module which we have inherited module (which we can remove later). The helloworld is the module that we created which currently has default boilerplate code.
``` json
"modules": {
          "helloworld": {
            "version": "1.0",
            "type": "docker",
            "status": "running",
            "restartPolicy": "always",
            "settings": {
              "image": "${MODULES.helloworld}",
              "createOptions": {}
            }
          },
          "SimulatedTemperatureSensor": {
            "version": "1.0",
            "type": "docker",
            "status": "running",
            "restartPolicy": "always",
            "settings": {
              "image": "mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0",
              "createOptions": {}
            }
          }
        }
      }
    },
    "$edgeHub": {
      "properties.desired": {
        "schemaVersion": "1.0",
        "routes": {
          "helloworldToIoTHub": "FROM /messages/modules/helloworld/outputs/* INTO $upstream",
          "sensorTohelloworld": "FROM /messages/modules/SimulatedTemperatureSensor/outputs/temperatureOutput INTO BrokeredEndpoint(\"/modules/helloworld/inputs/input1\")"
        },
        "storeAndForwardConfiguration": {
          "timeToLiveSecs": 7200
        }
      }
    }
  }
```
``` bash
# Snippet
```

Positive
: The important thing to understand from the above is, we have 2 modules: Temperature sensor generates simulated data & sends it to hello world (as defined in the "sensorTohelloworld" route). The hellow world module sends the message to IoT Hub (as defined in the "hellowworldToIoTHub" route). The exact code in helloworld which does this is showcased above in the Program.cs:PipeMessage()

In the next step, we will cover building & deploying the custom module to the IoT Edge device we had created earlier.

![Goal](images/goal_4.png)

<!-- ------------------------ -->
## Deploying your custom module
Duration: 5

1. Before the deployment to begin, we want our local docker instance to connect to the ACR that we had created during the previous step. So open Terminal window from VS Code and run the following command:
``` bash
$ docker login testiotcr.azurecr.io 
Username: testiotcr
Password:
Login Succeeded
```
``` bash
# This URL should be replaced by the name of your ACR
```

2. We are now ready to build & deploy the IoT edge module. Right click the <code>deployment.template.json</code> file to select option <code>"Build and Push IoT Edge Solution"</code>. This will generate the final deployment file and also push the IoT edge docker images to the ACR
![Image 32](images/32.png)

3. Now, right click on <code>config/deployment.amd64.json</code> file and select <code>"Create Deployment for Single Device"</code>
![Image 34](images/34.png)

4. You will be prompted to select the IoT Edge device that we had created earlier in Step 3. Once you select the device, you should see following message on the console:
``` bash
[Edge] Start deployment to device [edgedevice] #This name might be different as per your device name that you have provided earlier
[Edge] Deployment succeeded.
```
``` bash
```

5. In VS Code, select the IoT Edge device where we have deployed the module, right click and select <code>Start Monitoring Built-in Event Endpoint"</code>. This will allow you to monitor any messages that your device sends to the cloud (IoT Hub)
![Image 41](images/41.png)

6. You can go to <code>shell.azure.com</code> and list the running modules:
``` bash
$ sudo iotedge list
NAME                        STATUS           DESCRIPTION      CONFIG
SimulatedTemperatureSensor  running          Up 2 minutes     mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0
edgeAgent                   running          Up 2 minutes     mcr.microsoft.com/azureiotedge-agent:1.0
edgeHub                     running          Up 2 minutes     mcr.microsoft.com/azureiotedge-hub:1.0
helloworld                  running          Up 2 minutes     testiotcr.azurecr.io/helloworld:0.0.1-amd64
```
``` bash
```

7. Restart the SimulatedTemperatureSensor module. This simulated module sends 500 messages at the start and goes back to sleep
``` bash
$ sudo iotedge restart SimulatedTemperatureSensor
```
``` bash
```

8. Incase you dont see all modules, you can restart iotedge daemon as follows to ensure it pulls latest images while starting up:
``` bash
$ sudo systemctl restart iotedge
```
``` bash
```

9. You should start seeing messages coming in your VSCode as below:
![Image 41](images/42.png)

10. You can also check the logs on the IoT Edge device by running following commands on shell:
``` bash
$ sudo iotedge logs SimulatedTemperatureSensor
$ sudo iotedge logs helloworld
```
``` bash
```

Positive
: You were able to deploy a custom module, Showcase intermodule communication, Send data from one module to cloud (IoT Hub) for further processing

![Goal](images/goal_5.png)

<!-- ------------------------ -->
## Conclusion

Positive
: Good job making it so far! 
- Some of the next steps you can start looking at is, how to query module twins, DirectMethod for more communication patterns between cloud & Edge
- This typically forms a one time setup: a baseline on which you will write your business logic. So you can iterate on this setup as per your use-case to add additional functionality.

Our architecture can be summarized as per below:
![Goal](images/arch.png)

This forms a baseline on which you can configure different Azure services, create new business logic (cloud or device) etc.

<!-- ------------------------ -->
## Bonus 

Duration: 10

1. What you did till now was use Azure portal and click through the entire process of provisioning, configuration. This is good for getting started to ensure you get a good understanding of what components were created in the backend.

2. For real world scenarios, you might need to create a replicable environment, something that you can create via a script. This could be used for development or testing (via devops) or replicating the setup from one instance to another.

3. Lets open <code>shell.azure.com</code>

4. We are going to run the following script on the shell. This script creates & configures Azure resources in a new resource group, allowing a new setup to created in few minutes. This script could be invoked via CI/CD pipelines (for example in your development setup), allowing to replicate, test a new setup with your business logic. We make use of Azure Resource Manager template & Cloud-Init scripts.
``` bash
# Run following command on cloud shell
bash -c "$(curl -sL https://raw.githubusercontent.com/amarrmb/azureiot_codelab/master/scripts/script.sh)"
```
``` script
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
CYAN='\033[4;36m'


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
```

5. The above script takes around 5-10 mins. You can refer the Credential.txt file which showcases the output which you can connect.

Negative
: EXERCISE: Deploy the IoT edge "hello world" module that you developed earlier to this device.

<!-- ------------------------ -->
## References

- Documentation references
  - [Azure IoT Hub documentation](https://docs.microsoft.com/en-us/azure/iot-hub/)
  - [Azure IoT Edge documentation](https://docs.microsoft.com/en-us/azure/iot-edge/)
  - [Azure IoT Edge troubleshooting](https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot)
  - [Azure Bastion](https://azure.microsoft.com/en-us/services/azure-bastion/) 
  - [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/) 
  - [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/) 

- Azure IoT Edge reference commands
``` bash
$ journalctl -u iotedge --no-pager --no-full # IoT Edge daemon logs
```
``` bash
$ sudo systemctl restart iotedge # restart IoT Edge runtime
```
``` bash
$ sudo iotedge list # list available modules
```
``` bash
$ sudo iotedge check # troubleshooting
```
