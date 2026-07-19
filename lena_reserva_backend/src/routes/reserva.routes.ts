import { Router } from "express";
import { controller } from "../controllers/reserva.controller";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";
import { validate } from "../middleware/validate.middleware";
import {
  reservaSchema,
  updateReservaSchema,
} from "../schemas/reserva.schema";

const router = Router();

/**
 * @swagger
 * tags:
 *   - name: Reservas
 *     description: Gestión de reservas
 */

/**
 * @swagger
 * /api/reservas:
 *   get:
 *     summary: Listar reservas
 *     tags: [Reservas]
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
 *         name: cliente
 *         schema:
 *           type: string
 *         description: Buscar por nombre, apellido o correo
 *       - in: query
 *         name: mesa
 *         schema:
 *           type: integer
 *       - in: query
 *         name: fecha
 *         schema:
 *           type: string
 *           format: date
 *           example: "2026-07-20"
 *       - in: query
 *         name: estado
 *         schema:
 *           type: string
 *           enum:
 *             - PENDIENTE
 *             - CONFIRMADA
 *             - CANCELADA
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
 *         description: Lista de reservas obtenida correctamente.
 *       401:
 *         description: Token inválido o inexistente.
 */
router.get(
  "/",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.getReservas.bind(controller)
);

/**
 * @swagger
 * /api/reservas/{id}:
 *   get:
 *     summary: Obtener una reserva por ID
 *     tags: [Reservas]
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
 *         description: Reserva encontrada.
 *       404:
 *         description: Reserva no encontrada.
 *       401:
 *         description: Token inválido.
 */
router.get(
  "/:id",
  authenticateToken,
  controller.getOne.bind(controller)
);

/**
 * @swagger
 * /api/reservas:
 *   post:
 *     summary: Crear una reserva
 *     tags: [Reservas]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - fecha
 *               - personas
 *               - usuarioId
 *               - mesaId
 *             properties:
 *               fecha:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-07-20T19:30:00.000Z"
 *               personas:
 *                 type: integer
 *                 example: 4
 *               usuarioId:
 *                 type: integer
 *                 example: 1
 *               mesaId:
 *                 type: integer
 *                 example: 2
 *               estado:
 *                 type: string
 *                 enum:
 *                   - PENDIENTE
 *                   - CONFIRMADA
 *                   - CANCELADA
 *                 example: PENDIENTE
 *     responses:
 *       201:
 *         description: Reserva creada correctamente.
 *       400:
 *         description: Error de validación.
 *       401:
 *         description: Token inválido.
 */
router.post(
  "/",
  authenticateToken,
  validate(reservaSchema),
  controller.create.bind(controller)
);

/**
 * @swagger
 * /api/reservas/{id}:
 *   put:
 *     summary: Actualizar una reserva
 *     tags: [Reservas]
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
 *               fecha:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-07-21T20:00:00.000Z"
 *               personas:
 *                 type: integer
 *                 example: 6
 *               usuarioId:
 *                 type: integer
 *                 example: 1
 *               mesaId:
 *                 type: integer
 *                 example: 2
 *               estado:
 *                 type: string
 *                 enum:
 *                   - PENDIENTE
 *                   - CONFIRMADA
 *                   - CANCELADA
 *                 example: CONFIRMADA
 *     responses:
 *       200:
 *         description: Reserva actualizada correctamente.
 *       400:
 *         description: Error de validación.
 *       404:
 *         description: Reserva no encontrada.
 *       401:
 *         description: Token inválido.
 */
router.put(
  "/:id",
  authenticateToken,
  validate(updateReservaSchema),
  controller.update.bind(controller)
);

/**
 * @swagger
 * /api/reservas/{id}:
 *   delete:
 *     summary: Eliminar una reserva
 *     tags: [Reservas]
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
 *         description: Reserva eliminada correctamente.
 *       404:
 *         description: Reserva no encontrada.
 *       401:
 *         description: Token inválido.
 */
router.delete(
  "/:id",
  authenticateToken,
  controller.remove.bind(controller)
);

export default router;