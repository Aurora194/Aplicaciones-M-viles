import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";
import * as userController from "../controllers/user.controller";
import { validate } from "../middleware/validate.middleware";
import { updateUserSchema } from "../validations/user.validation";

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Usuarios
 *   description: Gestión de usuarios
 */

/**
 * @swagger
 * /api/usuarios/perfil:
 *   get:
 *     summary: Obtener perfil del usuario autenticado
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Perfil obtenido correctamente
 */
router.get(
    "/perfil",
    authenticateToken,
    (req, res) => {
        res.json({
            success: true,
            usuario: req.user
        });
    }
);

/**
 * @swagger
 * /api/usuarios/admin:
 *   get:
 *     summary: Panel administrador
 *     tags: [Usuarios]
 */
router.get(
    "/admin",
    authenticateToken,
    authorizeRole("ADMIN"),
    (req, res) => {
        res.json({
            success: true,
            mensaje: "Bienvenido administrador"
        });
    }
);

/**
 * @swagger
 * /api/usuarios:
 *   get:
 *     summary: Listar usuarios
 *     tags: [Usuarios]
 */
router.get(
    "/",
    authenticateToken,
    authorizeRole("ADMIN"),
    userController.listUsers
);

/**
 * @swagger
 * /api/usuarios/{id}:
 *   get:
 *     summary: Obtener usuario por ID
 *     tags: [Usuarios]
 */
router.get(
    "/:id",
    authenticateToken,
    userController.getOne
);

/**
 * @swagger
 * /api/usuarios/{id}:
 *   put:
 *     summary: Actualizar usuario
 *     tags: [Usuarios]
 */
router.put(
    "/:id",
    authenticateToken,
    validate(updateUserSchema),
    userController.update
);

/**
 * @swagger
 * /api/usuarios/{id}:
 *   delete:
 *     summary: Eliminar usuario
 *     tags: [Usuarios]
 */
router.delete(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    userController.remove
);

export default router;