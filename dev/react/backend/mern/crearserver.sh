#!/bin/bash

# Instalar dependencias
echo "Instalando dependencias..."
npm install express mongoose dotenv body-parser
sleep 2

# Crear estructura de carpetas
echo "Creando estructura de carpetas..."
mkdir -p src/models src/routes src/controllers src/config
touch .env
sleep 2

# Crear archivos de código fuente
echo "Creando archivos de código fuente..."
# Archivo db.js en la carpeta config
echo "const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'Connection error:'));
db.once('open', () => {
  console.log('Connected to the database');
});" > src/config/db.js
sleep 2

# Archivo City.js en la carpeta models
echo "const mongoose = require('mongoose');

const citySchema = new mongoose.Schema({
  name: String,
  photo: String,
  country: String,
});

const City = mongoose.model('City', citySchema);

module.exports = City;" > src/models/City.js
sleep 2

# Archivo cityController.js en la carpeta controllers
echo "const City = require('../models/City');

const createCity = async (req, res) => {

  try {
    const newCity = await City.create(req.body);
    res.status(201).json(newCity);
  } catch (error) {
    res.status(500).json({ error: 'Error creating city' });
  }
};

const getAllCities = async (req, res) => {

  try {
    const cities = await City.find();
    res.status(200).json(cities);
  } catch (error) {
    res.status(500).json({ error: 'Error getting cities' });
  }
};

const getCityById = async (req, res) => {

  try {
    const city = await City.findById(req.params.id);
    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }
    res.status(200).json(city);
  } catch (error) {
    res.status(500).json({ error: 'Error getting city' });
  }
};

const updateCity = async (req, res) => {

  try {
    const updatedCity = await City.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    if (!updatedCity) {
      return res.status(404).json({ error: 'City not found' });
    }
    res.status(200).json(updatedCity);
  } catch (error) {
    res.status(500).json({ error: 'Error updating city' });
  }
};

const deleteCity = async (req, res) => {

  try {
    const deletedCity = await City.findByIdAndDelete(req.params.id);
    if (!deletedCity) {
      return res.status(404).json({ error: 'City not found' });
    }
    res.status(200).json({ message: 'City deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Error deleting city' });
  }
};

module.exports = {
  createCity,
  getAllCities,
  getCityById,
  updateCity,
  deleteCity,
};" > src/controllers/cityController.js
sleep 2

# Archivo cityRoutes.js en la carpeta routes
echo "const express = require('express');
const router = express.Router();
const cityController = require('../controllers/cityController');

// Ruta para crear una ciudad
router.post('/', cityController.createCity);

// Ruta para obtener todas las ciudades
router.get('/', cityController.getAllCities);

// Ruta para obtener una ciudad por su ID
router.get('/:id', cityController.getCityById);

// Ruta para modificar una ciudad por su ID
router.put('/:id', cityController.updateCity);

// Ruta para borrar una ciudad por su ID
router.delete('/:id', cityController.deleteCity);

module.exports = router;" > src/routes/cityRoutes.js
sleep 2

# Archivo index.js en la carpeta src
echo "const express = require('express');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const db = require('./config/db');
const cityRoutes = require('./routes/cityRoutes');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());

app.use('/cities', cityRoutes);

app.listen(PORT, () => {
  console.log(\`Server is running on port \${PORT}\`);
});" > src/index.js

# Solicitar información al usuario y construir MONGODB_URI
echo "Ingresa la información de la base de datos:"
read -p "Nombre de usuario de MongoDB: " DB_USERNAME
read -sp "Contraseña de MongoDB: " DB_PASSWORD
echo ""
read -p "Nombre de la base de datos: " DB_NAME

MONGODB_URI="mongodb+srv://$DB_USERNAME:$DB_PASSWORD@cluster1.74gyrrd.mongodb.net/$DB_NAME?retryWrites=true&w=majority"
echo "MONGODB_URI=$MONGODB_URI" >> .env

# Dar instrucciones al usuario
echo "Configuración completa. Ahora, configura las variables restantes en el archivo .env y ejecuta 'npm start' para iniciar el servidor."
