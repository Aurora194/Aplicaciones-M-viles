import { Request, Response } from "express";
import { MesaService } from "../services/mesa.service";

const service = new MesaService();

class MesaController {

  async getMesas(req: Request, res: Response) {

    try {

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;
      const search = req.query.search as string;

      const disponible =
        req.query.disponible === undefined
          ? undefined
          : req.query.disponible === "true";

      const order =
        (req.query.order as "asc" | "desc") || "asc";

      const result = await service.getMesas(
        page,
        limit,
        search,
        disponible,
        order
      );

      return res.json(result);

    } catch (error) {

      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Error interno del servidor"
      });

    }

  }

  async disponibles(req: Request, res: Response) {

    const result = await service.getMesas(
      1,
      100,
      undefined,
      true,
      "asc"
    );

    res.json(result);

  }

  async getOne(req: Request, res: Response) {

    try {

      const id = Number(req.params.id);

      const result = await service.getMesaById(id);

      res.json(result);

    } catch {

      res.status(404).json({
        success: false,
        message: "Mesa no encontrada"
      });

    }

  }

  async create(req: Request, res: Response) {

    try {

      const result = await service.createMesa(req.body);

      res.status(201).json(result);

    } catch (error) {

      console.error(error);

      res.status(500).json({
        success: false,
        message: "No fue posible crear"
      });

    }

  }

  async update(req: Request, res: Response) {

    try {

      const id = Number(req.params.id);

      const result = await service.updateMesa(id, req.body);

      res.json(result);

    } catch {

      res.status(500).json({
        success: false,
        message: "No fue posible actualizar"
      });

    }

  }

  async remove(req: Request, res: Response) {

    try {

      const id = Number(req.params.id);

      const result = await service.deleteMesa(id);

      res.json(result);

    } catch {

      res.status(500).json({
        success: false,
        message: "No fue posible eliminar"
      });

    }

  }

}

export const controller = new MesaController();