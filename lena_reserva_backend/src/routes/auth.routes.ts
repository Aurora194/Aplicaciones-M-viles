import { Router } from "express";
import {
    login,
    register,
    refresh,
    logout,
    forgotPassword,
    resetPassword
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

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Solicitar recuperación de contraseña
 *     description: Envía un código de recuperación al correo electrónico registrado.
 *     tags:
 *       - Autenticación
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - correo
 *             properties:
 *               correo:
 *                 type: string
 *                 format: email
 *                 example: usuario@gmail.com
 *     responses:
 *       200:
 *         description: Solicitud procesada correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Si el correo está registrado, se enviará un código de recuperación.
 *       400:
 *         description: Correo electrónico inválido
 *       500:
 *         description: Error interno del servidor
 */
router.post(
  "/forgot-password",
  forgotPassword
);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Restablecer contraseña
 *     description: Permite establecer una nueva contraseña utilizando el código de recuperación enviado al correo.
 *     tags:
 *       - Autenticación
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - correo
 *               - codigo
 *               - nuevaPassword
 *             properties:
 *               correo:
 *                 type: string
 *                 format: email
 *                 example: usuario@gmail.com
 *               codigo:
 *                 type: string
 *                 example: "123456"
 *                 description: Código de recuperación de 6 dígitos.
 *               nuevaPassword:
 *                 type: string
 *                 format: password
 *                 example: nueva123
 *                 description: Nueva contraseña del usuario.
 *     responses:
 *       200:
 *         description: Contraseña restablecida correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Contraseña restablecida correctamente.
 *       400:
 *         description: Código inválido, expirado o datos incorrectos
 *       404:
 *         description: Usuario no encontrado
 *       500:
 *         description: Error interno del servidor
 */
router.post(
  "/reset-password",
  resetPassword
);

export default router;