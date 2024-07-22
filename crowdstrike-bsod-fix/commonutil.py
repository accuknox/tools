# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium

import subprocess
import os
import glob
import time

# Function to get the device name
def get_dev_name():
    res = subprocess.run(["fdisk -l"], capture_output=True, shell=True).stdout.decode()
    for line in res.splitlines():
        if "NTFS" in line:
            device_name = line.split(" ")[0]
            return device_name
    return ""

# Function to remove the file
def remove_cs_file(mount_point):
    file_pattern = f"{mount_point}/Windows/System32/drivers/CrowdStrike/C-00000291*.sys"
    for file in glob.glob(file_pattern):
        os.remove(file)

def mount_rem_cs_file(args):
    mntpt = os.getcwd() + "/windows"
    os.makedirs(mntpt, exist_ok=True)
    log.info(f"mount directory {mntpt}")

    devname=""
    for retry in range(20):
        devname=commonutil.get_dev_name()
        if devname:
            break
        time.sleep(1)
    if not args.dry_run:
        subprocess.run(
            ["mount", devname, mntpt], capture_output=True
        )
        remove_cs_file(mntpt)
        subprocess.run(["umount", mntpt], capture_output=True)
