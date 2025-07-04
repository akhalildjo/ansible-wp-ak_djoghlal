SSH_KEY=~/.ssh/ansible_key
SSH_PUB=$(SSH_KEY).pub

all: up ssh-key inject-key

# Étape 1 : Lancer docker-compose
up:
	docker-compose up -d

# Étape 2 : Générer la paire de clés si elle n'existe pas
ssh-key:
	@if [ ! -f $(SSH_KEY) ]; then \
		echo "[+] Génération de la paire de clés SSH..."; \
		ssh-keygen -t rsa -b 4096 -f $(SSH_KEY) -N ""; \
	else \
		echo "[✔] Clé SSH déjà existante à $(SSH_KEY)"; \
	fi

# Étape 3 : Injecter la clé publique dans les conteneurs
inject-key:
	@for container in ubuntu-ansible rocky-ansible; do \
		echo "[+] Attente que l'utilisateur 'ansible' soit prêt dans $$container..."; \
		until docker exec $$container id ansible >/dev/null 2>&1; do \
			sleep 1; \
		done; \
		echo "[✔] Utilisateur 'ansible' prêt dans $$container"; \
		echo "[+] Injection de la clé SSH dans $$container..."; \
		docker exec -u ansible $$container mkdir -p /home/ansible/.ssh; \
		docker cp $(SSH_PUB) $$container:/home/ansible/.ssh/authorized_keys; \
		docker exec -u root $$container chown -R ansible:ansible /home/ansible/.ssh; \
		docker exec -u root $$container chmod 700 /home/ansible/.ssh; \
		docker exec -u root $$container chmod 600 /home/ansible/.ssh/authorized_keys; \
	done

ping:
	@echo "[+] Test de la connexion SSH avec Ansible..."
	ansible -i inventory.yml all -m ping

deploy:
	@mkdir -p logs
	@echo "[+] Déploiement WordPress avec Ansible..."
	@ansible-playbook -i inventory.yml site_local_role.yml -vv > logs/deploy.log 2>&1

clean:
	@echo "[🧹] Suppression des conteneurs et nettoyage..."
	docker-compose down -v
	@echo "[🗝️] Suppression des clés SSH..."
	rm -f ~/.ssh/ansible_key ~/.ssh/ansible_key.pub
	@echo "[🗑️] Suppression des logs..."
	rm -rf logs