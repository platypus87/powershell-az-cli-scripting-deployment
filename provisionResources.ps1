# TODO: set variables
$studentName = "MattW"
$rgName = "MattW-lc0820-ps-rg"
$vmName = "MattW-lc0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmAdminUsername = "student"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

az configure --default location=eastus

# TODO: provision RG
az group create -n $rgName
az configure --default group=$rgName

# TODO: provision VM
az vm create -n $vmName --size "$vmSize" --image "$vmImage" --admin-username "student" --assign-identity

# TODO: capture the VM systemAssignedIdentity
$systemAssignedIdentity="$(az vm show --query "identity.principalId" -o tsv)"

# TODO: open vm port 443
az vm open-port --port 443

# provision KV
az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name $kvName -n $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy -n "$kvName" --object-id "$systemAssignedIdentity" --secret-permissions get list

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
ifconfig