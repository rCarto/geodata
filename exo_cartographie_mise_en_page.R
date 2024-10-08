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


# 4. Créez une carte représentant la population active travaillant dans l'industrie. ----

# plusieurs cartes sont possible ici

# les stocks
mf_map(com)
mf_map(x = com, var = "IND", type = "prop")
# les ratios
mf_map(x = com, var = "SACT_IND", type = "choro")
# une combinaison des 2
mf_map(x = com, var = c("ACT", "SACT_IND"), type = "prop_choro")



# 5. Ajoutez les éléments d'habillage indispensables. ----

mf_scale()
mf_arrow()
mf_title()
mf_credits()

# 6. Utilisez un thème personnalisé. ----

mon_theme <- mf_theme(bg = , fg = , mar =, ...)
mf_map(com)

# 7. Ajoutez un carton de localisation du Lot. ----
# import des départements
dep <- st_read("data/lot46.gpkg", layer = "departement")
# affichage de la carte principale
mf_map(com, var = , type = , ...)
# Affichage du carton
mf_inset_on(x = dep, pos = ..., cex = ...)
mf_map(dep, col = , border = )
mf_map(com, col = , border = , add = T)
mf_inset_off()


# 8. Exportez la carte au format PNG avec 800 pixels de large.  ----

mf_export(com, "carte.png", width = 800, ...)
# affichage de la carte principale
mf_map(com, var = , type = , add = TRUE, ...)
# reste de la carte
mf_title(...)
...
# finaliser l'export
dev.off()


# 9. Comment rendre la carte plus intelligible ? Allez-y ! ----
# Voir mf_annotation() par exemple



