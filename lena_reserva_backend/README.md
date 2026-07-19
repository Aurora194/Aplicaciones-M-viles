# Lena Reserva Backend


API REST para gestión de reservas.


## Tecnologías

- Node.js
- Express
- TypeScript
- Prisma ORM
- MySQL
- JWT
- Swagger
- Docker


## Instalación


Clonar proyecto:

git clone URL


Instalar dependencias:

npm install



## Variables de entorno


Crear:

.env


Ejemplo:


DATABASE_URL="mysql://root:@localhost:3306/lena_reserva"

JWT_SECRET=lena_reserva_secret



## Base de datos


Migraciones:

npx prisma migrate dev



Generar Prisma:

npx prisma generate



## Ejecutar


Desarrollo:

npm run dev



Producción:

npm run build

npm start



## Documentación API


Swagger:

http://localhost:3000/api-docs



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