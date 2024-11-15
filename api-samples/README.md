# Sample API scripts

Sample API scripts to help users with achieving certain batch processing tasks by using AccuKnox control plane APIs. For e.g., [export runtime policies](policyDump.sh).

## Setting `.accuknox.cfg`
The API samples script expect the presence of `.accuknox.cfg` in the home directory of the current user. Sample [.accuknox.cfg](.accuknox.cfg).

To get the `TENANT_ID` and `TOKEN` for your account:
1. Go to AccuKnox Control Plane
2. Settings -> User-Management -> Select User burger menu -> Get-Access-Key
3. Create the access-key. You will find key/token and tenant-id in the creation flow.

> Security Best Practice: Please use the "Viewer" only role for creating the access-key.

![](../res/user-access-key-token.gif)
