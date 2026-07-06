# HANDOFF — « Au juste mot — La CNV appliquée »

Document de reprise pour toute personne (ou instance Claude Code) qui prend le
projet en main. Il complète `CLAUDE.md` (les règles) par le **récit** : où on en
est, pourquoi les choses sont comme elles sont, et ce qui reste à faire.

Dernière mise à jour : passage à un dépôt Git dédié avec CI/CD.

---

## 1. Résumé exécutif

« Au juste mot » est une **PWA de littératie émotionnelle** en français
québécois, en ligne sur **https://justemotcnv.com**, développée par Fred (FMP
InfoSolutions) pour son ami **Tommy Welsh**, formé en CNV. Elle apprend à
**nommer finement un ressenti** et à **relier ce ressenti au besoin qu'il
signale**, selon la Communication NonViolente.

L'app est **complète et fonctionnelle**. Elle vient de recevoir quatre
améliorations majeures (clarification sentiments/besoins, définitions par
famille, jeu des besoins, suivi de progression). Le présent dépôt marque le
passage d'un flux « zip + script » à un flux **Git + déploiement continu**.

Techniquement, c'est un **unique `index.html` autonome** (HTML + CSS + JS +
données inline), servi en statique par Nginx. Pas de build, pas de framework,
pas de dépendances externes — un choix assumé (voir §4).

---

## 2. Le produit : ce qu'il fait

Quatre modes, accessibles par onglets, plus un sélecteur d'accord grammatical
**Féminin / Masculin / Neutre** (le vocabulaire source est au féminin ; les
formes masculine et neutre inclusive sont pré-calculées).

- **Explorer** — parcourir le vocabulaire. Deux mondes séparés visuellement :
  les **Sentiments** (familles quand un besoin est comblé / non comblé) et les
  **Besoins** (6 catégories). Recherche par mot, filtres, **définition par
  famille**, **fiches de besoins cliquables**, un **encart pédagogique** qui
  distingue sentiment et besoin, et une **carte de progression**.
- **Associer** — jeu. Une **bascule Sentiments / Besoins** :
  - *Sentiments* : on montre un mot, on devine sa **famille** (ex. *égayé →
    Joie*).
  - *Besoins* : on montre un besoin, on devine sa **famille de besoins** (ex.
    *Liberté → Autonomie*). Comme un besoin peut appartenir à plusieurs
    familles, **toute réponse juste est acceptée**.
- **Me situer** — parcours guidé : valence → famille → mot → courte réflexion.
- **Vrai/faux** — distinguer un **vrai sentiment** d'un **jugement déguisé**
  (« faux-sentiment » : *ignoré*, *rejeté*, *trahi*…). Sur un faux, l'app en
  propose la **traduction CNV** (un vrai sentiment + un besoin).

**Suivi de progression** : deux barres (Sentiments, Besoins) qui se remplissent
au fil des bonnes réponses. **100 % local** (`localStorage`) — rien n'est
partagé ni envoyé.

---

## 3. Décisions de design majeures (et pourquoi)

> À lire absolument avant de « simplifier » le contenu : plusieurs choix qui
> pourraient sembler perfectibles sont en fait **fondés sur la recherche** et
> délibérés.

### 3.1 On garde la richesse (16 familles), on ne réduit PAS aux 6 émotions de base

Tommy a proposé de réorganiser l'app autour des « six émotions de base ».
Décision : **non**, et c'est étayé.

- Le modèle des 6 émotions de base (Ekman) est **contesté depuis plus de 20
  ans** ; le cadre concurrent le plus actif (théorie de l'émotion construite,
  Barrett) repose sur un espace **valence × activation** et sur la **granularité
  émotionnelle**.
- La **granularité émotionnelle** — savoir distinguer finement ses états — est
  associée à une **meilleure régulation** et à **moins de comportements à
  risque** (alcool, agression, automutilation), et **apprendre des concepts
  émotionnels l'augmente durablement**. C'est *exactement* la mission de l'app.
- Réduire à 6 catégories **écraserait** cette granularité (Joie, Vitalité,
  Émerveillement fusionneraient) — donc irait **contre** l'objectif
  thérapeutique.
- L'acte central — **mettre un mot sur un ressenti** — est lui-même une forme de
  régulation (*affect labeling* : baisse mesurable de la réponse de l'amygdale).

**Formulation à garder pour Tommy** : les 16 familles ne *contredisent* pas ses
grandes émotions, elles les *nuancent*. On respecte l'esprit de sa carte en la
rendant plus fine.

### 3.2 Séparer sentiments et besoins

C'était la meilleure intuition de Tommy. Un **sentiment** est un *signal* ; un
**besoin** est le *levier* d'action. Les mélanger brouille les deux. D'où : deux
mondes distincts dans l'Explorer, un jeu dédié aux besoins, un encart
« Sentiment ou besoin ? ».

### 3.3 Définitions **par famille**, pas par mot

Ce qui aide, c'est le **lien ressenti → besoin**, pas une glose de dictionnaire.
Chaque famille (16) et catégorie de besoin (6) porte une définition courte de ce
type. Un mot hérite de la définition de sa famille principale.

### 3.4 Suivi **sobre**, jamais de « monstres abattus »

La gamification RPG proposée par Tommy a été retenue **dans l'idée** (le feedback
motive, la répétition ancre le vocabulaire) mais **pas dans le costume** :
« Ton vocabulaire s'enrichit », deux barres discrètes, rien d'agressif.

### 3.5 Idée validée à implémenter — le jeu d'intensité

Tommy propose un jeu « Léger / Modéré / Intense » (*agacé < fâché < furieux*).
**C'est une bonne idée** : distinguer des degrés dans une même famille, c'est
affiner la granularité — le cœur de l'app. Meilleure, pour un jeu, que l'« axe
énergie » abstrait envisagé auparavant. **Seul obstacle** : classer les ~600
mots est subjectif et non sourcé par Dialogo → à faire **valider**. Voir le
backlog (§6) pour l'option ciblée recommandée.

---

## 4. Architecture (résumé — détail dans `docs/ARCHITECTURE.md`)

- **`aujustemotcnv/index.html`** : tout le produit. Trois objets de données
  inline :
  - `DATA` — familles (sentiments comblés / non comblés), faux-sentiments,
    catégories de besoins ; mots au **féminin**.
  - `GENRE` — accords **pré-calculés** (masculin, neutre inclusif).
  - `DEFS` — définitions par famille et par catégorie de besoin.
- **PWA** : `sw.js`, `manifest.webmanifest`, `icons/`.
- **`donnees-emotions.json`** : copie **documentaire** du contenu (l'app ne le
  lit pas ; le tenir à jour quand on modifie `DATA`/`DEFS`).
- **Pourquoi mono-fichier** : simplicité radicale, zéro dépendance, offline
  trivial, longévité. C'est un **choix** aligné avec les valeurs du projet, pas
  une dette. Ne pas « moderniser » sans discuter.

---

## 5. Infrastructure & déploiement (détail dans `docs/DEPLOIEMENT.md`)

- VPS OVH `deploy@192.99.68.47` (Ubuntu 24.04), **Nginx**, webroot
  **`/var/www/aujustemotcnv`**, HTTPS Let's Encrypt (`certbot --nginx`).
- DNS **Cloudflare** en **« DNS only » (gris)** ; NS chez RapideNet.
- **CI/CD** : push sur **`dev`** → GitHub Actions rsync vers le webroot, avec
  **versionnement automatique du service worker** (cache = SHA du commit).
- Le **vhost** (`deploiement/aujustemotcnv.conf`) gère : SPA fallback,
  `no-cache` sur `sw.js` / `index.html` / manifest / JSON, cache long sur les
  icônes, gzip, en-têtes de sécurité.

---

## 6. Backlog (par ordre de valeur)

1. **Jeu d'intensité (Léger / Modéré / Intense).** Idée validée de Tommy.
   Recommandation : **commencer ciblé** sur ~6-8 familles à gradation
   consensuelle (ex. Colère : *agacé · fâché · furieux* ; Peur : *inquiet ·
   anxieux · terrifié* ; Joie : *content · joyeux · radieux* ; Tristesse :
   *déçu · malheureux · désespéré* ; Fatigue : *las · fatigué · épuisé* ;
   Vitalité : *animé · énergique · survolté*). Faire **valider les triplets par
   Tommy avant de coder**. Le classement des ~600 mots (option complète) ne se
   fait qu'après validation de la méthode.
2. **Section d'édition réservée à Fred + Tommy.** Design complet dans
   `docs/EDITEUR-CONTENU.md`. Recommandation : commencer par une file de
   suggestions + revue humaine sur `dev`, avant toute UI d'édition.
3. **Vraies statistiques CNV.** Celles avancées par Tommy (« CNV dans 35+ pays »,
   « 75 % des participants ») ne sont **pas vérifiées** — ne pas les publier
   telles quelles, surtout face à cnvquebec / spiralis. Sourcer des chiffres
   fiables si on en veut.
4. **Échange de liens** avec cnvquebec.org et spiralis.ca (preuve de sérieux) —
   **vérifier que les sites sont actifs** avant, et arriver avec notre lien déjà
   en place (section « Pour se former »).
5. **Bouton de don** discret, cadré « couvrir l'hébergement » (pas
   « rentabiliser ») — reste à décider quel compte (Fred ou FMP).
6. **Axe énergie (activation)** comme seconde dimension explicite du circumplex —
   optionnel, cap de fond ; le jeu d'intensité le rend moins prioritaire.

---

## 7. Pièges connus

Voir `CLAUDE.md` §7 — en une ligne : **le moteur d'accord Python est perdu**
(ajouter un mot de sentiment demande ses formes M/N) ; **le contenu CNV est
subjectif** (validation avant prod) ; **DNS Cloudflare en gris** (sinon certbot
casse) ; **ne pas figer la version du service worker**.

---

## 8. Comment démarrer

1. Cloner le dépôt, créer la branche `dev`.
2. Lire `CLAUDE.md`, puis `docs/ARCHITECTURE.md` et `docs/DEPLOIEMENT.md`.
3. Configurer la CI (secrets GitHub + `deploiement/setup-ci-vps.sh` sur le VPS) —
   voir `docs/DEPLOIEMENT.md`.
4. Servir l'app en local pour tester : `aujustemotcnv/serve.ps1` (ou n'importe
   quel serveur statique ; l'ouvrir en `file://` fonctionne aussi, le service
   worker échoue alors silencieusement, c'est prévu).
5. Toute modification : éditer `aujustemotcnv/index.html`. Après une modif du JS,
   **vérifier la syntaxe** (extraire le `<script>` et `node --check`) avant de
   pousser — l'app est en production.

---

## 9. Contacts

- **Fred** (technique, décisions) : `Fred@fmpinfo.ca`.
- **Tommy Welsh** (contenu CNV) : via Fred.
