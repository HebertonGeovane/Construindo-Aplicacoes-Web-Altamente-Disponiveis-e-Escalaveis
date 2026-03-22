#!/bin/bash
yum update -y
yum install -y httpd php jq aws-cli

# 1. Criar o arquivo PHP que busca os metadados do lado do SERVIDOR
cat <<'EOF' > /var/www/html/metadata.php
<?php
header('Content-Type: application/json');
$token = shell_exec('curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s');
$instance_id = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/instance-id");
$az = shell_exec("curl -H 'X-aws-ec2-metadata-token: $token' -s http://169.254.169.254/latest/meta-data/placement/availability-zone");

echo json_encode([
    "instance_id" => trim($instance_id),
    "az" => trim($az)
]);
?>
EOF

# 2. Busca os dados reais para validação (Necessário Role IAM com Permissão de Leitura)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

# Verifica o nome do ASG real
ASG_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' --output text)
if [ "$ASG_NAME" == "None" ] || [ -z "$ASG_NAME" ]; then ASG_NAME="Nao-Encontrado"; fi

# Verifica se a Ação Programada HAS-SA existe de verdade no console
SA_CHECK=$(aws autoscaling describe-scheduled-actions --auto-scaling-group-name "$ASG_NAME" --scheduled-action-names "HAS-SA" --region "$REGION" --query 'ScheduledUpdateGroupActions[0].ScheduledActionName' --output text)

if [ "$SA_CHECK" != "HAS-SA" ]; then 
    SA_REAL="FALTOU-CRIAR-ACAO"; 
else 
    SA_REAL="HAS-SA"; 
fi

# Gera o arquivo de configuração que o index.html vai ler para comparar
echo "{\"asg_real\": \"$ASG_NAME\", \"sa_real\": \"$SA_REAL\"}" > /var/www/html/config_real.json

# 3. Baixa o código do GitHub
cd /var/www/html
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/index.html -O index.html
mkdir -p assets
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/assets/arquitetura.jpeg -O assets/arquitetura.jpeg

chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd