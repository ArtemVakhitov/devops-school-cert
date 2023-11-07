# DevOps School Certification Assignment

Write a Jenkins pipeline that launches VM instances at a cloud provider, builds a Java app on the build server, and deploys the app on the staging server. Terraform and Ansible code must be used. The app must be deployed in a container.

## Configuration

This uses a server with Jenkins, Terraform, Ansible, and Yandex CLI installed. Yandex CLI is set up for a non-root user. In Jenkins, an agent is created on localhost with SSH access running as the same user as Yandex CLI.

The following parameters are defined for the build:
- regen: If set (true), requests a new Yandex Cloud token.
- destroy: If set (true), initiates a "terraform destroy" action.

The pipeline uses Docker Hub credentials stored natively in Jenkins. Make sure to replace those, along with the corresponding image tags, with your own at stages 5 and 6.

The Boxfuse app (original repo: <https://github.com/boxfuse/boxfuse-sample-java-war-hello>) is used for this assignment, imported into my own repo at <https://github.com/ArtemVakhitov/myboxfuse.git> with a Dockerfile added to it. I could do without it but decided to reuse this repo created for another DevOps School assignment.

For the pipeline to work without modifications, it needs to be run using the SCM checkout procedure and not copy-pasted into the Jenkins pipeline editor.

## Steps

1. Prepare Jenkins workspace. In particular, on the first run, this requests a Yandex Cloud token and saves it to a file. On subsequent runs, the token is requested again only if the "regen" build parameter is set to true; otherwise, the saved token is reused.
Note that the pipeline creates a temporary SSH key pair for each build, deleting a previously created key pair of the same name if it finds one.
2. Run "terraform init" and "terraform apply" to create the VM instances and populate Ansible inventory. Alternatively, run "terraform destroy" to destroy previously created instances if the "destroy" build parameter is set to "true".
3. Run Ansible playbook that installs the required packages on the instances.
4. On the build server, clone the app repo and build the app using Maven.
5. Build a Docker image of the app and push it from the build server to Docker Hub.
6. Pull the app image from Docker Hub and deploy on the staging server at <http://staging_ip/hello-1.0>.