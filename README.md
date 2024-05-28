# Script de Post Instalación de Arch Linux

hace un pequeño cambio en el archivo de configuracion de pacman, Agrega ILoveCandi.
Instala varios programas que me parecen necesarios.
Instala aur.

## Correcion de bug y explicacion de los prgramas

Si vas a usar la \ para saltar a la próxima línea y continuar, asegúrate que no haya espacios porque no vas a tener más que errores. Ese fue uno de mos errores y que no supe como resolverlo hasta ahora.
Antes tenía una explicación para cada programa en el script, pero como lo tuvo que quitar para arreglar el error los explicaré a continuación.

| Programa                  | Descripción |
|---------------------------|-------------|
| **xorg**                  | El sistema de ventanas X.Org, que proporciona la base para un entorno gráfico en sistemas Unix y similares a Unix. |
| **xorg-xinit**            | Herramientas de inicialización de X, como `startx`, que se usan para iniciar el servidor X y sus clientes. |
| **picom**                 | Un compositor de ventanas para X, que agrega efectos visuales como sombras, transparencias y desvanecimientos. |
| **feh**                   | Un visor de imágenes rápido y ligero que también se puede usar para establecer fondos de pantalla. |
| **xrandr**                | Herramienta de línea de comandos para configurar y ajustar las propiedades de la pantalla, como la resolución y la rotación. |
| **arandr**                | Interfaz gráfica para `xrandr` que facilita la configuración de monitores múltiples y sus disposiciones. |
| **chromium**              | Un navegador web de código abierto del proyecto Chromium, que sirve como base para Google Chrome. |
| **alacritty**             | Un emulador de terminal rápido y moderno que usa GPU para la renderización. |
| **lightdm**               | Un gestor de sesiones (display manager) ligero que se usa para iniciar sesiones gráficas. |
| **lightdm-gtk-greeter**   | Interfaz gráfica (greeter) para LightDM basada en GTK, que proporciona una pantalla de inicio de sesión. |
| **pulseaudio**            | Un servidor de sonido que proporciona funcionalidades avanzadas de mezcla y gestión de audio. |
| **trayer**                | Un pequeño tray de sistema para X, que permite mostrar iconos de estado y notificaciones. |
| **pavucontrol**           | Control de volumen de PulseAudio, una interfaz gráfica para gestionar las configuraciones de audio y dispositivos. |
| **rofi**                  | Un lanzador de aplicaciones y selector de ventanas que también puede funcionar como selector de SSH y ejecutador de comandos. |
| **libnotify**             | Una biblioteca para enviar notificaciones en el escritorio. |
| **notification-daemon**   | Un servidor que muestra notificaciones del sistema utilizando `libnotify`. |
| **udiskie**               | Un demonio de gestión de discos que maneja el montaje automático de dispositivos extraíbles. |
| **ntfs-3g**               | Un controlador para leer y escribir en sistemas de archivos NTFS, comúnmente usados por Windows. |
| **libreoffice**           | Una suite ofimática completa y de código abierto que incluye procesador de textos, hojas de cálculo, presentaciones, y más. |
| **git**                   | Un sistema de control de versiones distribuido que se usa para el seguimiento de cambios en el código fuente durante el desarrollo de software. |
| **unzip**                 | Una utilidad para descomprimir archivos `.zip`. |
| **zip**                   | Una utilidad para comprimir archivos en el formato `.zip`. |
| **scrot**                 | Una herramienta de línea de comandos para tomar capturas de pantalla. |
| **vlc**                   | Un reproductor multimedia versátil y de código abierto que soporta una amplia variedad de formatos de audio y video. |
| **base-devel**            | Un grupo de paquetes que incluye herramientas básicas de desarrollo y compilación, como `gcc`, `make`, y otros utilitarios esenciales para la construcción de software desde el código fuente. |

Estos programas cubren una amplia gama de funciones, desde la gestión del entorno gráfico y la configuración de pantallas hasta el manejo de audio, edición de imágenes, navegación web y desarrollo de software.


# Scrpt para iniciar Rclone al inicio del sistema

El script compruba la aclidad de la conexion, y en vase a eso ejecuta rclone con el parametro --deamon. 
