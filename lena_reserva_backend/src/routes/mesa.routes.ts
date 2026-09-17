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
 *     summary: Obtener mesas disponibles para una fecha y hora
 *     description: >
 *       Obtiene las mesas que están habilitadas y que no poseen una reserva
 *       pendiente o confirmada para la fecha y hora indicada.
 *       Las reservas canceladas no bloquean la disponibilidad de la mesa.
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: fecha
 *         required: false
 *         schema:
 *           type: string
 *           format: date-time
 *         description: >
 *           Fecha y hora para consultar la disponibilidad de las mesas.
 *           Si no se proporciona, se muestran las mesas marcadas como disponibles.
 *         example: "2026-09-20T20:30:00.000Z"
 *     responses:
 *       200:
 *         description: Lista de mesas disponibles.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 1
 *                       numero:
 *                         type: string
 *                         example: "VIP 1"
 *                       capacidad:
 *                         type: integer
 *                         example: 4
 *                       disponible:
 *                         type: boolean
 *                         example: true
 *       400:
 *         description: Fecha inválida o error al consultar la disponibilidad.
 *       401:
 *         description: Token inválido o inexistente.
 */
router.get(
  "/disponibles",
  authenticateToken,
  controller.disponibles.bind(controller)
);

/**
 * @swagger
 * /api/mesas:
 *   get:
 *     summary: Listar todas las mesas
 *     description: >
 *       Obtiene las mesas registradas que no han sido eliminadas.
 *       Este endpoint está disponible únicamente para usuarios administradores.
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *           minimum: 1
 *         description: Número de página.
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *           minimum: 1
 *         description: Cantidad de registros por página.
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Texto para buscar por número o nombre de mesa.
 *         example: "VIP"
 *       - in: query
 *         name: disponible
 *         schema:
 *           type: boolean
 *         description: Filtrar mesas por disponibilidad general.
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum:
 *             - asc
 *             - desc
 *           default: asc
 *         description: Orden de los resultados.
 *     responses:
 *       200:
 *         description: Lista de mesas obtenida correctamente.
 *       401:
 *         description: Token inválido o inexistente.
 *       403:
 *         description: El usuario no tiene permisos de administrador.
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
 *     description: Obtiene la información de una mesa específica.
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Identificador de la mesa.
 *         example: 1
 *     responses:
 *       200:
 *         description: Mesa encontrada correctamente.
 *       401:
 *         description: Token inválido o inexistente.
 *       403:
 *         description: El usuario no tiene permisos de administrador.
 *       404:
 *         description: Mesa no encontrada.
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
 *     description: >
 *       Registra una nueva mesa. El número o nombre de la mesa debe ser único.
 *       El campo numero se maneja como texto para permitir valores como
 *       "7", "VIP 1" o "Salón VIP 1".
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
 *                 type: string
 *                 description: Número o nombre identificador de la mesa.
 *                 example: "VIP 1"
 *               capacidad:
 *                 type: integer
 *                 minimum: 1
 *                 description: Cantidad máxima de personas que puede recibir la mesa.
 *                 example: 4
 *               disponible:
 *                 type: boolean
 *                 description: Indica si la mesa está habilitada para recibir reservas.
 *                 default: true
 *                 example: true
 *     responses:
 *       201:
 *         description: Mesa creada correctamente.
 *       400:
 *         description: Error de validación o mesa duplicada.
 *       401:
 *         description: Token inválido o inexistente.
 *       403:
 *         description: El usuario no tiene permisos de administrador.
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
 *     description: >
 *       Actualiza los datos de una mesa existente. No se permite cambiar
 *       el estado de disponibilidad mientras la mesa tenga una reserva
 *       pendiente o confirmada activa.
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Identificador de la mesa.
 *         example: 1
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               numero:
 *                 type: string
 *                 description: Número o nombre identificador de la mesa.
 *                 example: "Salón VIP 1"
 *               capacidad:
 *                 type: integer
 *                 minimum: 1
 *                 description: Capacidad máxima de la mesa.
 *                 example: 6
 *               disponible:
 *                 type: boolean
 *                 description: Estado general de disponibilidad de la mesa.
 *                 example: true
 *     responses:
 *       200:
 *         description: Mesa actualizada correctamente.
 *       400:
 *         description: Error de validación, mesa duplicada o mesa con reserva activa.
 *       401:
 *         description: Token inválido o inexistente.
 *       403:
 *         description: El usuario no tiene permisos de administrador.
 *       404:
 *         description: Mesa no encontrada.
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
 *     description: >
 *       Realiza la eliminación lógica de una mesa. Una mesa no puede ser
 *       eliminada si posee una reserva pendiente o confirmada activa.
 *       Las reservas canceladas no impiden la eliminación.
 *     tags: [Mesas]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Identificador de la mesa.
 *         example: 1
 *     responses:
 *       200:
 *         description: Mesa eliminada correctamente.
 *       400:
 *         description: La mesa tiene una reserva pendiente o confirmada.
 *       401:
 *         description: Token inválido o inexistente.
 *       403:
 *         description: El usuario no tiene permisos de administrador.
 *       404:
 *         description: Mesa no encontrada.
 */
router.delete(
  "/:id",
  authenticateToken,
  authorizeRole("ADMIN"),
  controller.remove.bind(controller)
);

export default router;