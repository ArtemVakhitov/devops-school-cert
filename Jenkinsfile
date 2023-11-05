pipeline {
    
    agent any

    stages {
        stage ('launch instances using Terraform') {
            steps {
                sh 'terraform init'
                sh 'terraform apply --auto-approve'
            }
        }
        stage ('prepare servers using Ansible') {
            steps {
                sh 'ansible-playbook playbook.yaml' 
            }
        }
        stage ('git') {
            steps {
                git 'https://github.com/ArtemVakhitov/myboxfuse.git'
            }
        }
        stage ('build') {
            steps {
                sh 'mvn package'
            }
            
        }
        stage ('build & push docker image') {
            environment {
                HOME = "${env.WORKSPACE}"
            }
            steps {
                sh 'docker build -t artemvakhitov/myboxweb .'
                sh 'cat /root/dockersecret | docker login -u artemvakhitov --password-stdin'
                sh 'docker push artemvakhitov/myboxweb'
            }
        }
        stage ('deploy on prod using docker') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no root@158.160.67.159 <<EOF
docker pull artemvakhitov/myboxweb
docker run -d -p 80:8080 artemvakhitov/myboxweb
EOF
'''
            }
        }
    }
}