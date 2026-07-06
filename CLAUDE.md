# CLAUDE.md — Constitution du projet « Au juste mot »

> Ce fichier est lu par Claude Code au début de chaque session. Il fixe le
> contexte, les valeurs et les garde-fous. En cas de doute, **demande avant
> d'agir** sur la production. Lis aussi `HANDOFF.md` pour l'état détaillé.

## 1. Mission

« Au juste mot — La CNV appliquée » est une application web / PWA de littératie
émotionnelle. Elle aide à **relier un mot-nuance émotionnel à sa famille de
sentiments et au besoin qu'il révèle**, dans le cadre de la Communication
NonViolente (CNV) de Marshall Rosenberg. Source du vocabulaire : la grille
« Liste de sentiments et besoins » de Dialogo (2022).

- **En ligne :** https://justemotcnv.com
- **Commanditaire / partenaire de contenu :** Tommy Welsh (ami de Fred, formé en
  CNV). C'est lui qui propose les évolutions de contenu ; Fred développe.
- **Propriétaire technique :** Fred (FMP InfoSolutions) — `Fred@fmpinfo.ca`.

## 2. Pour qui je travaille

- **Fred** : développeur, francophone québécois, MSP. Préférences permanentes :
  - Répondre **en français**.
  - **Raisonner en profondeur** ; traiter chaque demande comme complexe sauf
    indication contraire ; ne jamais sacrifier la qualité à la brièveté.
  - Tout script destiné à Fred doit être **compatible Windows PowerShell 5.1**
    (ASCII pur si possible ; éviter les dépendances exotiques).
  - Pour toute **estimation de temps**, donner **deux chiffres** : humain seul
    ET assisté par IA.
- **Tommy** : non-développeur. Il propose du contenu (mots, définitions,
  classements, idées de jeux). Son jugement CNV fait autorité sur le *contenu* ;
  il ne code pas.

## 3. Valeurs non négociables

Ces valeurs sont celles de Fred et doivent guider chaque décision :

1. **Anti-enshittification** : pas d'abonnement, pas de traçage, pas de pub, pas
   de dépendance à un service tiers qui pourrait « pourrir ». L'app est
   *same-origin*, sans ressource externe, sans analytics.
2. **Local-first & souveraineté** : tout tourne sur l'infra de Fred (VPS OVH).
   Les données de l'utilisateur (progression) restent **dans son navigateur**
   (`localStorage`) — rien n'est envoyé nulle part.
3. **Accessibilité** : police Atkinson Hyperlegible, contrastes soignés,
   **jamais de codage par la couleur seule** (pas de rouge/vert distinctif —
   daltonisme). Toujours doubler la couleur par une forme, une icône ou du texte.
4. **Ton doux** : sujet intime. Pas de gamification agressive (« monstres
   abattus »), pas d'infantilisation. Encouragement sobre.
5. **Rigueur du contenu CNV** : le contenu émotionnel est **subjectif et
   sensible**. Tout ajout ou reclassement doit pouvoir être **validé par une
   personne formée en CNV** (Tommy). Ne jamais inventer une couche non sourcée
   et la pousser en prod sans validation. Voir §7.

## 4. Stack & architecture (résumé)

- **Application** : un seul fichier autonome, `aujustemotcnv/index.html`
  (~900 lignes). Il contient **tout** : le HTML, le CSS (dans `<style>`), le
  JavaScript (dans un unique `<script>`), et **les données inline**.
- **Pas de build, pas de framework, pas de dépendances.** C'est voulu. On édite
  l'`index.html` directement.
- **PWA** : `sw.js` (service worker, cache offline), `manifest.webmanifest`,
  `icons/`. Données de référence : `donnees-emotions.json` (documentaire, voir §6).
- **Hébergement** : VPS OVH `deploy@192.99.68.47` (Ubuntu 24.04), **Nginx**,
  webroot **`/var/www/aujustemotcnv`**, HTTPS Let's Encrypt via `certbot --nginx`.
- **DNS** : Cloudflare (compte `Fred@fmpinfo.ca`), enregistrements en
  **« DNS only » (nuage GRIS)** — crucial pour le renouvellement certbot. NS
  Cloudflare déclarés chez RapideNet (registrar).

Détails complets : `docs/ARCHITECTURE.md`.

## 5. Workflow Git & déploiement

- **`dev`** : branche de travail. Chaque push **déploie automatiquement** via
  GitHub Actions (`.github/workflows/deploy-dev.yml`) — rsync de `aujustemotcnv/`
  vers le webroot. Voir `docs/DEPLOIEMENT.md`.
- **`main`** : à considérer comme la prod stable (voir la topologie recommandée
  à deux environnements dans `docs/DEPLOIEMENT.md` — fortement conseillée dès que
  du contenu non validé peut être poussé).
- **Versionnement du cache (IMPORTANT)** : le service worker met en cache
  l'app. Si sa version (`const CACHE = "ajm-…"`) ne change pas, **les clients
  installés ne voient jamais la mise à jour**. Le déploiement s'en occupe
  automatiquement :
  - en CI, la version devient `ajm-<sha-du-commit>` ;
  - en déploiement manuel, `ajm-<horodatage>`.
  → **Ne code jamais une version figée** dans `sw.js`. Laisse `ajm-dev` ; le
  déploiement la remplace.

## 6. Où vit le contenu

- **La vérité applicative** est **inline dans `index.html`**, dans trois objets :
  - `DATA` : familles de sentiments (comblés / non comblés), faux-sentiments,
    et catégories de besoins — chaque mot au **féminin** (source Dialogo).
  - `GENRE` : formes d'accord **pré-calculées** (masculin, neutre inclusif) pour
    chaque mot. C'est ce qui permet le sélecteur d'accord F / M / N.
  - `DEFS` : une définition courte par famille et par catégorie de besoin (le
    lien *sentiment → besoin*).
- `donnees-emotions.json` est une **copie documentaire** du contenu (avec les
  définitions). L'app **ne le lit pas** actuellement. Tiens-le à jour quand tu
  modifies `DATA`/`DEFS`, mais l'`index.html` fait foi.

## 7. Pièges connus (à ne pas réapprendre à la dure)

1. **Le moteur d'accord (Python) est PERDU.** Les formes de `GENRE` étaient
   générées par un `build.py` disparu lors d'une réinitialisation d'environnement.
   Conséquence : tant qu'on ajoute du **code** ou des **textes invariables**
   (définitions, libellés, règles de jeu), tout va bien. Mais **ajouter un
   nouveau mot de sentiment** exige son accord M/N. Deux voies :
   - reconstruire un moteur d'accord (idéalement en **JS**, pour qu'il tourne
     dans l'app et un futur éditeur) — chantier à part ;
   - ou saisir les 3 formes à la main pour chaque mot ajouté.
   **Ne feins pas d'avoir le moteur.** Signale-le.
2. **Contenu CNV subjectif.** Les « faux-sentiments » et tout futur classement
   (p. ex. intensité Léger/Modéré/Intense) sont discutables. Ils doivent passer
   par une validation humaine (Tommy) avant la prod. Le flux `dev` → revue →
   prod existe pour ça.
3. **DNS Cloudflare en gris.** Ne bascule jamais les enregistrements en
   « proxy » (nuage orange) sans réémettre les certificats : `certbot --nginx`
   échouerait au renouvellement.
4. **Le vhost préserve le HTTPS.** `deployer-serveur.sh` n'écrase pas le vhost
   s'il existe (sinon on perdrait le bloc 443 ajouté par certbot). Respecte ça.

## 8. Ce qu'il ne faut PAS faire

- Ajouter une dépendance externe (CDN, police distante, tracker, SaaS).
- Introduire un système d'abonnement ou de compte obligatoire.
- Coder par la couleur seule.
- Pousser en prod du contenu CNV non validé.
- Figer la version du service worker.
- Réécrire l'app en framework « parce que ce serait plus propre » — la
  simplicité mono-fichier est un choix, pas un accident. Discute avant.

## 9. Backlog (voir HANDOFF.md pour le détail)

- **Jeu d'intensité** (Léger / Modéré / Intense) — idée validée de Tommy. Option
  ciblée recommandée : ~6-8 familles à gradation consensuelle. Classement à
  faire valider.
- **Section d'édition** réservée à Fred + Tommy (voir `docs/EDITEUR-CONTENU.md`).
- Sourcer de **vraies statistiques CNV** vérifiables (ne pas réutiliser telles
  quelles celles de Tommy).
- **Échange de liens** avec cnvquebec.org / spiralis.ca (vérifier qu'ils sont
  actifs avant).
- **Bouton de don** discret (cadré « couvrir l'hébergement »), compte à préciser.
- Éventuel **axe énergie** (activation) comme seconde dimension explicite.
