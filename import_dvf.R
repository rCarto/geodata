library(sf)


com_raw <- st_read("data-raw/ADECOGC_3-0_SHP_LAMB93_FR/COMMUNE.shp")
com <- com_raw[com_raw$INSEE_COM %in% c("94080", "93048"), ]
st_write(obj = com, dsn = paste0("data/dvf.gpkg"), layer = "com",
         delete_layer = TRUE, quiet = TRUE)


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

apt <- st_jitter(apt, amount = 5)


st_write(obj = apt, dsn = paste0("data/dvf.gpkg"), layer = "dvf",
         delete_layer = TRUE, quiet = TRUE)





library(osmdata)

bb <- st_bbox(st_buffer(st_transform(com, 4326), 250))
# define a bounding box
my_opq <- opq(bbox = bb)
# extract le Rhône
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




q4 <- add_osm_feature(my_opq, key = 'highway', value = '', value_exact = FALSE)
res4 <- osmdata_sf(q4)$osm_lines
roads <- st_geometry(res4)
q5 <- add_osm_feature(my_opq, key = 'railway', value = '', value_exact = FALSE)
res5 <- osmdata_sf(q5)$osm_lines
rail <- st_geometry(res5)

road <- st_transform(roads, 2154)
rail <- st_transform(rail, 2154)


st_write(obj = road, dsn = paste0("data/dvf.gpkg"), layer = "route",
         delete_layer = TRUE, quiet = TRUE)
st_write(obj = rail, dsn = paste0("data/dvf.gpkg"), layer = "rail",
         delete_layer = TRUE, quiet = TRUE)
st_write(obj = green, dsn = paste0("data/dvf.gpkg"), layer = "parc",
         delete_layer = TRUE, quiet = TRUE)





library(mapsf)

com <- st_read("data/dvf.gpkg", layer = "com")
parc <- st_read("data/dvf.gpkg", layer = "parc")
route <- st_read("data/dvf.gpkg", layer = "route")
rail <- st_read("data/dvf.gpkg", layer = "rail")



x <- st_make_grid(com, cellsize = 100, square = FALSE)
x <- st_sf(geometry = x)
x <- x[com, ]
x$idgrid <- 1:nrow(x)
apt$idgrid <- unlist(st_intersects(apt, x))
rr <- aggregate(list(prixmed = apt$prix), by = list(idgrid = apt$idgrid), median)
x$n <- unlist(lapply(st_intersects(x, apt), length))
xx <- merge(x, rr, by= "idgrid", all.x = T)



mf_export(com, theme = "darkula", width = 1000 )
mf_map(xx[xx$n>=5, ], "prixmed", "choro",
       add = T, border = NA,
       leg_pos = "topright",nbreaks = 20
       )
mf_map(parc, col = "grey7", border = "grey7", add=T)
mf_map(route, lwd = .2, col ="#b5b3b5", add=T )
mf_map(rail, lwd = .2, col ="#b5b3b5", add=T, lty = 2 )
mf_map(apt, add=T, col = "blue", pch = 20, cex = .1)
mf_map(com, col = NA, border = "white", add = T)
dev.off()
