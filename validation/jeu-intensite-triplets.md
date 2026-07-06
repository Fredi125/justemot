# Jeu d'intensité — proposition de triplets (à valider par Tommy)

> **Statut : PROPOSITION.** Rien ici n'est en production. Le classement en
> intensité est **subjectif** et **non sourcé par Dialogo** ; il doit être
> **validé par Tommy** (jugement CNV) avant d'être câblé dans l'app. C'est
> exactement le point de contrôle prévu par `CLAUDE.md` §3.5 et §5.
>
> Données structurées correspondantes : `validation/intensites-proposees.json`.

---

## 1. L'idée (rappel)

Ajouter un mode de jeu qui distingue **des degrés d'intensité à l'intérieur d'une
même famille** : *agacé < fâché < furieux*. C'est une idée validée de Tommy
(HANDOFF §3.5) et elle sert directement la mission : distinguer finement ses
états, c'est **augmenter la granularité émotionnelle** — le cœur de l'app.

Choix assumé, conforme au backlog (HANDOFF §6, item 1) : **on commence ciblé**
sur quelques familles à gradation consensuelle, **pas** sur les ~600 mots (ce
classement complet ne se fait qu'après validation de la méthode).

---

## 2. Ce que Tommy doit valider

Pour chaque famille ci-dessous : **le triplet est-il juste ?** Sinon, quel mot
mettre à la place ? La colonne « autres candidats » liste des mots **déjà
présents dans la famille** (dans l'app) parmi lesquels choisir — inutile d'en
inventer de nouveaux (un mot neuf demanderait son accord M/N, chantier à part).

Tous les mots ci-dessous sont donnés **au féminin** (la source Dialogo l'est) ;
l'app applique automatiquement l'accord M / N via le sélecteur existant.

### Groupe A — haute confiance (gradation consensuelle)

| Famille | Léger | Modéré | Intense | Autres candidats (déjà dans la famille) |
|---|---|---|---|---|
| **Colère** | agacée | fâchée | furieuse | léger : titillée, contrariée, irritée · modéré : énervée, exaspérée · intense : excédée, outrée, révoltée |
| **Peur** | inquiète | anxieuse | terrifiée | léger : soucieuse, préoccupée · modéré : nerveuse, apeurée, effrayée · intense : épouvantée, horrifiée, paniquée |
| **Joie** | contente | joyeuse | radieuse | léger : gaie, amusée · modéré : ravie, enchantée, réjouie · intense : rayonnante, hilare |
| **Triste** | déçue | malheureuse | désespérée | léger : peinée, désappointée · modéré : attristée, chagrinée, découragée · intense : abattue, accablée, en détresse |
| **Fatiguée** | lasse | fatiguée | épuisée | léger : ramollie, endormie · modéré : surmenée, saturée, dépassée · intense : crevée, vidée, au bout du rouleau |
| **Vitalité** | animée | énergique | survoltée | léger : éveillée, vive · modéré : enthousiaste, vibrante · intense : exaltée, surexcitée, exubérante |

### Groupe B — à discuter (gradation plausible mais moins évidente)

| Famille | Léger | Modéré | Intense | Remarque |
|---|---|---|---|---|
| **Émerveillement** | impressionnée | émerveillée | subjuguée | « impressionnée » est aussi dans *Surprise*. Gradation moins nette. |
| **Confuse** | hésitante | déroutée | désemparée | La confusion se gradue-t-elle en *intensité* ou en *degré de perte de repères* ? |

### Points d'attention à trancher

1. **Mots multi-familles.** *survoltée* est à la fois dans Vitalité **et** Colère ;
   *impressionnée* dans Émerveillement **et** Surprise. Acceptable si on affiche
   toujours la famille en contexte (« Colère : … »), mais à confirmer.
2. **Groupe B :** on garde 6 familles (A seul) pour une v1 sobre, ou on inclut
   les 8 ? Recommandation : **v1 = groupe A uniquement**, on ajoute B plus tard.
3. **Échelle à 3 niveaux** (Léger / Modéré / Intense) : suffisante, ou faut-il
   un cran de plus quelque part ? (Rester à 3 est plus lisible.)

---

## 3. Comment Tommy répond (au choix)

- **Le plus simple :** annoter ce tableau (par courriel à Fred) — « Colère
  modéré : mettre *exaspérée* plutôt que *fâchée* », etc.
- **Ou** modifier directement `validation/intensites-proposees.json` (les champs
  `triplet.leger / modere / intense`) et le renvoyer.

Une fois validé, Fred (ou Claude Code) passe le `statut` du JSON à « VALIDÉ »,
câble le mode de jeu (§4), teste sur `dev`, et ce n'est **qu'après** que ça part
en prod.

---

## 4. Conception du jeu (spéc technique — pour l'implémentation, après validation)

> Rien de ceci n'est encore dans `index.html`. C'est la spéc turnkey pour câbler
> vite le jour où les triplets sont validés.

### 4.1 Mécanique retenue : « devine le degré »

On montre **un mot**, avec sa **famille en contexte**, et trois choix :
**Léger · Modéré · Intense**. Bonne réponse = le degré du mot dans son triplet.

C'est le **même patron** que le jeu *Associer* (un mot + trois options), donc
réutilisation maximale du DOM et du style existants (`#gameWord`, `#gameOpts`,
`#gameFeedback`, `#gameNext`, `.opt`, `.good/.bad`). Variante v2 possible :
« ordonne les 3 mots » (demande un nouveau DOM — à faire plus tard).

### 4.2 Intégration : 3ᵉ segment dans *Associer*

Le mode *Associer* a déjà une bascule `Sentiments / Besoins` (fonction
`setAssoc`). On ajoute un **3ᵉ segment `Intensité`**, sur le modèle exact des deux
autres. Aucune nouvelle dépendance, pas de nouvel onglet.

### 4.3 Accord grammatical — zéro dépendance au moteur perdu

`disp(canon)` renvoie le féminin tel quel, sinon l'accord M/N via `GENRE`, sinon
repli sur le féminin (correct pour les mots épicènes comme *énergique*). **Tous
les mots des triplets sont déjà couverts** → l'affichage F/M/N fonctionne sans
rien reconstruire.

### 4.4 Données à ajouter dans `index.html` (une fois validées)

Un petit objet inline, à côté de `DATA` / `DEFS` (garder aussi le JSON de
`validation/` à jour, comme pour `donnees-emotions.json`) :

```js
// Triplets d'intensité — VALIDÉS par Tommy le AAAA-MM-JJ. Mots au féminin,
// affichés via disp() (accord F/M/N). Ne pas ajouter de famille sans validation.
const INTENSITE = [
  { id:"colere",  label:"Colère",    valence:"insat", mots:{leger:"agacée",   modere:"fâchée",     intense:"furieuse"} },
  { id:"peur",    label:"Peur",      valence:"insat", mots:{leger:"inquiète", modere:"anxieuse",   intense:"terrifiée"} },
  { id:"joie",    label:"Joie",      valence:"sat",   mots:{leger:"contente", modere:"joyeuse",    intense:"radieuse"} },
  { id:"triste",  label:"Triste",    valence:"insat", mots:{leger:"déçue",    modere:"malheureuse",intense:"désespérée"} },
  { id:"fatiguee",label:"Fatiguée",  valence:"insat", mots:{leger:"lasse",    modere:"fatiguée",   intense:"épuisée"} },
  { id:"vitalite",label:"Vitalité",  valence:"sat",   mots:{leger:"animée",   modere:"énergique",  intense:"survoltée"} },
];
const INT_NIVEAUX = [
  { k:"leger",   label:"Léger"  },
  { k:"modere",  label:"Modéré" },
  { k:"intense", label:"Intense"},
];
```

### 4.5 Squelette de logique (à coller dans le `<script>`, style aligné sur l'existant)

```js
// --- Jeu d'intensité (3e bascule d'Associer) -----------------------------
let intRound = null; // { fam, niveauK }

function intStart(){
  const fam = INTENSITE[Math.floor(Math.random()*INTENSITE.length)];
  const niveauK = INT_NIVEAUX[Math.floor(Math.random()*INT_NIVEAUX.length)].k;
  intRound = { fam, niveauK };
  intRender();
}

function intRender(){
  const { fam, niveauK } = intRound;
  const mot = fam.mots[niveauK];
  // Famille affichée en contexte (le degré n'a de sens que dans sa famille) :
  document.getElementById("gameWord").innerHTML =
    `<span class="pill">${esc(fam.label)}</span><br>${esc(disp(mot))}`;
  const opts = document.getElementById("gameOpts");
  opts.innerHTML = "";
  INT_NIVEAUX.forEach(n=>{
    opts.appendChild(el(
      `<button class="opt" onclick="intAnswer('${n.k}')">${esc(n.label)}</button>`
    ));
  });
  document.getElementById("gameFeedback").textContent = "";
  document.getElementById("gameNext").hidden = true;
}

function intAnswer(choiceK){
  const bon = intRound.niveauK;
  document.querySelectorAll("#gameOpts .opt").forEach(b=>{
    b.disabled = true;
    const k = b.getAttribute("onclick").match(/'(\w+)'/)[1];
    if(k===bon)          b.classList.add("good");   // + coche/texte : jamais la couleur seule
    else if(k===choiceK) b.classList.add("bad");
    else                 b.classList.add("dim");
  });
  const ok = choiceK===bon;
  document.getElementById("gameFeedback").textContent = ok
    ? "Juste — bien senti."
    : `Ici, c'est « ${INT_NIVEAUX.find(n=>n.k===bon).label} ».`;
  if(ok) markLearned("sent", INTENSITE.find(f=>f===intRound.fam).mots[bon]);
  document.getElementById("gameNext").hidden = false;
}
```

Et dans `setAssoc(k)`, ajouter la branche `"intensite"` (afficher la consigne
« À quel degré ce mot situe-t-il le ressenti ? » et appeler `intStart()`), plus
le 3ᵉ bouton de segment dans le HTML d'*Associer*.

### 4.6 Accessibilité (rappel non négociable)

- Jamais la **couleur seule** : le bon/mauvais choix doit aussi porter une
  **icône ou un texte** (✓ / ✗) et le feedback textuel ci-dessus.
- L'ordre Léger → Modéré → Intense donne déjà un repère de **position**.

### 4.7 Vérification avant push (rappel ARCHITECTURE §7)

`node --check` sur le `<script>` extrait ; confirmer que `#gameWord/#gameOpts/…`
existent ; tester le parcours en local (`serve.ps1`) ; pousser sur `dev`.

---

## 5. Estimation (une fois les triplets validés par Tommy)

| Tâche | Humain seul | Assisté IA |
|---|---|---|
| Câbler le mode « Intensité » (3e bascule, données + logique + style) | 4–8 h | 1–2 h |
| (v2) mécanique « ordonner les 3 mots » | +3–5 h | +1 h |

La validation des triplets par Tommy est le **seul préalable bloquant** ; le code,
lui, est prêt à poser.
