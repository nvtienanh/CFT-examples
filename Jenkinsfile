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
        GIT_URL    = 'ssh://git@github.com:nvtienanh'
        GIT_REPO   = 'CFT-examples.git'
        GIT_CREDS  = 'github_nvtienanh'
        AWS_REGION = 'ap-southeast-1'
        ACCOUNT_ID_DEV      = '856190911244'
        ACCOUNT_ID_STAGING  = '856190911244'
        ACCOUNT_ID_PROD     = '856190911244'
        DEPLOYER_ROLE       = 'nvta/deployment/role-nvta-deployer'
        S3_BUCKET_URL_CONFIG      = "s3://s3-app-nvta-${params.DEPLOY_ENV}-config-ap-southeast-1"
    }

    stages {
        stage('build') {
            steps {
                sh 'python3 --version'
            }
        }
    }
}