import { Router } from "express";

import {

    getUsers,

    getUserById,

    updateUser,

    deleteUser

} from "../controllers/user.controller";

import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Usuarios
 *   description: Gestión de usuarios
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Obtener usuarios con paginación, búsqueda y filtros
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         example: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         example: 10
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         example: juan
 *       - in: query
 *         name: rol
 *         schema:
 *           type: string
 *         example: CLIENTE
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *         example: nombre
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *         example: asc
 *     responses:
 *       200:
 *         description: Lista de usuarios.
 */

router.get(

    "/",

    authenticateToken,

    authorizeRole("ADMIN"),

    getUsers

);

router.get(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    getUserById

);

router.put(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    updateUser

);

router.delete(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    deleteUser

);

export default router;