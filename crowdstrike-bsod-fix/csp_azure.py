# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

# Import the needed credential and management objects from the libraries.
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
import subprocess
import os
import commonutil

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("azure")

def detach_vol(client, args, inst_id, disk_id):
    response = client.virtual_machines.begin_attach_detach_data_disks(
        resource_group_name=args.resource_group,
        vm_name=inst_id,
        parameters={
            "dataDisksToDetach": [
                {
                    "detachOption": "ForceDetach",
                    "diskId": disk_id,
                },
            ],
        },
    ).result()
    print(response)
    return

def attach_vol(client, args, inst_id, disk_id):
    response = client.virtual_machines.begin_attach_detach_data_disks(
        resource_group_name=args.resource_group,
        vm_name=inst_id,
        parameters={
            "dataDisksToAttach": [
                {
                    "caching": "ReadWrite",
                    "deleteOption": "Detach",
                    "diskEncryptionSet": {
                        "id": "/subscriptions/{subscription-id}/resourceGroups/myResourceGroup/providers/Microsoft.Compute/diskEncryptionSets/{existing-diskEncryptionSet-name}"
                    },
                    "diskId": disk_id,
                    "lun": 1,
                    "writeAcceleratorEnabled": True,
                },
            ],
        },
    ).result()
    print(response)
    return

def get_dev_name():
    res = subprocess.run(["fdisk -l"], capture_output=True, shell=True).stdout.decode()
    for line in res.splitlines():
        if "NTFS" in line:
            device_name = line.split(" ")[0]
            return device_name
    return ""

def check_disk(client, args, inst_id, line):
    try:
        resp = detach_vol(client, args, inst_id, line)
        print(resp)
        commonutil.mount_rem_cs_file(args)
        resp = attach_vol(client, args, inst_id, line)
        print(resp)
    except Exception as e:
        log.error(f"failed to detach/attach disk {inst_id}: {e}")
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

            client.virtual_machines.begin_start(
                resource_group_name=args.resource_group,
                vm_name=inst_id,
            ).result()

            res = subprocess.run(["az vm list | jq -r .[].storageProfile.dataDisks[].managedDisk.id"], 
                                 capture_output=True, shell=True).stdout.decode()
            print(res)
            for line in res.splitlines():
                if "/subscriptions/" in line:
                    check_disk(client, args, inst_id, line)

            client.virtual_machines.begin_start(
                resource_group_name=args.resource_group,
                vm_name=inst_id,
            ).result()
        except Exception as err:
            log.error(f"instance get failed {inst_id}: {err}")
            continue
