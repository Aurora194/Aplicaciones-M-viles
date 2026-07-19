import { Router } from "express";
import { controller } from "../controllers/user.controller";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";

const router = Router();
/**
 * @swagger
 * tags:
 *   name: Usuarios
 *   description: Gestión de usuarios
 */

router.get(
    "/",
    authenticateToken,
    authorizeRole("ADMIN"),
    controller.getUsers.bind(controller)
);
/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Obtener usuarios
 *     description: Lista usuarios con paginación, búsqueda y filtros.
 *     tags:
 *       - Usuarios
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: page
 *         in: query
 *         schema:
 *           type: integer
 *           example: 1
 *
 *       - name: limit
 *         in: query
 *         schema:
 *           type: integer
 *           example: 10
 *
 *       - name: search
 *         in: query
 *         schema:
 *           type: string
 *           example: Juan
 *
 *       - name: rol
 *         in: query
 *         schema:
 *           type: string
 *           enum:
 *             - ADMIN
 *             - CLIENTE
 *
 *     responses:
 *       200:
 *         description: Usuarios encontrados
 *
 *       401:
 *         description: Token inválido
 *
 *       403:
 *         description: Sin permisos
 */ 
/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Obtener un usuario por ID
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 1
 *     responses:
 *       200:
 *         description: Usuario encontrado.
 *       404:
 *         description: Usuario no encontrado.
 *       401:
 *         description: Token inválido.
 *       403:
 *         description: Acceso denegado.
 */
router.get(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    controller.getUserById.bind(controller)
);

/**
 * @swagger
 * /api/users/{id}:
 *   put:
 *     summary: Actualizar un usuario
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 1
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
 *                 example: Pérez
 *               telefono:
 *                 type: string
 *                 example: 0999999999
 *               rol:
 *                 type: string
 *                 enum:
 *                   - ADMIN
 *                   - CLIENTE
 *     responses:
 *       200:
 *         description: Usuario actualizado correctamente.
 *       404:
 *         description: Usuario no encontrado.
 *       401:
 *         description: Token inválido.
 *       403:
 *         description: Acceso denegado.
 */
router.put(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    controller.updateUser.bind(controller)
);
/**
 * @swagger
 * /api/users/{id}:
 *   delete:
 *     summary: Eliminar un usuario (Soft Delete)
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 1
 *     responses:
 *       200:
 *         description: Usuario eliminado correctamente.
 *       404:
 *         description: Usuario no encontrado.
 *       401:
 *         description: Token inválido.
 *       403:
 *         description: Acceso denegado.
 */
router.delete(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    controller.deleteUser.bind(controller)
);

export default router;