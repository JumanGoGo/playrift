# PlayRift 🎮

Aplicación Flutter educativa. Consume la API REST de [RAWG Video Games Database](https://rawg.io/apidocs) para mostrar un catálogo interactivo de videojuegos.

---

## Índice

- [Descripción](#descripción)
- [Capturas de pantalla](#capturas-de-pantalla)
- [Requisitos previos](#requisitos-previos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Arquitectura MVC](#arquitectura-mvc)
- [Funcionalidades implementadas](#funcionalidades-implementadas)
- [API utilizada](#api-utilizada)
- [Conceptos aplicados](#conceptos-aplicados)
- [Dependencias](#dependencias)

---

## Descripción

PlayRift es una aplicación Flutter multiplataforma que permite explorar un catálogo de más de 500,000 videojuegos. Fue construida como proyecto educativo para practicar consumo de APIs REST, arquitectura MVC, manejo de estados y navegación en Flutter.

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
│   └── app_config.dart         ← API Key y URL base (no incluido en el repo)
├── models/
│   ├── game_model.dart         ← Modelo principal: Game, Platform
│   └── genre_model.dart        ← Submodelo: Genre
├── services/
│   └── game_service.dart       ← Peticiones HTTP a la API RAWG
└── views/
    ├── home_page.dart          ← Pantalla principal con destacados y ranking
    ├── browse_page.dart        ← Búsqueda, filtros por género y paginación
    └── detail_page.dart        ← Detalle completo del juego
```

---

## Arquitectura MVC

El proyecto implementa el patrón **Modelo - Vista - Controlador**:

```
API REST (RAWG)
      │
      ▼
GameService          ← hace las peticiones HTTP (Controlador o Servicio)
      │
      ▼
Game / Genre         ← deserializa el JSON con fromJson() (Modelo)
      │
      ▼
HomePage             ← muestra los datos al usuario (Vista)
BrowsePage
DetailPage
```

Cada capa tiene una única responsabilidad:
- **Servicio**: hablar con la API y retornar datos crudos
- **Modelo**: definir la estructura de datos y convertir JSON a objetos Dart
- **Vista**: mostrar datos y manejar la interacción del usuario

---

## Funcionalidades implementadas

### Pantalla principal (`HomePage`)
- Carrusel horizontal de juegos destacados con portadas reales
- Chips de géneros obtenidos dinámicamente de la API
- Ranking de los 20 juegos mejor valorados con miniaturas
- Botón de juego aleatorio (ruleta para jugadores indecisos)
- Carga paralela de datos con `Future.wait`

### Explorador (`BrowsePage`)
- Búsqueda en tiempo real con **debounce de 500ms** para optimizar peticiones
- Filtro por género con chips interactivos animados
- Paginación con botón "Cargar más"
- Manejo de los 4 estados: cargando, error, vacío y con datos

### Detalle del juego (`DetailPage`)
- Hero animation: la portada vuela desde la tarjeta hasta el detalle
- Imagen de portada como banner expandible (SliverAppBar)
- Métricas visuales: rating, Metacritic con color dinámico y tiempo de juego
- Chips de géneros
- Iconos de plataformas con color por plataforma (PC, PlayStation, Xbox, Nintendo, iOS, Android)
- Fecha de lanzamiento

---

## API utilizada

**RAWG Video Games Database** — [rawg.io](https://rawg.io)

| Endpoint | Uso |
|---|---|
| `GET /games` | Lista paginada de juegos con búsqueda y filtros |
| `GET /genres` | Lista de géneros disponibles |

Parámetros utilizados:

| Parámetro | Descripción |
|---|---|
| `key` | API Key de autenticación |
| `page` | Número de página para paginación |
| `page_size` | Cantidad de resultados por página (máx. 40) |
| `search` | Búsqueda por nombre de juego |
| `genres` | Filtrar por ID de género |
| `ordering` | Ordenamiento: `-rating`, `-added` |

---

## Conceptos aplicados

| Concepto | Dónde se usa |
|---|---|
| `fromJson` + `factory` | `game_model.dart`, `genre_model.dart` |
| `Future` + `async/await` | `game_service.dart`, todas las vistas |
| `Future.wait` (paralelo) | `home_page.dart` — carga simultánea de 3 endpoints |
| `setState` | Manejo de estados en todas las vistas |
| `Navigator.push` | Navegación entre pantallas |
| `Hero` animation | Transición de portada entre lista y detalle |
| Debounce con `Timer` | `browse_page.dart` — búsqueda optimizada |
| `CustomScrollView` + `SliverAppBar` | `home_page.dart`, `detail_page.dart` |
| `NeverScrollableScrollPhysics` | Lista anidada en `home_page.dart` |
| Operador `??` (null-safety) | Todos los `fromJson` |

---

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0

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
- **http** — Cliente HTTP para consumo de APIs REST
- **RAWG API** — Base de datos pública de videojuegos

---

*Proyecto educativo desarrollado por Alejandro Juarez — IDESVA DSE II, Marzo 2026*