---
sidebar_position: 9
title: FAQ
description: Questions frequemment posees sur IAckathon
---

# Questions frequemment posees

Retrouvez ici les reponses aux questions les plus courantes sur IAckathon.

## Questions generales

### Qu'est-ce que IAckathon ?

IAckathon est une application Android qui vous permet de discuter avec une intelligence artificielle directement sur votre telephone, sans connexion internet. Elle utilise les modeles Gemma de Google qui s'executent localement sur votre appareil.

### Est-ce vraiment gratuit ?

Oui, IAckathon est entierement gratuit. Il n'y a pas d'abonnement, pas de publicites et pas de limites d'utilisation.

### Mes donnees sont-elles privees ?

Absolument. Tout se passe sur votre appareil :
- Vos conversations ne sont jamais envoyees sur Internet
- Vos documents PDF restent locaux
- Aucune telemetrie n'est collectee

### IAckathon fonctionne-t-il sur iPhone ?

Non, actuellement IAckathon est uniquement disponible sur Android. Une version iOS pourrait etre envisagee dans le futur.

---

## Installation et compatibilite

### Mon telephone est-il compatible ?

Votre telephone est compatible si :
- Android 8.0 ou superieur
- Au moins 4 Go de RAM
- Processeur ARM64 (la plupart des telephones recents)

### Pourquoi l'installation est bloquee ?

Android bloque par defaut les applications hors Play Store. Solutions :
1. Activez "Sources inconnues" dans les parametres
2. Desactivez temporairement Play Protect
3. Consultez le [guide d'installation](/user-guide/installation)

### Combien d'espace disque faut-il ?

- Application : ~50 Mo
- Modele Gemma 3 1B : ~900 Mo
- Modele Gemma 3 Nano E2B : ~2 Go
- Modele Gemma 3 Nano E4B : ~4 Go

Prevoyez au moins 2 Go d'espace libre.

---

## Modeles et performances

### Quel modele choisir ?

| Votre besoin | Modele recommande |
|--------------|-------------------|
| Telephone d'entree de gamme | Gemma 3 1B |
| Analyser des images | Gemma 3 Nano E2B/E4B |
| Raisonnement complexe | DeepSeek R1 1.5B |
| Usage general | Gemma 3 Nano E2B |

### Pourquoi les reponses sont lentes ?

Plusieurs facteurs peuvent ralentir les reponses :
1. **RAM insuffisante** : Fermez les autres applications
2. **Modele trop lourd** : Essayez un modele plus leger
3. **Conversation longue** : Commencez une nouvelle conversation
4. **Appareil ancien** : Les anciens processeurs sont plus lents

### Puis-je utiliser plusieurs modeles ?

Oui, vous pouvez telecharger plusieurs modeles. Cependant, un seul modele peut etre charge en memoire a la fois.

### Les modeles s'ameliorent-ils avec le temps ?

Non, les modeles sont fixes. Ils n'apprennent pas de vos conversations. Cela garantit la confidentialite mais signifie aussi qu'ils ne s'adaptent pas a votre style.

---

## Utilisation du chat

### L'IA se souvient-elle de mes conversations precedentes ?

Non, chaque conversation est independante. L'IA n'a acces qu'aux messages de la conversation en cours.

### Comment obtenir de meilleures reponses ?

1. **Soyez precis** dans vos questions
2. **Donnez du contexte** : mentionnez votre niveau, votre objectif
3. **Demandez un format** : liste, tableau, paragraphe
4. **Iterez** : affinez votre demande si la reponse ne convient pas

### Pourquoi l'IA repond parfois a cote ?

Les modeles locaux sont moins puissants que ChatGPT ou Claude. Pour de meilleurs resultats :
- Posez des questions plus simples
- Decoupez les taches complexes
- Reformulez si necessaire

### L'IA peut-elle faire des erreurs ?

Oui, comme toute IA, elle peut :
- Donner des informations incorrectes
- Mal comprendre votre question
- Generer du contenu incoherent

Verifiez toujours les informations importantes.

---

## Documents PDF (RAG)

### Quels types de PDF fonctionnent ?

| Type | Support |
|------|---------|
| PDF avec texte selectionnable | Excellent |
| PDF avec images de texte | Non supporte |
| PDF scanne sans OCR | Non supporte |
| PDF protege | Non supporte |

### Le PDF est trop gros, que faire ?

- Divisez le PDF en plusieurs parties
- Importez uniquement les sections pertinentes
- Utilisez des PDF de moins de 100 pages

### L'IA ne trouve pas l'information dans mon PDF

1. Verifiez que le document est **active** (switch vert)
2. Reformulez votre question
3. Utilisez les memes termes que le document
4. Verifiez que le PDF contient bien l'information

---

## Problemes techniques

### L'application plante au demarrage

1. Redemarrez votre telephone
2. Liberez de la RAM (fermez les apps)
3. Verifiez l'espace de stockage disponible
4. Reinstallez l'application

### Le modele ne se charge pas

1. Assurez-vous d'avoir assez de RAM libre
2. Redemarrez l'application
3. Retelecharger le modele si necessaire
4. Essayez un modele plus leger

### Le telechargement echoue

1. Verifiez votre connexion internet
2. Verifiez l'espace de stockage
3. Relancez le telechargement
4. Essayez sur un autre reseau Wi-Fi

### La generation de texte s'arrete

1. La limite de tokens est peut-etre atteinte
2. Augmentez la "Longueur maximale" dans les parametres
3. Posez des questions plus courtes

---

## Batterie et ressources

### IAckathon consomme-t-il beaucoup de batterie ?

L'inference IA est gourmande en ressources. Conseils :
- Utilisez le modele le plus leger possible
- Fermez l'app quand vous ne l'utilisez pas
- Gardez votre telephone branche pour les sessions longues

### L'application chauffe mon telephone

C'est normal lors de longues sessions. L'IA utilise intensivement le processeur. Si ca devient excessif :
- Faites une pause
- Fermez l'application
- Laissez le telephone refroidir

---

## Confidentialite et securite

### Ou sont stockees mes conversations ?

Localement sur votre appareil, dans une base de donnees SQLite. Elles ne sont jamais envoyees sur Internet.

### Comment supprimer toutes mes donnees ?

1. Supprimez les conversations depuis l'historique
2. Ou desinstallez l'application
3. Ou effacez les donnees de l'app (Parametres Android > Applications > IAckathon > Stockage > Effacer les donnees)

### L'application demande-t-elle des permissions ?

| Permission | Usage |
|------------|-------|
| Stockage | Sauvegarder les modeles et conversations |
| Camera/Galerie | Envoyer des images (modeles multimodaux) |

Aucune permission reseau n'est requise apres le telechargement des modeles.

---

## Autres questions

### Comment signaler un bug ?

Ouvrez une issue sur GitHub :
```
https://github.com/iackathon/iackathon/issues
```

### Comment contribuer au projet ?

Consultez la [documentation developpeur](/developer/contributing) pour savoir comment contribuer.

### Y aura-t-il de nouveaux modeles ?

De nouveaux modeles sont ajoutes regulierement au fur et a mesure de leur disponibilite dans l'ecosysteme Gemma.
