#!/bin/bash
yum update -y
yum install -y httpd php jq aws-cli

# ================================
# 1. METADATA (EC2 INFO)
# ================================
cat <<'EOF' > /var/www/html/metadata.php
<?php
header('Content-Type: application/json');

$token = shell_exec('curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"');

$instance_id = trim(shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/instance-id"));
$az = trim(shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/placement/availability-zone"));

echo json_encode([
  "instance_id" => $instance_id,
  "az" => $az
]);
?>
EOF

# ================================
# 2. VALIDATION (REAL AWS)
# ================================
cat <<'EOF' > /var/www/html/validate.php
<?php
header('Content-Type: application/json');

// ===== METADADOS =====
$token = shell_exec('curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"');

$instance_id = trim(shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/instance-id"));
$region = trim(shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/placement/region"));

// ===== ASG =====
$asg_real = trim(shell_exec("
aws ec2 describe-instances \
--instance-ids $instance_id \
--region $region \
--query 'Reservations[0].Instances[0].Tags[?Key==`aws:autoscaling:groupName`].Value' \
--output text
"));

// ===== SCHEDULED ACTIONS =====
$raw = shell_exec("
aws autoscaling describe-scheduled-actions \
--auto-scaling-group-name \"$asg_real\" \
--region $region \
--output json
");

$data = json_decode($raw, true);

$sa_found = false;
$cron_ok = false;

foreach ($data['ScheduledUpdateGroupActions'] ?? [] as $action) {
  if ($action['ScheduledActionName'] === "HAS-SA") {
    $sa_found = true;

    $recurrence = $action['Recurrence'] ?? "";

    if (
      strpos($recurrence, "9") !== false &&
      strpos($recurrence, "17") !== false &&
      stripos($recurrence, "MON-FRI") !== false
    ) {
      $cron_ok = true;
    }
  }
}

echo json_encode([
  "asg_real" => $asg_real,
  "sa_found" => $sa_found,
  "cron_ok" => $cron_ok
]);
?>
EOF

# ================================
# 3. BAIXAR FRONTEND DO GITHUB
# ================================
cd /var/www/html

wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/index.html -O index.html

mkdir -p assets
wget https://raw.githubusercontent.com/HebertonGeovane/Construindo-Aplicacoes-Web-Altamente-Disponiveis-e-Escalaveis/main/assets/arquitetura.jpeg -O assets/arquitetura.jpeg

# ================================
# 4. PERMISSÕES + APACHE
# ================================
chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd