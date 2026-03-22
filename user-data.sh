#!/bin/bash
yum update -y
yum install -y httpd php jq aws-cli

# 1. Configura Metadados PHP
cat <<'EOF' > /var/www/html/metadata.php
<?php
header('Content-Type: application/json');
$token = shell_exec('curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"');
$instance_id = shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/instance-id");
$az = shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/placement/availability-zone");
echo json_encode(["instance_id" => trim($instance_id), "az" => trim($az)]);
?>
EOF

# 2. Busca Dados da Infraestrutura Real (API AWS)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)


ASG_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' --output text)


SA_CHECK=$(aws autoscaling describe-scheduled-actions --auto-scaling-group-name "$ASG_NAME" --scheduled-action-names "HAS-SA" --region "$REGION" --query 'ScheduledUpdateGroupActions[0].ScheduledActionName' --output text)


echo "{\"asg_real\": \"$ASG_NAME\", \"sa_real\": \"${SA_CHECK:-NOT_FOUND}\"}" > /var/www/html/config_real.json


chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd