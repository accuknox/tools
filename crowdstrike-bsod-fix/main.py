# CrowdStrike BSoD Remediation for AWS, GCP, Azure
# Copyright 2024 AccuKnox
# Copyright 2024 XCitium
# Note: Use it at your own risk
# License: Apache 2

import argparse
import logging
import aws

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("main")

supported_csps=['aws', 'gcp', 'azure']

def main() -> None:
    argp = argparse.ArgumentParser()
    argp.add_argument("--csp", required=True, help="Cloud Service Provider name [aws/gcp/azure]")
    argp.add_argument("--instances", required=True, help="Instance list separated by comma")
    argp.add_argument("--dry-run", action="store_true")
    args = argp.parse_args()

    if args.csp not in ['aws', 'gcp', 'azure']:
        log.error(f"unsupported cloud service provider [{args.csp}]. Supported {supported_csps}.")
        exit(1)
    log.info(f"using cloud service provider {args.csp}")
    log.info(f"Instances {args.instances}")
    module = __import__(args.csp)
    func = getattr(module, f"handle_{args.csp}")
    func(args) # calls handle_aws, handle_gcp, handle_azure

if __name__ == "__main__":
    main()
