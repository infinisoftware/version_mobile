# The Gift Exchange Global — application mobile

Application Flutter (Android et iOS) pour les membres. Elle utilise la même API que le site et reprend ses couleurs et sa mise en page. La partie admin n'est pas incluse.

**Pas de partie publique** (décision du client, 07/11/2026) : l'application s'ouvre directement sur la connexion. La vitrine (`LandingPage`) et les pages d'information publiques restent sur le site et ne doivent pas être ajoutées à l'application.

## Lancer l'application

```bash
cd version_mobile
flutter pub get
flutter run
```

Par défaut, l'application utilise l'API de production. Pour utiliser le backend local :

```bash
# Émulateur Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
# Simulateur iOS
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## État d'avancement

| Fonction | État |
| --- | --- |
| Thème Dark Slate et couleurs des 8 niveaux | Fait |
| Connexion (email ou nom d'utilisateur), session gardée | Fait |
| Langues EN / FR / ES | Fait |
| Tableau de bord : profil, lien d'invitation, 8 niveaux | Fait |
| Bouton « Sign up » sur la connexion | Ouvre le formulaire du site dans le navigateur, en attendant l'inscription dans l'application |
| Inscription, mot de passe oublié, vérification de l'email | À faire |
| Signature des Conditions et de la Confidentialité | À faire |
| Paiement « I've paid » et preuve | À faire |
| Board : Centre, contributeurs, prochain, file, Pending (Bronze), compte à rebours 24 h | Fait (lecture seule, rafraîchi toutes les 10 s) |
| Board : Confirmer, Pas reçu, Enlever un donateur, voir la preuve, parcours d'un membre | À faire |
| Forum : fil, publication avec photo, j'aime, commentaires et réponses, suppression de ses publications, cloche des notifications | Fait |
| Forum : autocomplétion des mentions `@` | À faire (les mentions tapées à la main marchent) |
| Support : mes demandes, nouvelle demande avec capture, conversation, fermeture | Fait (vue membre ; pas la vue équipe) |
| Pièces jointes PDF (envoi et affichage) | À faire (photos seulement) |
| Compte : profil, parrain, lien d'invitation (copier, WhatsApp, nouveau lien), coordonnées, moyens de paiement (Zelle, Cash App, banque, crypto vérifiée), parcours, signatures, langue | Fait |
| Icônes du haut : messagerie paiements & litiges (non-lus) et cloche du forum, sur Dashboard, Board, Forum, Support, Compte | Fait |
| Messagerie : conversations, messages avec photo, « Re-mentionner payé », « Lancer un litige », « Confirmer » (receveur, mot confirm) | Fait |
| Téléphone avec sélecteur de pays (comme le site) | À faire (saisie au format +509 37833690) |
| Parcours d'un autre membre (clic sur un nom) | À faire |

## Licence

Le code de l'application est publié sous licence [GPL-3.0](LICENSE). Les polices Plus Jakarta Sans sont sous licence SIL OFL 1.1 (`assets/fonts/OFL.txt`). Le nom « The Gift Exchange Global » et le logo ne sont pas couverts par cette licence.

Le serveur (API) n'est pas public : l'application se connecte au service en ligne The Gift Exchange Global.
