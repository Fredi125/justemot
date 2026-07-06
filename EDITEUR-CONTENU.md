# Éditer l'application à distance — analyse et recommandation

Objectif exprimé : permettre de **modifier l'app sans passer par du code**, soit
via une interface, soit via une **tâche périodique Claude** qui va chercher les
suggestions en attente et les applique. **Accès réservé à Fred et Tommy.**

Ce document pose le problème, compare trois approches avec leurs compromis, et
recommande un chemin **par phases**. Rien ici n'est encore implémenté — c'est le
plan à valider.

---

## 1. Ce qu'on veut vraiment éditer (et qui)

Aujourd'hui, Tommy envoie ses suggestions par courriel ; Fred les transforme en
code. Ce qui change, dans les faits, c'est presque toujours du **contenu**, pas
du **code** :

| Type de modification | Fréquence | Demande le moteur d'accord ? |
|---|---|---|
| Corriger/écrire une **définition** de famille | fréquent | non |
| Classer des **triplets d'intensité** (Léger/Modéré/Intense) | à venir | non |
| Ajuster un **faux-sentiment** et sa traduction | occasionnel | non |
| Modifier un **texte d'interface** (consigne, encart) | occasionnel | non |
| Reclasser un mot dans une autre famille | rare | non |
| **Ajouter un mot de sentiment** | rare | **OUI** |

**Conclusion importante** : ~90 % des éditions de Tommy ne touchent **pas** aux
mots eux-mêmes, donc **ne dépendent pas du moteur d'accord perdu**. Seul l'ajout
de nouveaux mots l'exige — on le laisse hors de l'éditeur au début (ça reste un
acte « dev », le temps de reconstruire un moteur d'accord en JS).

---

## 2. Le préalable transverse : découpler le contenu du code

Aujourd'hui le contenu est **inline** dans `index.html` (`DATA`, `GENRE`,
`DEFS`). Pour qu'un éditeur ou une tâche automatisée modifie du contenu
proprement, il faut **sortir le contenu éditable** dans des fichiers **JSON
versionnés** que l'app charge au démarrage :

- `contenu/definitions.json`, `contenu/faux-sentiments.json`,
  `contenu/intensites.json`, `contenu/textes.json`.
- L'app les charge par `fetch`, avec **repli sur des valeurs inline** si le
  réseau échoue (robustesse offline), et le **service worker les met en cache**.
- Les **mots + accords** (`DATA`/`GENRE`) restent inline tant que le moteur
  d'accord n'est pas reconstruit — ils ne sont pas dans le périmètre d'édition.

C'est un petit chantier, mais c'est **le socle** des phases 2 et 3. Appelons-le
**Phase 0**.

---

## 3. Trois approches

### Approche A — File de suggestions + tâche périodique (ce que tu proposes)

Les suggestions arrivent dans un **canal** (issues GitHub étiquetées
`suggestion`, ou un fichier `INBOX/suggestions.md`, ou un petit formulaire web
qui crée l'issue). Une **tâche périodique** (Claude récurrent, ou Claude Code
lancé par une planification) lit les suggestions en attente, applique les
changements au contenu, et **ouvre une Pull Request sur `dev`**. Fred (ou Tommy)
**révise et fusionne** ; la CI déploie.

- **+** Git reste la source de vérité (historique, rollback, revue **intégrée**).
- **+** Human-in-the-loop **natif** : la PR est le point de validation — parfait
  pour du contenu CNV subjectif.
- **+** Peu de code : surtout de la config, un gabarit d'issue/PR, éventuellement
  un mini-formulaire.
- **+** Exploite directement la fonctionnalité de tâches périodiques.
- **−** Tommy doit passer par GitHub (issues) — friction s'il n'aime pas ;
  atténuée par un formulaire web simple.
- **−** Dépend de l'accès de la tâche à GitHub (connecteur MCP GitHub, ou `gh`
  CLI dans l'environnement planifié) — à confirmer selon l'outil.
- **−** Traitement **par lots** (à intervalle), pas instantané — acceptable ici.

### Approche B — Back-office statique + commit via l'API GitHub

Une page protégée (`admin.html`, non liée depuis l'app publique) avec des
**formulaires** (éditer les définitions, classer les triplets d'intensité,
ajuster les faux-sentiments). À l'enregistrement, la page **commit le JSON via
l'API GitHub** (sur une PR vers `dev`). CI déploie.

- **+** UI conviviale pour Tommy, sans voir GitHub.
- **+** Reste **statique** (pas de backend permanent) — aligné avec les valeurs.
- **+** Git reste la source de vérité.
- **−** Vrai développement (formulaires, validation, appels API).
- **−** Authentification : **OAuth GitHub** restreint à 2 comptes (setup d'une
  OAuth App) — ou un jeton personnel par personne, moins ergonomique et à
  cadrer (scope minimal, repo unique) car il vit dans le navigateur.

### Approche C — Backend sur le VPS

Un mini-service authentifié sur le VPS édite le JSON et redéploie.

- **−** Introduit un **backend permanent** à sécuriser, maintenir, mettre à jour,
  pour **deux** utilisateurs — disproportionné et **contraire** à la philosophie
  « statique, same-origin, sans dépendance ».
- **−** Risque de **divergence** entre l'état serveur et le repo.
- **−** Nouvelle surface d'attaque exposée.
- **Verdict : à éviter**, sauf besoin futur d'édition temps réel sans Git.

---

## 4. Recommandation : par phases

> Fil rouge non négociable : **tout contenu passe par `dev` et une revue humaine
> avant la prod.** Le contenu CNV est subjectif ; il ne doit pas atteindre les
> utilisateurs sans validation (idéalement de Tommy).

**Phase 1 — Minimal, tout de suite (Approche A légère).**
Activer les **issues GitHub** avec un gabarit « suggestion », ou tenir un
`INBOX/suggestions.md`. Quand tu veux traiter le lot, tu lances Claude Code avec
la consigne : « lis les suggestions en attente, applique-les au contenu, ouvre
une PR sur `dev` ». Tu révises, tu fusionnes, la CI déploie. Coût quasi nul,
bénéfice immédiat : le flux est structuré et tracé.

**Phase 0 — Externaliser le contenu éditable** (préalable aux phases suivantes,
à faire quand on veut aller plus loin que Phase 1).

**Phase 2 — Automatiser l'entrée (Approche A complète).**
Un **formulaire web protégé** (page non indexée, OAuth GitHub restreint à
vous deux) où Tommy dépose une suggestion → crée une issue. Une **tâche
périodique** traite les nouvelles issues → PR sur `dev`. Tu gardes la main sur le
merge.

**Phase 3 — Édition assistée par UI (Approche B), seulement si le besoin se
confirme.** Back-office `admin.html` avec OAuth GitHub (2 comptes), formulaires
d'édition du contenu, commit → PR sur `dev`.

---

## 5. Le flux recommandé (schéma)

```
  Tommy / Fred
      │  (courriel → issue, ou formulaire, ou INBOX/suggestions.md)
      ▼
  Suggestions en attente  ──►  Tâche périodique (Claude)
                                   │  applique au contenu (JSON)
                                   ▼
                          Pull Request sur `dev`
                                   │
                       Revue humaine (Fred, idéalement Tommy)  ◄── point de contrôle CNV
                                   │  merge
                                   ▼
                       CI déploie sur PRÉPROD (dev.justemotcnv.com)
                                   │  test à deux
                                   ▼
                        PR `dev → main` (merge validé)
                                   │
                                   ▼
                       CI déploie en PROD (justemotcnv.com)
```

(La distinction préprod/prod suppose la topologie à deux environnements de
`docs/DEPLOIEMENT.md` §3 — vivement conseillée dès qu'une automatisation peut
produire du contenu.)

---

## 6. Accès réservé à Fred + Tommy

Le plus simple **et** le plus robuste : un **dépôt GitHub privé avec exactement
deux collaborateurs**. Toute la chaîne (issues, PR, merge) hérite de ce contrôle
d'accès — **aucune authentification maison à écrire**.

- Formulaire (Phase 2) ou back-office (Phase 3) : **OAuth GitHub** vérifiant que
  le compte connecté est l'un des deux. Éviter les mots de passe partagés.
- La branche `main` (prod) devrait exiger une **revue de PR** avant merge, pour
  qu'aucune contribution ne parte seule en prod.

---

## 7. Sur la « tâche périodique Claude »

Le flux ci-dessus est agnostique au mécanisme exact, car il dépend de l'outil
et de son état courant. Deux implémentations réalistes :

1. **Tâche récurrente Claude** avec un **connecteur GitHub (MCP)** autorisé sur
   le dépôt : elle lit les issues `suggestion`, applique, ouvre la PR.
2. **Claude Code planifié côté Fred** (Planificateur de tâches Windows, ou cron
   sur le VPS) avec le `gh` CLI authentifié : même résultat, entièrement sous
   ton contrôle et sur ton infra — ce qui colle à tes valeurs de souveraineté.

Dans les deux cas, **la tâche ne fait qu'ouvrir une PR** — jamais de merge
automatique en prod. La valeur ajoutée de l'automatisation est de **préparer** le
travail ; la décision reste humaine.

---

## 8. Estimations (humain seul / assisté IA)

| Phase | Contenu | Humain seul | Assisté IA |
|---|---|---|---|
| **1** | File de suggestions + gabarit + flux Claude Code manuel | 2–4 h | 30–45 min |
| **0** | Externaliser le contenu éditable en JSON (fetch + cache SW + repli) | 6–10 h | 1–2 h |
| **2** | Formulaire web protégé (OAuth) → issue + tâche périodique → PR | 10–20 h | 2–4 h |
| **3** | Back-office `admin.html` (OAuth) + formulaires d'édition | 25–50 h | 6–12 h |
| — | Reconstruire un **moteur d'accord en JS** (pour éditer/ajouter des mots) | 8–16 h | 2–4 h |

**Mon conseil** : Phase 1 immédiatement (structure le flux pour presque rien),
puis Phase 0 + Phase 2 quand tu veux ouvrir la porte à Tommy sans toi. La Phase 3
seulement si une vraie UI d'édition devient nécessaire. Le moteur d'accord JS est
un chantier indépendant, à faire le jour où ajouter des mots depuis l'éditeur
devient un besoin réel.
