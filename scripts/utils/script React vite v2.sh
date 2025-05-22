#!/bin/bash
set -e

# Comprobar si el directorio ya existe antes de continuar
if [ -d "reactVite" ]; then
  echo "El directorio 'reactVite' ya existe."
  read -r -p "¿Deseas eliminarlo? (si/no): " confirmacion

  if [ "$confirmacion" == "si" ]; then
    echo "Eliminando el directorio 'reactVite'..."
    rm -rf reactVite
  else
    echo "Abortando."
    exit 1
  fi
fi

# Crear un nuevo proyecto Vite con React y la plantilla "vanilla"
npm create vite@latest reactVite . -- --template vanilla

# Cambiar al directorio del proyecto
cd reactVite || exit

# Eliminar archivos y carpeta generados por Vite
rm -f main.js javascript.svg counter.js
rm -rf public/*

# Instalar dependencias
npm install axios dotenv nodemon react-dom react-router-dom bootstrap --save

# Instalar dependencias de desarrollo
npm install -D tailwindcss postcss autoprefixer @reduxjs/toolkit

# Inicializar Tailwind CSS
npx tailwindcss init -p


# Crear la estructura de directorios
mkdir -p src/components src/models src/layouts src/pages src/redux/actions src/redux/reducers src/services src/utils src/routes




# Crear archivos iniciales a partir de plantillas
cat <<EOL > ./src/index.jsx
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);
EOL

cat <<EOL > ./src/App.jsx
import React from 'react';
import { RouterProvider, createBrowserRouter } from 'react-router-dom'
import Index from './pages/index';
import router from './routes/router'

function App() {
  return (
    <RouterProvider router={router}/>
  );
}
export default App;

EOL

cat <<EOL >src/routes/router.jsx

import React from 'react'
import { createBrowserRouter } from 'react-router-dom';
import Index from '../pages/index';

const router = createBrowserRouter(

  [
    { path: '/',element: <Index /> }

    // Agrega otras rutas si es necesario
  ]

);

export default router;

EOL

cat <<EOL >src/pages/index.jsx
import React from 'react';

const Index = () => {
  return (
    <div className='App'>
      <header className='App-header'>
        <h1 className="text-3xl font-bold underline">
          ¡Hola mundo!
        </h1>
        <h2>¡Mi Aplicación React!</h2>
      </header>
    </div>
  );
}

export default Index;
EOL

cat <<EOL >src/components/nav.jsx
import React from 'react';
import { Link } from 'react-router-dom';

function Nav() {
  return (
    <div>
      <ul>
        <li>
          <Link to="/">Página Pública</Link>
        </li>
      </ul>
    </div>
  );
}

export default Nav;
EOL

cat <<EOL >src/redux/store.js
import { configureStore } from '@reduxjs/toolkit';

const store = configureStore({
  // Configura tus reducers aquí
});

export default store;
EOL

cat <<EOL >src/redux/reducers/reducer.js
import { combineReducers } from 'redux';

const rootReducer = combineReducers({
  // Agrega tus reducers aquí
});

export default rootReducer;
EOL

cat <<EOL >src/redux/actions/actions.js
import { createAction } from '@reduxjs/toolkit';

// Agrega tus acciones aquí
EOL


# Eliminar el contenido original del archivo HTML
rm index.html

# Crear un nuevo archivo HTML adaptado utilizando EOF
cat <<EOF >index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="style.css">
    <title>Tu Título Personalizado</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/index.jsx"></script>
  </body>
</html>
EOF




# Comando para modificar tailwind.config.js
sed '/ content: / c content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}",],' tailwind.config.js >tmpfile && mv tmpfile tailwind.config.js

echo '
@tailwind base;
@tailwind components;
@tailwind utilities;
' >style.css




# Crear archivo .env con variables de entorno (personaliza según tus necesidades)
cat <<EOL >.env
BD_URL=TuClaveDeAPI
URL=http://localhost:3000
EOL



# Crear archivo .gitignore

cat <<EOL >.gitignore

.env
node_modules

EOL



# Abrir Visual Studio Code (Insiders) en el directorio del proyecto
code-insiders .

# Iniciar el servidor de desarrollo de Vite
npm run dev

echo "Proyecto reactVite configurado y en ejecución."
