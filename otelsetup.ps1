# Adjust this settings
$certificateDomain = "otelcollector.cloud3s.online"
$DataDog_APIKey = "your datadog api key"

# Internal variables
$stackName = "my-ec2-stack"
$templateFile = "https://raw.githubusercontent.com/silvasm76/opentelemetry-collector-deployment/refs/heads/main/cloudformationtemplate.yaml"
$region = "us-east-1"
$userData = @'
#!/bin/bash
# Download and setup the OpenTelemetry Collector
curl -L -o /tmp/otelcol-contrib_0.113.0_linux_amd64.tar.gz https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.113.0/otelcol-contrib_0.113.0_linux_amd64.tar.gz
cd /tmp
tar -xzf otelcol-contrib_0.113.0_linux_amd64.tar.gz
mv otelcol-contrib /usr/bin/otelcol
chmod +x /usr/bin/otelcol
curl https://raw.githubusercontent.com/silvasm76/opentelemetry-collector-deployment/refs/heads/main/datadogconfig.yaml | sed 's/{apikey}/$DDAPIKEY/g' > /tmp/otelconfig.yaml 
/usr/bin/otelcol --config=/tmp/otelconfig.yaml
'@
$userData = $userData -replace '\$DDAPIKEY', $DataDog_APIKey

Write-Output "Cleaning existing stack with same name"
aws cloudformation delete-stack --stack-name $stackName  --region $region
aws cloudformation wait stack-delete-complete --stack-name $stackName --region $region

Write-Output "Fetching Arn of certificate"

# Run the AWS CLI command and fetch the certificate ARN
$certificateArn = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$certificateDomain'].CertificateArn" --output text

# Check if the ARN was found
if ([string]::IsNullOrEmpty($certificateArn)) {
    Write-Error "Certificate ARN for domain $certificateDomain not found."
    exit 1  # Exit with an error code
}

curl $templateFile -o cloudformationtemplate.yaml
$base64EncodedUserData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userData))

# Create the CloudFormation stack
aws cloudformation create-stack --stack-name $stackName --template-body file://cloudformationtemplate.yaml --region $region  --parameters ParameterKey=CertificateArn,ParameterValue=$certificateArn ParameterKey=UserDataFile,ParameterValue=$base64EncodedUserData

# Wait for stack creation to complete
Write-Output "Waiting  stack $stackName to be created..."
aws cloudformation wait stack-create-complete --stack-name $stackName --region $region

# Retrieve the ALB CNAME from the stack outputs
Write-Output "Retrieving ALB DNS Name ..."
$ALBarns = aws cloudformation describe-stack-resources --stack-name $stackName --query "StackResources[?ResourceType=='AWS::ElasticLoadBalancingV2::LoadBalancer'].PhysicalResourceId" | ConvertFrom-Json
$ALBDNSName = aws elbv2 describe-load-balancers --load-balancer-arns $ALBarns --query "LoadBalancers[0].DNSName" --output text
Write-Output "Next Steps, Add CNAME record on your DNS, point subdomain to:" $ALBDNSName
 
 
