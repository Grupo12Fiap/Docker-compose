#!/bin/bash

set -e
set -u

function create_user_and_database() {
	local database=$1
	local init_script=$2
	echo "  Creating database '$database' with script '$init_script'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
	    CREATE DATABASE $database;
EOSQL

	# Se o script de inicialização existir, aplica-o ao banco criado
	if [ -f "$init_script" ]; then
		echo "  Applying $init_script to $database..."
		psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$database" -f "$init_script"
	else
		echo "  No init script found for $database, skipping."
	fi
}

# Lista de bancos e seus respectivos scripts (mapeados no docker-compose)
# Os nomes dos arquivos devem bater com o que você colocou no volumes do compose
create_user_and_database "auth_db" "/docker-entrypoint-initdb.d/1-auth.sql"
create_user_and_database "flags_db" "/docker-entrypoint-initdb.d/2-flag.sql"
create_user_and_database "targeting_db" "/docker-entrypoint-initdb.d/3-targeting.sql"

echo "All databases and tables created successfully!"