# AWS DevOps Challenge — React, Express, Docker, Terraform & CI/CD

A full-stack application deployed to AWS using containerization, infrastructure as code, and a Jenkins-based deployment workflow.

## Live Application

- **Frontend:** http://devops-challenge-alb-279600759.us-east-1.elb.amazonaws.com/
- **AWS Region:** `us-east-1`

The frontend and backend are served through an AWS Application Load Balancer. The application was tested with HTTP 200 responses from both frontend and backend endpoints.

## Project Overview

This project takes a React frontend and Express backend and deploys them as containerized services on Amazon ECS.

It demonstrates infrastructure provisioning, container builds, application deployment, CI/CD workflow automation, service recovery, and frontend autoscaling configuration.

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
Jenkins CI/CD Workflow
   |
   v
Build and publish Docker images
   |
   v
Amazon ECR
   |
   v
Amazon ECS Services
   |
   +---- Frontend container
   |
   +---- Backend container
   |
   v
Application Load Balancer
   |
   v
Public HTTP endpoint
```

Terraform configuration is maintained in `infrastructure/terraform/`.

## Technologies Used

- **AWS:** ECS, ECR, Application Load Balancer, VPC, subnets, and CloudWatch alarms
- **Terraform:** Infrastructure as code
- **Docker:** Container images for the frontend and backend
- **Docker Compose:** Local multi-container development
- **Jenkins:** CI/CD workflow
- **Git and GitHub:** Source control and project hosting
- **React:** Frontend application
- **Node.js and Express:** Backend API

## Repository Structure

```text
.
├── backend/                  # Express backend
├── frontend/                 # React frontend and Nginx configuration
├── infrastructure/
│   └── terraform/            # AWS infrastructure definitions
├── compose.yaml              # Local container orchestration
├── .gitignore
└── README.md
```

## Prerequisites

For local development:

- Git
- Node.js and npm, or Docker with Docker Compose

For AWS infrastructure deployment:

- An AWS account
- AWS CLI configured with appropriate permissions
- Terraform installed
- Docker installed
- Access to the GitHub repository and Jenkins deployment environment

AWS resources may incur charges. Review resource pricing and clean up resources when they are no longer needed.

## Run Locally with Docker Compose

From the repository root:

```bash
docker compose up --build
```

- Frontend: http://localhost:3000
- Backend: http://localhost:8080

Stop the containers with:

```bash
docker compose down
```

The Compose configuration builds the frontend and backend from their respective directories.

## Run Without Docker

Start the backend first:

```bash
cd backend
npm ci
npm start
```

In a second terminal, start the frontend:

```bash
cd frontend
npm ci
npm start
```

The frontend is available at `http://localhost:3000`, and the backend listens on port `8080`.

## AWS Infrastructure

Terraform files are located in `infrastructure/terraform/`.

The configuration defines AWS resources for the networking layer, container registries, ECS cluster, and application services.

Review the Terraform configuration and confirm the AWS account, region, variables, and permissions before applying changes.

From the Terraform directory:

```bash
cd infrastructure/terraform
terraform init
terraform validate
terraform plan
```

Inspect the plan carefully before applying it. Applying Terraform can create, modify, or destroy billable resources. Do not run `terraform apply` against an existing environment without confirming that the configuration and state refer to the intended infrastructure.

The default region is `us-east-1`.

## CI/CD Workflow

Jenkins runs the deployment pipeline defined in the repository's `Jenkinsfile`.

The `devops-challenge-pipeline` job is configured to use Pipeline script from SCM:
- **Source control:** Git
- **Repository:** https://github.com/CloudbyEmily/devops-code-challenge1
- **Branch:** `*/main`
- **Pipeline script path:** `Jenkinsfile`

To run a deployment, open the Jenkins job, select **Build Now**, and review the console output. The pipeline builds and publishes the frontend and backend Docker images, updates the ECS task definitions and services, and waits for the services to become stable.

AWS credentials are configured in Jenkins using credential IDs. Secret values must not be stored in this README or committed to GitHub. Verify the latest build result in Jenkins and the service status in AWS after deployment.

## Reliability and Scaling

The following checks and configurations were completed during the project:
- Sent five frontend requests and five backend requests; all ten returned HTTP 200.
- Stopped a frontend ECS task and verified that ECS returned to one running task.
- Configured and verified frontend ECS service autoscaling with a minimum capacity of 1 task and a maximum capacity of 4 tasks.
- Configured and verified a CPU target-tracking scaling policy targeting 50% average CPU utilization.
- The frontend ECS task is configured with 512 CPU units and 1 GB of memory.
- Confirmed that AWS created CloudWatch alarms associated with scaling.
Scaling test limitation: The autoscaling configuration was verified.

## Security Notes

- Do not commit AWS credentials, access keys, private keys, `.env` files, Terraform state, or saved Terraform plans.
- The root and Terraform `.gitignore` files exclude common sensitive local files.
- Use IAM roles and least-privilege permissions wherever possible.
- Keep Terraform state in a properly secured backend for collaborative or production use.
- The live application currently uses HTTP. HTTPS and an appropriate TLS certificate should be configured before treating the endpoint as production-ready.

## Future Improvements

- Demonstrate and document a real autoscaling event under controlled load.
- Configure and test HTTPS with a TLS certificate.
- Add automated application tests to the CI/CD workflow.
- Add deployment health verification and rollback handling.
- Document infrastructure teardown and cost-management procedures.

## Author

**Emily — Cloud and DevOps Portfolio Project**

This project was built to develop practical experience with AWS, Docker, Terraform, ECS, CI/CD, and operational reliability.
