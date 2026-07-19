import { Router } from "express";
import { controller } from "../controllers/mesa.controller";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";

const router = Router();

/**
 * @swagger
 * tags:
 *   - name: Mesas
 *     description: Gestión de mesas del restaurante
 */

/**
 * @swagger
 * /api/mesas/disponibles:
 *   get:
 *     summary: Obtener mesas disponibles
 *     tags: [Mesas]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Número de mesa
 *       - in: query
 *         name: disponible
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum:
 *             - asc
 *             - desc
 *           default: asc
 *     responses:
 *       200:
 *         description: Lista de mesas disponibles.
 */
router.get(
  "/disponibles",
  controller.disponibles.bind(controller)
);

/**
 * @swagger
 * /api/mesas:
 *   get:
 *     summary: Listar todas las mesas
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Número de mesa
 *       - in: query
 *         name: disponible
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum:
 *             - asc
 *             - desc
 *           default: asc
 *     responses:
 *       200:
 *         description: Lista de mesas obtenida correctamente.
 *       401:
 *         description: Token inválido o inexistente.
 */
router.get(
  "/",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.getMesas.bind(controller)
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
 *       401:
 *         description: Token inválido.
 */
router.get(
  "/:id",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.getOne.bind(controller)
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
 *       400:
 *         description: Error de validación.
 *       401:
 *         description: Token inválido.
 */
router.post(
  "/",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.create.bind(controller)
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
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               numero:
 *                 type: integer
 *                 example: 8
 *               capacidad:
 *                 type: integer
 *                 example: 6
 *               disponible:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Mesa actualizada correctamente.
 *       400:
 *         description: Error de validación.
 *       404:
 *         description: Mesa no encontrada.
 *       401:
 *         description: Token inválido.
 */
router.put(
  "/:id",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.update.bind(controller)
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
 *         description: Mesa eliminada correctamente.
 *       404:
 *         description: Mesa no encontrada.
 *       401:
 *         description: Token inválido.
 */
router.delete(
  "/:id",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.remove.bind(controller)
);

export default router;