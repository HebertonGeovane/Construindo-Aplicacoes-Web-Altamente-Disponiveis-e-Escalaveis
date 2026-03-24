# 🚀 AWS Highly Available Architecture Challenge

Desafio prático de arquitetura AWS focado na implementação de uma infraestrutura resiliente e escalável.

Toda a validação da arquitetura é realizada em **tempo real**, através de uma interface web interativa hospedada diretamente nas instâncias EC2, exibindo dados dinâmicos via IMDSv2.

---

# ⚠️ IMPORTANTE — CUSTOS

> ❗ **Atenção:** Este laboratório pode gerar custos na AWS. 
> Se a sua conta não estiver no **Free Tier**, consulte os preços antes de iniciar.

## 💰 Serviços utilizados

| Serviço            | Pode gerar custo? | Observação |
|--------------------|------------------|------------|
| VPC                | ❌ Não           | Subnets e rede básica são gratuitas |
| EC2 (t3.micro)     | ⚠️ Sim           | Gratuito apenas no Free Tier |
| Auto Scaling Group | ⚠️ Sim           | Depende do número de instâncias ligadas |
| ALB                | ⚠️ Sim           | Cobrado por hora de provimento + tráfego |
| CloudFront         | ⚠️ Sim           | Possui cota gratuita limitada |

---

## ⚠️ LIMPEZA DO AMBIENTE

Para evitar cobranças indesejadas após o desafio, você **NÃO deve excluir apenas as instâncias EC2**.
✔ **O fluxo correto é:** Excluir o **Auto Scaling Group (ASG)** primeiro. Caso contrário, o ASG identificará a falta de instâncias e criará novas automaticamente.

---

## 🧑‍💻 PRÉ-REQUISITOS (Responsabilidade do Aluno)

Antes de iniciar o desafio técnico, realize o provisionamento manual:

### 🌐 Infraestrutura de Rede
1. Criar uma **VPC** com 3 Availability Zones (AZs).
2. Criar os seguintes **Security Groups**:

| Nome | Regra de Entrada | Origem (Source) |
|------|------------------|-----------------|
| **ALB-SG** | HTTP (80) | 0.0.0.0/0 |
| **APPServer-SG** | HTTP (80) | Security Group: `ALB-SG` |

### 🔐 IAM Role
Criar uma Role chamada **`EC2-AutoScaling-Reader`** para que a instância consiga validar a própria infraestrutura.
* **Permissões necessárias:**
  - `AmazonEC2ReadOnlyAccess`
  - `AutoScalingReadOnlyAccess`

---

## 🧪 PASSO A PASSO DO DESAFIO

### 1️⃣ Criar Launch Template
Configure o molde das instâncias:
* **Tipo:** t3.micro
* **Rede:** IP Público habilitado
* **Segurança:** Anexar `APPServer-SG` e a IAM Role `EC2-AutoScaling-Reader`
* **User Data:** Utilize o script `user-data.sh` disponível neste repositório.

### 2️⃣ Configurar Target Group
* **Nome:** `APP-TG`
* **Health Check Settings:**
  - Healthy threshold: 2
  - Unhealthy threshold: 10
  - Timeout: 50
  - Interval: 60

### 3️⃣ Criar Load Balancer (ALB)
* **Nome:** `APP-ALB`
* **Zonas:** Selecionar as 3 AZs da sua VPC.
* **Listener:** Porta 80 direcionando para o Target Group `APP-TG`.

### 4️⃣ Criar Auto Scaling Group (ASG)
* **Nome:** `APP-ASG`
* **Capacidade:** Desejada: 3 | Mínima: 3 | Máxima: 4.
* **Integração:** Anexar ao Load Balancer `APP-ALB`.

### 5️⃣ Scheduled Action (Ação Programada)
Crie uma ação agendada no ASG para simular o horário comercial:
* **Nome:** `HAS-SA`
* **Recorrência (Cron):** `0 9 * * MON-FRI` (Início às 9h de Seg a Sex).

### 6️⃣ CloudFront (CDN)
* **Origin:** DNS do `APP-ALB`.
* **Protocolo:** HTTP Only (Porta 80).

---

## 🎯 VALIDAÇÃO FINAL

Após o deploy, acesse o link fornecido pelo CloudFront (ou DNS do ALB):

1. Vá até a aba **Dashboard EC2 Live** e atualize a página para ver o balanceamento entre instâncias.
2. Vá até a aba **Formulário de Validação**.
3. Preencha os campos exatamente como configurado:
   - **Auto Scaling Group:** `APP-ASG`
   - **Scheduled Action:** `HAS-SA`
4. Clique em **VERIFICAR LABORATÓRIO**.

---

## 🏆 RESULTADO ESPERADO
Ao clicar em verificar, o sistema consultará os metadados reais da sua conta AWS via CLI. O sucesso será confirmado apenas se:
* A instância fizer parte do grupo `APP-ASG`.
* A Scheduled Action `HAS-SA` existir no console AWS.

---

# Tecnologias Utilizadas

<div align="center">

<img src="https://upload.wikimedia.org/wikipedia/commons/9/93/Amazon_Web_Services_Logo.svg" alt="AWS" width="60" height="60" style="margin: 10px;"/>

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/linux/linux-original.svg" alt="Linux" width="60" height="60" style="margin: 10px;"/>

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" alt="Bash" width="60" height="60" style="margin: 10px;"/>

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/php/php-original.svg" alt="PHP" width="60" height="60" style="margin: 10px;"/>

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/javascript/javascript-original.svg" alt="JavaScript" width="60" height="60" style="margin: 10px;"/>

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/html5/html5-original.svg" alt="HTML" width="60" height="60" style="margin: 10px;"/>

<img src="https://www.vectorlogo.zone/logos/tailwindcss/tailwindcss-icon.svg" alt="TailwindCSS" width="60" height="60" style="margin: 10px;"/>

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/apache/apache-original.svg" alt="Apache" width="60" height="60" style="margin: 10px;"/>

</div>

## 👨‍💻 Autor

**Heberton Geovane**

[![LinkedIn](https://img.shields.io/badge/linkedin-%230077B5.svg?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/heberton-geovane)
