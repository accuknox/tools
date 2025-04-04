"""
Usage:
Run the following command to fetch JSON data using `knoxctl` and convert it to a CSV file:

    knoxctl api cluster alerts --filters '{"field":"Action","value":"Block", "op": "match"}' --stime 1743013859 --etime 1743678818 --page 1 --page-size 5 --json | python3 knoxctl-alerts-json-to-csv.py
    knoxctl api cluster alerts --filters '{"field":"Action","value":"Block","op":"match"}' --filters '{"field":"cluster_id","value":"62833", "op": "match"}'  --stime $(date -d "7 days ago" +%s) --etime $(date +%s) --page 1 --page-size 5 --json | python3 knoxctl-alerts-json-to-csv.py

This script:
- Reads JSON input from stdin.
- Flattens the 'Owner' field into prefixed keys like 'Owner_name', etc.
- Joins the 'ATags' list into a comma-separated string.
- Outputs the flattened data into a file named 'knoxctl.out.csv'.
"""

import csv
import json
import sys

# Read JSON data from file
data = json.load(sys.stdin)

# Flatten and process each dictionary in the array
def flatten_dict(d):
    flat_dict = d.copy()
    if "Owner" in d:
        for key, value in d["Owner"].items():
            flat_dict[f"Owner_{key}"] = value  # Add prefix 'Owner_'
        flat_dict.pop("Owner", None)  # Remove nested Owner dict
    flat_dict["ATags"] = ", ".join(d.get("ATags", []))  # Convert list to string
    return flat_dict

flattened_data = [flatten_dict(item) for item in data]

# Write to CSV
csv_file = "knoxctl.out.csv"
with open(csv_file, "w", newline="") as file:
    writer = csv.DictWriter(file, fieldnames=flattened_data[0].keys())
    writer.writeheader()
    writer.writerows(flattened_data)

print(f"CSV file '{csv_file}' has been created successfully.")
