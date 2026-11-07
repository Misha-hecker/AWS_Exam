# AWS Exam — ToDoAI на Application Load Balancer


Навчальний приклад розгортання Docker-застосунку через Amazon ECR і Terraform
(Application Load Balancer + Auto Scaling) з опційним DNS у Route53.
Не зберігайте тут особисті ідентифікатори акаунтів, домени чи локальні шляхи.

## Архітектура

```
                        ┌────────────────────────────────────────────────┐
                        │              Route53 (ваш домен)                │
                        │   hosted zone + alias A-запис → ALB (IPv4)     │
                        └───────────────────────┬────────────────────────┘
                                                │
Інтернет ──► :80 ──► ┌──────────────────────────▼──────────────────────────┐
                     │  Application Load Balancer (todoai-alb, публічний)  │
                     │  SG: 80/tcp з 0.0.0.0/0                            │
                     └──────────────────────────┬──────────────────────────┘
                                                │ forward
                     ┌──────────────────────────▼──────────────────────────┐
                     │  Target Group (todoai-tg, порт 5173, health: /)     │
                     └──────────────────────────┬──────────────────────────┘
                                                │
             ┌──────────────────────────────────▼──────────────────────────────────┐
             │  Auto Scaling Group (todoai-asg): min 1 / max 2 / desired 1,        │
             │  health check = ELB, 3 публічні підсети default VPC                 │
             │  ┌──────────────────────────────────────────────────────────────┐   │
             │  │ EC2 t3.micro (Amazon Linux 2023, launch template):          │   │
             │  │   user_data: dnf install docker → ecr login → pull → run    │   │
             │  │   контейнер: todoai:v1, порт 5173 (vite preview)            │   │
             │  │   IAM-роль ecsInstanceRole-todoai + instance profile        │   │
             │  │   (AmazonEC2ContainerRegistryReadOnly)                      │   │
             │  │   SG: 5173/tcp лише від SG ALB                              │   │
             │  └──────────────────────────────────────────────────────────────┘   │
             └─────────────────────────────────────────────────────────────────────┘
                                                ▲
              Autoscaling policy (пункт 3a): target-tracking
              ASGAverageCPUUtilization = 60% → масштабування до 2 інстансів
                                                ▲
             ┌──────────────────────────────────┴──────────────────────────────────┐
             │  Amazon ECR (приватний): <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1 │
             └─────────────────────────────────────────────────────────────────────┘
```

## Структура репозиторію

```
AWS_Exam/
├── AWS Exam.txt                  # умова завдання
├── README.md                     # цей файл
├── .gitignore                    # tfstate/.terraform/secrets — у гіт не потрапляють
├── Screenshots/                  # скріншоти виконання (звіт)
├── .agents/skills/               # Agent Skills: project-specific AWS workflows
│   ├── terraform-aws-workflow/SKILL.md
│   ├── ecr-image-release/SKILL.md
│   ├── aws-deployment-verification/SKILL.md
│   └── aws-infrastructure-security-review/SKILL.md
└── Terraform/
    ├── versions.tf               # Terraform >= 1.5, провайдер hashicorp/aws ~> 5.0
    ├── providers.tf              # регіон eu-north-1, креди із ~/.aws/credentials
    ├── variables.tf              # змінні (регіон, домен, ASG, порт, CPU target)
    ├── vpc.tf                    # default VPC + публічні підсеті
    ├── sg.tf                     # SG ALB (:80) і SG застосунку (:5173 лише від ALB)
    ├── iam.tf                    # IAM-роль + instance profile для pull з ECR
    ├── launch.tf                 # launch template: AL2023 + user_data (docker run)
    ├── alb.tf                    # ALB + target group + listener :80
    ├── asg.tf                    # Auto Scaling Group (min/max/desired)
    ├── scaling.tf                # autoscaling policy: target-tracking по CPU 60%
    ├── route53.tf                # hosted zone + alias-запис для вашого домену
    ├── outputs.tf                # корисні виводи (ALB DNS, NS, URI образу)
    └── terraform.tfvars.example  # приклад значень (без секретів!)
```

## Виконані кроки

### 1. Docker-образ (вихідник: репозиторій ToDoAI)

Образ зібрано з готового `Dockerfile` (node → `npm install && npm run build` →
`vite preview --host 0.0.0.0 --port 5173`):

```bash
docker build -t todoai:v1 .
```

### 2. Завантаження в Amazon ECR

```bash
aws ecr create-repository --repository-name todoai --region eu-north-1 \
  --image-scanning-configuration scanOnPush=true
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com
docker tag todoai:v1 <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1
docker push <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1
```

Образ: `<AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1`

### 3. Terraform: ALB + autoscaling policy

```powershell
cd Terraform
terraform init
terraform plan
terraform apply        # (на Windows: C:\Windows\System32\terraform.exe)
```
Створюється: SG ×2, IAM-роль + instance profile, launch template,
ALB + target group + listener, ASG (min 1 / max 2 / desired 1),
**autoscaling policy `todoai-cpu-target-tracking`** (target-tracking,
`ASGAverageCPUUtilization` = 60%, пункт 3a завдання),
hosted zone + alias-запис у Route53.

### 4. Публічний доступ через Route53

Після `terraform apply` Terraform виведе NS-записи зони — додайте їх у панелі
керування вашого реєстратора (див. розділ «Делегування домену»).

### 5. GitHub

Код, README та скріншоти комітяться в цей репозиторій.
**Секрети (tfstate, tfvars, ключі) у гіт не потрапляють** — виключені `.gitignore`.

## Передумови та інструменти

| Інструмент | Де виконується | Версія |
|---|---|---|
| `aws` CLI | WSL Ubuntu | 2.38.5 |
| `docker` | WSL Ubuntu | 29.9.2 |
| `terraform` | Windows (`C:\Windows\System32\terraform.exe`) | 1.15.7 |
| `git` | обидва середовища | 2.43 |

- Регіон прикладу: `eu-north-1`. AWS account ID та IAM-користувач залежать від вашого середовища; не публікуйте їх.
- Креденціали — у `~/.aws/credentials` (профіль `default`), **у репозиторій не комітяться**.

## IAM-права

Надавайте deployment identity лише необхідні дозволи для EC2, ELB, Auto Scaling,
ECR, IAM PassRole/instance profile та Route53 (якщо використовуєте DNS).
Уникайте постійного використання root або широких admin-політик; не додавайте
до README ідентифікатори акаунтів, імена користувачів чи деталі приватних прав.

## Делегування домену

Для власного домену після створення hosted zone оновіть NS-записи у реєстратора
значеннями з `terraform output nameservers`. Делегація змінюється окремо від
Terraform; час оновлення залежить від DNS-кешів і TTL.

## Перевірка після розгортання

Використовуйте ALB DNS та домен, вказані у Terraform outputs, щоб перевірити
HTTP-відповідь, стан Auto Scaling Group, target health і scaling policy.
Не вставляйте реальні домени, account ID, IP-адреси чи resource ID у README.

## Поточний стан

Навчальне розгортання, яке раніше описувалося в цьому README, знищене через
`terraform destroy`; приватний ECR-репозиторій `todoai` також видалений.
Отже, описані ресурси та застосунок більше не доступні. Якщо DNS делегували
на Route53, перевірте NS-записи у реєстратора окремо.

### Примітка щодо Vite

Vite може блокувати незнайомі `Host` заголовки. Налаштовуйте
`preview.allowedHosts` лише для конкретних доменів, яким довіряєте; не вимикайте
перевірку host indiscriminately.

## Очищення

```powershell
cd Terraform
terraform destroy
aws ecr delete-repository --repository-name todoai --force
```
