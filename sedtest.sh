
AWS_ECR_ACCOUNT_URL=url
CIRCLE_SHA1=hash
sed -i".back" -e "s/\<IMAGE1_NAME\>/${AWS_ECR_ACCOUNT_URL}\/ecs-deploy-test-nginx:${CIRCLE_SHA1}/" taskdef-copy.json