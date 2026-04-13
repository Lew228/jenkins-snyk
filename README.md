# Tutorial: Running a Snyk & Jenkins IaC Pipeline on Apple Silicon (M1/M2/M3)

This guide covers the specific challenges of running a DevSecOps pipeline locally using Docker Desktop on a Mac, focusing on architecture mismatches, volume persistence, and Snyk tool pathing.

## Prerequisites
- Docker Desktop (with Rosetta emulation enabled in Settings > General).
- AWS Account with an IAM user (e.g., JenkinsCLI).
- Snyk Account with an API Token and Org Slug.

### Step 1: The "Architecture Fix"
The most common error on Mac is the `rosetta error: failed to open elf during Snyk scans`. This happens because Jenkins plugins often download Intel (x86_64) binaries that fail in an ARM64 container.

**The Fix:** Force the Jenkins container to run on the Intel platform.

Bash
```
docker run -d \
  --name jenkins-snyk \
  --platform linux/amd64 \
  -p 8080:8080 -p 50000:50000 \
  -v <your_volume_id>:/var/jenkins_home \
  jenkins/jenkins:lts
```
**Pro-Tip:** If you have existing data, find your volume ID first using docker inspect <container_id> under the "Mounts" section to ensure you don't lose your Jenkins configurations.

### Step 2: AWS Credential Configuration
For Terraform to run a plan or apply, Jenkins must inject your IAM credentials into the shell environment.

**Install the AWS Credentials plugin in Jenkins.**

Go to Manage Jenkins > Credentials > Global and add a new "AWS Credentials" item.

**CRITICAL:** Set the ID to `aws-iam-user-creds` to match the Jenkinsfile requirement.

### Step 3: Fixing the Jenkinsfile Pathing
Standard Jenkins tutorials often use `/var/lib/jenkins`, but inside a Docker container, the path is `/var/jenkins_home`. Additionally, binary names can vary.

**Debugging the Path:**
If you get a `"not found"` error, use this debug step in your pipeline to find the exact location of the Snyk binary:

Groovy
```
sh 'find /var/jenkins_home/tools -name "snyk*"'
```

### Step 4: Optimizing the Snyk Scan
The Snyk Jenkins plugin sometimes crashes when trying to generate HTML reports in a virtualized environment. To ensure the scan report prints directly to your Console Output, use a direct shell block.

Recommended Pipeline Stage:

Groovy
```
stage('Snyk IaC Scan Test') {
    steps {
        withCredentials([string(credentialsId: 'snyk-api-token-string', variable: 'SNYK_TOKEN')]) {
            sh '''
                # Use the absolute path discovered in Step 3
                SNYK_BIN="/var/jenkins_home/tools/io.snyk.jenkins.tools.SnykInstallation/snyk/snyk-linux"
                
                $SNYK_BIN auth $SNYK_TOKEN
                
                # Run IaC scan and print report to console
                # '|| true' ensures the pipeline proceeds to Terraform even if vulnerabilities exist
                $SNYK_BIN iac test --org=$SNYK_ORG --severity-threshold=high || true
            '''
        }
    }
}
```

### Step 5: Running Terraform
Once the Snyk stage is stable, ensure the following are installed inside your Jenkins container:

- Terraform CLI
- AWS CLI
- Python

If these were installed via apt-get in a previous container, you must reinstall them in the new linux/amd64 container as they are not stored in the Jenkins volume.

### Key Takeaways for Cloud Engineers
**Shift Left:** Snyk identifies vulnerabilities (like public S3 buckets or wide-open Security Groups) before they are ever deployed.

**Architecture Awareness:** Always check if your local environment (ARM64) matches your tool requirements (often x86_64).

**Volume Persistence:** Map your `/var/jenkins_home` to a named Docker volume so your work survives container restarts.