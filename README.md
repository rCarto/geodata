# geodata

Ce dépôt contient les données utilisées dans les documents suivants : 

- [Géomatique avec R](https://rcarto.github.io/geomatique_avec_r/)
- [Cartographie avec R](https://rcarto.github.io/cartographie_avec_r/)


Pour utiliser les données il suffit de télécharger le dépôt puis de le décompresser. Vous pourrez ensuite jouer l'ensemble des exemples proposés.    
Les données sources sont lourdes et ne sont pas proposées en téléchargement ici.   
Vous trouverez ci-dessous les scripts utilisés pour préparer les données. 

## Les communes et les routes

Dans cette partie on prépare les données sur les géométries des communes et des routes du Lot (46) 

Source : [Admin Express COG Carto 3.0, IGN - 2021](https://geoservices.ign.fr/adminexpress) & [BD CARTO® 4.0, IGN - 2021](https://geoservices.ign.fr/bdcarto)

```r
# Import des données brutes
library(sf)
dep_raw <- st_read("data-raw/ADECOGC_3-0_SHP_LAMB93_FR/DEPARTEMENT.shp")
road_raw <- st_read("data-raw/BDC_4-0_SHP_LAMB93_R76-ED211/RESEAU_ROUTIER/TRONCON_ROUTE.shp")
com_raw <- st_read("data-raw/BDC_4-0_SHP_LAMB93_R76-ED211/ADMINISTRATIF/COMMUNE.shp")

## Sélection pour le Lot (46)
dep <- dep_raw[dep_raw$INSEE_DEP=="46", ]
com <- com_raw[com_raw$INSEE_DEP=="46", ]
road <- road_raw[st_intersects(road_raw, dep, sparse = FALSE), ]
road <- road[!road$VOCATION %in% c("Bretelle", "Piste cyclable"),]

st_write(obj = dep_raw, dsn = "data/lot46.gpkg", layer = "departement", delete_layer = T)
st_write(obj = road, dsn = "data/lot46.gpkg", layer = "route", delete_layer = T)
```
## Données sur la population active occupée

Ici nous allons rajouter des données sur la poulation active occupée âgée de 25 à 54 ans, par secteur d'activité et sexe, au lieu de résidence 

Source : [Recensements harmonisés - Séries départementales et communales, INSEE - 2020](https://www.insee.fr/fr/statistiques/1893185)

```r
# POPULATION ACTIVE OCCUPĖE ÂGĖE DE 25 À 54 ANS, PAR SECTEUR D'ACTIVITĖ ET SEXE - AU LIEU DE RĖSIDENCE
library(readxl)
dd <- data.frame(read_xls("data-raw/pop-act2554-empl-sa-sexe-cd-6817.xls", sheet = "COM_2017", skip = 15))
dd$INSEE_COM <- paste0(dd$DR, dd$CR)
names(dd)[7:14] <- c("AGR_H", "AGR_F", "IND_H", "IND_F", "BTP_H", "BTP_F", "TER_H", "TER_F")
com <- com[, c("INSEE_COM", "NOM_COM", "STATUT", "POPULATION")]
com <- merge(com, dd[, 7:15], by = "INSEE_COM", all.x = T)
st_write(obj = com, dsn = "data/lot46.gpkg", layer = "commune", delete_layer = T)
```


## Données sur les restaurants

Nous allons ensuite créer une couche des restaurants 

Source : [Base permanente des équipements (BPE), INSEE - 2021](https://www.insee.fr/fr/statistiques/3568638?sommaire=3568656)


```r
library(sf)
dep <- st_read('data/lot46.gpkg', layer = "departement")
bpe_raw <- read.csv("data-raw/bpe20_ensemble_xy_csv/bpe20_ensemble_xy.csv", sep = ";")
bpe_restau <- bpe_raw[bpe_raw$TYPEQU == "A504", ]
bpe_restau <- bpe_restau[!is.na(bpe_restau$LAMBERT_X),]
restau_raw <- st_as_sf(bpe_restau, coords = c("LAMBERT_X", "LAMBERT_Y"), 
                       crs = st_crs(dep))
restau <- restau_raw[st_intersects(restau_raw, st_buffer(dep[dep$INSEE_DEP==46,], 50000), sparse = F),]
st_write(obj = restau, dsn = "data/lot46.gpkg", layer = "restaurant", delete_layer = T)                                   
```


## Grille de population

Nous allons traiter ici la grille de population de l'INSEE. 

Source : [Données carroyées – Carreau de 1km, INSEE - 2019](https://www.insee.fr/fr/statistiques/4176293?sommaire=4176305)

```r
library(sf)
library(terra)
dep <- st_read('data/lot46.gpkg', layer = "departement")
g <- st_read("data-raw/Filosofi2015_carreaux_1000m_gpkg/Filosofi2015_carreaux_1000m_metropole_gpkg/Filosofi2015_carreaux_1000m_metropole.gpkg")
dep <- st_transform(dep[dep$INSEE_DEP == 46, ], 3035)
g <- st_transform(g, 3035)
gg <- g[st_intersects(g, st_as_sfc(st_bbox(st_buffer(dep, 50000))),
                      sparse = F), ]
# export vectoriel
st_write(obj = gg, dsn = "data/grid46.gpkg", layer = "grid", delete_layer = T)

# export tif
XY  <- data.frame(Id_carr1km = gg$Id_carr1km, st_coordinates( st_centroid(gg)))
XY$X <- round(XY$X, 0)
XY$Y <- round(XY$Y, 0)
aa <- expand.grid(X = seq(min(XY$X), max(XY$X), 1000),
                  Y = seq(min(XY$Y), max(XY$Y), 1000))
to <- merge(aa, XY, by = c("X", "Y"), all.x  = TRUE)
grid <- merge(to,gg, by = "Id_carr1km", all.x = T )
r <- rast(grid[2:4], type = "xyz")
crs(r) <- "epsg:3035"
# export raster
terra::writeRaster(r, "data/pop.tif", overwrite = TRUE)

# export csv
# découpage selon l'emprise du departement
rpop <- trim(mask(r, vect(dep)))
# transformation en data.frame
pop <- as.data.frame(rpop, xy = TRUE)
pop <- pop[order(pop$y), ]
write.csv(pop, file = "data/pop.csv", row.names = FALSE)

```


## Données altimétriques


Source : [SRTM, depuis le package `elevatr`](https://github.com/jhollist/elevatr/)

```r
library(elevatr)
library(sf)
dep <- st_read('data/lot46.gpkg', layer = "departement")
dep46 <- dep[dep$INSEE_DEP=="46", ]
elev <- get_elev_raster(st_transform(dep46, 4326), z = 11, clip="bbox")
elev <- terra::rast(elev)
terra::writeRaster(elev, "data/elevation.tif", overwrite = TRUE)
```

## Données CORINE Land Cover

Source : [Corine Land Cover (CLC) 2018, Version 2020_20u1 - Copernicus Programme](https://land.copernicus.eu/pan-european/corine-land-cover/clc2018?tab=download)

```r
library(terra)
# Import du raster
CLC2018 <- rast("data-raw/U2018_CLC2018_V2020_20u1.tif")
# Import de données vectorielles
commune <- vect("data/lot46.gpkg", layer="commune")
# Agrégation communes du Lot
lot46 <-  aggregate(commune)
# (Re)projection
lot46_LAEA <- project(x= lot46, y = CLC2018)
# Découpage du CLC2018 par les limites départementales du Lot
CLC_lot <- crop(CLC2018, lot46_LAEA)
## Recodage des types d'occupation du sol
reclassif <- matrix(c(1,1,111,2,2,112,3,3,121,4,4,122,5,5,123,6,6,124,7,7,131,
                      8,8,132,9,9,133,10,10,141,11,11,142,12,12,211,13,13,212,
                      14,14,213,15,15,221,16,16,222,17,17,223,18,18,231,
                      19,19,241,20,20,242,21,21,243,22,22,244,23,23,311,
                      24,24,312,25,25,313,26,26,321,27,27,322,28,28,323,
                      29,29,324,30,30,331,31,31,332,32,32,333,33,33,334,
                      34,34,335,35,35,411,36,36,412,37,37,421,38,38,422,
                      39,39,423,40,40,511,41,41,512,42,42,521,43,43,522,
                      44,44,523,48,48,NA),
                    ncol = 3, byrow = TRUE)
# Reclassification
CLC_lot_2 <- classify(CLC_lot, rcl = reclassif, right = NA)
names(CLC_lot_2) <- "CLC2018"
# Enregistrement
writeRaster(x = CLC_lot_2, filename = "data/CLC2018_Lot.tif", overwrite=TRUE)
```


## Données Sentinel-2 

Source : [Sentinel, *Sentinel-2A*, S2A_OPER_MSI_L2A_DS_VGS2_20211012T140548_S20211012T105447_N03.01, 12 Octobre 2021 - Copernicus Programme](https://scihub.copernicus.eu/dhus/#/home), téléchargé le 28 décembre 2021.

```r
library(terra)
# Import des bandes spectrales rouge et proche infra-rouge
B04_R <- rast("data-raw/T31TCK_20211012T105011_B04_10m.jp2")
B08_IR <- rast("data-raw/T31TCK_20211012T105011_B08_10m.jp2")
# Import de données vectorielles
commune <- vect("data/lot46.gpkg", layer="commune")
cahors <- subset(commune, commune$INSEE_COM == "46042") 
Sentinel2A <- c(B04_R, B08_IR)
Sentinel2A_L93 <- project(x= Sentinel2A, y = commune, method = "near")
Sentinel2A_cahors <- crop(Sentinel2A_L93, cahors)
writeRaster(x = Sentinel2A_cahors, filename = "data/Sentinel2A.tif")
```

## Données de demandes de valeurs foncières géolocalisées (DVF)

Extraction des données DVF dans les communes de Montreuil et de Vincennes

Source : [Demandes de valeurs foncières géolocalisées, Etalab, 2021](https://www.data.gouv.fr/fr/datasets/demandes-de-valeurs-foncieres-geolocalisees/)

```r
library(sf)
# import des communes de Vincennes et de Montreuil
com_raw <- st_read("data-raw/ADECOGC_3-0_SHP_LAMB93_FR/COMMUNE.shp")
com <- com_raw[com_raw$INSEE_COM %in% c("94080", "93048"), ]
st_write(obj = com, dsn = paste0("data/dvf.gpkg"), layer = "com",
         delete_layer = TRUE, quiet = TRUE)

# Téléchargement des données DVF
dvf_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv/%s/communes/%s/%s.csv"
dvf_file <- "data-raw/dvf/%s_%s.csv"
for (i in 2016:2021){
  download.file(
    url = sprintf(dvf_url, i, 94, 94080),
    destfile = sprintf(dvf_file, i, 94080)
  )
}
for (i in 2016:2021){
  download.file(
    url = sprintf(dvf_url, i, 93, 93048),
    destfile = sprintf(dvf_file, i, 93048)
  )
}
lf <- list.files("data-raw/dvf")
ldvf <- vector("list", length(lf))
for (i in 1:length(lf)){
  ldvf[[i]] <-read.csv(paste0("data-raw/dvf/", lf[[i]]))
}
dvf <- do.call(rbind, ldvf)

# les monoventes
ag <- aggregate(dvf$id_mutation,by = list(id_mutation = dvf$id_mutation), FUN = length)
mono <- dvf[dvf$id_mutation %in% ag[ag$x==1,"id_mutation"] &
              dvf$nature_mutation=="Vente" &
              dvf$type_local=="Appartement", ]

# les multiventes homogènes
x <- dvf[dvf$id_mutation %in% ag[ag$x!=1,"id_mutation"],]
xx <- aggregate(x$id_mutation, by = list(x$id_mutation, x$type_local), length)
ag <- aggregate(xx$Group.1, by = list(id_mutation = xx$Group.1), length)
multihomo <- dvf[dvf$id_mutation %in% ag[ag$x==1,"id_mutation"] &
                   dvf$nature_mutation=="Vente" &
                   dvf$type_local=="Appartement", ]
# Seul les doubles (plus de 2 et on a des trucs bizarre...)
ag <- aggregate(multihomo$id_mutation, by = list(id_mutation = multihomo$id_mutation), length)
bihomo <- multihomo[multihomo$id_mutation %in% ag[ag$x==2, "id_mutation"],]
bihomo <- aggregate(bihomo, by = list(bihomo$id_mutation), head, 1)[,-1]

# bind des 2
apt <- rbind(mono, bihomo)

# spatial stuff
apt <- apt[!is.na(apt$longitude),]
apt <- st_as_sf(apt, coords = c("longitude","latitude"), crs = 4326)
apt <- st_transform(apt, st_crs(2154) )

# price outlier stuff
apt$prix <- apt$valeur_fonciere / apt$surface_reelle_bati
qt <- quantile(apt$prix,probs = seq(0,1,.01), na.rm = T)
apt <- apt[!is.na(apt$prix) &  apt$prix<qt[96] & apt$prix>qt[4], ]
# jitter
apt <- st_jitter(apt, amount = 15)
# Export
st_write(obj = apt, dsn = paste0("data/dvf.gpkg"), layer = "dvf",
         delete_layer = TRUE, quiet = TRUE)
```

## Données OpenStreetMap

Extraction de certaines données OpenStreetMap dans la région de Montreuil et
de Vincennes. 

Source : [© les contributeurs d’OpenStreetMap, 2021](https://www.openstreetmap.org/)

```r
library(sf)
library(osmdata)
com <- st_read("data/dvf.gpkg", layer = "com")
# define a bounding box
bb <- st_bbox(st_buffer(st_transform(com, 4326), 250))
my_opq <- opq(bbox = bb)
# extract green spaces
green1 <- my_opq %>%
  add_osm_feature(key = "landuse", value = c("allotments",
                                             "farmland","cemetery",
                                             "forest", "grass", "greenfield",
                                             "meadow",
                                             "orchard", "recreation_ground",
                                             "village_green", "vineyard")) %>%
  osmdata_sf()
green2 <- my_opq %>%
  add_osm_feature(key = "amenity", value = c("grave_yard")) %>%
  osmdata_sf()
green3 <- my_opq %>%
  add_osm_feature(key = "leisure", value = c("garden", "golf_course",
                                             "nature_reserve", "park", "pitch")) %>%
  osmdata_sf()
green4 <- my_opq %>%
  add_osm_feature(key = "natural", value = c("wood", "scrub", "health",
                                             "grassland", "wetland")) %>%
  osmdata_sf()
green5 <- my_opq %>%
  add_osm_feature(key = "tourism", value = c("camp_site")) %>%
  osmdata_sf()

sg <- function(x){
  if(!is.null(x$osm_polygons)){
    a <- st_geometry(x$osm_polygons)
  } else {
    a <- NULL
  }
  if(!is.null(x$osm_multipolygons)){
    b <- st_geometry(x$osm_multipolygons)
  } else {
    b <- NULL
  }
  r <- c(a,b)
  r
}
gr <- c(sg(green1), sg(green2), sg(green3), sg(green4), sg(green5))
green <- st_union(st_make_valid(gr))
green <- st_transform(green, 2154)
green <- st_buffer(st_buffer(green, 5), -5)

# Extract roads & railways
q4 <- add_osm_feature(my_opq, key = 'highway', value = '', value_exact = FALSE)
res4 <- osmdata_sf(q4)$osm_lines
roads <- st_geometry(res4)
q5 <- add_osm_feature(my_opq, key = 'railway', value = '', value_exact = FALSE)
res5 <- osmdata_sf(q5)$osm_lines
rail <- st_geometry(res5)
road <- st_transform(roads, 2154)
rail <- st_transform(rail, 2154)

# export
st_write(obj = road, dsn = paste0("data/dvf.gpkg"), layer = "route",
         delete_layer = TRUE, quiet = TRUE)
st_write(obj = rail, dsn = paste0("data/dvf.gpkg"), layer = "rail",
         delete_layer = TRUE, quiet = TRUE)
st_write(obj = green, dsn = paste0("data/dvf.gpkg"), layer = "parc",
         delete_layer = TRUE, quiet = TRUE)
```
