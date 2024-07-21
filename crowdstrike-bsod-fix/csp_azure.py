# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

# Import the needed credential and management objects from the libraries.
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient

def handle_azure(args):
    # Acquire a credential object.
    client = ComputeManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id="{subscription-id}",
    )

    response = client.virtual_machines.get(
        resource_group_name="myResourceGroup",
        vm_name="myVM",
    )
    print(response)