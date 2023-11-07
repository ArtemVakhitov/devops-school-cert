pipeline {
    // This is an agent created on the Jenkins server and running under the primary, non-root user
    agent { label 'local' }

    stages {
        
        stage ('set up workspace') {
            steps {
                sh '''
                    rm -rf devops-school-cert
                    git clone https://github.com/ArtemVakhitov/devops-school-cert.git
                    cp -n devops-school-cert/.terraformrc $HOME
                    rm -f $HOME/.ssh/id_dsa*
                    ssh-keygen -q -t ecdsa -N "" -f $HOME/.ssh/id_dsa
                '''
            }
        }
        
        stage ('launch instances using Terraform') {
            environment {
                REGEN = "${params.regen}"
            }
            steps {
                dir ("devops-school-cert") {
                    sh '''
                        export PATH="$HOME/yandex-cloud/bin":$PATH
                        # Don't request a token every time, use a file and regen request variable
                        if [ -f "yctoken" ] && ! $REGEN; then
                            export YC_TOKEN=$(cat yctoken)
                        else
                            export YC_TOKEN=$(yc iam create-token | tee yctoken)
                        fi
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' devops-school-cert/hosts) <<-EOF
						git clone https://github.com/ArtemVakhitov/myboxfuse.git
						EOF
                   '''
            }
        }

        stage ('build app') {
            steps {
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' devops-school-cert/hosts) <<-EOF
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[build\]/{n;p;}' devops-school-cert/hosts) <<-EOF
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
                sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(sed -n '/\[staging\]/{n;p;}' devops-school-cert/hosts) <<-EOF
						sudo docker pull artemvakhitov/myboxweb
						sudo docker run -d -p 80:8080 artemvakhitov/myboxweb
						EOF
                   '''
            }
        }
    }
}