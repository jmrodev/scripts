import os
import shutil
import hashlib

# Define los tipos de archivo que deseas buscar
PHOTO_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff'}
VIDEO_EXTENSIONS = {'.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv','.3gp','.m4v'}

# Directorios de origen y destino
SOURCE_DIR = '/home/jmro/Escritorio/fotos'
PHOTO_DIR = '/home/jmro/Escritorio/foto_filtrada'
VIDEO_DIR = '/home/jmro/Escritorio/videos'
DUPLICATES_DIR = '/home/jmro/Escritorio/duplicados'

# Crear directorios de destino si no existen
os.makedirs(PHOTO_DIR, exist_ok=True)
os.makedirs(VIDEO_DIR, exist_ok=True)
os.makedirs(DUPLICATES_DIR, exist_ok=True)

# Función para calcular el hash MD5 de un archivo
def calculate_md5(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

# Diccionarios para guardar hashes y rutas de archivos
photo_hashes = {}
video_hashes = {}

# Función principal para organizar archivos
def organize_files(src_dir):
    for root, _, files in os.walk(src_dir):
        for file in files:
            file_path = os.path.join(root, file)
            file_ext = os.path.splitext(file)[1].lower()

            if file_ext in PHOTO_EXTENSIONS or file_ext in VIDEO_EXTENSIONS:
                # Calcula el hash del archivo
                file_hash = calculate_md5(file_path)

                # Determina el directorio de destino
                if file_ext in PHOTO_EXTENSIONS:
                    dest_dir = PHOTO_DIR
                    hash_dict = photo_hashes
                elif file_ext in VIDEO_EXTENSIONS:
                    dest_dir = VIDEO_DIR
                    hash_dict = video_hashes

                # Comprueba si el archivo es un duplicado
                if file_hash in hash_dict:
                    duplicate_path = os.path.join(DUPLICATES_DIR, file)
                    shutil.move(file_path, duplicate_path)
                    print(f"Duplicado movido: {file_path} -> {duplicate_path} (idéntico a {hash_dict[file_hash]})")
                else:
                    # Mueve el archivo al directorio de destino
                    dest_path = os.path.join(dest_dir, file)
                    shutil.move(file_path, dest_path)
                    hash_dict[file_hash] = dest_path
                    print(f"Movido: {file_path} -> {dest_path}")

# Ejecuta la función para organizar archivos
organize_files(SOURCE_DIR)
