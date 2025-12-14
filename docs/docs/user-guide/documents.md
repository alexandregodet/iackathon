---
sidebar_position: 6
title: Documents PDF
description: Interrogez vos documents PDF avec l'IA (RAG)
---

# Utiliser des documents PDF

IAckathon integre une fonctionnalite de **RAG** (Retrieval-Augmented Generation) qui vous permet d'importer des documents PDF et de poser des questions sur leur contenu.

## Qu'est-ce que le RAG ?

Le RAG est une technique qui permet a l'IA de :

1. **Analyser** votre document PDF
2. **Extraire** les passages pertinents
3. **Repondre** a vos questions en se basant sur le contenu du document

:::info Avantage du RAG
L'IA n'invente pas les informations - elle les extrait directement de votre document.
:::

## Importer un document

### Etape 1 : Ouvrir le menu d'import

1. Dans le chat, appuyez sur le bouton **+**
2. Selectionnez **pdf**

### Etape 2 : Choisir le document

1. Naviguez dans vos fichiers
2. Selectionnez un fichier PDF
3. L'application analyse le document

### Etape 3 : Traitement du document

Le traitement comprend plusieurs etapes :

```
Lecture du PDF...     [====      ] 40%
Extraction du texte... [======    ] 60%
Decoupage en chunks... [========  ] 80%
Indexation...         [==========] 100%
```

:::tip Temps de traitement
Le temps de traitement depend de la taille du document. Un document de 10 pages prend generalement 10-30 secondes.
:::

## Gerer les documents

### Documents actifs

Un badge sur le bouton **+** indique le nombre de documents actifs. Un document actif signifie que l'IA utilisera son contenu pour repondre a vos questions.

### Voir les documents importes

1. Appuyez sur **+**
2. Appuyez sur **pdf**
3. La liste des documents importes s'affiche

### Actions sur un document

- **Activer/Desactiver** : Basculez le switch pour inclure/exclure le document
- **Supprimer** : Appuyez sur l'icone de suppression

## Poser des questions

Une fois le document importe et actif, posez vos questions normalement :

### Exemples de questions

```
Quel est le sujet principal de ce document ?
```

```
Resume les points cles du chapitre 3.
```

```
Quelles sont les conclusions de l'auteur ?
```

```
Trouve les passages qui mentionnent le mot "innovation".
```

### Comment l'IA repond

1. L'IA recherche les passages pertinents dans votre document
2. Elle utilise ces passages comme contexte
3. Elle formule une reponse basee sur le contenu trouve

## Bonnes pratiques

### Documents compatibles

| Type | Compatibilite |
|------|---------------|
| PDF texte | Excellent |
| PDF avec images | Texte extrait uniquement |
| PDF scanne (OCR) | Non supporte actuellement |
| PDF protege | Non supporte |

### Optimiser les resultats

:::tip Conseils
1. **Documents clairs** : Les PDFs avec du texte selectionnable fonctionnent mieux
2. **Questions precises** : "Que dit le document sur X ?" plutot que "Parle-moi du document"
3. **Un sujet a la fois** : Posez des questions sur un theme specifique
:::

### Limites

- **Taille maximale** : Documents de moins de 100 pages recommandes
- **Langue** : Fonctionne mieux avec le francais et l'anglais
- **Format** : Uniquement les fichiers PDF

## Cas d'usage

### Etude et revision

```
J'etudie pour un examen. Quels sont les concepts cles
de ce chapitre que je dois retenir ?
```

### Recherche d'information

```
Ce contrat mentionne-t-il des clauses de resiliation ?
Cite les passages pertinents.
```

### Resume de document

```
Fais un resume de ce document en 5 points principaux.
```

### Comprehension

```
Explique-moi le concept de [terme technique]
mentionne dans ce document.
```

## Depannage

### Le document ne s'importe pas

**Solutions possibles** :
- Verifiez que le fichier est bien un PDF
- Assurez-vous que le PDF n'est pas protege par mot de passe
- Essayez avec un fichier plus petit

### Les reponses ne correspondent pas au document

**Solutions possibles** :
- Verifiez que le document est bien active (switch actif)
- Reformulez votre question de maniere plus specifique
- Assurez-vous que le document contient bien l'information recherchee

### Traitement tres long

**Solutions possibles** :
- Les documents volumineux prennent plus de temps
- Fermez les autres applications pour liberer des ressources
- Essayez avec un document plus court

## Questions frequentes

**Q : Puis-je importer plusieurs documents ?**
R : Oui, vous pouvez importer plusieurs documents. Activez ceux que vous souhaitez utiliser.

**Q : Les documents sont-ils envoyes sur Internet ?**
R : Non, tout le traitement se fait localement sur votre appareil.

**Q : Mes documents sont-ils sauvegardes ?**
R : L'index du document est sauvegarde localement. Vous pouvez supprimer les documents a tout moment.
