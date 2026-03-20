#!/bin/bash
yum update -y
yum install -y httpd php jq

# 1. Criar o arquivo PHP que busca os metadados do lado do SERVIDOR
cat <<'EOF' > /var/www/html/metadata.php
<?php
$token = shell_exec('curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s');
$instance_id = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/instance-id");
$az = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/placement/availability-zone");

echo json_encode([
    "instance_id" => trim($instance_id),
    "az" => trim($az)
]);
?>
EOF

# 2. Busca o nome do ASG (Necessário Role IAM)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
ASG_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' --output text)

if [ "$ASG_NAME" == "None" ] || [ -z "$ASG_NAME" ]; then ASG_NAME="Lab-ASG"; fi
echo "{\"asg_real\": \"$ASG_NAME\", \"sa_real\": \"DIY-SA\"}" > /var/www/html/config_real.json

# 3. Baixa o código do GitHub
cd /var/www/html
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/index.html -O index.html
mkdir -p assets
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/assets/arquitetura.jpeg -O assets/arquitetura.jpeg

chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd