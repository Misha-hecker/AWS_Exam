# AWS Exam — ToDoAI на Application Load Balancer

Виконання завдання з `AWS Exam.txt`: Docker-образ → Amazon ECR → Terraform
(ALB + autoscaling policy) → публічний доступ через Route53 за іменем
`myrkoslk.pp.ua` → усе в GitHub.

## Архітектура

```
                        ┌────────────────────────────────────────────────┐
                        │              Route53 (myrkoslk.pp.ua)          │
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
             │  health check = ELB, 3 публічні підсеті default VPC                 │
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
             │  Amazon ECR (приватний): 679607640360.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1 │
             └─────────────────────────────────────────────────────────────────────┘
```

## Структура репозиторію

```
AWS_Exam/
├── AWS Exam.txt                  # умова завдання
├── README.md                     # цей файл
├── .gitignore                    # tfstate/.terraform/secrets — у гіт не потрапляють
├── Screenshots/                  # скріншоти виконання (звіт)
├── Skills/
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
    ├── route53.tf                # hosted zone + alias-запис myrkoslk.pp.ua
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
  docker login --username AWS --password-stdin 679607640360.dkr.ecr.eu-north-1.amazonaws.com
docker tag todoai:v1 679607640360.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1
docker push 679607640360.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1
```

Образ: `679607640360.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1`

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

Після `terraform apply` виведе NS-записи зони — вони підставляються
в панель управління доменом pp.ua/uadns (див. розділ «Делегування»).

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

- AWS-акаунт: `679607640360`, IAM-користувач `master`, регіон `eu-north-1`.
- Креденціали — у `~/.aws/credentials` (профіль `default`), **у репозиторій не комітяться**.
- Папка у WSL: `/mnt/c/Users/mihaj/Desktop/AWS_Exam`.

## Потрібні політики IAM (для користувача `master`)

Через обмеження прав користувача `master` у консолі AWS (IAM → Users →
master → Permissions) **треба додати дві AWS managed policies**:

1. **`AmazonRoute53FullAccess`** — без неї Terraform не проходить plan/apply:
   бракує `route53:GetChange` (очікування INSYNC) та
   `route53:ListTagsForResource` (читання тегів зони).
   Створення зони та записів уже дозволені — бракує лише цих двох дій.
2. **`IAMFullAccess`** — бракує `iam:CreateInstanceProfile`
   (підвішування ролі до EC2-інстанса) та `iam:PassRole` для `RunInstances`.
   Роль при цьому навмисно називається `ecsInstanceRole-todoai` — це
   відповідає умові наявної політики `AmazonECS_FullAccess`
   (`iam:PassRole` лише для `ecsInstanceRole*` → `ec2.amazonaws.com`).

Якщо консоль працює від імені `master` і сама видає AccessDenied —
увійдіть в AWS Console як **root** і навішайте політики там.

Уже наявні політики, які покривають решту: `AmazonEC2FullAccess`
(`ec2:*`, `elasticloadbalancing:*`, `autoscaling:*`, `cloudwatch:*`),
`AmazonEC2ContainerRegistryFullAccess` (ECR), `AmazonECS_FullAccess`
(частин IAM/Route53), `AmazonS3FullAccess`, `AdministratorAccess-Amplify`, `Amplify`.

## Делегування домену (ручний крок)

Домен `myrkoslk.pp.ua` делегований на NS паркувального сервісу pp.ua
(`parked1/parked2.uadns.com`, A-запис `135.181.41.169` — parking-сторінка).
Після створення hosted zone в AWS у панелі **pp.ua / uadns** треба замінити
NS-записи домену на NS зони Route53 (виводяться командою `terraform output nameservers`).

Час оновлення делегації — до кількох хвилин/годин (залежить від TTL панелі).

## Перевірка після розгортання

```bash
# NS-записи домену (мають збігатися із зоною Route53)
nslookup -type=NS myrkoslk.pp.ua 1.1.1.1

# Відповідь застосунку через ALB (напряму, до налаштування DNS)
curl -I http://<alb_dns_name>/

# Відповідь через домен
curl -I http://myrkoslk.pp.ua/

# Стан Auto Scaling Group (має бути 1..2 інстанси, healthy)
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names todoai-asg \
  --query 'AutoScalingGroups[0].{min:MinSize,max:MaxSize,desired:DesiredCapacity,instances:Instances[*].{id:InstanceId,state:LifecycleState,health:HealthStatus}'

# Стан цільових груп ALB
aws elbv2 describe-target-health --target-group-arn <target_group_arn>

# Autoscaling policy (target tracking, CPU 60%)
aws autoscaling describe-policies --auto-scaling-group-names todoai-asg \
  --query 'ScalingPolicies[].[PolicyName,PolicyType]'
```

## Результат (фінальний стан)

Розгортання завершено — усі сервіси працюють:

| Параметр | Значення |
|---|---|
| ALB DNS | `todoai-alb-1961312966.eu-north-1.elb.amazonaws.com` |
| Публічний URL | **http://myrkoslk.pp.ua/** → `HTTP/1.1 200 OK` ✅ |
| Hosted zone | `Z0392929378K6WZA49W8C` (alias A-запис → ALB) |
| NS зони | ns-245.awsdns-30.com, ns-839.awsdns-40.net, ns-1928.awsdns-49.co.uk, ns-1397.awsdns-46.org |
| Делегація pp.ua | NS замінено на AWS-NS; A = IP ALB (`13.63.146.10`, `16.192.238.42`) ✅ |
| ASG | `todoai-asg`: min 1 / max 2 / desired 1, health check = ELB |
| Інстанс | `i-0618d8831897e4607` — InService / Healthy, target group **healthy** |
| Autoscaling policy | `todoai-cpu-target-tracking` — TargetTrackingScaling, `ASGAverageCPUUtilization` = 60% |
| ECR | `679607640360.dkr.ecr.eu-north-1.amazonaws.com/todoai:v1` |

### Фікс: vite блокував запити з ALB (403)

Vite 5.4.x (security-fix) відхиляє запити з невідомим `Host`:

```
Blocked request. This host ("todoai-alb-...elb.amazonaws.com") is not allowed.
```

Виправлення — `preview.allowedHosts` у `vite.config.ts` вихідника ToDoAI
(дозволено `myrkoslk.pp.ua`, DNS-ім'я ALB та `.elb.amazonaws.com`),
образ перезібрано й перезалито в ECR (digest `sha256:3bb8956e…`),
інстанс ASG перестворено для підтягування нового `v1`.
**Цю зміну `vite.config.ts` треба закомітити у репозиторій ToDoAI.**

### Скріншоти

- `Screenshots/01-ecr-image.png` — образ `todoai:v1` локально та в ECR
- `Screenshots/02-terraform-apply.png` — `terraform apply` + outputs
- `Screenshots/03-dns-delegation.png` — NS/A-записи та `HTTP 200` через домен
- `Screenshots/04-verify-infra.png` — target healthy, ASG, policy, перевірки curl

## Очищення

```powershell
cd Terraform
terraform destroy
# + видалити ECR-репозиторій (якщо не потрібен):
# aws ecr delete-repository --repository-name todoai
# + повернути NS паркувальника в панелі pp.ua
```
