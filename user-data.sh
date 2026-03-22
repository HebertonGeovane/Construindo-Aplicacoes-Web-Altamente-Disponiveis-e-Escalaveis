#!/bin/bash
yum update -y
yum install -y httpd php jq aws-cli

# 1. Criar o arquivo PHP que busca os metadados do lado do SERVIDOR
cat <<'EOF' > /var/www/html/metadata.php
<?php
$token = shell_exec('curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s');
$instance_id = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/instance-id");
$az = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/placement/availability-zone");

header('Content-Type: application/json');
echo json_encode([
    "instance_id" => trim($instance_id),
    "az" => trim($az)
]);
?>
EOF

# 2. Busca o nome do ASG e Valida a Ação Programada (Necessário Role IAM)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)


ASG_REAL=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' --output text)


SA_CHECK=$(aws autoscaling describe-scheduled-actions \
    --auto-scaling-group-name "$ASG_REAL" \
    --scheduled-action-names "HAS-SA" \
    --region "$REGION" \
    --query 'ScheduledUpdateGroupActions[0].ScheduledActionName' \
    --output text)


if [ "$SA_CHECK" == "None" ] || [ -z "$SA_CHECK" ]; then
    SA_FINAL="NAO_CRIADO"
else
    SA_FINAL="HAS-SA"
fi


echo "{\"asg_real\": \"$ASG_REAL\", \"sa_real\": \"$SA_FINAL\"}" > /var/www/html/config_real.json

# 3. Baixa o código do GitHub
cd /var/www/html
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/index.html -O index.html
mkdir -p assets
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/assets/arquitetura.jpeg -O assets/arquitetura.jpeg


rm -f /var/www/html/index.index.html

chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd