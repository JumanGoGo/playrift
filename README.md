# PlayRift 🎮

Aplicación Flutter multiplataforma que consume la API REST de [RAWG Video Games Database](https://rawg.io/apidocs) para mostrar un catálogo interactivo de videojuegos con una interfaz moderna inspirada en tiendas digitales como Steam, Epic Games Store y PlayStation Store.

---

## Índice

- [Descripción](#descripción)
- [Requisitos previos](#requisitos-previos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Arquitectura MVC](#arquitectura-mvc)
- [Funcionalidades implementadas](#funcionalidades-implementadas)
- [Filtro de contenido adulto](#filtro-de-contenido-adulto)
- [API utilizada](#api-utilizada)
- [Conceptos aplicados](#conceptos-aplicados)
- [Paleta de colores](#paleta-de-colores)
- [Dependencias](#dependencias)
- [Tecnologías usadas](#tecnologías-usadas)

---

## Descripción

PlayRift es una aplicación Flutter multiplataforma que permite explorar un catálogo de más de 500,000 videojuegos. Fue construida como proyecto educativo para practicar consumo de APIs REST, arquitectura MVC, manejo de estados y navegación en Flutter.

La interfaz sigue un diseño **dark premium** con estética de tienda de videojuegos digital, utilizando tipografía Inter para la UI general y Orbitron exclusivamente para el branding "PlayRift".

---

## Requisitos previos

| Herramienta | Versión mínima |
|---|---|
| Flutter SDK | 3.10.8 o superior |
| Dart SDK | ^3.10.8 |
| Android Studio o VS Code | Última versión estable |
| Git | Cualquier versión reciente |

Verifica tu entorno con:

```bash
flutter doctor
```

---

## Instalación y ejecución

### 1. Clonar el repositorio

```bash
git clone https://github.com/JumanGoGo/playrift.git
cd playrift
```

### 2. Configurar la API Key

Crea el archivo `lib/config/app_config.dart` (este archivo está en `.gitignore` por seguridad):

```dart
class AppConfig {
  static const String apiKey = 'TU_API_KEY_AQUI';
  static const String baseUrl = 'https://api.rawg.io/api';
}
```

Obtén tu API Key gratuita en [rawg.io/apidocs](https://rawg.io/apidocs).

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la aplicación

```bash
# En el emulador o dispositivo por defecto
flutter run

# En una plataforma específica
flutter run -d windows
flutter run -d chrome
flutter run -d <device_id>

# Ver dispositivos disponibles
flutter devices
```

---

## Estructura del proyecto

```
lib/
├── config/
│   └── app_config.dart          ← API Key y URL base (no incluido en el repo)
├── models/
│   ├── game_model.dart          ← Modelos: Game, Platform, EsrbRating
│   └── genre_model.dart         ← Modelo: Genre
├── services/
│   ├── game_service.dart        ← Peticiones HTTP a la API RAWG
│   └── favorites_service.dart   ← Persistencia local con SharedPreferences
└── views/
    ├── home_page.dart           ← Inicio: carrusel destacado, top rated, géneros
    ├── browse_page.dart         ← Explorador: búsqueda, filtros, grid 2 columnas
    ├── detail_page.dart         ← Detalle: screenshots, saga, descripción completa
    ├── favorites_page.dart      ← Favoritos: gestión local con swipe-to-delete
    └── widgets/
        └── mature_overlay.dart  ← Overlay para ocultar contenido adulto
```

---

## Arquitectura MVC

El proyecto implementa el patrón **Modelo - Vista - Controlador**:

```
API REST (RAWG)
      │
      ▼
GameService / FavoritesService   ← Controlador / Servicio
      │
      ▼
Game / Genre / Platform          ← Modelo (deserialización JSON)
      │
      ▼
HomePage / BrowsePage /          ← Vista (UI + interacción)
DetailPage / FavoritesPage
```

Cada capa tiene una única responsabilidad:
- **Servicio**: comunicarse con la API REST y con el almacenamiento local
- **Modelo**: definir la estructura de datos y convertir JSON ↔ objetos Dart
- **Vista**: renderizar datos y manejar la interacción del usuario

---

## Funcionalidades implementadas

### Pantalla principal (`HomePage`)
- Carrusel automático de juegos destacados (auto-scroll cada 5 segundos con loop)
- Banner hero de 300px con badge "DESTACADO" y gradiente superpuesto
- Sección de **Top Rated**: scroll horizontal de cards con ranking numerado
- Chips de géneros obtenidos dinámicamente desde la API
- Botón de **juego aleatorio** (icono casino) para descubrir juegos al azar
- Carga paralela de datos con `Future.wait` (3 endpoints simultáneos)
- Pull-to-refresh con `RefreshIndicator`

### Explorador (`BrowsePage`)
- Búsqueda en tiempo real con **debounce de 500ms** para optimizar peticiones
- Filtro por género con chips interactivos
- Ordenamiento configurable: por rating, fecha, popularidad
- **Grid de 2 columnas** con cards de proporción 0.72
- Paginación con botón "Cargar más"
- Botón de favorito integrado en cada card (corazón rosa)
- Manejo de 4 estados: cargando, error, vacío y con datos

### Detalle del juego (`DetailPage`)
- **Hero animation**: la portada transiciona con animación desde la card
- Banner hero de 360px con gradiente superpuesto
- Botones circulares flotantes: retroceso y favorito
- Métricas visuales en cards: rating (ámbar), Metacritic (color dinámico), playtime
- Descripción completa obtenida desde el endpoint de detalle (`description_raw`)
- Chips de géneros y plataformas
- Galería de **screenshots** en scroll horizontal (290×180px)
- Sección de **juegos de la misma saga** en scroll horizontal
- Carga asíncrona independiente de screenshots, saga y descripción

### Favoritos (`FavoritesPage`)
- Lista de juegos guardados localmente con `SharedPreferences`
- **Swipe-to-delete** (deslizar para eliminar) con confirmación visual
- Botón de corazón para remover favoritos directamente
- Contador de juegos favoritos en el header
- Empty state con ilustración e instrucciones al usuario
- Sincronización automática al cambiar de pestaña

### Navegación
- Barra de navegación inferior con **efecto glass** (`BackdropFilter` blur 30)
- `IndexedStack` para preservar el estado entre pestañas
- Navegación cruzada: tap en género desde Home abre Browse filtrado
- `GlobalKey` para comunicación entre widgets (refresh de favoritos, filtro por género)

---

## Filtro de contenido adulto

PlayRift implementa un sistema de detección de contenido adulto basado en **palabras clave** mediante expresión regular aplicada sobre:
- Nombre del juego
- Tags del juego

Cuando se detecta contenido adulto, la imagen se reemplaza por un overlay oscuro con badge "18+" y texto "CONTENIDO RESTRINGIDO". Este filtro se aplica en todas las vistas: Home, Browse, Detail y Favoritos.

---

## API utilizada

**RAWG Video Games Database** — [rawg.io](https://rawg.io)

| Endpoint | Uso |
|---|---|
| `GET /games` | Lista paginada de juegos con búsqueda y filtros |
| `GET /games/{id}` | Detalle completo del juego (incluye `description_raw`) |
| `GET /games/{id}/screenshots` | Capturas de pantalla del juego |
| `GET /games/{id}/game-series` | Juegos de la misma saga |
| `GET /genres` | Lista de géneros disponibles |

Parámetros utilizados:

| Parámetro | Descripción |
|---|---|
| `key` | API Key de autenticación |
| `page` | Número de página para paginación |
| `page_size` | Cantidad de resultados por página (máx. 40) |
| `search` | Búsqueda por nombre de juego |
| `genres` | Filtrar por ID de género |
| `ordering` | Ordenamiento: `-rating`, `-added`, etc. |

---

## Conceptos aplicados

| Concepto | Dónde se usa |
|---|---|
| `fromJson` / `toJson` + `factory` | `game_model.dart`, `genre_model.dart` |
| `Future` + `async/await` | `game_service.dart`, todas las vistas |
| `Future.wait` (carga paralela) | `home_page.dart` — 3 endpoints simultáneos |
| `setState` | Manejo de estados reactivo en todas las vistas |
| `Navigator.push` | Navegación entre pantallas |
| `Hero` animation | Transición de portada entre lista y detalle |
| Debounce con `Timer` | `browse_page.dart` — búsqueda optimizada |
| `PageView` + auto-scroll | `home_page.dart` — carrusel de destacados |
| `BackdropFilter` (glass effect) | `main.dart` — barra de navegación |
| `IndexedStack` | `main.dart` — preservación de estado entre tabs |
| `GlobalKey` | `main.dart` — comunicación cross-widget |
| `SharedPreferences` | `favorites_service.dart` — persistencia local |
| `Dismissible` (swipe-to-delete) | `favorites_page.dart` — eliminar favoritos |
| `RefreshIndicator` | `home_page.dart` — pull-to-refresh |
| `RegExp` (expresión regular) | `game_model.dart` — filtro de contenido adulto |
| Operador `??` (null-safety) | Todos los `fromJson` |
| `copyWith` pattern | `game_model.dart` — `copyWithDescription()` |

---

## Paleta de colores

| Color | Hex | Uso |
|---|---|---|
| Navy Black | `#0A0E1A` | Fondo principal |
| Dark Surface | `#141829` | Cards y contenedores |
| Border | `#1E2340` | Bordes sutiles |
| Violet | `#8B5CF6` | Acento primario, navegación activa |
| Cyan | `#06B6D4` | Acento secundario |
| Amber | `#FBBF24` | Ratings y estrellas |
| Pink | `#EC4899` | Favoritos (corazón) |
| Emerald | `#10B981` | Metacritic alto (≥80) |
| Red | `#EF4444` | Errores, contenido restringido |
| Indigo | `#A5B4FC` | Chips de géneros |
| Slate | `#64748B` | Texto secundario |
| Light | `#F1F5F9` | Texto principal |

---

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  google_fonts: ^8.0.2
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## Tecnologías usadas

- **Flutter 3.x** — Framework UI multiplataforma
- **Dart 3.x** — Lenguaje de programación
- **Material Design 3** — Sistema de diseño (`useMaterial3: true`)
- **Google Fonts** — Tipografía Inter (UI) + Orbitron (branding)
- **http** — Cliente HTTP para consumo de APIs REST
- **SharedPreferences** — Almacenamiento local clave-valor
- **RAWG API** — Base de datos pública de videojuegos (+500,000 títulos)

---

*Proyecto educativo desarrollado por Alejandro Juarez — 06IDESVA DSE II, Abril 2026*
