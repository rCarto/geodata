# geodata

Ce dépôt contient les données utilisées dans les documents suivants : 

- Géomatique avec R
- Cartographie avec R


Pour utiliser les données il suffit de télécharger le dépôt puis de le décompresser. Vous pourrez ensuite jouer l'ensemble des exemples proposés dans ces documents. 


Voici comment ont-été constituées les données proposées. Les données sources sont lourdes et ne sont pas 

## Constitution de la base de données vectorielle

Source : BD Carto & ADMIN Express
```r
library(sf)
dep_raw <- st_read("data-raw/ADECOGC_3-0_SHP_LAMB93_FR/DEPARTEMENT.shp")
road_raw <- st_read("data-raw/BDC_4-0_SHP_LAMB93_R76-ED211/RESEAU_ROUTIER/TRONCON_ROUTE.shp")
com_raw <- st_read("data-raw/BDC_4-0_SHP_LAMB93_R76-ED211/ADMINISTRATIF/COMMUNE.shp")

## Sélection pour le Lot (46)
dep <- dep_raw[dep_raw$INSEE_DEP=="46", ]
com <- com_raw[com_raw$INSEE_DEP=="46", ]
road <- road_raw[st_intersects(road_raw, dep, sparse = FALSE), ]
road <- road[!road$VOCATION %in% c("Bretelle", "Piste cyclable"),]
```

Source : BPE, INSEE

```r

# restaurant
## from https://www.insee.fr/fr/statistiques/3568638?sommaire=3568656
bpe_raw <- read.csv("data-raw/bpe20_ensemble_xy_csv/bpe20_ensemble_xy.csv", sep = ";")
bpe_restau <- bpe_raw[bpe_raw$TYPEQU == "A504", ]
bpe_restau <- bpe_restau[!is.na(bpe_restau$LAMBERT_X),]
restau_raw <- st_as_sf(bpe_restau, coords = c("LAMBERT_X", "LAMBERT_Y"), crs = st_crs(dep))
restau <- restau_raw[st_intersects(restau_raw, st_buffer(dep[dep$INSEE_DEP==46,], 50000), sparse = F),]


# POPULATION ACTIVE OCCUPĖE ÂGĖE DE 25 À 54 ANS, PAR SECTEUR D'ACTIVITĖ ET SEXE - AU LIEU DE RĖSIDENCE
library(readxl)
dd <- data.frame(read_xls("data-raw/pop-act2554-empl-sa-sexe-cd-6817.xls", sheet = "COM_2017", skip = 15))
dd$INSEE_COM <- paste0(dd$DR, dd$CR)
names(dd)[7:14] <- c("AGR_H", "AGR_F", "IND_H", "IND_F", "BTP_H", "BTP_F", "TER_H", "TER_F")
com <- com[, c("INSEE_COM", "NOM_COM", "STATUT", "POPULATION")]
com <- merge(com, dd[, 7:15], by = "INSEE_COM", all.x = T)



st_write(obj = dep_raw, dsn = "data/lot46.gpkg", layer = "departement", delete_layer = T)
st_write(obj = com, dsn = "data/lot46.gpkg", layer = "commune", delete_layer = T)
st_write(obj = road, dsn = "data/lot46.gpkg", layer = "route", delete_layer = T)
st_write(obj = restau, dsn = "data/lot46.gpkg", layer = "restaurant", delete_layer = T)




# la grille de pop
library(sf)
dep <- st_read('data/lot46.gpkg', layer = "departement")
g <- st_read("data-raw/Filosofi2015_carreaux_1000m_gpkg/Filosofi2015_carreaux_1000m_metropole_gpkg/Filosofi2015_carreaux_1000m_metropole.gpkg")
dep <- st_transform(dep[dep$INSEE_DEP == 46, ], 3035)
g <- st_transform(g, 3035)
gg <- g[st_intersects(g, st_as_sfc(st_bbox(st_buffer(dep, 50000))),
                      sparse = F), ]
st_write(obj = gg, dsn = "data/grid46.gpkg", layer = "grid", delete_layer = T)


XY  <- data.frame(Id_carr1km = gg$Id_carr1km, st_coordinates( st_centroid(gg)))
XY$X <- round(XY$X, 0)
XY$Y <- round(XY$Y, 0)
aa <- expand.grid(X = seq(min(XY$X), max(XY$X), 1000),
                  Y = seq(min(XY$Y), max(XY$Y), 1000))
to <- merge(aa, XY, by = c("X", "Y"), all.x  = TRUE)
grid <- merge(to,gg, by = "Id_carr1km", all.x = T )
library(terra)
r <- rast(grid[2:4], type = "xyz")
crs(r) <- "epsg:3035"
terra::writeRaster(r, "data/pop.tif", overwrite = TRUE)




library(elevatr)
library(sf)
dep <- st_read('data/lot46.gpkg', layer = "departement")
dep46 <- dep[dep$INSEE_DEP=="46", ]
elev <- get_elev_raster(st_transform(dep46, 4326), z = 11, clip="bbox")
elev <- terra::rast(elev)
terra::writeRaster(elev, "data/elevation.tif", overwrite = TRUE)

```
