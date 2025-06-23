# Guide des scripts PowerShell pour Minikube

## Sommaire

- [Objectif du projet](#objectif-du-projet)
  - [Pourquoi Minikube ?](#pourquoi-minikube)
  - [Rôle de Hyper-V](#rôle-de-hyper-v)
  - [Gestion des conteneurs](#gestion-des-conteneurs)
  - [Avantages de l'approche locale](#avantages-de-lapproche-locale)
  - [Rôle de Task](#rôle-de-task)
- [Préambule : Prérequis](#préambule--prérequis)
  - [Installation des prérequis avec Chocolatey](#installation-des-prérequis-avec-chocolatey)
  - [Vérification des prérequis](#vérification-des-prérequis)
- [Description des scripts](#description-des-scripts)
  - [1. `setup-minikube.ps1`](#1-setup-minikubeps1)
  - [2. `start-minikube.ps1`](#2-start-minikubeps1)
  - [3. `stop-minikube.ps1`](#3-stop-minikubeps1)
  - [4. `remove.ps1`](#4-removeps1)
  - [5. Utilisation de `taskfile.yaml` avec Task](#5-utilisation-de-taskfileyaml-avec-task)
- [Résumé des cas d'utilisation](#résumé-des-cas-dutilisation)
- [Conseils supplémentaires](#conseils-supplémentaires)

## Objectif du projet

Ce projet vise à simplifier le développement, le test et le déploiement de conteneurs dans un environnement Kubernetes local à l'aide de **Minikube**. Minikube est un outil puissant qui permet de créer un cluster Kubernetes monocœur sur une machine locale, offrant ainsi un environnement de développement rapide et isolé pour les développeurs travaillant sur des applications conteneurisées. L'objectif principal est de fournir une configuration reproductible et automatisée pour gérer un cluster Minikube sur Windows, en utilisant des scripts PowerShell et un fichier `taskfile.yaml` pour orchestrer les tâches.

### Pourquoi Minikube ?

Kubernetes est une plateforme robuste pour orchestrer des conteneurs à grande échelle, mais sa configuration peut être complexe, surtout pour le développement local. Minikube résout ce problème en :

- Créant un cluster Kubernetes léger, idéal pour tester des applications conteneurisées sans nécessiter une infrastructure cloud.
- Permettant de simuler un environnement de production avec des fonctionnalités comme l'ingress, les registres de conteneurs, et la gestion des nœuds.
- Simplifiant l'intégration avec des outils comme **Docker** pour construire et gérer les conteneurs, et **kubectl** pour interagir avec le cluster.

Dans ce projet, Minikube est configuré pour utiliser **Hyper-V** comme driver de virtualisation, garantissant des performances optimales sur Windows et une isolation complète des conteneurs.

### Rôle de Hyper-V

**Hyper-V** est une technologie de virtualisation native de Windows, utilisée ici pour exécuter la machine virtuelle (VM) hébergeant le cluster Minikube. Hyper-V offre :

- Une isolation forte entre la VM Minikube et le système hôte, garantissant la sécurité et la stabilité.
- La possibilité de configurer des commutateurs virtuels (comme `MinikubeSwitch`) pour gérer le réseau de la VM.
- La prise en charge d'adresses MAC statiques pour assurer une IP stable, essentielle pour les entrées DNS locales (par exemple, `nutrition.local` et `gateway.local` dans le fichier `hosts`).
- Une gestion efficace des ressources (CPU, RAM, disque) allouées à la VM, permettant d'adapter Minikube aux besoins du projet.

Hyper-V est un choix privilégié pour Minikube sur Windows, car il est intégré au système d'exploitation (à partir de Windows 10 Pro/Enterprise) et ne nécessite pas d'outils tiers comme VirtualBox.

### Gestion des conteneurs

Les conteneurs sont au cœur de ce projet, et leur gestion repose sur l'intégration de **Docker** et **Kubernetes** :

- **Docker Desktop** : Fournit le moteur de conteneurs utilisé par Minikube pour exécuter les images conteneurisées. Les scripts configurent l'environnement local pour que Docker communique directement avec le daemon Docker de la VM Minikube, simplifiant la construction et le test des images.
- **Kubernetes** : Orchestre les conteneurs dans le cluster Minikube, gérant le déploiement, la mise à l'échelle, et la communication entre services. Les addons comme `ingress` et `registry` activés dans ce projet permettent de simuler des scénarios avancés (par exemple, l'exposition de services via des URL personnalisées ou le stockage local d'images).
- **kubectl** : Permet d'interagir avec le cluster pour déployer des applications, inspecter les pods, ou vérifier l'état des nœuds.

### Avantages de l'approche locale

Développer avec Minikube présente plusieurs avantages :

- **Rapidité** : Les itérations de développement sont plus rapides sans dépendance à un cluster distant.
- **Coût** : Aucun frais d'infrastructure cloud n'est requis pour les tests locaux.
- **Flexibilité** : Les scripts automatisés et `taskfile.yaml` permettent de configurer, démarrer, arrêter, ou supprimer le cluster en quelques commandes.
- **Reproductibilité** : L'utilisation d'une adresse MAC statique et d'entrées DNS fixes garantit un environnement cohérent.

### Rôle de Task

L'outil **Task** (configuré via `taskfile.yaml`) ajoute une couche d'automatisation en regroupant les scripts PowerShell dans des tâches conviviales. Cela réduit la complexité pour les développeurs, qui peuvent exécuter des commandes comme `task setup` ou `task start` au lieu d'invoquer directement les scripts.

Ce guide et les scripts associés sont conçus pour les développeurs souhaitant un flux de travail fluide pour créer et tester des applications Kubernetes localement, tout en tirant parti des capacités avancées de Minikube, Hyper-V, et Docker.

## Préambule : Prérequis

Avant d'utiliser les scripts fournis (`setup-minikube.ps1`, `start-minikube.ps1`, `stop-minikube.ps1`, `remove.ps1`) ou les tâches définies dans `taskfile.yaml`, assurez-vous que les outils suivants sont installés sur votre machine Windows :

- **Docker Desktop** : Nécessaire pour exécuter les conteneurs dans Minikube.
- **kubectl** : L'outil en ligne de commande pour interagir avec Kubernetes.
- **Minikube** : Pour créer et gérer un cluster Kubernetes local.
- **Hyper-V** : Activé sur Windows pour la virtualisation.
- **Task** : Un outil pour exécuter des tâches définies dans `taskfile.yaml`, permettant d'automatiser l'exécution des scripts.

### Installation des prérequis avec Chocolatey

Vous pouvez installer ces outils à l'aide de Chocolatey, un gestionnaire de paquets pour Windows. Si Chocolatey n'est pas installé, exécutez d'abord (en tant qu'administrateur) :

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

Ensuite, installez les outils nécessaires :

```powershell
choco install docker-desktop kubernetes-cli minikube task -y
```

### Vérification des prérequis

Pour vérifier que Docker Desktop, kubectl, Minikube et Task sont correctement installés, exécutez les commandes suivantes dans un terminal PowerShell :

```powershell
docker --version
kubectl version --client
minikube version
task --version
```

Si l'une des commandes échoue, assurez-vous d'installer ou de configurer correctement l'outil correspondant. De plus, vérifiez que Hyper-V est activé :

```powershell
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
```

Si l'état est `Disabled`, activez Hyper-V via :

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

**Note** : Tous les scripts doivent être exécutés en tant qu'administrateur dans PowerShell, car ils modifient des fichiers système (comme `hosts`) et interagissent avec Hyper-V. Si vous utilisez `task`, assurez-vous que le terminal PowerShell est également ouvert en mode administrateur.

## Description des scripts

### 1. `setup-minikube.ps1`

**Objectif** : Configure un environnement Minikube pour la première fois ou réinitialise un environnement existant avec Hyper-V, en utilisant l'adaptateur réseau `Ethernet 2`.

**Fonctionnement** :

- **Nettoyage initial** : Supprime les fichiers de configuration Minikube existants dans `~/.minikube` pour garantir une installation propre.
- **Vérification de Docker** : Confirme que Docker Desktop est en cours d'exécution sur la machine hôte.
- **Création du commutateur Hyper-V** : Crée ou met à jour un commutateur virtuel nommé `MinikubeSwitch` associé à l'adaptateur `Ethernet 2`, en vérifiant que l'adaptateur est actif.
- **Configuration du driver** : Définit Hyper-V comme driver pour Minikube.
- **Démarrage initial** : Lance Minikube avec des ressources prédéfinies (4 CPU, 8 Go de RAM, 40 Go de disque) et le commutateur `MinikubeSwitch`.
- **Arrêt temporaire** : Arrête Minikube pour permettre la configuration réseau.
- **Adresse MAC statique** : Attribue une adresse MAC statique (`00-15-5D-01-03-04`) à la VM Minikube pour garantir une IP stable.
- **Redémarrage** : Relance Minikube pour appliquer la configuration réseau.
- **Mise à jour du fichier hosts** : Ajoute ou met à jour une entrée pour `nutrition.local` et `gateway.local` avec l'IP de Minikube, avec des tentatives répétées en cas de verrouillage du fichier.
- **Configuration Docker** : Configure l'environnement Docker local pour interagir avec le daemon Docker de la VM Minikube.
- **Vérification du daemon Docker** : Vérifie que le service Docker est actif dans la VM, avec un redémarrage si nécessaire.
- **Activation des addons** : Active les addons `registry` et `ingress` pour prendre en charge le stockage local d'images et l'exposition des services.
- **Vérification finale** : Affiche l'état de Minikube, les informations du cluster Kubernetes, et la liste des nœuds pour confirmer que tout fonctionne correctement.

**Conditions d'utilisation** :

- Utilisez ce script pour une **installation initiale** ou pour **réinitialiser** Minikube.
- Exécutez-le si vous rencontrez des problèmes de configuration ou si vous souhaitez repartir de zéro.
- Nécessite Hyper-V activé, Docker Desktop en cours d'exécution, et l'adaptateur `Ethernet 2` actif.

**Exemple d'exécution** :

```powershell
.\setup-minikube.ps1
```

### 2. `start-minikube.ps1`

**Objectif** : Démarre la VM Minikube et met à jour le fichier `hosts` avec l'IP actuelle.

**Fonctionnement** :

- **Vérification des privilèges** : S'assure que le script est exécuté en tant qu'administrateur.
- **État de la VM** : Vérifie si la VM Minikube est déjà en cours d'exécution.
- **Démarrage** : Si la VM n'est pas en cours, démarre Minikube avec le driver Hyper-V et le commutateur `MinikubeSwitch`.
- **IP et fichier hosts** : Récupère l'IP de Minikube et met à jour ou ajoute une entrée dans le fichier `hosts` pour `nutrition.local` et `gateway.local`.

**Conditions d'utilisation** :

- Utilisez ce script pour **démarrer Minikube** après l'avoir configuré avec `setup-minikube.ps1`.
- Exécutez-le si la VM est arrêtée ou si l'IP a changé et doit être mise à jour dans `hosts`.

**Exemple d'exécution** :

```powershell
.\start-minikube.ps1
```

### 3. `stop-minikube.ps1`

**Objectif** : Arrête la VM Minikube et supprime l'entrée correspondante du fichier `hosts`.

**Fonctionnement** :

- **Vérification des privilèges** : S'assure que le script est exécuté en tant qu'administrateur.
- **État de la VM** : Vérifie si la VM Minikube est en cours d'exécution.
- **Arrêt** : Si la VM est en cours, arrête Minikube.
- **Nettoyage du fichier hosts** : Supprime l'entrée correspondant à `nutrition.local` et `gateway.local` dans le fichier `hosts`.

**Conditions d'utilisation** :

- Utilisez ce script pour **arrêter Minikube** lorsque vous n'en avez plus besoin.
- Exécutez-le pour libérer des ressources système ou avant de supprimer la VM avec `remove.ps1`.

**Exemple d'exécution** :

```powershell
.\stop-minikube.ps1
```

### 4. `remove.ps1`

**Objectif** : Supprime complètement Minikube, ses configurations, et les ressources associées dans Hyper-V.

**Fonctionnement** :

- **Encodage UTF-8** : Force l'encodage UTF-8 pour une sortie cohérente du script.
- **Suppression de Minikube** : Exécute `minikube delete --all --purge` pour supprimer toutes les configurations Minikube.
- **Arrêt et suppression de la VM** : Arrête et supprime la VM nommée `minikube` dans Hyper-V, si elle existe.
- **Nettoyage des fichiers** : Supprime le dossier de configuration Minikube (`~/.minikube`).
- **Suppression des disques virtuels** : Supprime les disques virtuels Minikube (fichiers `.vhdx`) dans le dossier Hyper-V.
- **Suppression du commutateur virtuel** : Supprime le commutateur virtuel `MinikubeSwitch` dans Hyper-V.
- **Désactivation des adaptateurs VMware** : Désactive les adaptateurs réseau VMware pour éviter des conflits avec Hyper-V.

**Conditions d'utilisation** :

- Utilisez ce script pour **supprimer définitivement** Minikube et toutes ses ressources, par exemple pour libérer de l'espace disque ou résoudre des problèmes graves.
- Exécutez `stop-minikube.ps1` avant si vous souhaitez nettoyer le fichier `hosts` au préalable.
- **Attention** : Cette action est irréversible et supprime toutes les données associées à la VM Minikube.

**Exemple d'exécution** :

```powershell
.\remove.ps1
```

### 5. Utilisation de `taskfile.yaml` avec Task

**Objectif** : Simplifier l'exécution des scripts PowerShell en utilisant l'outil `task` et le fichier de configuration `taskfile.yaml`.

**Fonctionnement** :

- Le fichier `taskfile.yaml` définit des tâches qui correspondent aux scripts PowerShell (`setup-minikube.ps1`, `start-minikube.ps1`, `stop-minikube.ps1`, `remove.ps1`).
- L'outil `task` permet d'exécuter ces scripts via des commandes simplifiées, en s'assurant qu'ils sont lancés en mode administrateur.

**Conditions d'utilisation** :

- Assurez-vous que `task` est installé via Chocolatey (voir la section **Installation des prérequis**).
- Ouvrez un terminal PowerShell en mode administrateur avant d'exécuter les commandes `task`.
- Le fichier `taskfile.yaml` doit être présent dans le répertoire du projet.

**Tâches disponibles** :

- `task setup` : Exécute `setup-minikube.ps1` pour configurer ou réinitialiser Minikube.
- `task start` : Exécute `start-minikube.ps1` pour démarrer Minikube et mettre à jour le fichier `hosts`.
- `task stop` : Exécute `stop-minikube.ps1` pour arrêter Minikube et nettoyer le fichier `hosts`.
- `task delete` : Exécute `remove.ps1` pour supprimer la VM Minikube.

**Exemple d'exécution** :

```powershell
task setup
task start
task stop
task delete
```

**Note** : Si vous exécutez `task` pour la première fois, assurez-vous que le fichier `taskfile.yaml` est correctement configuré et que vous êtes dans le répertoire du projet. Consultez le contenu de `taskfile.yaml` pour personnaliser les tâches si nécessaire.

## Résumé des cas d'utilisation

| Script/Tâche                        | Quand l'utiliser                                                             |
| ----------------------------------- | ---------------------------------------------------------------------------- |
| `setup-minikube.ps1` / `task setup` | Pour une première installation ou une réinitialisation complète de Minikube avec Hyper-V, incluant la configuration réseau et les addons. |
| `start-minikube.ps1` / `task start` | Pour démarrer Minikube et mettre à jour le fichier `hosts`.                  |
| `stop-minikube.ps1` / `task stop`   | Pour arrêter Minikube et nettoyer le fichier `hosts`.                        |
| `remove.ps1` / `task delete`        | Pour supprimer définitivement Minikube, ses configurations, et les ressources Hyper-V associées. |

## Conseils supplémentaires

- **Exécution en administrateur** : Ouvrez PowerShell en mode administrateur (`Clic droit > Exécuter en tant qu'administrateur`) avant d'exécuter les scripts ou les commandes `task`.
- **Dépannage** : Si un script ou une tâche échoue, consultez les journaux Minikube avec `minikube logs --file=logs.txt`.
- **Fichier hosts** : Les scripts modifient `C:\Windows\System32\drivers\etc\hosts`. Assurez-vous qu'aucun autre processus ne verrouille ce fichier.
- **Ressources** : Minikube est configuré avec 4 CPU, 8 Go de RAM et 40 Go de disque. Ajustez ces valeurs dans `setup-minikube.ps1` si nécessaire.