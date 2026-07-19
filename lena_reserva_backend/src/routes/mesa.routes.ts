import { Router } from "express";
import * as mesaController from "../controllers/mesa.controller";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";
import { validate } from "../middleware/validate.middleware";
import { mesaSchema } from "../validations/mesa.validation";

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Mesas
 *   description: Gestión de mesas del restaurante
 */

/**
 * @swagger
 * /api/mesas/disponibles:
 *   get:
 *     summary: Obtener mesas disponibles
 *     tags: [Mesas]
 *     responses:
 *       200:
 *         description: Lista de mesas disponibles.
 */
router.get(
    "/disponibles",
    mesaController.disponibles
);

/**
 * @swagger
 * /api/mesas:
 *   get:
 *     summary: Listar todas las mesas
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de mesas.
 */
router.get(
    "/",
    authenticateToken,
    authorizeRole("ADMIN"),
    mesaController.list
);

/**
 * @swagger
 * /api/mesas/{id}:
 *   get:
 *     summary: Obtener una mesa por ID
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Mesa encontrada.
 *       404:
 *         description: Mesa no encontrada.
 */
router.get(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    mesaController.getOne
);

/**
 * @swagger
 * /api/mesas:
 *   post:
 *     summary: Crear una mesa
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - numero
 *               - capacidad
 *             properties:
 *               numero:
 *                 type: integer
 *                 example: 5
 *               capacidad:
 *                 type: integer
 *                 example: 4
 *               disponible:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       201:
 *         description: Mesa creada correctamente.
 */
router.post(
    "/",
    authenticateToken,
    authorizeRole("ADMIN"),
    validate(mesaSchema),
    mesaController.create
);

/**
 * @swagger
 * /api/mesas/{id}:
 *   put:
 *     summary: Actualizar una mesa
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Mesa actualizada.
 */
router.put(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    validate(mesaSchema),
    mesaController.update
);

/**
 * @swagger
 * /api/mesas/{id}:
 *   delete:
 *     summary: Eliminar una mesa
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Mesa eliminada.
 */
router.delete(
    "/:id",
    authenticateToken,
    authorizeRole("ADMIN"),
    mesaController.remove
);

export default router;