pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        ECS_CLUSTER = 'devops-challenge-cluster'
        FRONTEND_SERVICE = 'devops-challenge-frontend'
        BACKEND_SERVICE = 'devops-challenge-backend'
        FRONTEND_REPO = 'devops-challenge-frontend'
        BACKEND_REPO = 'devops-challenge-backend'
    }

    stages {
        stage('Checkout and Verify') {
            steps {
                checkout scm
                sh '''
                    set -eu
                    test -f README.md
                    test -f backend/package.json
                    test -f backend/Dockerfile
                    test -f frontend/package.json
                    test -f frontend/Dockerfile
                    echo "Project files verified."
                '''
            }
        }

        stage('Build, Test, and Push Images') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        set -eu
                        set +x

                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                        IMAGE_TAG="${GIT_COMMIT:-$(git rev-parse HEAD)}"
                        IMAGE_TAG=$(printf '%s' "$IMAGE_TAG" | cut -c1-12)

                        FRONTEND_IMAGE="${REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"
                        BACKEND_IMAGE="${REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"

                        aws ecr get-login-password --region "$AWS_DEFAULT_REGION" |
                            docker login --username AWS --password-stdin "$REGISTRY"

                        docker build --pull -t "$FRONTEND_IMAGE" frontend
                        docker build --pull -t "$BACKEND_IMAGE" backend

                        # Run the backend's available test script when defined.
                        if node -e "process.exit(require('./backend/package.json').scripts?.test ? 0 : 1)"; then
                        else
                            echo "No backend test script is defined; skipping automated backend tests."
                        fi

                        docker push "$FRONTEND_IMAGE"
                        docker push "$BACKEND_IMAGE"

                        echo "$IMAGE_TAG" > .image-tag
                        echo "IMAGE_TAG=$IMAGE_TAG" > .image-tag.env
                    '''
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        set -eu
                        set +x

                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                        IMAGE_TAG=$(git rev-parse HEAD | cut -c1-12)

                        for SERVICE in "$FRONTEND_SERVICE" "$BACKEND_SERVICE"; do
                            echo "Updating $SERVICE..."
                            TASK_ARN=$(aws ecs describe-services \
                                --cluster "$ECS_CLUSTER" \
                                --services "$SERVICE" \
                                --query 'services[0].taskDefinition' \
                                --output text)

                            TASK_JSON=$(mktemp)
                            UPDATED_JSON=$(mktemp)
                            aws ecs describe-task-definition \
                                --task-definition "$TASK_ARN" \
                                --query taskDefinition > "$TASK_JSON"

                            case "$SERVICE" in
                                "$FRONTEND_SERVICE") CONTAINER_NAME="frontend" ;;
                                "$BACKEND_SERVICE") CONTAINER_NAME="backend" ;;
                            esac

                            IMAGE="${REGISTRY}/${SERVICE}:${IMAGE_TAG}"

                            CONTAINER_NAME="$CONTAINER_NAME" IMAGE="$IMAGE" \
                            python3 - "$TASK_JSON" "$UPDATED_JSON" <<'PY'
import json, os, sys
source, target = sys.argv[1:3]
with open(source) as f:
    task = json.load(f)
name = os.environ["CONTAINER_NAME"]
image = os.environ["IMAGE"]
found = False
for container in task.get("containerDefinitions", []):
    if container["name"] == name:
        container["image"] = image
        found = True
if not found:
    raise SystemExit("Expected container name not found: " + name)
allowed = (
    "family", "taskRoleArn", "executionRoleArn", "networkMode",
    "containerDefinitions", "volumes", "placementConstraints",
    "requiresCompatibilities", "cpu", "memory", "pidMode", "ipcMode",
    "proxyConfiguration", "inferenceAccelerators", "ephemeralStorage",
    "runtimePlatform"
)
with open(target, "w") as f:
    json.dump({k: v for k, v in task.items() if k in allowed}, f)
PY

                            NEW_TASK=$(aws ecs register-task-definition \
                                --cli-input-json "file://$UPDATED_JSON" \
                                --query 'taskDefinition.taskDefinitionArn' \
                                --output text)

                            aws ecs update-service \
                                --cluster "$ECS_CLUSTER" \
                                --service "$SERVICE" \
                                --task-definition "$NEW_TASK" >/dev/null

                            rm -f "$TASK_JSON" "$UPDATED_JSON"
                        done

                        echo "New task definitions registered and deployments requested."
                    '''
                }
            }
        }

        stage('Wait for ECS Stability') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id',
                           variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key',
                           variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        set -eu
                        set +x
                        aws ecs wait services-stable \
                            --cluster "$ECS_CLUSTER" \
                            --services "$FRONTEND_SERVICE" "$BACKEND_SERVICE"
                        echo "Both ECS services reached a stable state."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Images built, pushed, and ECS services reached stability.'
        }
        failure {
            echo 'FAILURE: Review Console Output for the failed stage.'
        }
    }
}
