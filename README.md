## to run this example, you need to enable the resource provider EncryptionAtHost


https://learn.microsoft.com/en-us/answers/questions/1377548/unable-to-enable-encryption-at-host-for-azure-vm




```
PS /home/system> Set-AzContext -SubscriptionId "68be2809-9674-447c-a43d-261ef2862c29"

   Tenant: 333d80f4-dd33-4824-8d53-cefe747d7677

SubscriptionName                SubscriptionId                       Account   Environment
----------------                --------------                       -------   -----------
ME-MngEnvMCAP627202-chianwong-1 68be2809-9674-447c-a43d-261ef2862c29 MSI@50342 AzureCloud

PS /home/system> 
PS /home/system> 
PS /home/system> 
PS /home/system> 
PS /home/system> 
PS /home/system> Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

FeatureName      ProviderName      RegistrationState
-----------      ------------      -----------------
EncryptionAtHost Microsoft.Compute Registered

PS /home/system> Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

FeatureName      ProviderName      RegistrationState
-----------      ------------      -----------------
EncryptionAtHost Microsoft.Compute Registered

```

## may require manual import of resource provider

```
jzwong ~/Library/CloudStorage/OneDrive-Microsoft/git/bdo/spokevm-test [main] $ terraform import azurerm_resource_provider_registration.hostencryptprovider "/subscriptions/0450884c-0ba2-44d8-81e5-ab63e21fe7b8/providers/Microsoft.Compute"
```