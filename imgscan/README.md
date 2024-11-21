# Bulk scan of GAR registry locally

GAR Prerequisites:
1. **REGISTRY**: Full registry path for GAR
2. **SA_EMAIL**: [Service Account Email](../res/gcp-service-account.png)
3. Service Account Json: File containing the creds
4. **IMGSPEC**: Regular expression for images to scan/upload-results. E.g. `.*:latest` => scan all the images having `latest` tag. Sample image name:`us-east1-docker.pkg.dev/kube-airgapped/accuknox-onprem/nginx:foobar`

AccuKnox Prerequisites:
1. **LABEL**: [AccuKnox Label](https://help.accuknox.com/how-to/how-to-create-labels/)
2. **TENANT**: [Tenant ID](https://help.accuknox.com/how-to/how-to-create-tokens/)
3. **TOKEN**: [AccuKnox Token](https://help.accuknox.com/how-to/how-to-create-tokens/)
4. **AKURL**: cspm.demo.accuknox.com

Scan images with tags `foobar`.
```bash
docker run -eIMGSPEC=".*:foobar$" \
           -eREGISTRY=us-east1-docker.pkg.dev/kube-airgapped/accuknox-onprem \
           -e"SA_EMAIL=<service-account-email>" \
           -eLABEL=labeltmp \
           -eTENANT=4093 \
           -eTOKEN=<get token> \
           -eAKURL=cspm.demo.accuknox.com \
           -v$PWD/service_account.json:/home/ak/service_account.json \
           -it accuknox/accuknox-container-scan:bulk
```

## Jenkins Script

```
pipeline {
    agent any
    environment {
        SA_FILE = credentials('SA_FILE')
        TOKEN = credentials('TOKEN')
        SA_EMAIL = credentials('SA_EMAIL')
    }
    stages {
        stage('Accuknox') {
            steps {
                script {
                    sh 'echo "$SA_FILE" > service_account.json'
                   
                    sh '''
                    docker run -e IMGSPEC=".*:foobar$" \
                        -e REGISTRY=us-east1-docker.pkg.dev/kube-airgapped/accuknox-onprem \
                        -e "SA_EMAIL=rj-test@kube-airgapped.iam.gserviceaccount.com" \
                        -e LABEL=mylabel \
                        -e TENANT=4093 \
                        -e TOKEN=$TOKEN \
                        -e AKURL=cspm.demo.accuknox.com \
                        -v "$PWD/service_account.json:/home/ak/service_account.json" \
                        accuknox/accuknox-container-scan:bulk
                    '''
                }
            }
        }
    }
}
```
