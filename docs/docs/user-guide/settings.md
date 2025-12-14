---
sidebar_position: 8
title: Parametres
description: Configurez IAckathon selon vos preferences
---

# Parametres de l'application

Personnalisez IAckathon selon vos besoins grace aux differentes options de configuration.

## Acceder aux parametres

Depuis l'ecran d'accueil, appuyez sur l'icone **engrenage** en haut a droite.

## Apparence

### Theme

Choisissez l'apparence visuelle de l'application :

| Theme | Description |
|-------|-------------|
| **Sombre** | Interface sombre, ideale pour une utilisation nocturne |
| **Clair** | Interface lumineuse, meilleure lisibilite en plein jour |
| **Systeme** | Suit automatiquement le theme de votre appareil |

:::tip Conseil
Le theme sombre reduit la fatigue oculaire et economise la batterie sur les ecrans OLED.
:::

## Parametres du modele

Ces parametres influencent le comportement de l'IA lors de la generation de texte.

### Temperature

**Valeur** : 0.0 a 2.0 (defaut : 0.8)

La temperature controle la creativite des reponses :

| Valeur | Comportement |
|--------|--------------|
| **0.0 - 0.3** | Reponses precises et previsibles |
| **0.4 - 0.7** | Equilibre entre precision et creativite |
| **0.8 - 1.2** | Reponses plus creatives et variees |
| **1.3 - 2.0** | Tres creatif, parfois incoherent |

**Recommandations :**
- Questions factuelles : Temperature basse (0.2-0.4)
- Redaction creative : Temperature moyenne-haute (0.8-1.0)
- Brainstorming : Temperature elevee (1.0-1.2)

### Top-K

**Valeur** : 1 a 100 (defaut : 40)

Limite le nombre de mots candidats a chaque etape de generation :

- **Valeur basse (1-10)** : Reponses plus coherentes mais repetitives
- **Valeur haute (50-100)** : Plus de diversite mais risque d'incoherence

### Top-P (Nucleus Sampling)

**Valeur** : 0.0 a 1.0 (defaut : 0.95)

Selectionne les mots dont la probabilite cumulee atteint ce seuil :

- **0.9** : Ne considere que les mots les plus probables
- **0.95** : Bon equilibre (recommande)
- **1.0** : Considere tous les mots possibles

### Longueur maximale

**Valeur** : 100 a 4096 tokens (defaut : 1024)

Limite la longueur maximale des reponses :

| Valeur | Usage |
|--------|-------|
| 256 | Reponses courtes, definitions |
| 512 | Reponses moyennes |
| 1024 | Reponses detaillees (defaut) |
| 2048+ | Textes longs, articles |

:::warning Attention
Des valeurs elevees augmentent le temps de generation et la consommation de RAM.
:::

## Prompt systeme

Le prompt systeme definit le comportement par defaut de l'IA.

### Qu'est-ce que c'est ?

C'est une instruction invisible qui precede toutes vos conversations. L'IA suivra ces instructions pour toutes ses reponses.

### Exemples de prompts systeme

**Assistant francophone :**
```
Tu es un assistant qui repond toujours en francais.
Tu es concis et precis dans tes reponses.
```

**Expert technique :**
```
Tu es un expert en developpement logiciel.
Tu fournis des explications techniques detaillees
avec des exemples de code quand c'est pertinent.
```

**Assistant educatif :**
```
Tu es un professeur patient et pedagogique.
Tu expliques les concepts etape par etape
et tu utilises des analogies simples.
```

### Bonnes pratiques

1. **Soyez clair** : Instructions simples et directes
2. **Soyez specifique** : Mentionnez le style, le format, la langue
3. **Testez** : Ajustez selon les resultats obtenus

## Synthese vocale (TTS)

### Activer la lecture vocale

Activez cette option pour que l'IA lise ses reponses a voix haute.

### Parametres vocaux

| Option | Description |
|--------|-------------|
| **Voix** | Selectionnez parmi les voix disponibles |
| **Vitesse** | Ajustez la vitesse de lecture (0.5x - 2.0x) |
| **Tonalite** | Modifiez la hauteur de la voix |

:::info Note
Les voix disponibles dependent de votre appareil Android.
:::

## Reinitialiser les parametres

Pour revenir aux parametres par defaut :

1. Faites defiler jusqu'en bas des parametres
2. Appuyez sur **Reinitialiser les parametres**
3. Confirmez

:::warning Attention
Cette action reinitialise tous les parametres. Vos conversations et modeles de prompts ne sont pas affectes.
:::

## Parametres recommandes

### Pour des reponses precises
```
Temperature : 0.3
Top-K : 20
Top-P : 0.9
Longueur max : 512
```

### Pour la redaction creative
```
Temperature : 0.9
Top-K : 50
Top-P : 0.95
Longueur max : 1024
```

### Pour l'apprentissage
```
Temperature : 0.6
Top-K : 40
Top-P : 0.95
Longueur max : 2048
Prompt systeme : "Tu es un professeur patient..."
```

## Questions frequentes

**Q : Mes parametres sont-ils sauvegardes ?**
R : Oui, ils persistent entre les sessions.

**Q : Les parametres affectent-ils le modele RAG ?**
R : Non, le RAG utilise des parametres specifiques pour la recherche.

**Q : Puis-je avoir differents parametres par conversation ?**
R : Non, les parametres sont globaux pour toute l'application.
