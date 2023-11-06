pipeline {
    
    agent any

    stages {
        // Jenkins runs unprivileged so this is how we get all files in the workspace
        stage ('set up workspace') {
            steps {
                sh '''
                    git clone https://github.com/ArtemVakhitov/devops-school-cert.git
                    cp -n devops-school-cert/.terraformrc ~
                    rm -f ~/.ssh/id_dsa*
                    ssh-keygen -q -t ecdsa -N "" -f ~/.ssh/id_dsa
                '''
            }
        }
        
        stage ('launch instances using Terraform') {
            steps {
                dir ("devops-school-cert") {
                    sh '''
                        export PATH="~/yandex-cloud/bin":$PATH
                        export YC_TOKEN=$(yc iam create-token)
                        export YC_CLOUD_ID=$(yc config get cloud-id)
                        export YC_FOLDER_ID=$(yc config get folder-id)
                        terraform init
                        terraform apply --auto-approve
                    '''
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' hosts) <<-EOF
						git clone https://github.com/ArtemVakhitov/myboxfuse.git
						EOF
                   '''
            }
        }

        stage ('build app') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' hosts) <<-EOF
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' hosts) <<-EOF
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[staging\]/{n;p;}' hosts) <<-EOF
						sudo docker pull artemvakhitov/myboxweb
						sudo docker run -d -p 80:8080 artemvakhitov/myboxweb
						EOF
                   '''
            }
        }
    }
}