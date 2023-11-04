# DevOps School Certification Assignment

Write a Jenkins pipeline that launches VM instances at a cloud provider, builds a Java app at the build server, and deploys the app on the staging server. Terraform and Ansible code muse be used. The app must be deployed in a container.

## Steps

1. Terraform validate, plan, apply — basic infra (servers) + populate Ansible inventory.
2. Run Ansible playbook that installs packages, clones the repo (or defer it to 3?), and copies the Dockerfile and Docker Hub secret.
3. Run Maven build on Build.
4. Login to Hub, build a Docker image, push the image to Hub on Build.
5. Pull the Docker image from Hub and deploy on Staging.

## Optional

- Implement a webhook that initiates git pull, rebuild, and redeploy. To do that, import the original app repo and simulate a change in the imported repo.
- Implement build notification directly from Jenkins or an additional monitoring component.