#!/usr/bin/env groovy

pipeline {
    agent any

    options {
      skipStagesAfterUnstable()
      disableConcurrentBuilds()
      timestamps()
      buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '15'))
    }

    parameters {
      string(name: 'BRANCH_NAME', defaultValue: 'master', description: 'Define branch name')
      choice(name: 'DEPLOY_ENV', choices: ['dev', 'staging', 'prod'], description: 'Define environment name')
    }

    environment {
        GIT_URL    = 'https://github.com/nvtienanh'
        GIT_REPO   = 'CFT-examples.git'
        GIT_CREDS  = 'github_nvtienanh'
        AWS_REGION = 'ap-southeast-1'
        ACCOUNT_ID_DEV      = '856190911244'
        ACCOUNT_ID_STAGING  = '856190911244'
        ACCOUNT_ID_PROD     = '856190911244'
        DEPLOYER_ROLE       = 'nvta/deployment/role-nvta-deployer'
        S3_BUCKET_URL_CONFIG      = "s3://s3-app-nvta-${params.DEPLOY_ENV}-config-default-ap-southeast-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout( [$class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH_NAME}"]],
                    clearWorkspace: true,
                    clean: true,
                    userRemoteConfigs: [
                        [
                            credentialsId: "${GIT_CREDS}",
                            url: "${GIT_URL}/${GIT_REPO}"]
                        ]
                ])
            }
        }

        stage('STEP 0: Approve Deployment') {
            when {
                beforeAgent true
                expression { params.DEPLOY_ENV == 'prod' }
            }
            steps {
                timeout(time:1, unit:'DAYS') {
                    input message:'Approve deployment?'
                }
                echo 'Continue'
            }
        }

        stage("STEP 1: Get ACCOUNT_ID for each environment") {
           when {
             expression {
               currentBuild.result == null || currentBuild.result == 'SUCCESS'
             }
           }
           steps {
               script {
                   if ("${params.DEPLOY_ENV}" == 'dev') {
                       ACCOUNT_ID = env.ACCOUNT_ID_DEV
                   } else if ("${params.DEPLOY_ENV}" == 'staging') {
                       ACCOUNT_ID = env.ACCOUNT_ID_STAGING
                   } else if ("${params.DEPLOY_ENV}" == 'prod') {
                       ACCOUNT_ID = env.ACCOUNT_ID_PROD
                   }
               }
           }
        }

        stage("STEP 2: Update/Deploy Base resources") {
           when {
             expression {
               currentBuild.result == null || currentBuild.result == 'SUCCESS'
             }
           }
           steps {
               withAWS(region: "${AWS_REGION}", credentials:'aws_nvtienanh') {
                   sh """
                   set +x
                   TEMPLATE_BODY="--template-body file://CFTs/base-resources.json --parameters ParameterKey=StageName,ParameterValue=${params.DEPLOY_ENV}"
                   bash create-or-update-stack.sh stack-nvta-${params.DEPLOY_ENV}-base-resources-global "\${TEMPLATE_BODY}"
                   """

                //    sleep 5 // Waiting for AWS S3 bucket creation is completely finished

                //    sh """
                //    aws s3 cp --sse aws:kms CFTs/Init.s3.buckets.cf.json "${S3_BUCKET_URL_CONFIG}"
                //    """
               }
           }
        }
    }
}