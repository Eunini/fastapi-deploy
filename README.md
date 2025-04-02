# FastAPI Deployment with Docker, Ansible, and GitHub Actions

This project demonstrates how to deploy a FastAPI application using Docker, Ansible, GitHub Actions, Terraform, and AWS services. The goal is to automate the deployment process, ensure consistency across environments, and enable monitoring and auto-scaling for high availability and performance.

## Project Overview

This project consists of the following components:
- **FastAPI Application**: A web application built with FastAPI.
- **Docker**: Containerizes the application to ensure consistency across different environments.
- **Ansible**: Automates the configuration of the server.
- **GitHub Actions**: Implements CI/CD to automate testing and deployment.
- **Terraform**: Provisions infrastructure on AWS.
- **AWS CloudWatch and Auto Scaling**: Monitors the application and scales the infrastructure based on traffic.

## Architecture

!Architecture Diagram ![fastapi drawio](https://github.com/user-attachments/assets/432f4a35-fb11-4dae-9924-750295881a7b)



### Components

1. **FastAPI Application**: The core application built with FastAPI.
2. **Docker**: Used to containerize the FastAPI application.
3. **PostgreSQL Database**: A relational database to store application data.
4. **EC2 Instance**: Hosts the Docker containers.
5. **GitHub Actions**: Automates CI/CD pipeline for building and deploying the application.
6. **Terraform**: Manages infrastructure provisioning on AWS.
7. **CloudWatch**: Monitors the application performance.
8. **Auto Scaling Group**: Automatically adjusts the number of EC2 instances based on traffic.

## Prerequisites

- AWS Account
- GitHub Account
- Docker
- Ansible
- Terraform
- Python 3.9
- FastAPI
- Uvicorn
- PostgreSQL

## Setup and Deployment

### Step 1: Configure Server Using Ansible

Create an Ansible playbook (`deploy.yml`) to install necessary dependencies, such as Python 3, Docker, and Docker Compose, and to start the Docker service.

```yaml name=deploy.yml
- hosts: fastapi
  become: true
  tasks:
    - name: Install Python 3, pip, and Docker
      apt:
        name:
          - python3
          - python3-pip
          - docker.io
          - docker-compose
        state: present

    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: true

    - name: Install dependencies for FastAPI
      pip:
        name:
          - fastapi
          - uvicorn
          - psycopg2
        state: present
```

Run the playbook:
```bash
ansible-playbook -i inventory.ini deploy.yml
```

### Step 2: Containerize Your FastAPI Application

Create a `Dockerfile` in the root of your FastAPI project directory.

```dockerfile name=Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Ensure you have a `requirements.txt` file with the necessary dependencies:

```txt name=requirements.txt
fastapi
uvicorn
psycopg2
```

Create a `docker-compose.yml` file to manage multiple services.

```yaml name=docker-compose.yml
version: "3"

services:
  app:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgresql://admin:YourSecurePassword@db:5432/fastapi_db

  db:
    image: postgres:13
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: YourSecurePassword
      POSTGRES_DB: fastapi_db
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

Build and run the containers:
```bash
docker-compose up --build -d
```

### Step 3: Set Up CI/CD with GitHub Actions

Create a GitHub Actions workflow (`.github/workflows/deploy.yml`) to build and deploy your Docker container.

```yaml name=.github/workflows/deploy.yml
name: Deploy FastAPI to EC2

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build and Push Docker Image
        run: |
          docker build -t your-docker-repo/fastapi-app .
          docker login -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
          docker push your-docker-repo/fastapi-app

      - name: SSH into EC2 and deploy
        run: |
          ssh -i ${{ secrets.EC2_SSH_KEY }} ubuntu@your-ec2-ip "cd /path/to/your/app && docker-compose pull && docker-compose up -d"
        env:
          EC2_SSH_KEY: ${{ secrets.EC2_SSH_KEY }}
```

Set the following GitHub secrets:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `EC2_SSH_KEY` (your EC2 private key for SSH access)

### Step 4: Set Up Monitoring with AWS CloudWatch and Auto Scaling

Enable Detailed Monitoring in the AWS Management Console.

#### AWS CloudWatch
- Go to the AWS Management Console → EC2 → Instances → Select your instance.
- Under Monitoring, enable Detailed Monitoring.

#### Auto Scaling
Create an Auto Scaling Group using Terraform.

```hcl name=main.tf
resource "aws_launch_configuration" "fastapi_lc" {
  name          = "fastapi-lc"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.fastapi_sg.id]
}

resource "aws_autoscaling_group" "fastapi_asg" {
  desired_capacity     = 2
  min_size             = 1
  max_size             = 5
  launch_configuration = aws_launch_configuration.fastapi_lc.name
  vpc_zone_identifier  = [subnet_id]
}
```

Apply the Terraform changes:
```bash
terraform apply
```

## Conclusion

You've successfully set up:
- Infrastructure provisioning with Terraform.
- Server configuration with Ansible.
- Containerization with Docker.
- CI/CD pipeline with GitHub Actions.
- Monitoring and auto-scaling using AWS CloudWatch and Auto Scaling.

Feel free to reach out with any questions or issues!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
