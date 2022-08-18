#lang scribble/manual
@require[@for-label[quittances-generator
                    racket/base]]

@title{quittances-generator}
@author{Vincent BERZIN}

@defmodule[quittances-generator]

Générateur de quittances de loyer pour les propriétaires-bailleurs.

@section{Dépendances}

Il faut que wkhtmltopdf soit installé.

@section{Configuration}

Voir en premier lieu le fichier quittances.json qui contient les informations sur le propriétaire et les logements et leurs locataires.

Il faut également un fichier image de signature (jpg ou png).

@section{Ligne de commande}

Soit sans paramètre, pour prendre le mois en cours du début à la fin
Soit en précisant l'année et le mois pour prendre en compte un mois spécifique

exemple pour le mois d'août 2022: quittance-generator 2022 8

@section{TODO}

Actuellement, l'entièreté du mois est prise en compte, il faudra pouvoir ajouter des périodes spécifiques si le locataire n'a pas occupé
le logement le mois complet.
