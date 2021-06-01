export AWS_PROFILE="kabocha-sndstg-cfn-user"

echo '### BUILD###'
# 変数定義
account_id="619278543031"
region_name="ap-northeast-1"
repogitory_name=$account_id.dkr.ecr.$region_name.amazonaws.com
tag=`date +%Y%m%d%H%M%S`
image_uri=$repogitory_name/dev-sandbox-ecstest-repo:$tag


# BUILD 
echo '# BUILD'
echo $account_id.dkr.ecr.$region_name.amazonaws.com/dev-sandbox-ecstest-repo:$tag
docker build -t $account_id.dkr.ecr.$region_name.amazonaws.com/dev-sandbox-ecstest-repo:$tag .

# ECR Login
echo '# ECR Login'
aws ecr get-login-password --region ap-northeast-1 --profile kabocha-sndstg-cfn-user | docker login --username AWS --password-stdin $account_id.dkr.ecr.$region_name.amazonaws.com

# ECR PUSH
echo '# ECR Push'
echo $image_uri
docker push $account_id.dkr.ecr.$region_name.amazonaws.com/dev-sandbox-ecstest-repo:$tag


echo "# Register TargetDefinition"
taskDefinition=$(cat <<EOM
{
    "executionRoleArn": "arn:aws:iam::619278543031:role/EcsSampleStack-DevSandboxSampleTaskDefinitionExecu-1JZAHU0K45DB",
    "containerDefinitions": [
        {
            "name": "codedeploy-sample-nginx",
            "image": "$image_uri",
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp"
                }
            ],
            "essential": true
        }
    ],
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "family": "codedeploy-sample-nginx",
    "tags": [
        {
            "key": "Service",
            "value": "ecs-deploy-test"
        }
    ]
}
EOM
)

taskDefinitionName=$(aws ecs register-task-definition --cli-input-json "$taskDefinition" --query "taskDefinition.join(':', [family,to_string(revision)])" --output text)
if [ -z "$taskDefinitionName" ]; then
    echo "taskDefitionが取得できません"
    exit 1
fi