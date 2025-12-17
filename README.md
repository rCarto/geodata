# geodata

Ce dépôt contient les données utilisées dans [Géomatique et cartographie avec R](https://rgeocarto.github.io/).

Les données sont stockées dans un projet RStudio. 

Pour utiliser les données il suffit de télécharger le dépôt puis de le décompresser.  

Vous pourrez ensuite jouer l'ensemble des exemples proposés.    

# Les données

&#10551; **lot.gpkg**

Ce fichier contient plusieurs couches d'informations.

- **departements** : les départements français métropolitains, [Admin Express COG Carto 3.0, IGN - 2021](https://geoservices.ign.fr/adminexpress);
- **communes** : les communes du département du Lot (46) avec des données sur la population active occupée âgée de 25 à 54 ans, par secteur d'activité et sexe, au lieu de résidence, en 2017, [BD CARTO® 4.0, IGN - 2021](https://geoservices.ign.fr/bdcarto) & [Recensements harmonisés - Séries départementales et communales, INSEE - 2020](https://www.insee.fr/fr/statistiques/1893185);
- **routes** : les routes de la commune de Gramat et alentours (46128), [BD CARTO® 4.0, IGN - 2021](https://geoservices.ign.fr/bdcarto);
- **restaurants** : les restaurants du Lot, [Base permanente des équipements (BPE), INSEE - 2021](https://www.insee.fr/fr/statistiques/3568638?sommaire=3568656);
- **elevations** : une grille régulière de points d'altitude (pas d'1 km), [Jarvis A., H.I. Reuter, A. Nelson, E. Guevara, 2008, Hole-filled seamless SRTM data V4, International Centre for Tropical Agriculture (CIAT)](http://srtm.csi.cgiar.org).


&#10551; **com.csv** 

Ce fichier tabulaire contient des informations complémentaire sur la population active occupée âgée de 25 à 54 ans, par secteur d'activité et sexe, au lieu de résidence, en 2017, [Recensements harmonisés - Séries départementales et communales, INSEE - 2020](https://www.insee.fr/fr/statistiques/1893185).

- le nombre d’actifs (ACT);
- le nombre d’actifs dans l’industrie (IND);
- la part des actifs dans la population totale (SACT);
- la part des actifs dans l’industrie dans le total des actifs (SACT_IND).


&#10551; **elevation.tif**

Une grille régulière de points d'altitude (pas de 30 mètres environ), [Jarvis A., H.I. Reuter, A. Nelson, E. Guevara, 2008, Hole-filled seamless SRTM data V4, International Centre for Tropical Agriculture (CIAT)](http://srtm.csi.cgiar.org).   

&#10551; **elev.tif** 

Une version reprojetée en Lambert 93 de **elevation.tif**


&#10551; **clc_2018.tif**

Données CORINE Land Cover, [Corine Land Cover (CLC) 2018, Version 2020_20u1 - Copernicus Programme](https://land.copernicus.eu/pan-european/corine-land-cover/clc2018?tab=download).  

&#10551; **clc.tif** 

Une version reprojetée en Lambert 93 de **clc_2018.tif**


&#10551; **Sentinel2A.tif**

Données Sentinel, [Sentinel, *Sentinel-2A*, S2A_OPER_MSI_L2A_DS_VGS2_20211012T140548_S20211012T105447_N03.01, 12 Octobre 2021 - Copernicus Programme](https://scihub.copernicus.eu/dhus/#/home), téléchargé le 28 décembre 2021.
