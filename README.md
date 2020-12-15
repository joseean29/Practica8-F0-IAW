# Practica8-IAW
##Fase 0. Instalación de Wordpress en un nivel (Un único servidor con todo lo necesario).
Antes de instalar nada lo que hacemos es declarar las variables que mas tarde usaremos al principio del script.

Instalamos Apache, MySQL, PHP, phpMyAdmin.
Una vez instalado esto que es lo de siempre procedemos a instalar Wordpress, creamos su base de datos usando las variables que creamos al principio y borrando lo que vamos a crear antes de hacerlo por si existiera.

Luego vamos a la configuración del archivo wp-config. En este paso lo que tenemos que hacer es definir dentro de el las variables de la base de datos y borrar el index.html para que cuando entremos en el sitio web aparezca Wordpress.

El último paso y para mi el más díficil es el de la configuración de las security keys, aquí tenemos que borrar el bloque que hay por defecto en el archivo de configuración ya que cualquier persona con fin de hacer daño si conoce los valores por defecto y nosotros no los hemos cambiado somos sumamente vulnerabe.
Para esto borramos el bloque y en su lugar introducimos mediante una variable que contiene las de api.wordpress un bloque nuevo que es mucho más seguro ya que va cambiando constantemente de valores. 

Todos estos pasos están mucho más detallados dentro del script.
