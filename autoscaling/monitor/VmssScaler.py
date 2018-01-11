from msrestazure.azure_active_directory import MSIAuthentication
from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
from azure.mgmt.compute import ComputeManagementClient
import logging


class VmssScaler(object):
    def __init__(self):
        # Create MSI Authentication
        # https://azure.microsoft.com/en-us/resources/samples/resource-manager-python-manage-resources-with-msi/
        credentials = MSIAuthentication()


        # Create a Subscription Client
        subscription_client = SubscriptionClient(credentials)
        self.print_item(subscription_client)
        self.print_properties(subscription_client)
        subscription = next(subscription_client.subscriptions.list())
        subscription_id = subscription.subscription_id
         # Create a Resource Management client
        self.resource_client = ResourceManagementClient(credentials, subscription_id)
        logging.info("Created Azure RM Client")
        self.compute_client = ComputeManagementClient(credentials, subscription_id)
        logging.info("Created Azure Compute Client")
        self.resource_group_name = 'mzdev'
        self.vm_scaleset_name = 'spic00'
        logging.info("RG: " + self.resource_group_name)
        logging.info("RG: " + self.vm_scaleset_name)
        # Get Current State of VMSS

    def scaleTo(self, vmss_name, num):
        # Scale up vm scale set to num
        model = self.compute_client.virtual_machine_scale_sets.get(self.resource_group_name, vmss_name)        
        model['sku']['capacity'] = num
        self.compute_client.virtual_machine_scale_sets.create_or_update(self.resource_group_name, vmss_name,
                model)

    def addInstances(self, vmss_name, num):
        # add num instances to current num of nodes
        model = self.compute_client.virtual_machine_scale_sets.get(self.resource_group_name, vmss_name) 
        current_capacity =  model['sku']['capacity']
        new_capacity = current_capacity + num
        model['sku']['capacity'] = new_capacity
        self.compute_client.virtual_machine_scale_sets.create_or_update(self.resource_group_name, vmss,
                model)
    def removeInstances(self, vmss_name, num):
        # remove num instances from vmss
        model = self.compute_client.virtual_machine_scale_sets.get(self.resource_group_name, vmss_name) 
        current_capacity = model['sku']['capacity']
        new_capacity = current_capacity - num if ((current_capacity - num) > 0) else 0
        model['sku']['capacity'] = new_capacity
        self.compute_client.virtual_machine_scale_sets.create_or_update(self.resource_group_name, vmss_name,
                model)


    def print_item(self, group):

        """Print a ResourceGroup instance."""

        print("\tName: {}".format(group.name))
        print("\tId: {}".format(group.id))
        print("\tLocation: {}".format(group.location))
        print("\tTags: {}".format(group.tags))
        print_properties(group.properties)



    def print_properties(self, props):

        """Print a ResourceGroup propertyies instance."""
        if props and props.provisioning_state:
            print("\tProperties:")
            print("\t\tProvisioning State: {}".format(props.provisioning_state))
        print("\n\n")
