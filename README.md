# Au juste mot — La CNV appliquée

Application web / PWA de **littératie émotionnelle** en français québécois. Elle
aide à **nommer finement un ressenti** et à le **relier au besoin qu'il
signale**, dans le cadre de la Communication NonViolente (CNV).

🌐 **En ligne :** https://justemotcnv.com

> Réalisation de **FMP InfoSolutions** pour Tommy Welsh. Vocabulaire tiré de la
> grille « Liste de sentiments et besoins » de Dialogo (2022).

---

## Démarrage rapide

```powershell
# Servir l'app en local (Windows PowerShell)
.\aujustemotcnv\serve.ps1
```

L'app est un **unique fichier autonome** (`aujustemotcnv/index.html`) : HTML,
CSS, JavaScript et données, sans build ni dépendance. On l'édite directement.

Ouvrir `index.html` en `file://` fonctionne aussi (le service worker échoue alors
silencieusement — c'est prévu).

---

## Structure du dépôt

```
aujustemot/
├── aujustemotcnv/            L'application (ce qui est déployé)
│   ├── index.html            Tout le produit : HTML + CSS + JS + données inline
│   ├── sw.js                 Service worker (cache PWA)
│   ├── manifest.webmanifest
│   ├── donnees-emotions.json Copie documentaire du contenu (l'app ne la lit pas)
│   ├── serve.ps1             Petit serveur statique local
│   └── icons/
├── deploiement/
│   ├── aujustemotcnv.conf    Vhost Nginx (HTTP ; certbot ajoute le HTTPS)
│   ├── deployer-serveur.sh   Déploiement initial sur le VPS (idempotent)
│   ├── televerser.ps1        Transfert du paquet depuis Windows
│   └── setup-ci-vps.sh       Prépare le VPS pour le déploiement continu
├── docs/
│   ├── ARCHITECTURE.md       Carte technique de l'index.html
│   ├── DEPLOIEMENT.md        CI/CD, secrets, préprod/prod, dépannage
│   └── EDITEUR-CONTENU.md    Design de l'édition à distance (Fred + Tommy)
├── validation/               Corpus de validation CNV (docx, xlsx)
├── .github/workflows/
│   └── deploy-dev.yml        Auto-déploiement sur push `dev`
├── CLAUDE.md                 Constitution du projet (lue par Claude Code)
├── HANDOFF.md                Reprise complète : état, décisions, backlog
└── README.md                 (ce fichier)
```

---

## À lire dans l'ordre

1. **`CLAUDE.md`** — les règles et valeurs du projet (contexte, garde-fous).
2. **`HANDOFF.md`** — l'état complet, les décisions et leur pourquoi, le backlog.
3. **`docs/ARCHITECTURE.md`** — comment est fait l'`index.html`.
4. **`docs/DEPLOIEMENT.md`** — comment ça se déploie.
5. **`docs/EDITEUR-CONTENU.md`** — la suite envisagée (édition à distance).

---

## Déploiement en un coup d'œil

- **Branche `dev`** → push → **GitHub Actions déploie automatiquement** (rsync
  vers le VPS), en versionnant le cache du service worker (SHA du commit).
- Configuration : secrets GitHub + `deploiement/setup-ci-vps.sh`. Tout est
  détaillé dans `docs/DEPLOIEMENT.md`.

---

## Valeurs

Sans abonnement, sans traçage, sans pub, sans dépendance externe. Données de
l'utilisateur **dans son navigateur** uniquement. Accessibilité soignée (jamais
de codage par la couleur seule). Ton doux. Voir `CLAUDE.md`.
