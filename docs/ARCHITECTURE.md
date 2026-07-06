# Architecture technique

Tout le produit tient dans **`aujustemotcnv/index.html`**. Ce document décrit sa
structure interne pour s'y repérer sans tout relire. (Les numéros de ligne ne
sont pas donnés : ils bougent. On se repère par **noms de fonctions et
d'objets**, stables.)

## 1. Anatomie du fichier

`index.html` a trois zones :

1. **`<head>` + `<style>`** — métadonnées PWA, polices (Atkinson Hyperlegible,
   Fraunces pour les titres), et **tout le CSS** (variables de thème + classes).
2. **`<body>`** — le HTML statique : barre d'onglets, sélecteur d'accord, les
   quatre panneaux (`#p-explorer`, `#p-associer`, `#p-situer`, `#p-demeler`), le
   pied de page.
3. **`<script>`** (un seul) — les **données inline**, puis toute la logique.

## 2. Données (inline dans le `<script>`)

### `DATA`
JSON valide décrivant tout le corpus :
```
{
  meta: {...},
  sentiments: {
    besoins_satisfaits:   [ {id, label, mots:[…au féminin]}, … ],   // 8 familles
    besoins_insatisfaits: [ {id, label, mots:[…]}, … ]              // 8 familles
  },
  faux_sentiments: { note, mots:[…] },                              // jugements déguisés
  besoins: [ {id, label, mots:[…]}, … ]                            // 6 catégories
}
```
- Les 8 familles « comblées » : `joie, vitalite, engage, tranquillite,
  affection, gratitude, emerveillement, confiance`.
- Les 8 « non comblées » : `triste, peur, colere, confuse, deconnectee,
  degoutee, fatiguee, surprise`.
- Les 6 besoins : `survie, relationnel, integrite, expression, autonomie,
  celebration`. (Les besoins sont des noms **invariables** — pas d'accord.)

### `GENRE`
Table d'accord **pré-calculée** : `{ "amusée": {m:"amusé", n:"amusé·e"}, … }`.
La fonction `disp(mot)` s'en sert pour afficher la bonne forme selon le sélecteur
F / M / N. **Ajouter un mot de sentiment = ajouter son entrée ici** (voir le
piège « moteur d'accord perdu » dans `CLAUDE.md`).

### `DEFS`
`{ id_de_famille_ou_de_besoin: "définition courte", … }` — 16 + 6 = 22 entrées.
Formulées comme le lien **sentiment → besoin**.

## 3. Variables dérivées (construites au chargement)

- `FAMILIES` — toutes les familles de sentiments (comblées + non comblées).
- `FAM_SAT`, `FAM_INSAT` — les deux sous-groupes.
- `BESOINS` — les 6 catégories de besoins.
- `wordIndex` — `mot_de_sentiment → [familles auxquelles il appartient]` (un mot
  peut appartenir à plusieurs familles → « multi »).
- `needCats` — `besoin → [catégories de besoins]` (un besoin peut appartenir à
  plusieurs catégories ; d'où « toute réponse juste est acceptée » dans le jeu).
- `NEED_WORDS` — la liste des besoins distincts.
- `VAL` — couleurs / classes / libellés par **valence** (`sat`, `insat`,
  `besoin`, `faux`).
- `FAUX`, `FAUX_MOTS` — faux-sentiments et leurs traductions CNV.
- `SENT_TOTAL`, `NEED_TOTAL` — totaux pour les barres de progression.

## 4. Fonctions par domaine

### Affichage & accord
- `disp(mot)` — applique l'accord (via `GENRE`) selon le réglage courant.
- `setGenre(g)` — change F / M / N et rafraîchit.
- `refresh()` — re-rend la vue courante après un changement d'accord (Explorer,
  Associer, Me situer).
- `speak(mot)` — synthèse vocale (Web Speech API).
- `el(html)`, `esc(txt)` — utilitaires DOM / échappement.

### Explorer
- `renderFamilies()` — grille des familles ; en mode « Tout », insère les
  **en-têtes de section** « Sentiments » / « Besoins » (fonction `head()`).
- `setFilter(v)` — filtres (tout / comblés / non comblés / besoins / à traduire).
- `onSearch(q)` — recherche par mot.
- `openFamily(valence, id)` — vue d'une famille : affiche `DEFS[id]`, puis les
  mots. Pour une catégorie de besoins, les mots sont **cliquables** vers
  `openNeed`.
- `openWord(mot)` — fiche d'un mot de sentiment : familles pointées + définition
  de la famille principale.
- `openNeed(nom, catId)` — fiche d'un besoin : sa/ses familles, la définition de
  la catégorie, et le rappel comblé/non comblé.
- `openFauxList()`, `openFaux(mot)` — liste et fiche des faux-sentiments.
- `backHome()` — retour à la grille.

### Associer (jeu à bascule)
- `setAssoc(k)` — bascule `"sentiments"` / `"besoins"` ; réinitialise le tour et
  met à jour libellés/consignes. Réutilise les mêmes éléments DOM (`#gameWord`,
  `#gameOpts`, `#gameFeedback`, `#gameNext`, `#score`).
- *Sentiments* : `nextRound()`, `renderGame()`, `answer(id)`, `updateScore()`.
- *Besoins* : `needRound()`, `needRender()`, `needAnswer(id)`.
- Les deux appellent `markLearned(...)` en cas de bonne réponse.

### Me situer
- `situerStart()`, `situerRender()`, `situerValence()`, `situerFamily()`,
  `situerPick()`, `situerReflect()` — parcours guidé pas à pas.

### Vrai/faux
- `demNext()`, `demRender()`, `demTrad()`, `demAnswer(choice)`, `demScore()` —
  tire 50 % vrai sentiment / 50 % faux ; sur un faux bien identifié, affiche la
  traduction CNV. Un vrai sentiment bien identifié compte dans la progression.

### Progression (local)
- `PROG = { sent:{…}, need:{…} }` — ensembles de mots « appris ».
- `loadProg()` / `saveProg()` — lecture/écriture `localStorage` (clé
  `ajm_prog`).
- `markLearned(kind, key)` — ajoute et rafraîchit.
- `renderProgress()` — la carte `#progressCard` (2 barres). N'apparaît qu'après
  la première bonne réponse.

### PWA (IIFE en fin de script)
- Invite d'installation (Android/Chrome/Edge), astuce iOS/Safari.
- Enregistrement du **service worker**, détection de mise à jour → bandeau
  « Une nouvelle version est prête » → `skip-waiting` → rechargement.
- Indicateur hors-ligne.

## 5. CSS : conventions

Variables de thème (dans `:root`) — thème papier crème/encre :
- `--paper`, `--paper-2`, `--ink`, `--ink-soft`, `--line`.
- Par **valence** : `--sat` (ocre, comblé), `--insat` (bleu-gris, non comblé),
  `--besoin` (vert), `--faux` (terre cuite) — chacune avec `-bg` et `-ink`.

Classes réutilisables utiles : `.card`, `.seg` (segment/bascule — réutilisé pour
l'accord ET pour Sentiments/Besoins), `.fam` / `.families`, `.belongs .b` (liens
cliquables), `.insight` (encadré), `.opt` (choix de jeu, avec `.good`/`.bad`/
`.dim`), `.pill`, `.famhead`, `.famdef`, `.primer`, `.prog*` (barres).

**Règle d'accessibilité** : ne jamais distinguer une information par la seule
couleur. Toujours doubler (forme, icône, texte, position).

## 6. Service worker (`sw.js`)

- `const CACHE = "ajm-…"` — **version du cache**. Doit changer à chaque
  déploiement (le déploiement s'en charge : SHA en CI, horodatage en manuel).
  Committé à `ajm-dev`.
- Stratégie : *cache-first* sur la coquille (`SHELL`), revalidation réseau ; les
  polices ont leur propre cache (`FONTS`).
- Le vhost force `no-cache` sur `sw.js` et `index.html` pour que les mises à jour
  se propagent vite.

## 7. Tester une modification

1. Éditer `aujustemotcnv/index.html`.
2. Vérifier le JS : extraire le `<script>` principal et lancer `node --check`
   dessus (l'app est en prod — ne pas casser la syntaxe).
3. Vérifier que tout élément DOM référencé par une nouvelle fonction existe
   (`id="…"`).
4. Servir en local (`serve.ps1`) et tester le parcours.
5. Pousser sur `dev` → la CI déploie et fait un smoke test.
