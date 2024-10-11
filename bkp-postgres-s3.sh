#!/bin/bash

# Solicita o nome e o caminho do arquivo .env
read -p "Digite o caminho para salvar o arquivo .env (ex: /etc/myapp/config_backup.env): " ENV_PATH

# Solicita os dados do banco de dados
read -p "Digite o nome do banco de dados: " DB_NAME
read -p "Digite o nome do usuário do banco de dados: " DB_USER
read -sp "Digite a senha do banco de dados: " DB_PASSWORD
echo ""
read -p "Digite a porta do PostgreSQL (default 5432): " DB_PORT
DB_PORT=${DB_PORT:-5432}

# Solicita as credenciais do AWS S3
read -p "Digite o bucket S3 (ex: s3://meu-bucket/backups): " S3_BUCKET
read -p "Digite o AWS Access Key: " AWS_ACCESS_KEY
read -sp "Digite o AWS Secret Key: " AWS_SECRET_KEY
echo ""

# Cria o arquivo .env com as credenciais fornecidas
cat <<EOL > $ENV_PATH
# Arquivo de configuração .env

# Credenciais do PostgreSQL
PGPASSWORD=$DB_PASSWORD

# Credenciais da AWS
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY

# Bucket S3
S3_BUCKET=$S3_BUCKET
EOL

# Define permissões seguras para o arquivo .env
chmod 600 $ENV_PATH
echo "Arquivo .env criado com sucesso em: $ENV_PATH"

# Cria o script de backup
BACKUP_SCRIPT="backup_postgres_to_s3.sh"

cat <<EOL > $BACKUP_SCRIPT
#!/bin/bash

# Carrega as variáveis de ambiente do arquivo .env
source $ENV_PATH

# Dados do banco de dados
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PORT="$DB_PORT"
BACKUP_FILE="\${DB_NAME}_\$(date +%Y%m%d%H%M%S).sql.gz"

# Realiza o backup do banco de dados
pg_dump -h localhost -p \$DB_PORT -U \$DB_USER \$DB_NAME | gzip > \$BACKUP_FILE

# Envia o backup para o S3
aws s3 cp \$BACKUP_FILE \$S3_BUCKET

# Remove o backup local
rm -f \$BACKUP_FILE

echo "Backup enviado para o S3 e arquivo local removido."
EOL

# Torna o script de backup executável
chmod +x $BACKUP_SCRIPT

echo "Script de backup gerado com sucesso: $BACKUP_SCRIPT"
