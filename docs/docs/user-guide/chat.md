---
sidebar_position: 5
title: Le Chat
description: Tout savoir sur les fonctionnalites de conversation
---

# Fonctionnalites du Chat

Le chat est le coeur de IAckathon. Decouvrez toutes ses fonctionnalites pour tirer le meilleur parti de vos conversations avec l'IA.

## Interface du chat

### Elements de l'ecran

```
+------------------------------------------+
|  < Modele actuel                     [H] |
+------------------------------------------+
|                                          |
|  [U] Votre message                       |
|                                          |
|  [A] Reponse de l'IA...                 |
|                                          |
|                                          |
+------------------------------------------+
|  [+] | Votre message...           | [>] |
+------------------------------------------+
```

- **`<`** : Retour a l'ecran precedent
- **Modele actuel** : Nom du modele charge (appuyez pour changer)
- **[H]** : Historique des conversations
- **[U]** : Vos messages (bulle droite)
- **[A]** : Messages de l'IA (bulle gauche)
- **[+]** : Menu d'options (images, PDF, templates)
- **[>]** : Envoyer le message

## Envoyer des messages

### Message texte simple

1. Tapez votre message dans le champ de saisie
2. Appuyez sur la fleche d'envoi
3. Votre message apparait a droite
4. La reponse de l'IA s'affiche progressivement a gauche

### Conseils pour de bonnes reponses

:::tip Soyez precis
Plus votre question est precise, meilleure sera la reponse.

**Moins bon** : "Parle-moi de la France"

**Meilleur** : "Quelles sont les 5 villes les plus peuplees de France ?"
:::

:::tip Donnez du contexte
L'IA ne se souvient que de la conversation en cours.

**Exemple** : "Je suis etudiant en informatique. Explique-moi les bases de donnees relationnelles."
:::

## Envoyer des images

*Disponible uniquement avec les modeles multimodaux (Gemma 3 Nano E2B/E4B)*

### Methode 1 : Via le menu +

1. Appuyez sur le bouton **+**
2. Selectionnez **image**
3. Choisissez une image de votre galerie
4. Ajoutez votre question
5. Envoyez

### Methode 2 : Glisser-deposer

1. Depuis votre galerie, partagez l'image vers IAckathon
2. L'image apparait en apercu
3. Ajoutez votre question et envoyez

### Exemples de questions sur les images

```
Decris cette image en detail.
```

```
Quel texte vois-tu sur cette photo ?
```

```
Quels objets sont presents dans cette image ?
```

```
Cette image represente-t-elle un paysage urbain ou naturel ?
```

## Gestion des conversations

### Historique

Appuyez sur l'icone d'historique pour voir vos conversations precedentes :

- Les conversations sont listees par date
- Le titre est genere automatiquement
- Appuyez sur une conversation pour la reprendre

### Actions sur les conversations

- **Renommer** : Appuyez longuement > Renommer
- **Supprimer** : Appuyez longuement > Supprimer
- **Nouvelle conversation** : Bouton + en bas

### Effacer la conversation actuelle

Pour recommencer une conversation :

1. Ouvrez le menu (trois points)
2. Selectionnez "Effacer la conversation"
3. Confirmez

:::warning Attention
Cette action supprime tous les messages de la conversation actuelle.
:::

## Actions sur les messages

### Copier un message

1. Appuyez longuement sur un message
2. Selectionnez "Copier"
3. Le texte est copie dans le presse-papiers

### Regenerer une reponse

Si une reponse ne vous convient pas :

1. Appuyez longuement sur la reponse de l'IA
2. Selectionnez "Regenerer"
3. L'IA genere une nouvelle reponse

### Arreter la generation

Si la reponse est trop longue ou si vous voulez l'arreter :

1. Pendant que l'IA repond, le bouton d'envoi devient un bouton stop
2. Appuyez dessus pour arreter la generation

## Mode Reflexion (Thinking)

*Disponible uniquement avec DeepSeek R1 1.5B*

### Comment ca marche

1. Posez votre question
2. L'IA affiche d'abord sa reflexion (en italique)
3. Puis elle donne sa reponse finale

### Exemple visuel

```
Vous : Combien de jours y a-t-il en fevrier 2024 ?

IA (reflexion) :
> L'annee 2024... est-elle bissextile ?
> 2024 / 4 = 506, donc divisible par 4
> 2024 n'est pas divisible par 100
> Donc 2024 est bissextile

IA (reponse) :
En 2024, fevrier compte 29 jours car c'est une annee bissextile.
```

## Indicateurs de performance

En bas de chaque reponse de l'IA, vous pouvez voir :

- **Tokens** : Nombre de tokens generes
- **Vitesse** : Tokens par seconde (t/s)

:::info Qu'est-ce qu'un token ?
Un token est une unite de texte (environ 3-4 caracteres en moyenne). Plus la vitesse est elevee, plus l'IA repond rapidement.
:::

## Astuces avancees

### Prompt systeme

Vous pouvez definir un comportement par defaut pour l'IA dans les parametres :

**Exemple** : "Tu es un assistant francophone. Tu reponds toujours de maniere concise et precise."

### Limiter la longueur des reponses

Incluez dans votre message :
- "Reponds en 2-3 phrases maximum"
- "Fais une liste de 5 points"
- "Resume en un paragraphe"

### Demander un format specifique

- "Presente sous forme de liste a puces"
- "Utilise un format tableau"
- "Ecris en style formel/informel"
