import os

def eliminar_json_y_carpetas_vacias(ruta):
    for directorio_actual, carpetas, archivos in os.walk(ruta, topdown=False):
        for archivo in archivos:
            if archivo.endswith('.json'):
                ruta_completa = os.path.join(directorio_actual, archivo)
                os.remove(ruta_completa)
                print(f"Archivo eliminado: {ruta_completa}")

        for carpeta in carpetas:
            ruta_carpeta = os.path.join(directorio_actual, carpeta)
            if not os.listdir(ruta_carpeta):
                os.rmdir(ruta_carpeta)
                print(f"Carpeta vacía eliminada: {ruta_carpeta}")

# Ruta inicial desde la cual se iniciará la búsqueda y eliminación
ruta_inicial = './'

eliminar_json_y_carpetas_vacias(ruta_inicial)
