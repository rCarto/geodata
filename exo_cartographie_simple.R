# 1. Importer la couche des communes du département du Lot à partir du ----
# fichier geopackage **lot46.gpkg**.

# La fonction st_layers() permet de connaitre les couches d'un fichier geopackage
library(sf)
st_layers('data/lot.gpkg')

# la fonction st_read() permet d'importer une couche d'un fichier geopackage
com <- st_read(...)

# 2. Importer le fichier **com.csv**.   ----
# Ce jeu de données porte sur les communes du lot et contient plusieurs variables supplémentaires:
#   - le nombre d'actifs (**ACT**).
#     - le nombre d'actifs dans l'industrie (**IND**)
#     - La part des actifs dans la population totale (**SACT**)
#     - La part des actifs dans l'industrie dans le total des actifs (**SACT_IND**)

com_df <- read.csv(...)


# 3. Joindre le jeu de données et la couche des communes. ----

# Utiliser la fonction merge() pour faire la jointure. L'ordre des objets est important.
# merge(com, com_sf, ...) donnera un objet sf.
# merge(com_df, com, ...) donnera un data.frame.

com <- merge(com, com_df, by = ..., all.x = TRUE)


# 4. Créer une carte de la population active.  ----
# Quel mode de représentation utiliser? Quels choix cela implique-t-il?

# Utiliser le type "prop" dans mf_map()

library(mapsf)
# afficher les communes
mf_map(com, col = , border = , lwd = )
# afficher des cercles proportionnels
mf_map(x = com, var = "ACT", type = "prop", ...)


# 6. Créer une carte de la part de la population active dans la population totale.  ----
# Quel mode de représentation utiliser? Quels choix cela implique-t-il?

# NE PAS OUBLIER d'étudier la distribution de la variable à représenter.
mf_distr(...)
summary(...)

# utiliser mf_get_breaks() pour définir les bornes de classe
bks <- mf_get_breaks(com$SACT, breaks = ...)

# utiliser mf_get_pal() pour définir la palette de couleurs à utiliser
cols <- mf_get_pal(n = ..., palette = ...)

# Utiliser le type "choro" dans mf_map()
mf_map(com, "SACT","choro", breaks = bks, pal = cols)
