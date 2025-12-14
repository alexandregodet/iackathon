---
sidebar_position: 4
title: Les modeles
description: Guide complet des modeles d'IA disponibles dans IAckathon
---

# Les modeles d'IA

IAckathon propose plusieurs modeles d'intelligence artificielle, chacun avec ses caracteristiques propres. Ce guide vous aide a choisir le modele adapte a vos besoins.

## Vue d'ensemble

| Modele | Taille | Type | Points forts |
|--------|--------|------|--------------|
| Gemma 3 1B | 900 Mo | Texte | Leger, rapide |
| Gemma 3 Nano E2B | 2 Go | Multimodal | Images + texte |
| Gemma 3 Nano E4B | 4 Go | Multimodal | Plus puissant |
| DeepSeek R1 1.5B | 1.8 Go | Texte + Reflexion | Raisonnement avance |

## Gemma 3 1B

### Caracteristiques
- **Taille** : ~900 Mo
- **Type** : Texte uniquement
- **RAM requise** : 2-3 Go

### Ideal pour
- Les appareils avec peu de stockage
- Les utilisateurs qui debutent
- Les conversations simples et rapides
- Les appareils d'entree de gamme

### Limites
- Pas de support pour les images
- Moins performant sur les taches complexes

---

## Gemma 3 Nano E2B

### Caracteristiques
- **Taille** : ~2 Go
- **Type** : Multimodal (texte + vision)
- **RAM requise** : 4-5 Go
- **Parametres effectifs** : 2 milliards

### Ideal pour
- L'analyse d'images et photos
- Les questions sur du contenu visuel
- Un bon equilibre performance/ressources

### Capacites visuelles
- Decrire le contenu d'une image
- Identifier des objets et personnes
- Lire du texte dans les images
- Repondre a des questions sur les images

---

## Gemma 3 Nano E4B

### Caracteristiques
- **Taille** : ~4 Go
- **Type** : Multimodal (texte + vision)
- **RAM requise** : 6-8 Go
- **Parametres effectifs** : 4 milliards

### Ideal pour
- Les taches complexes
- Une meilleure comprehension contextuelle
- Les appareils haut de gamme

### Avantages par rapport au E2B
- Reponses plus precises
- Meilleure comprehension des nuances
- Analyse d'images plus detaillee

---

## DeepSeek R1 1.5B

### Caracteristiques
- **Taille** : ~1.8 Go
- **Type** : Texte avec mode reflexion
- **RAM requise** : 3-4 Go

### Le mode Reflexion (Thinking)

Ce qui rend DeepSeek unique, c'est son mode de reflexion. Avant de repondre, le modele "pense" a voix haute, vous permettant de voir son raisonnement.

#### Exemple

**Question** : Combien font 17 x 23 ?

**Reflexion du modele** :
> Je dois calculer 17 x 23...
> Je peux decomposer : 17 x 20 = 340
> Puis 17 x 3 = 51
> Donc 340 + 51 = 391

**Reponse** : 17 x 23 = 391

### Ideal pour
- Les problemes de mathematiques
- Le raisonnement logique
- Les taches necessitant des explications
- L'apprentissage et la comprehension

---

## Comment choisir ?

### Selon votre appareil

```
Entree de gamme (4 Go RAM) --> Gemma 3 1B
Milieu de gamme (6 Go RAM) --> Gemma 3 Nano E2B ou DeepSeek R1
Haut de gamme (8+ Go RAM) --> Gemma 3 Nano E4B
```

### Selon vos besoins

| Besoin | Modele recommande |
|--------|-------------------|
| Conversations simples | Gemma 3 1B |
| Analyser des images | Gemma 3 Nano E2B/E4B |
| Problemes de maths | DeepSeek R1 1.5B |
| Redaction | Gemma 3 1B ou E2B |
| Questions complexes | Gemma 3 Nano E4B |

## Changer de modele

Vous pouvez telecharger plusieurs modeles et passer de l'un a l'autre :

1. Depuis le chat, appuyez sur le nom du modele en haut
2. Selectionnez un autre modele
3. Si non telecharge, telechargez-le
4. Chargez le nouveau modele

:::info Stockage
Chaque modele est stocke separement. Vous pouvez supprimer les modeles non utilises depuis les parametres Android (Applications > IAckathon > Stockage).
:::

## Performances et optimisation

### Conseils pour de meilleures performances

1. **Fermez les autres applications** pour liberer de la RAM
2. **Redemarrez l'appareil** avant une session intensive
3. **Evitez les conversations tres longues** - commencez une nouvelle conversation regulierement
4. **Utilisez le modele adapte** a votre appareil

### Indicateurs de performance

- **Temps de reponse** : Le temps avant que l'IA commence a repondre
- **Tokens/seconde** : Affiche dans le chat, indique la vitesse de generation
