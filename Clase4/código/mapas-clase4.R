# Instalar paquetes
install.packages(c("tidyverse","sf","maps","tmap","mapview","gifski","devtools"))
# Cargar paquetes
paquetes <- c("tidyverse","sf","maps","tmap","mapview","gifski","devtools")
lapply(paquetes, require, character.only = TRUE)

# Cargo base de homicidios por localidad
homicidios <- read.csv(file = "https://github.com/FoxHound112263/DS-Training-DAFP/raw/master/data/homicidios.txt",sep = "\t",fileEncoding = "UTF-8",encoding = "UTF-8")

# Convertir a texto
homicidios$Localidad <- as.character(homicidios$Localidad)

# Reemplazar sin información por Sumapaz
homicidios$Localidad[homicidios$Localidad == "Sin información"] <- "Sumapaz"

# Convertir Total temporalmente en texto para reemplazar caracter " - "
homicidios$Total <- as.character(homicidios$Total)

# Reemplazar guion por cero
homicidios$Total[homicidios$Total == " - "] <- 0

# Convertir en numérico
homicidios$Total <- as.numeric(homicidios$Total)


# Operador de tubo
homicidios_fix <- homicidios %>% 
  # Agrupar
  group_by(Localidad) %>% 
  # Filtrar por máximo valor
  filter(Total == max(Total)) %>% 
  # Desagrupar
  ungroup() %>%
  # Dejar valores únicos
  unique()

# Quitar último valor que no sirve
homicidios_fix <- homicidios_fix[-nrow(homicidios_fix),]


#-------#
# Mapas #
#-------#



# geojson con localidades de Bogotá
localidades <- st_read('https://github.com/FoxHound112263/DS-Training-DAFP/raw/master/data/bta_localidades.json')

names(localidades)

localidades$NOMBRE

install.packages("ggplot2")
library(ggplot2)
# Mapa rápido
ggplot(localidades) + 
  geom_sf()

# Mapa con relleno
ggplot(localidades) +
  geom_sf(aes(fill = NOMBRE))

# Generar variable categórica para el mapa
# Agregar datos a localidades
nueva_columna <- c("Norte", "Sur", "Sur", "Norte", "Norte", "Sur", "Centro", "Occidente", "Sur", "Sur", "Norte", "Norte", "Norte", "Sur", "Sur","Sur","Sur", "Centro", "Sur", "Sur")

# Crear nueva columna
library(tidyverse)
localidades <- mutate(localidades, ubicación = nueva_columna)

# En el mapa
ggplot(localidades) +
  geom_sf(aes(fill = ubicación))



# Hacer igual ambas columnas
homicidios_fix$Localidad <- toupper(homicidios_fix$Localidad) 

# Verificar que todas las localidades estén
homicidios_fix$Localidad %in% localidades$NOMBRE

# Igualar nombre faltante
homicidios_fix$Localidad[homicidios_fix$Localidad == "LA CANDELARIA" ] <- "CANDELARIA"

# Ordenar uno con base en otro
homicidios_fix <-  homicidios_fix[order(match(homicidios_fix$Localidad,localidades$NOMBRE )), ]

# Colorear por homicidios
ggplot(localidades) +
  # Rellenar por número de homicidios
  geom_sf(aes(fill = homicidios_fix$Total)) +
  # Colorear
  scale_fill_distiller(palette = "Spectral") +
  # Mostrar localidades en mapa
  geom_sf_text(aes(label = substr(NOMBRE, start = 1, stop = 3)),size = 2.5)


# Agregar ubicación a gráfico de barras
homicidios_fix <- mutate(homicidios_fix, ubicación = nueva_columna)

# Gráfico full
ggplot(homicidios_fix) +
  geom_col(aes(x = reorder(Localidad,Total), y = Total, fill = ubicación)) +
  geom_text(aes(x = Localidad, y = Total, label = Total), nudge_y = 5) +
  labs(title = "Homicidios en Bogotá por localidad",
       subtitle = "Año 2017",
       y = "Total") +
  coord_flip() +
  # Fondo y panel blanco
  theme(panel.grid = element_blank(), panel.background = element_blank())


# Graficar con latitudes y longitudes
library(maps)

# Mapa mundial rápido
mundo <- map_data(map = "world")

ggplot(data = mundo,mapping = aes(x = long,y=lat,group=group))+
  geom_polygon(fill='white',color='black') +
  coord_quickmap()

# Relleno cada país con un color
ggplot(data = mundo,mapping = aes(x = long,y=lat,group=group))+
  geom_polygon(fill=mundo$group,color='black')


# Sacar mapa de Colombia
install.packages("dplyr")
library(dplyr)
colombia <- mundo %>% filter(region == "Colombia")

# Gráfico de Colombia vacío
ggplot(data = colombia,mapping = aes(x = long,y=lat,group=group))+
  geom_polygon(fill='white',color='black') + 
  coord_quickmap() +
  theme(panel.grid = element_blank(), panel.background = element_blank())

########################################################################

# Cargar shape_file de Colombia
install.packages("sf")
library(sf)
my_sf <- st_read("shape_colombia/depto.shp")

# Instalar paquete 
devtools::install_github("nebulae-co/homicidios")

library("homicidios")
homicidios <-  homicidios::homicidios

# Eliminar columnas inútiles para este ejercicio
homicidios$id <- NULL
homicidios$municipio <- NULL
homicidios$id_depto <- NULL

my_sf$DPTO <- NULL

# library(dplyr)
# homicidios_2013 <- homicidios %>% filter(año == 2000) %>% 
#   group_by(depto) %>% 
#   summarise_(poblacion = sum(poblacion),
#             tasa = sum(tasa),
#             homicidios = sum(homicidios))

# Tratar base
homicidios_2013 <- homicidios %>% filter(as.numeric(año) == 2013)
homicidios_2013$año <- NULL

homicidios_2013 <- homicidios_2013 %>%  group_by(depto) %>% summarise_all(sum)


# Emparejar base de homicidios y del mapa
colnames(homicidios_2013)[1] <- "NOMBRE_DPT"

homicidios_2013$NOMBRE_DPT <- c("AMAZONAS","ANTIOQUIA","ARAUCA","ARCHIPIELAGO DE SAN ANDRES PROVIDENCIA Y SANTA CATALINA",
                                "ATLANTICO","SANTAFE DE BOGOTA D.C","BOLIVAR",
                                "BOYACA","CALDAS","CAQUETA","CASANARE","CAUCA","CESAR","CHOCO",
                                "CORDOBA","CUNDINAMARCA","GUAINIA","GUAVIARE","HUILA","LA GUAJIRA","MAGDALENA", "META",
                                "NARIÑO","NORTE DE SANTANDER","PUTUMAYO","QUINDIO",
                                "RISARALDA","SANTANDER","SUCRE","TOLIMA","VALLE DEL CAUCA",
                                "VAUPES","VICHADA")


# Mapa
plot(my_sf['NOMBRE_DPT'])

# Emparejar ambas bases de datos
colombia_sf <- full_join(my_sf, homicidios_2013)
install.packages("tmap")
library(tmap)

colombia_sf %>% 
  tm_shape() +
  tm_fill(col = "poblacion", title = "No. personas") +
  tm_borders(lwd = 0.5) +
  tm_text("NOMBRE_DPT", size = 0.5) +
  tm_style("gray") +
  tm_layout(
    main.title = "Población (2013)",
    main.title.position = c("center"),
    main.title.size = 1,
    legend.position = c("left", "bottom")
  ) +
  tm_credits("Fuente:\nCenso 2013", position = c("right", "bottom"))


# Gráfico de puntos
colombia_sf %>% 
  tm_shape() +
  tm_polygons() +
  tm_bubbles(col = "gold", size = "poblacion", 
             scale = 3, title.size = "") +
  tm_text("NOMBRE_DPT", size = "poblacion", root = 9,
          legend.size.show = FALSE) +
  tm_layout(
    main.title = "Población 2013)",
    main.title.position = c("center"),
    main.title.size = 1,
    legend.position = c("left", "bottom")   
  )


# Interactivo

tmap_mode("view")
colombia_sf %>% 
  mutate(label = str_c(NOMBRE_DPT, ": ", homicidios)
  ) %>% 
  select(label, everything()) %>%
  tm_shape() +
  tm_fill(col = 'poblacion', title = "Homicidios") +
  tm_borders(lwd = 0.5)

install.packages("mapview")
library(mapview)

mapview(
  colombia_sf,
  zcol = c("NOMBRE_DPT", "poblacion", "homicidios", 
           "tasa"),
  legend = FALSE,
  hide = TRUE
)



# Animación
install.packages("gapminder")
library(gapminder)
head(gapminder)

gapminder <-  gapminder::gapminder

install.packages("ggplot2")
library(ggplot2)
# Gráfico estático
p <- ggplot(
  gapminder, 
  aes(x = gdpPercap, y=lifeExp, size = pop, colour = country)
) +
  geom_point(show.legend = FALSE, alpha = 0.7) +
  scale_color_viridis_d() +
  scale_size(range = c(2, 12)) +
  scale_x_log10() +
  labs(x = "GDP per capita", y = "Life expectancy")
p

install.packages("gifski")
library(gifski)

install.packages("gganimate")
library(gganimate)

p + transition_time(year) +
  labs(title = "Year: {frame_time}")

#Por continente
p + facet_wrap(~continent) +
  transition_time(year) +
  labs(title = "Year: {frame_time}")

# Deje una marca
p + transition_time(year) +
  labs(title = "Year: {frame_time}") +
  view_follow(fixed_y = TRUE)

# Otro
p + transition_time(year) +
  labs(title = "Year: {frame_time}") +
  shadow_wake(wake_length = 0.1, alpha = FALSE)

# Datos originales de fondo
p + transition_time(year) +
  labs(title = "Year: {frame_time}") +
  shadow_mark(alpha = 0.3, size = 0.5)

####################### Base de datos de pib y life expectancy

# Gráfico de líneas
p <- ggplot(
  airquality,
  aes(Day, Temp, group = Month, color = factor(Month))
) +
  geom_line() +
  scale_color_viridis_d() +
  labs(x = "Día del mes", y = "Temperatura") +
  theme(legend.position = "top")
p

# Aparecer de manera gradual
p + transition_reveal(Day)

# Agregarle un puntico
p + 
  geom_point() +
  transition_reveal(Day)

# Marcar camino
p + 
  geom_point(aes(group = seq_along(Day))) +
  transition_reveal(Day)

