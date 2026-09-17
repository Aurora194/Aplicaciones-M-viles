import { Request, Response } from "express";

import { MesaService } from "../services/mesa.service";
import { logger } from "../config/logger";

const service = new MesaService();

class MesaController {
  // =========================================================
  // LISTAR MESAS
  // =========================================================

  async getMesas(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        "Consulta de mesas"
      );

      const page =
        Number(req.query.page) || 1;

      const limit =
        Number(req.query.limit) || 10;

      const search =
        req.query.search as
          | string
          | undefined;

      const disponible =
        req.query.disponible === undefined
          ? undefined
          : req.query.disponible ===
            "true";

      const order =
        (req.query.order as
          | "asc"
          | "desc") || "asc";

      const result =
        await service.getMesas(
          page,
          limit,
          search,
          disponible,
          order
        );

      return res.json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message:
          error?.message ??
          "Error interno del servidor",
      });
    }
  }

  // =========================================================
  // MESAS DISPONIBLES
  // =========================================================

  async disponibles(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        "Consulta de mesas disponibles"
      );

      const fechaParam =
        req.query.fecha;

      let fecha:
        | string
        | undefined;

      if (
        typeof fechaParam ===
        "string"
      ) {
        fecha =
          fechaParam.trim();

        if (!fecha) {
          fecha = undefined;
        }
      }

      console.log(
        "======================================"
      );

      console.log(
        "CONTROLLER DISPONIBILIDAD"
      );

      console.log(
        "Query fecha:",
        fecha
      );

      const result =
        await service.getMesasDisponibles(
          fecha
        );

      console.log(
        "Resultado disponibilidad:",
        result.data.length,
        "mesas"
      );

      console.log(
        "======================================"
      );

      return res.json(result);
    } catch (error: any) {
      console.error(
        "ERROR DISPONIBILIDAD:",
        error
      );

      return res.status(400).json({
        success: false,
        message:
          error?.message ??
          "No fue posible consultar las mesas disponibles",
      });
    }
  }

  // =========================================================
  // OBTENER UNA MESA
  // =========================================================

  async getOne(
    req: Request,
    res: Response
  ) {
    try {
      const id =
        Number(req.params.id);

      if (
        !Number.isInteger(id) ||
        id <= 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Identificador de mesa inválido",
        });
      }

      const result =
        await service.getMesaById(
          id
        );

      return res.json(result);
    } catch (error: any) {
      return res.status(404).json({
        success: false,
        message:
          error?.message ??
          "Mesa no encontrada",
      });
    }
  }

  // =========================================================
  // CREAR
  // =========================================================

  async create(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        "Mesa creada"
      );

      const result =
        await service.createMesa(
          req.body
        );

      return res.status(201).json(
        result
      );
    } catch (error: any) {
      console.error(error);

      return res.status(400).json({
        success: false,
        message:
          error?.message ??
          "No fue posible crear la mesa",
      });
    }
  }

  // =========================================================
  // ACTUALIZAR
  // =========================================================

  async update(
    req: Request,
    res: Response
  ) {
    try {
      const id =
        Number(req.params.id);

      if (
        !Number.isInteger(id) ||
        id <= 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Identificador de mesa inválido",
        });
      }

      const result =
        await service.updateMesa(
          id,
          req.body
        );

      return res.json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(400).json({
        success: false,
        message:
          error?.message ??
          "No fue posible actualizar la mesa",
      });
    }
  }

  // =========================================================
  // ELIMINAR
  // =========================================================

  async remove(
    req: Request,
    res: Response
  ) {
    try {
      logger.info(
        "Mesa eliminada"
      );

      const id =
        Number(req.params.id);

      if (
        !Number.isInteger(id) ||
        id <= 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Identificador de mesa inválido",
        });
      }

      const result =
        await service.deleteMesa(
          id
        );

      return res.json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(400).json({
        success: false,
        message:
          error?.message ??
          "No fue posible eliminar la mesa",
      });
    }
  }
}

export const controller =
  new MesaController();