#!/usr/bin/env bash
# =============================================================================
#  Déploiement de « Au juste mot — La CNV appliquée » sur le VPS.
#  Idempotent et non destructif : n'ajoute qu'un vhost dédié, ne touche à
#  AUCUN autre site. Valide la configuration nginx AVANT tout rechargement.
#
#  Usage (depuis le dossier deploiement/ extrait du zip) :
#      bash deployer-serveur.sh
# =============================================================================
set -euo pipefail

APP="aujustemotcnv"
DOMAIN="justemotcnv.com"
WEBROOT="/var/www/${APP}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SRC="${SCRIPT_DIR}/../${APP}"
VHOST_SRC="${SCRIPT_DIR}/${APP}.conf"

echo "==> 1/5  Vérifications préalables"
[ -d "$APP_SRC" ]   || { echo "ERREUR : dossier application introuvable : $APP_SRC"; exit 1; }
[ -f "$VHOST_SRC" ] || { echo "ERREUR : vhost introuvable : $VHOST_SRC"; exit 1; }
command -v nginx >/dev/null 2>&1 || { echo "ERREUR : nginx introuvable"; exit 1; }
[ -f "${APP_SRC}/index.html" ] || { echo "ERREUR : index.html manquant dans $APP_SRC"; exit 1; }

echo "==> 2/5  Copie des fichiers vers ${WEBROOT}"
sudo mkdir -p "$WEBROOT"
# -T : copie le CONTENU de APP_SRC dans WEBROOT (et non un sous-dossier)
sudo cp -rT "$APP_SRC" "$WEBROOT"
# permissions en lecture seule pour le serveur (root:root, lisible par tous)
sudo find "$WEBROOT" -type d -exec chmod 755 {} \;
sudo find "$WEBROOT" -type f -exec chmod 644 {} \;
echo "    $(find "$APP_SRC" -type f | wc -l) fichiers déployés."

echo "==> 3/5  Installation du vhost (seulement s'il n'existe pas deja)"
VHOST_DEST="/etc/nginx/sites-available/${APP}.conf"
if [ -f "$VHOST_DEST" ]; then
    echo "    Vhost deja present : conserve tel quel."
    echo "    (On ne l'ecrase PAS, pour preserver le bloc HTTPS ajoute par certbot.)"
    echo "    Pour forcer une reinstallation propre : sudo rm $VHOST_DEST, relancer ce script, puis refaire certbot."
else
    sudo cp "$VHOST_SRC" "$VHOST_DEST"
    sudo ln -sfn "$VHOST_DEST" "/etc/nginx/sites-enabled/${APP}.conf"
    echo "    Vhost installe (HTTP). Active ensuite le HTTPS avec certbot (voir plus bas)."
fi

echo "==> 4/5  Validation de la configuration nginx (filet de sécurité)"
# En cas d'erreur ici, set -e interrompt AVANT le reload : les autres sites
# ne sont jamais perturbés.
sudo nginx -t

echo "==> 5/5  Rechargement de nginx"
sudo systemctl reload nginx

echo
echo "----------------------------------------------------------------------"
echo "  Fichiers servis depuis ${WEBROOT}"
echo "  En HTTP : http://${DOMAIN}  (le DNS doit déjà pointer vers ce VPS)"
echo
echo "  DERNIÈRE ÉTAPE — activer le HTTPS via Let's Encrypt :"
echo "      sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
echo
echo "  Puis vérifier :"
echo "      curl -I https://${DOMAIN}"
echo "----------------------------------------------------------------------"
