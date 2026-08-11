# Lena Reserva Backend

API REST para gestión de reservas.

## Tecnologías

* Node.js
* Express
* TypeScript
* Prisma ORM
* MySQL
* JWT
* Swagger
* Redis
* Docker

## Instalación

Clonar proyecto:

[git clone URL](https://github.com/Aurora194/Aplicaciones-M-viles.git)

Instalar dependencias:

npm install

## Variables de entorno

Crear:

.env

Ejemplo:

DATABASE_URL="mysql://root:password@mysql:3306/lena_reserva"

JWT_SECRET=lena_reserva_secret

## Base de datos

Sincronizar Prisma con la base de datos:

docker exec lena_reserva_api npx prisma db push

Generar Prisma:

docker exec lena_reserva_api npx prisma generate

## Ejecutar

Desarrollo con Docker:

docker compose up -d

Esto levanta los servicios:

* **API:** `http://localhost:3000`
* **MySQL:** `localhost:3307`
* **Redis:** `localhost:6379`

Para verificar que los contenedores estén ejecutándose:

docker ps

Para consultar los logs de la API:

docker logs lena_reserva_api --tail 50

### Prisma

Para sincronizar la base de datos con el esquema de Prisma:

docker exec lena_reserva_api npx prisma db push

Para generar el cliente de Prisma:

docker exec lena_reserva_api npx prisma generate

### Detener los servicios

docker compose down

Producción:

npm run build

npm start

## Documentación API

Swagger:

http://localhost:3000/api/docs/

## Seguridad implementada

✔ Helmet

✔ Compression

✔ Rate Limit

✔ JWT Authentication

✔ Control de roles

✔ Validación de datos

## Endpoints

Usuarios:

GET /api/users

POST /api/users

Mesas:

GET /api/mesas

POST /api/mesas

Reservas:

GET /api/reservas

POST /api/reservas

## Autor

Aurora Vargas

Proyecto Lena Reserva
