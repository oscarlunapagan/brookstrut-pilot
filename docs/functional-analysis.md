# Brookstrut: análisis funcional

**Estado:** borrador para revisar.

## 1. Introducción

### 1.1 Objetivo

Este documento describe qué hace la aplicación Brookstrut y cómo lo hace: sus actores, sus casos de uso, su modelo de datos y sus procesos. Es el punto de partida para especificar los evolutivos.

### 1.2 Audiencia

Quien analice, desarrolle o revise un evolutivo de Brookstrut.

### 1.3 Definiciones

| Concepto | Descripción |
|---|---|
| Región | Zona geográfica que agrupa tiendas, como "Boston Area". Una región es la región por defecto |
| Tienda | Punto de venta de la cadena. Tiene un tipo, una dirección, una región y una fecha de apertura |
| Tipo de tienda | `Branch` (sucursal) o `Flagship` (tienda insignia) |
| Producto | Artículo del catálogo, con un tipo y un precio de venta recomendado (PVP) |
| Tipo de producto | `Food`, `Fruit`, `Miscellaneous`, `Snacks` o `Soap` |
| PVP | Precio de venta recomendado del producto (`MSRP`). Es el precio por defecto en todas las tiendas |
| Inventario de la tienda | Productos que vende una tienda. Un producto puede no venderse en todas las tiendas |
| Precio de tienda | Precio del producto en una tienda concreta. Si no está informado, se usa el PVP |
| Oferta | Descuento en porcentaje sobre el precio de un producto en una tienda, con fecha de inicio y de fin |
| Venta | Línea de venta: un producto, una cantidad y un precio unitario, en una tienda y en una fecha |
| Transacción | Conjunto de líneas de venta de un mismo pedido, identificadas por el mismo `TRANSACTION_ID` |
| Generación de ventas | Proceso que crea ventas aleatorias para simular la actividad de las tiendas |

### 1.4 Documentos relacionados

| Documento | Descripción |
|---|---|
| `README.md` | Estructura del repositorio y despliegue |
| `docs/requirements/` | Requisitos de cada evolutivo |

## 2. Visión general del sistema

Brookstrut es una aplicación Oracle APEX 26.1 de una cadena de tiendas. Permite mantener las regiones, las tiendas, los productos y el inventario de cada tienda, consultar el historial de ventas desde muchas vistas distintas y analizarlo en informes. Como no tiene ventas reales, incluye procesos que las generan al azar.

```text
                       ┌──────────────────────────────────────────┐
  Usuario ──────────── │ Aplicación APEX (app 100, alias BROOKSTRUT)
  (cuenta de APEX)     │  - Mantenimiento: regiones, tiendas,      │
                       │    productos e inventario                 │
                       │  - Consulta del historial de ventas       │
                       │  - Informes de ventas                     │
                       │  - Generación de ventas y administración  │
                       └──────────────────┬───────────────────────┘
                                          │
                       ┌──────────────────┴───────────────────────┐
                       │ Base de datos (esquema de la app)         │
                       │  - Tablas OOW_DEMO_*                      │
                       │  - Paquetes de generación de datos,       │
                       │    registro de eventos y temporizador     │
                       └──────────────────────────────────────────┘
```

La interfaz está en inglés. Los nombres de páginas de este documento son los de la aplicación.

## 3. Requisitos funcionales

### 3.1 Catálogo de requisitos funcionales

| Código | Requisito funcional | Versión | Prioridad |
|---|---|---|---|
| RF000 | Requisitos iniciales: la aplicación tal como la instala la galería de APEX 26.1 | 26.1.1 | - |

Cada evolutivo añade aquí sus requisitos, con el código que le asigne su documento de requisitos.


## 4. Requisitos no funcionales

| Código | Requisito | Descripción |
|---|---|---|
| RNF-001 | Plataforma | Oracle Autonomous Database 26ai y Oracle APEX 26.1 |
| RNF-002 | Autenticación | Cuentas de APEX del workspace ("Oracle APEX Accounts") |
| RNF-003 | Autorización | No hay esquemas de autorización: cualquier usuario autenticado accede a todas las páginas y acciones, incluida la administración |
| RNF-004 | Interfaz | Universal Theme, con selección de estilo por el usuario (página 10010) |
| RNF-005 | Despliegue | Desde el repositorio, con Liquibase de SQLcl: migraciones, código y app en APEXlang |

## 5. Casos de uso

### 5.1 Catálogo de actores

#### Usuario

| | |
|---|---|
| Tipo | Principal |
| Descripción de su rol | Cualquier persona con cuenta de APEX en el workspace |
| Objetivos | Mantener las regiones, las tiendas, los productos y el inventario. Consultar y analizar las ventas. Generar ventas de prueba y administrar la aplicación |
| Casos de uso relacionados | Todos |

#### Proceso de generación de ventas

| | |
|---|---|
| Tipo | Secundario |
| Descripción de su rol | Lógica de la base de datos que crea ventas aleatorias |
| Objetivos | Simular la actividad de las tiendas para que los informes tengan datos |
| Casos de uso relacionados | CU06 Generar ventas, CU09 Administración |

### 5.2 Catálogo de casos de uso

| ID | Caso de uso | Páginas | Actores |
|---|---|---|---|
| CU01 | Identificación del usuario | 101 | Usuario |
| CU02 | Mantenimiento de regiones | 8, 9, 15 | Usuario |
| CU03 | Mantenimiento de tiendas | 6, 7 | Usuario |
| CU04 | Mantenimiento de productos | 11, 12 | Usuario |
| CU05 | Inventario de la tienda | 7, 27 | Usuario |
| CU06 | Generar ventas | 5, 28, 29, 30, 31, 41 | Usuario, proceso de generación de ventas |
| CU07 | Consultar el historial de ventas | 2, 13, 23, 36, 38, 42, 43, 45, 46, 50, 51 | Usuario |
| CU08 | Informes de ventas | 3, 5, 18, 19, 20, 22, 25, 27, 32 | Usuario |
| CU09 | Administración | 4, 10020, 17, 21, 24, 26, 33, 34, 35, 39, 40, 10010 | Usuario, proceso de generación de ventas |

### 5.3 Descripción de los casos de uso

Se describen los casos de uso que mantienen datos o tienen reglas. Los de consulta (CU07 y CU08) se resumen en el [mapa de páginas](#73-mapa-de-páginas).

#### CU03 Mantenimiento de tiendas

| | |
|---|---|
| Nombre del caso de uso | Mantenimiento de tiendas |
| Descripción | Alta, consulta, modificación y baja de las tiendas de la cadena |
| Actores participantes | Usuario (P) |

**Flujo básico**

*Consulta*

- C1. El usuario accede a "Stores" (página 6).
- C2. El sistema muestra las tiendas con una búsqueda facetada: nombre, tipo, ciudad, estado y región, y sus ventas.
- C3. El usuario selecciona una tienda, y el sistema muestra su formulario (página 7).

*Alta*

- N1. Desde la página 6, el usuario pulsa "Create".
- N2. El sistema muestra el formulario vacío. Ver [formulario de tienda](#721-formulario-de-tienda-página-7).
- N3. El usuario informa los datos, selecciona los productos que vende la tienda y pulsa "Create".
- N4. El sistema valida los datos obligatorios.
- N5. El sistema crea la tienda y su inventario, y vuelve a la página 6.

*Actualización*

- A1. Se aplica el flujo de consulta, de C1 a C3.
- A2. El usuario modifica los datos o los productos y pulsa "Apply Changes".
- A3. El sistema valida los datos obligatorios.
- A4. El sistema guarda la tienda y su inventario con los productos seleccionados, y vuelve a la página 6 con el mensaje "Inventory updated."

*Baja*

- B1. Se aplica el flujo de consulta, de C1 a C3.
- B2. El usuario pulsa "Delete" y confirma.
- B3. El sistema borra la tienda y vuelve a la página 6.

**Flujos alternativos**

- En los puntos N4 y A3, si falta el nombre, la dirección o la ciudad, el sistema no guarda y muestra el error junto al campo.
- En el punto B3, si la tienda tiene ventas o inventario, la base de datos rechaza el borrado por sus claves ajenas, y el sistema muestra el error.

**Condiciones de entrada:** el usuario está autenticado.

**Condiciones de salida:** la tienda y su inventario quedan guardados o borrados.

**Requisitos vinculados:** RF000.

#### CU04 Mantenimiento de productos

| | |
|---|---|
| Nombre del caso de uso | Mantenimiento de productos |
| Descripción | Alta, consulta, modificación y baja de los productos del catálogo |
| Actores participantes | Usuario (P) |

**Flujo básico**

- C1. El usuario accede a "Products" (página 11), un informe interactivo con los productos y sus ventas.
- C2. El usuario selecciona un producto o pulsa "Create", y el sistema muestra el formulario (página 12): nombre\*, tipo (lista), descripción y PVP.
- C3. El usuario guarda, y el sistema valida que el nombre no esté vacío ni sea solo espacios.

**Flujos alternativos**

- En el punto C3, si el nombre está vacío, el sistema no guarda y muestra el error junto al campo.

**Condiciones de entrada:** el usuario está autenticado.

**Requisitos vinculados:** RF000.

#### CU05 Inventario de la tienda

| | |
|---|---|
| Nombre del caso de uso | Inventario de la tienda |
| Descripción | Qué productos vende cada tienda, y a qué precio y con qué oferta |
| Actores participantes | Usuario (P) |

**Flujo básico**

- I1. El inventario se mantiene desde el formulario de la tienda (CU03), con una lista de selección doble ("Store Inventory") de todos los productos.
- I2. El usuario consulta la disponibilidad de cada producto por tienda en "Product Availability" (página 27).

**Reglas**

- Un producto que no está en el inventario de una tienda no se vende en ella.

**Requisitos vinculados:** RF000.

#### CU06 Generar ventas

| | |
|---|---|
| Nombre del caso de uso | Generar ventas |
| Descripción | Crear ventas aleatorias para simular la actividad de las tiendas |
| Actores participantes | Usuario (P), proceso de generación de ventas (S) |

**Flujo básico**

- G1. El usuario accede a "Generate Transactions" (página 28) y elige generar una transacción, cien o un volumen de días.
- G2. El sistema llama a `oow_demo_gen_data_pkg`: `generate_transaction` para una, `exec_100_transactions` para cien y `oow_demo_gen_sales_data` para un volumen.
- G3. Por cada día, tienda y pedido, el proceso recorre el inventario de la tienda y decide al azar si vende cada producto.
- G4. Por cada producto vendido, el proceso elige una cantidad de 1 a 10 y el precio unitario.
- G5. El proceso inserta las líneas de venta, con el mismo `TRANSACTION_ID` para todas las del pedido, y registra la ejecución en `OOW_DEMO_HIST_GEN_LOG`.
- G6. El sistema muestra las ventas generadas (páginas 29 a 31) o el resultado de la carga (página 41).

**Flujos alternativos**

- En el punto G5, si hay un error, el proceso lo registra en `OOW_DEMO_EVENT_LOG` con su traza.

**Requisitos vinculados:** RF000.

#### CU09 Administración

Opciones de "Administration" (página 4):

- **Reiniciar los datos de ejemplo** (página 40), con volúmenes de S a 5XL. Borra las ventas y vuelve a generarlas con `oow_demo_sample_data` y `oow_demo_gen_data_pkg`.
- **Borrar el historial de ventas** (página 26).
- **Consultar el registro de eventos** (página 21) y el **registro de generación de ventas** (páginas 24 y 33 a 35).
- **Calendario de actividad** (página 17) y **páginas vistas** (página 39).
- **Opciones de configuración** (página 10020), con las build options de la app.

## 6. Procesos de la base de datos

| Paquete | Qué hace |
|---|---|
| `oow_demo_sample_data` | Carga y borra los datos de ejemplo: regiones, productos, tiendas e inventario (`load`, `remove`, `is_loaded`) |
| `oow_demo_gen_data_pkg` | Genera ventas aleatorias (CU06) |
| `oow_demo_event_pkg` | Registra eventos y errores en `OOW_DEMO_EVENT_LOG` (`log`) |
| `oow_demo_timing` | Mide el tiempo que tardan las páginas de historial en cargar |

Los triggers `BIU_*` de cada tabla asignan el `ID`, a partir de `SYS_GUID()`, y llevan la versión de fila (`ROW_VERSION_NUMBER`). Los de `OOW_DEMO_STORES` rellenan además `N1` a `N4` con valores aleatorios, y el de `OOW_DEMO_PREFERENCES` registra quién y cuándo crea o modifica cada preferencia.

## 7. Información de soporte

### 7.1 Diccionario de datos

Todas las tablas usan un `ID` numérico como clave primaria, que asigna su trigger. Las de mantenimiento tienen `ROW_VERSION_NUMBER`, que empieza en 1 y aumenta en cada modificación.

#### OOW_DEMO_REGIONS

Regiones de la cadena.

| Atributo | Tipo | Por defecto | Opcional | Comentarios |
|---|---|---|---|---|
| `ID` | N | | No | PK |
| `REGION_NAME` | A(255) | | Sí | Nombre |
| `REGION_ZOOM` | A(50) | | Sí | Nivel de zoom del mapa |
| `REGION_LAT`, `REGION_LNG` | N(9,6) | | Sí | Centro del mapa |
| `REGION_COLOR` | A(7) | | Sí | Color en hexadecimal |
| `IS_DEFAULT_YN` | A(1) | | Sí | `Y` en la región por defecto |

#### OOW_DEMO_STORES

Tiendas.

| Atributo | Tipo | Por defecto | Opcional | Comentarios |
|---|---|---|---|---|
| `ID` | N | | No | PK |
| `STORE_NAME` | A(255) | | Sí | Obligatorio en el formulario |
| `STORE_TYPE` | A(50) | | Sí | `Branch` o `Flagship` |
| `STORE_ADDRESS` | A(255) | | Sí | Obligatorio en el formulario |
| `STORE_CITY` | A(50) | | Sí | Obligatorio en el formulario |
| `STORE_STATE` | A(50) | | Sí | |
| `STORE_ZIP` | A(12) | | Sí | |
| `STORE_LAT`, `STORE_LNG` | N(9,6) | | Sí | Posición en el mapa |
| `STORE_OPEN_DATE` | Fecha y hora | | Sí | Fecha de apertura |
| `REGION_ID` | N | | Sí | Región. Sin clave ajena a `OOW_DEMO_REGIONS` |
| `N1` a `N4` | N | Aleatorio | Sí | Valores de demostración para informes |

#### OOW_DEMO_ITEMS

Productos.

| Atributo | Tipo | Por defecto | Opcional | Comentarios |
|---|---|---|---|---|
| `ID` | N | | No | PK |
| `ITEM_TYPE` | A(255) | | No | Tipo de producto |
| `ITEM_NAME` | A(60) | | No | Nombre |
| `ITEM_DESC` | A(255) | | Sí | Descripción |
| `MSRP` | N | 1 | No | PVP |

#### OOW_DEMO_STORE_PRODUCTS

Inventario de cada tienda, con su precio y su oferta.

| Atributo | Tipo | Por defecto | Opcional | Comentarios |
|---|---|---|---|---|
| `ID` | N | | No | PK |
| `STORE_ID` | N | | Sí | FK a `OOW_DEMO_STORES` |
| `ITEM_ID` | N | | Sí | FK a `OOW_DEMO_ITEMS` |
| `ITEM_PRICE` | N | | Sí | Precio de tienda. Si es nulo, se usa el PVP |
| `DISCOUNT_PCT` | N | | Sí | Descuento de la oferta, en porcentaje |
| `SALE_START_DATE`, `SALE_END_DATE` | Fecha | | Sí | Periodo de la oferta |

No hay restricción que impida repetir un producto en la misma tienda.

#### OOW_DEMO_SALES_HISTORY

Líneas de venta.

| Atributo | Tipo | Por defecto | Opcional | Comentarios |
|---|---|---|---|---|
| `ID` | N | | No | PK |
| `STORE_ID` | N | | No | FK a `OOW_DEMO_STORES` |
| `PRODUCT_ID` | N | | No | FK a `OOW_DEMO_ITEMS` |
| `DATE_OF_SALE` | Fecha y hora | | Sí | Fecha de la venta |
| `QUANTITY` | N | 1 | Sí | Unidades |
| `ITEM_PRICE` | N | | Sí | Precio unitario cobrado |
| `TRANSACTION_ID` | A(30) | | Sí | Pedido al que pertenece la línea, con formato `AAAAMMDD-n` |
| `CREATED_ON` | Fecha y hora | | Sí | Lo asigna el trigger |
| `SALES_DATA` | A(4000) | | Sí | Copia de la línea en JSON. La rellena el trigger al insertar, si viene vacía |

#### Tablas técnicas

| Tabla | Contenido |
|---|---|
| `OOW_DEMO_EVENT_LOG` | Registro de eventos y errores: tipo (`MESSAGE`, `WARNING` o `ERROR`), nombre, detalle, mensaje y traza |
| `OOW_DEMO_HIST_GEN_LOG` | Una fila por ejecución de la generación de ventas: usuario, días, pedidos, inicio, fin y filas creadas |
| `OOW_DEMO_PREFERENCES` | Preferencias por nombre, en mayúsculas y únicas, con quién y cuándo las creó o modificó |

### 7.2 Formularios

#### 7.2.1 Formulario de tienda (página 7)

Los campos marcados con \* son obligatorios.

| Campo | Automático | Origen | Observaciones |
|---|---|---|---|
| Store Name \* | No | `STORE_NAME` | |
| Store Type | No | `STORE_TYPE` | Lista: `Branch` o `Flagship` |
| Store Address \* | No | `STORE_ADDRESS` | |
| Store City \* | No | `STORE_CITY` | |
| Store State | No | `STORE_STATE` | |
| Store Zip | No | `STORE_ZIP` | |
| Region | No | `REGION_ID` | Lista de regiones |
| Store Open Date | No | `STORE_OPEN_DATE` | |
| Store Lat, Store Lng | No | `STORE_LAT`, `STORE_LNG` | |
| Store Inventory | No | `OOW_DEMO_STORE_PRODUCTS` | Lista de selección doble con todos los productos |

#### 7.2.2 Formulario de producto (página 12)

| Campo | Automático | Origen | Observaciones |
|---|---|---|---|
| Item Name \* | No | `ITEM_NAME` | No puede ser solo espacios |
| Item Type | No | `ITEM_TYPE` | Lista de tipos |
| Item Desc | No | `ITEM_DESC` | |
| MSRP | No | `MSRP` | PVP |

### 7.3 Mapa de páginas

| Área | Páginas |
|---|---|
| Inicio | 1 Home, 14 About |
| Regiones | 8 Store Regions, 9 Region, 15 Region Stores |
| Tiendas | 6 Stores Report, 7 Store, 3 Store (rendimiento: ventas de los últimos 30 días frente a los 30 anteriores, e inventario con precio de venta) |
| Productos | 11 Products, 12 Product, 27 Product Availability |
| Historial de ventas | 2, 38 Content Row; 13, 50 Classic; 23 Interactive Grid; 51 Interactive Report; 42 Calendar; 43 Recent Sales; 45 Smart Search; 46 Cards; 36 Transaction Detail |
| Informes | 19 Reports (índice), 5 Sales Dashboard, 18 Sales by Product, 20 Sales by Store by Day, 22 Sales by Store by Week, 25 Sales by Product and Store by Week, 32 Table Counts |
| Generación de ventas | 28 Generate Transactions, 29 Generate Transaction, 30 Transaction, 31 100 Transactions Generated, 41 Load Data |
| Administración | 4 Administration, 17 Activity Calendar, 16 Top Users, 21 Event Log, 24 Sales History Generation Log, 26 Remove Transaction History, 33 Transaction Log, 34 y 35 Transaction Summary, 39 Page Views, 40 Reset Sample Data, 10010 Theme Style Selection, 10020 Configuration Options |
| Acceso | 101 Login |

### 7.4 Datos de ejemplo

Instalados con la app en el entorno de desarrollo:

| Entidad | Volumen |
|---|---|
| Regiones | 4. Boston Area es la región por defecto |
| Tiendas | 15: 10 `Branch` y 5 `Flagship` |
| Productos | 18, de 5 tipos, con PVP entre 1,59 y 25 |
| Inventario | 118 productos en tiendas. 25 con precio de tienda y 6 con descuento |
| Ventas | 5.000 líneas en 176 transacciones |
