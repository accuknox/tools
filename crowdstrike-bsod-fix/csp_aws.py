# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

import logging
import boto3
import commonutil

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("aws")

def detach_volumes(ec2, inst_id, dry_run=False):
    try:
        volumes = ec2.describe_volumes(
            Filters=[{"Name": "attachment.instance-id", "Values": [inst_id]}]
        )
    except Exception as e:
        if "DryRunOperation" not in str(e):
            log.error(f"Failed to get volumes for instance {inst_id}: {e}")
        return

    for volume in volumes["Volumes"]:
        vid = volume["VolumeId"]
        try:
            res = ec2.detach_volume(VolumeId=vid, DryRun=dry_run)
            waiter = ec2.get_waiter("volume_available")
            waiter.wait(VolumeIds=[vid])
        except Exception as e:
            if "DryRunOperation" not in str(e):
                log.error(f"Failed to detach volume {vid}: {e}")
            continue
        yield vid, res["Device"]

# Function to attach volume to the current instance
def attach_vol(ec2, inst_id, vid, dev, dry_run=False):
    try:
        ec2.attach_volume(
            InstanceId=inst_id, VolumeId=vid, Device=dev, DryRun=dry_run
        )
        waiter = ec2.get_waiter("volume_in_use")
        waiter.wait(VolumeIds=[vid])
    except Exception as e:
        if "DryRunOperation" not in str(e):
            log.error(f"Failed to attach volume {vid}: {e}")


# Function to detach volume from the current instance
def detach_vol(ec2, vid, dry_run=False):
    try:
        ec2.detach_volume(VolumeId=vid, DryRun=dry_run)
        waiter = ec2.get_waiter("volume_available")
        waiter.wait(VolumeIds=[vid])
    except Exception as e:
        if "DryRunOperation" not in str(e):
            log.error(f"Failed to detach volume {vid}: {e}")

# Function to start an instance
def start_instance(ec2, inst_id, dry_run=False):
    try:
        ec2.start_instances(InstanceIds=[inst_id], DryRun=dry_run)
        waiter = ec2.get_waiter("instance_running")
        waiter.wait(InstanceIds=[inst_id])
    except Exception as e:
        if "DryRunOperation" not in str(e):
            log.error(f"Failed to start instance {inst_id}: {e}")

# Function to stop an instance
def stop_instance(ec2, inst_id, dry_run=False):
    try:
        ec2.stop_instances(InstanceIds=[inst_id], DryRun=dry_run)
        waiter = ec2.get_waiter("instance_stopped")
        waiter.wait(InstanceIds=[inst_id])
    except Exception as e:
        if "DryRunOperation" not in str(e):
            log.error(f"Failed to stop instance {inst_id}: {e}")

def handle_aws(args):
    log.info(f"called {args.csp}")
    instances=args.instances.split(",")
    ec2 = boto3.client('ec2')
    # response = ec2.describe_instances()
    # print(response)
    # return

    for inst_id in instances:
        log.info(f"checking {inst_id}")
        try:
            stop_instance(ec2=ec2, inst_id=inst_id, dry_run=args.dry_run)
        except Exception as err:
            log.error(f"could not stop {inst_id}: {err}")
            continue

        for vid, dev in detach_volumes(ec2=ec2, inst_id=inst_id, dry_run=args.dry_run):
            try:
                attach_vol(ec2=ec2, inst_id=inst_id, vid=vid, dev="/dev/sdz", dry_run=args.dry_run)
            except Exception as err:
                if "DryRunOperation" not in str(err):
                    log.error(f"attach vol failed {vid}: {err}")
                    continue

            try:
                commonutil.mount_rem_cs_file(args)
            finally:
                detach_vol(ec2, vid, dry_run=args.dry_run)
                attach_vol(ec2, inst_id, vid, dev, dry_run=args.dry_run)

        start_instance(ec2, inst_id, dry_run=args.dry_run)
