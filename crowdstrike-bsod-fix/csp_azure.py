# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

# Import the needed credential and management objects from the libraries.
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("azure")

def handle_azure(args):
    if not args.resource_group:
        log.error("needs --resource-group <group> to be specified")
        return
    if not args.subscription_id:
        log.error("needs --subscription-id <id> to be specified")
        return
    log.info(f"\nAzure:\n\tSubscription-ID: {args.subscription_id}\n\tResource-Group: {args.resource_group}")
    # Acquire a credential object.
    client = ComputeManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id="{args.subscription_id}",
    )

"""     instances=args.instances.split(",")
    for inst_id in instances:
        log.info(f"checking {inst_id}")
        try:
            response = client.virtual_machines.get(
                resource_group_name=args.resource_group,
                vm_name=inst_id,
            )
            print(response)
        except Exception as err:
            log.error(f"instance get failed {inst_id}: {err}")
            continue """