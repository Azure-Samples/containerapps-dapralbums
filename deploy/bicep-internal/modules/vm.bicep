
param subnetId string
param adminUsername string = 'azureuser'
param location string
param vm string

@secure()
param adminSshKey string

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: 'jumpbox-vm'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${vm}-jumpbox'
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-07-01' = {
  name: '${vm}-jumpbox-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: subnetId
          }
          primary: true
          publicIPAddress: {
            id: publicIp.id
          }
        }
        name: 'primary'
      }
    ]
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2018-10-01' = {
  name: '${vm}-jumpbox'
  location: location
  
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_F2s_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
        diskSizeGB: 32
      }
    }
    osProfile: {
      computerName: '${vm}-jumpbox'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output fqdn string = publicIp.properties.dnsSettings.fqdn
