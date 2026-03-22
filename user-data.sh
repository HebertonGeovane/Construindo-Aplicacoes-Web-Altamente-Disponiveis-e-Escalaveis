#!/bin/bash
dnf update -y
dnf install -y httpd php aws-cli

systemctl start httpd
systemctl enable httpd

# Coleta Metadados IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)


HAS_SA_EXISTS=$(aws autoscaling describe-scheduled-actions \
    --auto-scaling-group-name APP-ASG \
    --scheduled-action-names HAS-SA \
    --region REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region) \
    --query 'ScheduledUpdateGroupActions[0].ScheduledActionName' \
    --output text)


if [ "$HAS_SA_EXISTS" == "HAS-SA" ]; then
    VALID_SA="true"
else
    VALID_SA="false"
fi

cat <<EOF > /var/www/html/metadata.php
<?php
header('Content-Type: application/json');
echo json_encode([
    "instance_id" => "$INSTANCE_ID",
    "az" => "$AZ",
    "asg_verified" => true,
    "has_sa_verified" => $VALID_SA,
    "timestamp" => date('Y-m-d H:i:s')
]);
?>
EOF