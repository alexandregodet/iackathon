---
sidebar_position: 7
title: Modeles de prompts
description: Creez et reutilisez vos prompts favoris
---

# Modeles de prompts

Les modeles de prompts vous permettent de sauvegarder vos instructions preferees pour les reutiliser rapidement dans vos conversations.

## Qu'est-ce qu'un modele de prompt ?

Un modele de prompt est un texte pre-ecrit que vous pouvez inserer dans le chat en un clic. C'est utile pour :

- Eviter de retaper les memes instructions
- Garantir la coherence de vos demandes
- Gagner du temps sur les taches repetitives

### Exemples de modeles

| Nom | Contenu |
|-----|---------|
| Resume | "Resume ce texte en 3 points principaux :" |
| Traduction | "Traduis le texte suivant en anglais :" |
| Correction | "Corrige les fautes d'orthographe et de grammaire :" |
| Explication | "Explique ce concept de maniere simple pour un debutant :" |

## Acceder aux modeles

### Depuis le chat

1. Appuyez sur le bouton **+**
2. Selectionnez **template**
3. La liste de vos modeles s'affiche

### Utiliser un modele

1. Appuyez sur le modele souhaite
2. Le texte est insere dans le champ de saisie
3. Ajoutez votre contenu a la suite
4. Envoyez le message

## Gerer les modeles

### Creer un modele

1. Depuis la liste des modeles, appuyez sur le bouton **+**
2. Remplissez les champs :
   - **Nom** : Un titre court et descriptif
   - **Categorie** (optionnel) : Pour organiser vos modeles
   - **Contenu** : Le texte du prompt
3. Appuyez sur **Creer**

### Modifier un modele

1. Appuyez sur le modele a modifier
2. Modifiez les champs souhaites
3. Appuyez sur **Enregistrer**

### Supprimer un modele

1. Appuyez sur l'icone de suppression (corbeille)
2. Confirmez la suppression

## Exemples de modeles utiles

### Pour la redaction

```
Nom: Ameliorer le style
Contenu: Reecris ce texte en ameliorant le style et la clarte,
tout en conservant le sens original :
```

```
Nom: Texte formel
Contenu: Reecris ce texte dans un style professionnel et formel :
```

```
Nom: Simplifier
Contenu: Simplifie ce texte pour qu'il soit comprehensible
par un enfant de 10 ans :
```

### Pour l'analyse

```
Nom: Points cles
Contenu: Identifie et liste les 5 points cles de ce texte :
```

```
Nom: Avantages/Inconvenients
Contenu: Analyse ce sujet et presente les avantages
et inconvenients sous forme de tableau :
```

```
Nom: Questions
Contenu: Genere 5 questions de comprehension sur ce texte :
```

### Pour la programmation

```
Nom: Expliquer le code
Contenu: Explique ce code ligne par ligne :
```

```
Nom: Trouver les bugs
Contenu: Analyse ce code et identifie les bugs potentiels :
```

```
Nom: Optimiser
Contenu: Propose des ameliorations pour optimiser ce code :
```

### Pour l'apprentissage

```
Nom: Flashcards
Contenu: Cree 5 flashcards (question/reponse) sur ce sujet :
```

```
Nom: Quiz
Contenu: Cree un quiz de 5 questions a choix multiples sur :
```

```
Nom: Analogie
Contenu: Explique ce concept avec une analogie simple :
```

## Organiser avec les categories

Les categories vous aident a organiser vos modeles :

### Creer une structure

```
Redaction/
  - Ameliorer le style
  - Texte formel
  - Simplifier

Analyse/
  - Points cles
  - Resume
  - Critique

Programmation/
  - Expliquer le code
  - Debug
  - Optimiser
```

### Bonnes pratiques

1. **Noms courts** : "Resume" plutot que "Faire un resume du texte"
2. **Categories coherentes** : Regroupez par theme ou usage
3. **Contenu actionnable** : Terminez par ":" pour faciliter l'ajout de contenu

## Astuces avancees

### Variables dans les modeles

Vous pouvez utiliser des marqueurs pour les parties a remplacer :

```
Nom: Traduction
Contenu: Traduis ce texte de [LANGUE_SOURCE] vers [LANGUE_CIBLE] :
```

Lors de l'utilisation, remplacez simplement les marqueurs.

### Chainer les prompts

Creez des modeles qui s'enchainent :

```
1. "Resume ce texte en 3 points :"
2. "Maintenant, developpe le point 2 en detail :"
3. "Propose des exemples concrets pour illustrer :"
```

### Modeles contextuels

Adaptez vos modeles au contexte :

```
Nom: Etudiant
Contenu: Tu es un professeur patient. Explique ce concept
de maniere pedagogique avec des exemples :
```

```
Nom: Expert
Contenu: En tant qu'expert dans le domaine, fournis une analyse
technique approfondie de :
```

## Questions frequentes

**Q : Combien de modeles puis-je creer ?**
R : Il n'y a pas de limite au nombre de modeles.

**Q : Les modeles sont-ils synchronises entre appareils ?**
R : Non, les modeles sont stockes localement sur votre appareil.

**Q : Puis-je exporter/importer mes modeles ?**
R : Cette fonctionnalite n'est pas encore disponible.
