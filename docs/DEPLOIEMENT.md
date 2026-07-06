# Déploiement

Deux chemins coexistent : **la CI (recommandé)** et **le manuel (secours)**.
Les deux **versionnent automatiquement le service worker** pour que les clients
installés reçoivent la mise à jour.

---

## 1. Déploiement continu (GitHub Actions)

**Principe** : chaque `git push` sur la branche **`dev`** déclenche
`.github/workflows/deploy-dev.yml`, qui :
1. réécrit `const CACHE` dans `sw.js` avec le **SHA court du commit** ;
2. `rsync` le dossier `aujustemotcnv/` vers le webroot du VPS ;
3. fait un **smoke test** HTTP (attend un code 200).

### 1.1 Prérequis côté VPS (une seule fois)

Après un premier déploiement (voir §4), lance sur le VPS :
```bash
bash deploiement/setup-ci-vps.sh
```
Il rend `/var/www/aujustemotcnv` inscriptible par l'utilisateur `deploy` (pour
rsync sans sudo) tout en le gardant lisible par nginx (`www-data`).

### 1.2 Clé SSH dédiée à la CI

Sur ta machine (PowerShell), génère une paire **sans passphrase**, réservée à la
CI :
```powershell
ssh-keygen -t ed25519 -C "github-ci-aujustemot" -f aujustemot_ci
```
Autorise la clé **publique** sur le VPS :
```powershell
Get-Content .\aujustemot_ci.pub | ssh deploy@192.99.68.47 "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```
> Durcissement conseillé : dans `~deploy/.ssh/authorized_keys`, préfixe la clé
> par `restrict,command="rrsync /var/www/aujustemotcnv"` pour la limiter au seul
> rsync vers ce dossier.

### 1.3 Secrets & variables GitHub

Dépôt → **Settings → Secrets and variables → Actions**.

**Secrets** (obligatoires) :

| Nom | Valeur |
|-----|--------|
| `VPS_HOST` | `192.99.68.47` |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | le contenu **complet** du fichier privé `aujustemot_ci` |

**Variables** (facultatives, pour une préproduction — voir §3) :

| Nom | Exemple |
|-----|---------|
| `DEPLOY_PATH` | `/var/www/aujustemotcnv-dev` |
| `CHECK_URL` | `https://dev.justemotcnv.com/` |

Sans ces variables, la CI déploie sur `/var/www/aujustemotcnv` et teste
`https://justemotcnv.com/`.

### 1.4 Ne jamais committer

La clé privée `aujustemot_ci` (le `.gitignore` bloque déjà `*_ci`, `*.pem`,
`*.key`, `.env`). En cas de fuite : révoquer la ligne dans `authorized_keys` et
régénérer.

---

## 2. Le versionnement automatique du service worker

Le `sw.js` est committé avec `const CACHE = "ajm-dev"`. **Ne le fige pas.**
- **CI** : remplacé par `ajm-<sha-du-commit>`.
- **Manuel** : `deployer-serveur.sh` le remplace par `ajm-<horodatage>`.

Sans ce bump, deux déploiements au contenu différent porteraient la même version
de cache, et les PWA installées **ne se mettraient jamais à jour**.

---

## 3. Topologie recommandée : `dev` → préproduction, `main` → production

**Fortement conseillée dès que du contenu non validé peut être poussé** (via
Tommy ou une tâche automatisée — voir `docs/EDITEUR-CONTENU.md`). Aujourd'hui,
`dev` déploie directement en prod, ce qui est acceptable tant que **toi seul**
pousses du contenu déjà revu.

Pour séparer les deux environnements :

1. **DNS (Cloudflare)** : ajoute un enregistrement **A** `dev` →
   `192.99.68.47`, en **« DNS only » (gris)** (comme les autres).
2. **Webroot de préprod** sur le VPS :
   ```bash
   sudo mkdir -p /var/www/aujustemotcnv-dev
   sudo chown -R deploy:www-data /var/www/aujustemotcnv-dev
   ```
3. **Vhost de préprod** : copie `deploiement/aujustemotcnv.conf` en changeant
   `server_name` pour `dev.justemotcnv.com` et `root` pour
   `/var/www/aujustemotcnv-dev`, active-le, puis
   `sudo certbot --nginx -d dev.justemotcnv.com`.
4. **Variables GitHub** : `DEPLOY_PATH=/var/www/aujustemotcnv-dev`,
   `CHECK_URL=https://dev.justemotcnv.com/`.
5. **Prod** : duplique le workflow en `deploy-prod.yml` déclenché sur `push:
   branches: [main]`, sans variables (donc webroot prod). Protège `main`
   (revue obligatoire) dans les réglages de branche.

Flux résultant : on travaille sur `dev` (déploie en préprod, on teste avec
Tommy), puis on ouvre une PR `dev → main` (revue), et le merge déploie en prod.

---

## 4. Premier déploiement / bootstrap (manuel)

Si le webroot et le vhost n'existent pas encore (nouveau serveur), le chemin
manuel initialise tout :

1. Construis le paquet (PowerShell, depuis la racine du dépôt) :
   ```powershell
   Compress-Archive -Path aujustemotcnv, deploiement -DestinationPath aujustemotcnv.zip -Force
   ```
2. Transfère et extrais :
   ```powershell
   .\deploiement\televerser.ps1 -Zip .\aujustemotcnv.zip
   ```
3. En SSH sur le VPS :
   ```bash
   cd /tmp/aujustemotcnv-paquet/deploiement && bash deployer-serveur.sh
   ```
   Le script copie les fichiers, installe le vhost **s'il n'existe pas**
   (il ne l'écrase jamais, pour préserver le HTTPS de certbot), valide la
   config, recharge nginx.
4. Active le HTTPS (première fois seulement) :
   ```bash
   sudo certbot --nginx -d justemotcnv.com -d www.justemotcnv.com
   ```
5. Vérifie : `curl -I https://justemotcnv.com` → `HTTP/2 200`.

Ensuite, active la CI (§1) et travaille par push sur `dev`.

---

## 5. Rollback

Le service worker versionné rend le retour arrière simple : redéployer un commit
antérieur (via `git revert`/`git checkout` puis push, ou relancer le workflow
sur un ancien SHA) réémet une version de cache et les clients reviennent à cet
état. Le webroot n'est pas historisé — **Git est la source de vérité**.

---

## 6. Dépannage

- **La CI échoue à l'étape SSH** → vérifier `VPS_SSH_KEY` (clé privée complète,
  y compris les lignes `BEGIN/END`), et que la publique est bien dans
  `authorized_keys` de `deploy`.
- **rsync : permission denied** → `setup-ci-vps.sh` n'a pas été lancé, ou le
  webroot n'appartient pas à `deploy`.
- **La mise à jour ne s'affiche pas chez un utilisateur** → vérifier que
  `const CACHE` a bien changé (regarder `sw.js` servi) ; forcer via le bandeau
  « Une nouvelle version est prête ».
- **certbot ne renouvelle plus** → un enregistrement DNS est probablement passé
  en « proxy » (orange) sur Cloudflare : le remettre en **gris**.
- **Smoke test rouge mais site OK** → l'`CHECK_URL` ne correspond pas à
  l'environnement déployé (préprod vs prod).
