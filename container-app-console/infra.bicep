param environment_name string = 'container-apps-keda'
param location string = 'westeurope'

var logAnalyticsWorkspaceName = 'logs-${environment_name}'
var appInsightsName = 'appins-${environment_name}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environment_name
  location: location
  properties: {
    daprAIInstrumentationKey: reference(appInsights.id, '2020-02-02').InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2021-06-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey
      }
    }
  }
}

resource kedademo 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'keda-demo-console'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 3000
      }
      secrets: [
        {
          name: 'azurewebjobsstorage'
          value: '<storage-connection-string>'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'erwinstaal/containerappconsole:1.7'
          name: 'hello-keda-queue-container'
          env: [
            {
              name: 'AzureWebJobsStorage'
              secretRef: 'azurewebjobsstorage'
            }
            {
              name: 'QUEUECONNECTIONSTRING'
              secretRef: 'azurewebjobsstorage'
            }
            {
              name: 'QUEUENAME'
              value: 'container-app-queue'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          probes: []
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 4
        rules: [
          {
            name: 'queue-trigger'
            custom: {
              type: 'azure-queue'
              metadata: {
                accountName: 'staalkeda'
                cloud: 'AzurePublicCloud'
                queueName: 'container-app-queue'
                pollingInterval: '5'
                cooldownPeriod: '5'
              }
              auth: [
                {
                  secretRef: 'azurewebjobsstorage'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}
