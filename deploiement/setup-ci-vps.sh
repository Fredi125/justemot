#!/usr/bin/env bash
# =============================================================================
#  Préparation du VPS pour le déploiement continu (GitHub Actions → rsync).
#  À lancer UNE SEULE FOIS sur le VPS, après le premier déploiement manuel.
#
#  Ce que ça fait : rend le webroot inscriptible par l'utilisateur `deploy`
#  (pour que rsync fonctionne sans sudo), tout en le gardant lisible par nginx.
#  Ça ne touche à aucun autre site ni au vhost ni aux certificats.
#
#  Usage :
#      bash setup-ci-vps.sh
# =============================================================================
set -euo pipefail

APP="aujustemotcnv"
WEBROOT="/var/www/${APP}"
DEPLOY_USER="${SUDO_USER:-deploy}"   # l'utilisateur qui fera les rsync

echo "==> 1/2  Permissions du webroot pour rsync par '${DEPLOY_USER}'"
sudo mkdir -p "$WEBROOT"
# Propriétaire = deploy (écriture rsync) ; groupe = www-data (lecture nginx)
sudo chown -R "${DEPLOY_USER}:www-data" "$WEBROOT"
# setgid sur les dossiers : les nouveaux fichiers héritent du groupe www-data
sudo find "$WEBROOT" -type d -exec chmod 2755 {} \;
sudo find "$WEBROOT" -type f -exec chmod 644 {} \;
echo "    $(ls -ld "$WEBROOT")"

echo
echo "==> 2/2  Clé de déploiement (à faire côté machine + GitHub)"
cat <<'STEPS'
    1) Sur ta machine, génère une paire DÉDIÉE à la CI, SANS passphrase :
         ssh-keygen -t ed25519 -C "github-ci-aujustemot" -f aujustemot_ci

    2) Autorise la clé PUBLIQUE pour l'utilisateur de déploiement sur le VPS :
         cat aujustemot_ci.pub >> ~/.ssh/authorized_keys
         chmod 600 ~/.ssh/authorized_keys

    3) Dans le dépôt GitHub → Settings → Secrets and variables → Actions,
       crée les SECRETS suivants :
         VPS_HOST     = 192.99.68.47
         VPS_USER     = deploy
         VPS_SSH_KEY  = (contenu COMPLET du fichier privé aujustemot_ci)

    4) (Optionnel) pour une préproduction, crée la VARIABLE :
         DEPLOY_PATH  = /var/www/aujustemotcnv-dev
         CHECK_URL    = https://dev.justemotcnv.com/

    Durcissement recommandé : dans ~/.ssh/authorized_keys, préfixe la clé CI
    par des restrictions, p. ex. :
      restrict,command="rrsync /var/www/aujustemotcnv" ssh-ed25519 AAAA... github-ci
    (rrsync limite la clé au seul rsync vers ce dossier.)
STEPS

echo
echo "Terminé. La branche dev déploiera désormais automatiquement."
