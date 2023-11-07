pipeline {
    // This is an agent created on the Jenkins server and running under the primary, non-root user
    agent { label 'local' }

    stages {
        
        stage ('set up workspace') {
        // If the "destroy" parameter is set, only the 2nd stage is run with "terraform destroy"
        when { expression { return !params.destroy } }
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
        
        stage ('launch or destroy instances using Terraform') {
            steps {
                dir ("devops-school-cert") {
                    sh '''
                        export PATH="$HOME/yandex-cloud/bin":$PATH
                        # Don't request a token every time, use a file and the "regen" parameter
                        if [ -f "$HOME/yctoken" ] && ! $regen; then
                            export YC_TOKEN=$(cat $HOME/yctoken)
                        else
                            export YC_TOKEN=$(yc iam create-token | tee $HOME/yctoken)
                        fi
                        export YC_CLOUD_ID=$(yc config get cloud-id)
                        export YC_FOLDER_ID=$(yc config get folder-id)
                        if $destroy; then
                            terraform destroy --auto-approve
                        else
                            terraform init
                            terraform apply --auto-approve
                        fi
                    '''
                }
            }
        }

        stage ('prepare servers using Ansible') {
        when { expression { return !params.destroy } }
            steps {
                dir ("devops-school-cert") {
                    sh 'ansible-playbook playbook.yaml'
                } 
            }
        }

        stage ('git clone app repo') {
        when { expression { return !params.destroy } }
            steps {
                dir ("devops-school-cert") {
                    sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output -raw build_ip) <<-EOF
							git clone https://github.com/ArtemVakhitov/myboxfuse.git
							EOF
                    '''
                }
            }
        }

        stage ('build app') {
        when { expression { return !params.destroy } }
            steps {
                dir ("devops-school-cert") {
                    sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output -raw build_ip) <<-EOF
							cd myboxfuse
							mvn package
							EOF
                       '''
                }
            }
        }

        stage ('build & push docker image') {
        when { expression { return !params.destroy } }
            environment {
                DKR = credentials("477ad5b1-786e-44ab-80f5-0faae9a7a84b")
            }
            steps {
                dir ("devops-school-cert") {
                    sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output -raw build_ip) <<-EOF
							cd myboxfuse
							sudo docker build -t artemvakhitov/myboxweb .
							sudo docker login -u $DKR_USR -p $DKR_PSW
							sudo docker push artemvakhitov/myboxweb
							EOF
                    '''
                }
            }
        }

        stage ('deploy on staging using docker') {
        when { expression { return !params.destroy } }
            steps {
                dir ("devops-school-cert") {
                    sh '''ssh -T -o StrictHostKeyChecking=no ubuntu@$(terraform output -raw staging_ip) <<-EOF
							sudo docker pull artemvakhitov/myboxweb
							sudo docker run -d -p 80:8080 artemvakhitov/myboxweb
							EOF
                    '''
                }
            }
        }
    }
}