from msrestazure.azure_active_directory import MSIAuthentication
from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
from azure.mgmt.compute import ComputeManagementClient

class VmssScaler(object):
    def __init__(self):
        # Create MSI Authentication
        credentials = MSIAuthentication()


        # Create a Subscription Client
        subscription_client = SubscriptionClient(credentials)
        subscription = next(subscription_client.subscriptions.list())
        subscription_id = subscription.subscription_id
         # Create a Resource Management client
        resource_client = ResourceManagementClient(credentials, subscription_id)
        self.compute_client = ComputeManagementClient(credentials, subscription_id)
        self.resource_group_name = 'mzdev'
        self.vm_scaleset_name = 'spic00'

        # Get Current State of VMSS
        self.model = self.compute_client.virtual_machine_scale_sets.get(self.resource_group_name, self.vm_scaleset_name)

    def scaleTo(self, num):
        # Scale up vm scale set to num
        self.model['sku']['capacity'] = num
        compute_client.virtual_machine_scale_sets.create_or_update(self,resource_group_name, self.vm_scaleset_name,
                self.model)

    def addInstances(self, num):
        # add num instances to current num of nodes
        current_capacity =  self.model['sku']['capacity']
        new_capacity = current_capacity + num
        self.model['sku']['capacity'] = new_capacity
        compute_client.virtual_machine_scale_sets.create_or_update(self,resource_group_name, self.vm_scaleset_name,
                self.model)
    def removeInstances(self, num):
        # remove num instances from vmss
        current_capacity =  self.model['sku']['capacity']
        new_capacity = current_capacity - num if ((current_capacity - num) > 0) else 0
        self.model['sku']['capacity'] = new_capacity
        compute_client.virtual_machine_scale_sets.create_or_update(self,resource_group_name, self.vm_scaleset_name,
                self.model)
