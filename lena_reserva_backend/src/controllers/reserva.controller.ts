import {
  Request,
  Response,
} from "express";

import {
  EstadoReserva,
} from "@prisma/client";

import {
  ReservaService,
} from "../services/reserva.service";

import {
  logger,
} from "../config/logger";

const service =
  new ReservaService();

class ReservaController {
  /* ============================================================
     LISTAR RESERVAS
     ============================================================ */

  async getReservas(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        "Consulta de reservas realizada"
      );

      /*
       * Paginación:
       *
       * Página inicial: 1
       * Límite predeterminado: 15
       */
      const page =
        Math.max(
          1,
          Number(req.query.page) || 1
        );

      const limit =
        Math.max(
          1,
          Number(req.query.limit) || 15
        );

      const cliente =
        req.query.cliente as
          | string
          | undefined;

      const mesa =
        req.query.mesa
          ? Number(req.query.mesa)
          : undefined;

      const fecha =
        req.query.fecha as
          | string
          | undefined;

      const estado =
        req.query.estado as
          | EstadoReserva
          | undefined;

      const order =
        req.query.order === "desc"
          ? "desc"
          : "asc";

      const result =
        await service.getReservas(
          page,
          limit,
          cliente,
          mesa,
          fecha,
          estado,
          order,
          (req as any).user
        );

      return res.json(result);
    } catch (error: any) {
      logger.error(
        `Error al consultar reservas: ${error.message}`
      );

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  /* ============================================================
     OBTENER UNA RESERVA
     ============================================================ */

  async getOne(
    req: Request,
    res: Response
  ) {
    try {
      const result =
        await service.getOne(
          Number(req.params.id),
          (req as any).user
        );

      return res.json(result);
    } catch (error: any) {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
  }

  /* ============================================================
     CREAR
     ============================================================ */

  async create(
    req: Request,
    res: Response
  ) {
    try {
      const result =
        await service.create(
          req.body,
          (req as any).user
        );

      logger.info(
        `Reserva ${result.data.id} creada correctamente`
      );

      return res
        .status(201)
        .json(result);
    } catch (error: any) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }

  /* ============================================================
     ACTUALIZAR
     ============================================================ */

  async update(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        `Actualizando reserva ${req.params.id}`
      );

      const result =
        await service.update(
          Number(req.params.id),
          req.body,
          (req as any).user
        );

      return res.json(result);
    } catch (error: any) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }

  /* ============================================================
     ELIMINAR
     ============================================================ */

  async remove(
    req: Request,
    res: Response
  ) {
    try {
      const id =
        Number(req.params.id);

      logger.info(
        `Eliminando reserva ${id}`
      );

      const result =
        await service.remove(
          id,
          (req as any).user
        );

      return res.json(result);
    } catch (error: any) {
      logger.error(
        `Error al eliminar reserva ${req.params.id}: ${error.message}`
      );

      /*
       * 403 cuando no es administrador.
       */
      if (
        error.message.includes(
          "Solo un administrador"
        )
      ) {
        return res.status(403).json({
          success: false,
          message: error.message,
        });
      }

      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
}

export const controller =
  new ReservaController();

