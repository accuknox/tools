# CrowdStrike BSoD Rememdiation

```
# expected pip version 24.1.2
pip3 install -r requirements.txt
```

## AWS

### Prerequisites
1. Download and install [aws cli](https://aws.amazon.com/cli/)
1. aws credentials are configured using `aws configure`
2. the region in the credentials are set properly

### Using AWS

```bash
python3 main.py --csp aws --instances i-0314fe10fbb79efd1,i-0214ae20ecc98e5d2
```

# Azure

### Prerequisites
1. Download and install [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux)
1. Configure `az login` such that it points to the right account/subscription

### Using Azure
```bash
python3 main.py --csp azure --instances sample-instance
```