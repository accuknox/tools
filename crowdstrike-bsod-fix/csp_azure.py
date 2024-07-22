# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

# Import the needed credential and management objects from the libraries.
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("azure")

def detach_vol(client, args, inst_id):
    response = client.virtual_machines.begin_attach_detach_data_disks(
        resource_group_name=resgrp,
        vm_name=inst_id,
        parameters={
            "dataDisksToDetach": [
                {
                    "detachOption": "ForceDetach",
                    "diskId": f"/subscriptions/{args.subscription_id}/resourceGroups/{args.resource_group}/providers/Microsoft.Compute/disks/rahulwinmachine-deleteby24July_disk1_1b82042a4eed45adbb41b61d9d942656",
                },
            ],
        },
    ).result()
    print(response)
    return

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
        subscription_id=f"{args.subscription_id}",
    )

    instances=args.instances.split(",")
    for inst_id in instances:
        log.info(f"checking {inst_id}")
        try:
            response = client.virtual_machines.get(
                resource_group_name=args.resource_group,
                vm_name=inst_id,
            )
            print(response)
            log.info(f"found the azure vm [{inst_id}]")

        except Exception as err:
            log.error(f"instance get failed {inst_id}: {err}")
            continue

        resp = detach_vol(client, args, inst_id)