import { Request, Response } from "express";
import { MesaService } from "../services/mesa.service";

const service = new MesaService();

export class MesaController {

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

      return res.status(200).json(result);

    } catch (error) {

      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Error interno del servidor"
      });

    }

  }

}

export const controller = new MesaController();