pipeline {
    
    agent any

    stages {
        // Jenkins runs unprivileged so this is how we get all files in the workspace
        stage ('set up workspace') {
            steps {
                sh 'git clone https://github.com/ArtemVakhitov/devops-school-cert.git'
                sh 'cp -n devops-school-cert/.terraformrc ~'
                sh 'rm -f ~/.ssh/id_dsa*'
                sh 'ssh-keygen -q -t ecdsa -N "" -f ~/.ssh/id_dsa'
            }
        }
        
        stage ('launch instances using Terraform') {
            steps {
                dir ("devops-school-cert") {
                    sh 'terraform init'
                    sh 'terraform apply --auto-approve'
                }
            }
        }

        stage ('prepare servers using Ansible') {
            steps {
                dir ("devops-school-cert") {
                    sh 'ansible-playbook playbook.yaml'
                } 
            }
        }

        stage ('git clone app repo') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output build_ip) <<-EOF
						git clone https://github.com/ArtemVakhitov/myboxfuse.git
						EOF
                   '''
            }
        }

        stage ('build app') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output build_ip) <<-EOF
						cd myboxfuse
						mvn package
						EOF
                   '''
            }
        }

        stage ('build & push docker image') {
            environment {
                DKR = credentials("477ad5b1-786e-44ab-80f5-0faae9a7a84b")
            }
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output build_ip) <<-EOF
						cd myboxfuse
						sudo docker build -t artemvakhitov/myboxweb .
						sudo docker login -u $DKR_USR -p $DKR_PSW
						sudo docker push artemvakhitov/myboxweb
						EOF
                   '''
            }
        }

        stage ('deploy on staging using docker') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output staging_ip) <<-EOF
						sudo docker pull artemvakhitov/myboxweb
						sudo docker run -d -p 80:8080 artemvakhitov/myboxweb
						EOF
                   '''
            }
        }
    }
}