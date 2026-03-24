# AtoM Portable + Asistente IA

**Access to Memory (AtoM) 2.10.0** con **Asistente IA archivístico** integrado, para instalación local en Windows usando Docker.
**Estado:** En desarrollo / Beta. Probado en Windows 10/11 con Docker Desktop.

---

## ¿Qué incluye?

- **AtoM 2.10.0** — aplicación web de descripción archivística basada en normas ICA (ISAD-G, ISAAR, ISDIAH, etc.)
- **Asistente IA** — herramienta de apoyo a la descripción archivística que usa modelos de IA locales (Ollama) para sugerir campos ISAD(G) y extraer metadatos de documentos. Funciona 100% en local, sin enviar datos a servidores externos.

---

## Requisitos

| Requisito | Detalle |
|---|---|
| Sistema operativo | Windows 10 / 11 (64 bits) |
| Docker Desktop | Versión 4.x o superior — [descargar](https://www.docker.com/products/docker-desktop/) |
| Espacio en disco | Mínimo 8 GB (recomendado 16 GB) |
| Internet | Solo durante la instalación inicial |
| Ollama (opcional) | Para el Asistente IA — [descargar](https://ollama.com) |

---

## Instalación

### Paso 1 — Primera vez (requiere internet)

1. Instale **Docker Desktop** y ábralo. Espere a que el icono de la ballena esté quieto.
2. Descomprima este paquete en la ubicación deseada (cualquier unidad: `C:\AtomPortable`, `D:\AtomPortable`, `E:\AtomPortable`...).
3. Ejecute `1_preparar_atom.bat`.
   - Descarga el código fuente de AtoM desde GitHub (~60 MB)
   - Construye la imagen Docker (~10-20 min)
   - Descarga y guarda todas las imágenes para uso offline
   - Inicializa la base de datos

### Paso 2 — Uso diario

1. Abra Docker Desktop.
2. Ejecute `2_iniciar_atom.bat`.
3. Acceda a:
   - **AtoM:** `http://localhost:8080`
   - **Asistente IA:** `http://localhost:8081`

### Paso 3 — Antes de apagar o desconectar

Ejecute siempre `3_detener_atom.bat` para evitar corrupción de datos.

---

## Credenciales por defecto

| Campo | Valor |
|---|---|
| Usuario | `admin@atom.local` |
| Contraseña | `Admin2024!` |

> ⚠️ **Cambie la contraseña** tras el primer acceso: menú superior derecho → *Admin → Mi perfil*.

---

## Asistente IA

Asistente IA
El asistente (http://localhost:8081) requiere Ollama instalado en el equipo con al menos un modelo descargado. Ningún dato sale del equipo.
Modelo recomendado
El modelo recomendado es gpt-oss:20b (Microsoft Phi-4 de 20B parámetros), que ofrece el mejor equilibrio entre calidad de respuesta y rendimiento en tareas archivísticas en español:
bashollama pull gpt-oss:20b
Otros modelos compatibles:
ModeloTamañoCalidadRAM mínimagpt-oss:20b~13 GB⭐⭐⭐⭐⭐ Recomendado16 GBllama3.2~2 GB⭐⭐⭐ Bueno8 GBmistral~4 GB⭐⭐⭐⭐ Muy bueno8 GBllama3.1:8b~5 GB⭐⭐⭐⭐ Muy bueno8 GB
Tips para obtener mejores resultados
📋 Para ISAD(G):

Cuanto más texto descriptivo incluya, mejores serán las sugerencias. Un párrafo mínimo.
Incluya información sobre el productor, las fechas y el contenido del fondo o serie.
Si el resultado no es satisfactorio, añada más contexto y vuelva a generar.
Los campos que el modelo no puede inferir del texto los omite — es el comportamiento correcto.

🏷️ Para Metadatos:

Pegue el texto completo del documento, no solo el encabezado.
Para documentos administrativos (actas, informes, circulares) funciona especialmente bien.
Las palabras clave generadas pueden usarse directamente como puntos de acceso en AtoM.

⚡ Rendimiento:

La primera consulta tarda más porque el modelo se carga en memoria (~30 seg con gpt-oss:20b).
Las consultas siguientes son más rápidas mientras Ollama permanezca activo.
Si el equipo tiene GPU compatible, Ollama la usará automáticamente para acelerar las respuestas.
Con gpt-oss:20b se recomienda cerrar otras aplicaciones pesadas durante el uso.

🔄 Si la respuesta no es correcta:

Reformule el texto de entrada con más detalle.
Cambie a un modelo más potente si dispone de más RAM.
El botón Generar sugeren

El asistente (`http://localhost:8081`) requiere **Ollama** instalado en el equipo con al menos un modelo descargado.

### Instalar Ollama

1. Descargue e instale Ollama desde [ollama.com](https://ollama.com)
2. Descargue un modelo (ejemplos):
   ```
   ollama pull llama3.2
   ollama pull mistral
   ```
3. Configure el modelo en la barra inferior del asistente.

### Funcionalidades

- **ISAD(G):** pegue texto descriptivo → sugiere campos de la norma ISAD(G)
- **Metadatos:** pegue contenido de un documento → extrae metadatos principales

Todo funciona en local. Ningún dato sale del equipo.

---

## Estructura de archivos

```
AtomPortable/
├── 1_preparar_atom.bat      ← Ejecutar UNA VEZ
├── 2_iniciar_atom.bat       ← Uso diario
├── 3_detener_atom.bat       ← Antes de apagar
├── docker-compose.yml
├── .env
├── INSTRUCCIONES.html
├── README.md
├── config/
│   ├── nginx.conf
│   └── mysqld.cnf
├── asistente-ia/
│   └── index.html           ← Interfaz del Asistente IA
├── datos/                   ← Base de datos (persistente)
├── uploads/                 ← Archivos subidos a AtoM
└── images/                  ← Imágenes Docker para uso offline
```

---

## Tecnologías

- [AtoM](https://www.accesstomemory.org) por [Artefactual Systems](https://www.artefactual.com) — Licencia AGPLv3
- [Docker](https://www.docker.com)
- [Ollama](https://ollama.com)
- Elasticsearch OSS 7.10.2
- Percona 8.0
- nginx 1.25

---

## Notas

- Esta instalación es para **uso local / pruebas**. Para producción consulte la [documentación oficial de AtoM](https://www.accesstomemory.org/docs/latest/).
- Los datos se almacenan en las carpetas `datos/` y `uploads/`. Haga copias de seguridad periódicas.
- El paquete ocupa ~8 GB tras la instalación completa.
