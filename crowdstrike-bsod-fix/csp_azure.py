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
    if args.az_res_grp:
        log.info(f"using azure resource group {args.az_res_grp}")
    else:
        log.error("CSP azure needs --az_res_grp <resource group> to be specified")
        return
    # Acquire a credential object.
    client = ComputeManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id="{subscription-id}",
    )

    instances=args.instances.split(",")
    for inst_id in instances:
        log.info(f"checking {inst_id}")
        try:
            response = client.virtual_machines.get(
                resource_group_name=args.az_res_grp,
                vm_name=inst_id,
            )
            print(response)
        except Exception as err:
            log.error(f"instance get failed {inst_id}: {err}")
            continue