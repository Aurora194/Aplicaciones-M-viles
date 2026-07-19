import { Router } from "express";
import {
    login,
    register,
    refresh,
    logout
} from "../controllers/auth.controller";


const router = Router();


/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Autenticación de usuarios
 */


/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Registrar usuario
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *                 example: Juan
 *               apellido:
 *                 type: string
 *                 example: Perez
 *               correo:
 *                 type: string
 *                 example: juan@gmail.com
 *               telefono:
 *                 type: string
 *                 example: 0999999999
 *               password:
 *                 type: string
 *                 example: 123456
 *     responses:
 *       201:
 *         description: Usuario creado
 */
router.post(
    "/register",
    register
);



/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login usuario
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               correo:
 *                 type: string
 *                 example: admin@gmail.com
 *               password:
 *                 type: string
 *                 example: 123456
 *     responses:
 *       200:
 *         description: Login correcto
 */
router.post(
    "/login",
    login
);



/**
 * @swagger
 * /api/auth/refresh:
 *   post:
 *     summary: Renovar Access Token
 *     tags: [Auth]
 *     responses:
 *       200:
 *         description: Token renovado
 */
router.post(
    "/refresh",
    refresh
);



/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Cerrar sesión
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logout correcto
 */
router.post(
    "/logout",
    logout
);



export default router;