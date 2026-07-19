import { Router } from "express";
import * as controller from "../controllers/reserva.controller";
import { authenticateToken } from "../middleware/auth.middleware";
import { authorizeRole } from "../middleware/role.middleware";
import { validate } from "../middleware/validate.middleware";
import { reservaSchema } from "../validations/reserva.validation";

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Reservas
 *   description: Gestión de reservas
 */

/**
 * @swagger
 * /api/reservas:
 *   get:
 *     summary: Listar reservas
 *     tags: [Reservas]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de reservas.
 */
router.get(
    "/",
    authenticateToken,
    authorizeRole("ADMIN"),
    controller.list
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
 */
router.get(
    "/:id",
    authenticateToken,
    controller.getOne
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
 *     responses:
 *       201:
 *         description: Reserva creada correctamente.
 */
router.post(
    "/",
    authenticateToken,
    validate(reservaSchema),
    controller.create
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
 *     responses:
 *       200:
 *         description: Reserva actualizada.
 */
router.put(
    "/:id",
    authenticateToken,
    validate(reservaSchema),
    controller.update
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
 *         description: Reserva eliminada.
 */
router.delete(
    "/:id",
    authenticateToken,
    controller.remove
);

export default router;