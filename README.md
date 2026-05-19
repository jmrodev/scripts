# 🛠️ Hub de Scripts - jmro

Repositorio consolidado de utilidades para Manjaro Linux, automatización de sistemas y herramientas de desarrollo.

## 🚀 Inicio Rápido

Para acceder a todas las utilidades desde una interfaz unificada, ejecuta:

\`\`\`bash
./main_menu.sh
\`\`\`

## 📂 Estructura del Repositorio

- **`backup/`**: Gestión de respaldos de dotfiles y paquetes (Arch/Manjaro). Incluye \`manage_backups.sh\`.
- **`instaladores/`**: Instalación automatizada de software (VSCode, Brew, Samba) y el **LAMP Modular**.
- **`servicios/`**: Gestor de servicios del sistema con interfaz Zenity.
- **`system/`**: Herramientas de mantenimiento, edición de configs (\`edit_configs.sh\`) y aceleración.
- **`network/`**: Utilidades de red para IP, Puertos y MAC.
- **`dev/`**: Scaffolding para proyectos (React, MERN, PHP) y gestión de servidores locales.
- **`git/`**: Automatización de clonación masiva desde GitHub.
- **`remote/`**: Scripts de acceso remoto (Cámara y Micrófono).
- **`utilities/`**: Scripts variados (Duplicados, Passwords, EncFS).
- **`whatsapp-mcp/`**: Servidor de integración con WhatsApp.

## 📊 Grafo de Conocimiento

Este proyecto utiliza [graphify](graphify-out/) para mapear las dependencias entre scripts. Puedes ver el grafo interactivo en \`graphify-out/graph.html\`.

## 🛠️ Desarrollo

Si añades un nuevo script, recuerda actualizar el \`main_menu.sh\` y ejecutar:
\`\`\`bash
graphify update .
\`\`\`
